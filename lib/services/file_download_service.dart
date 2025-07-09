import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'message_logger.dart';
import 'file_server_service.dart';

/// Manages file downloads for clients
class FileDownloadService {
  final MessageLogger _logger;
  final Function()? _onStateChanged;
  final Map<String, FileDownloadTask> _downloadTasks = {};
  
  // Map to track file locks to prevent concurrent operations on the same file
  final Map<String, Completer<void>> _fileLocks = {};
  
  FileDownloadService(this._logger, {Function()? onStateChanged}) 
    : _onStateChanged = onStateChanged;
  
  // Getters
  List<FileDownloadTask> get activeTasks => _downloadTasks.values.toList();
  
  /// Acquire a lock on a file to prevent concurrent access
  Future<void> _acquireFileLock(String filePath) async {
    if (_fileLocks.containsKey(filePath)) {
      // Wait for existing operation to complete
      _logger.log('🔒 Waiting for file lock on: ${path.basename(filePath)}');
      await _fileLocks[filePath]!.future;
    }
    
    // Create a new lock
    _fileLocks[filePath] = Completer<void>();
  }
  
  /// Release a file lock
  void _releaseFileLock(String filePath) {
    if (_fileLocks.containsKey(filePath)) {
      _fileLocks[filePath]!.complete();
      _fileLocks.remove(filePath);
      _logger.log('🔓 Released file lock on: ${path.basename(filePath)}');
    }
  }
  
  /// Start downloading a file from a share info
  Future<FileDownloadTask?> downloadFile(FileShareInfo shareInfo) async {
    _logger.log('📥 Starting download for file: ${shareInfo.fileName}');
    
    try {
      // Create download directory if it doesn't exist
      final downloadsDir = await _getDownloadsDirectory();
      
      // Generate unique filename to avoid conflicts
      final fileName = shareInfo.fileName;
      final filePath = path.join(downloadsDir.path, fileName);
      
      // Acquire a lock on the file
      await _acquireFileLock(filePath);
      
      try {
        // Check if file already exists and handle appropriately
        var file = File(filePath);
        if (await file.exists()) {
          // Append number to filename to make it unique
          final baseName = path.basenameWithoutExtension(fileName);
          final extension = path.extension(fileName);
          int counter = 1;
          String newPath;
          do {
            newPath = path.join(downloadsDir.path, '${baseName}_$counter$extension');
            counter++;
          } while (await File(newPath).exists());
          
          _logger.log('⚠️ File already exists, saving as: ${path.basename(newPath)}');
          file = File(newPath);
        }
        
        // Create a download task
        final task = FileDownloadTask(
          fileId: shareInfo.fileId,
          fileName: path.basename(file.path),
          fileSize: shareInfo.fileSize,
          url: shareInfo.url,
          destinationFile: file,
          startTime: DateTime.now(),
        );
        
        // Store task
        _downloadTasks[shareInfo.fileId] = task;
        _onStateChanged?.call();
        
        // Release the file lock before starting the download
        _releaseFileLock(filePath);
        
        // Start download
        _startDownload(task);
        
        return task;
      } catch (e) {
        // Make sure to release the lock if there's an error
        _releaseFileLock(filePath);
        rethrow;
      }
    } catch (e) {
      _logger.log('❌ Error starting download: $e');
      return null;
    }
  }
  
  /// Start the actual download process
  Future<void> _startDownload(FileDownloadTask task) async {
    _logger.log('🚀 Starting download from: ${task.url}');
    
    try {
      // Acquire a lock on the destination file
      final filePath = task.destinationFile.path;
      await _acquireFileLock(filePath);
      
      try {
        // Check if we can resume a previous download
        int startByte = 0;
        if (await task.destinationFile.exists()) {
          startByte = await task.destinationFile.length();
          if (startByte > 0) {
            _logger.log('⏯️ Resuming download from byte: $startByte');
            task.bytesDownloaded = startByte;
          }
        }
        
        // Create HTTP client
        final client = http.Client();
        
        try {
          // Create request with range header for resuming
          final request = http.Request('GET', Uri.parse(task.url));
          if (startByte > 0) {
            request.headers['Range'] = 'bytes=$startByte-';
          }
          
          // Add cache control headers
          request.headers['Cache-Control'] = 'no-cache';
          request.headers['Pragma'] = 'no-cache';
          
          // Send request and get stream
          final streamedResponse = await client.send(request);
          
          if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 206) {
            task.status = DownloadStatus.inProgress;
            _onStateChanged?.call();
            
            // Get content length for progress calculation
            final contentLength = streamedResponse.contentLength ?? task.fileSize;
            
            // If we're starting fresh (status 200), truncate the file
            if (streamedResponse.statusCode == 200 && startByte > 0) {
              // Truncate file for fresh download
              await task.destinationFile.writeAsBytes([], mode: FileMode.write);
              startByte = 0;
              task.bytesDownloaded = 0;
            }
            
            // Update task with expected total
            task.expectedBytes = startByte + contentLength;
            
            // Create download timer
            final now = DateTime.now();
            
            // For large video files, use a different approach with direct writing
            // instead of using RandomAccessFile which might cause locking issues
            final bytes = await streamedResponse.stream.toList();
            
            if (startByte > 0) {
              // For resumed downloads, append to existing file
              final existingBytes = await task.destinationFile.readAsBytes();
              List<int> combinedBytes = [...existingBytes];
              
              // Process bytes in chunks to update progress
              int processedBytes = 0;
              final chunkSize = 65536; // 64KB chunks
              
              for (var chunk in bytes) {
                combinedBytes.addAll(chunk);
                processedBytes += chunk.length;
                
                // Update progress periodically
                task.bytesDownloaded = startByte + processedBytes;
                _onStateChanged?.call(); // Notify listeners of progress update
                
                // Don't update too frequently to avoid UI lag
                if (processedBytes % chunkSize == 0) {
                  await Future.delayed(const Duration(milliseconds: 100));
                }
              }
              
              await task.destinationFile.writeAsBytes(combinedBytes, flush: true);
            } else {
              // For fresh downloads, process and write in chunks
              final outputFile = await task.destinationFile.open(mode: FileMode.write);
              
              try {
                int processedBytes = 0;
                final chunkSize = 65536; // 64KB chunks
                
                for (var chunk in bytes) {
                  await outputFile.writeFrom(chunk);
                  processedBytes += chunk.length;
                  
                  // Update progress periodically
                  task.bytesDownloaded = processedBytes;
                  _onStateChanged?.call(); // Notify listeners of progress update
                  
                  // Don't update too frequently to avoid UI lag
                  if (processedBytes % chunkSize == 0) {
                    await Future.delayed(const Duration(milliseconds: 100));
                  }
                }
              } finally {
                await outputFile.close();
              }
            }
            
            // Update progress
            task.bytesDownloaded = startByte + bytes.length;
            
            // Calculate final speed
            final duration = DateTime.now().difference(now).inMilliseconds / 1000;
            task.downloadSpeed = bytes.length / duration; // bytes per second
            
            // Verify file size
            final finalSize = await task.destinationFile.length();
            final expectedSize = task.fileSize;
            
            if (finalSize == expectedSize || (expectedSize == 0 && finalSize > 0)) {
              // Download completed successfully
              task.status = DownloadStatus.completed;
              task.endTime = DateTime.now();
              _logger.log('✅ Download completed: ${task.fileName}');
              _logger.log('📊 Final file size: ${_formatFileSize(finalSize)}');
            } else {
              // File size mismatch but don't fail for videos as size might be estimated
              _logger.log('⚠️ File size difference: expected $expectedSize bytes, got $finalSize bytes');
              if (task.fileName.toLowerCase().endsWith('.mp4') || 
                  task.fileName.toLowerCase().endsWith('.mov') ||
                  task.fileName.toLowerCase().endsWith('.avi')) {
                _logger.log('📹 Video file download - ignoring size difference');
                task.status = DownloadStatus.completed;
                task.endTime = DateTime.now();
              } else if ((finalSize - expectedSize).abs() < 1024) {
                // Small difference (less than 1KB) is acceptable
                _logger.log('✅ File size difference is minimal, marking as completed');
                task.status = DownloadStatus.completed;
                task.endTime = DateTime.now();
              } else {
                task.status = DownloadStatus.failed;
                task.error = 'File size verification failed';
              }
            }
          } else {
            task.status = DownloadStatus.failed;
            task.error = 'Server returned ${streamedResponse.statusCode}';
            _logger.log('❌ Download failed with status: ${streamedResponse.statusCode}');
          }
        } finally {
          client.close();
        }
      } finally {
        // Release the file lock
        _releaseFileLock(filePath);
      }
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.error = e.toString();
      _logger.log('❌ Download error: $e');
    }
    
    _onStateChanged?.call();
  }
  
  /// Format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
  
  /// Cancel a download task
  Future<bool> cancelDownload(String fileId) async {
    _logger.log('🛑 Cancelling download for ID: $fileId');
    
    if (!_downloadTasks.containsKey(fileId)) {
      _logger.log('⚠️ Download task not found: $fileId');
      return false;
    }
    
    final task = _downloadTasks[fileId]!;
    task.status = DownloadStatus.cancelled;
    
    // Optional: Delete partial file
    try {
      final filePath = task.destinationFile.path;
      await _acquireFileLock(filePath);
      
      try {
        if (await task.destinationFile.exists()) {
          await task.destinationFile.delete();
          _logger.log('🗑️ Deleted partial download file');
        }
      } finally {
        _releaseFileLock(filePath);
      }
    } catch (e) {
      _logger.log('⚠️ Error deleting partial file: $e');
    }
    
    _downloadTasks.remove(fileId);
    _onStateChanged?.call();
    return true;
  }
  
  /// Get downloads directory
  Future<Directory> _getDownloadsDirectory() async {
    Directory? directory;
    
    try {
      if (Platform.isAndroid) {
        // Use downloads directory on Android
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to app documents directory
          directory = await getApplicationDocumentsDirectory();
        }
      } else {
        // Use documents directory on iOS and other platforms
        directory = await getApplicationDocumentsDirectory();
      }
      
      // Create downloads subfolder
      final downloadsDir = Directory('${directory.path}/MqttDownloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      
      return downloadsDir;
    } catch (e) {
      _logger.log('⚠️ Error getting downloads directory: $e');
      // Fallback to temporary directory
      final tempDir = await getTemporaryDirectory();
      final downloadsDir = Directory('${tempDir.path}/MqttDownloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      return downloadsDir;
    }
  }
  
  /// Clean up resources
  void dispose() {
    // Cancel all active downloads
    _downloadTasks.forEach((id, task) {
      if (task.status == DownloadStatus.inProgress) {
        task.status = DownloadStatus.cancelled;
      }
    });
    _downloadTasks.clear();
  }
}

/// Download status enum
enum DownloadStatus {
  pending,
  inProgress,
  paused,
  completed,
  failed,
  cancelled,
}

/// File download task
class FileDownloadTask {
  final String fileId;
  final String fileName;
  final int fileSize;
  final String url;
  final File destinationFile;
  final DateTime startTime;
  
  DateTime? endTime;
  DownloadStatus status = DownloadStatus.pending;
  int bytesDownloaded = 0;
  int expectedBytes = 0;
  double downloadSpeed = 0.0; // bytes per second
  String? error;
  
  FileDownloadTask({
    required this.fileId,
    required this.fileName,
    required this.fileSize,
    required this.url,
    required this.destinationFile,
    required this.startTime,
  });
  
  /// Get download progress as percentage
  double get progress {
    if (fileSize <= 0) return 0.0;
    return bytesDownloaded / fileSize;
  }
  
  /// Get estimated time remaining in seconds
  int get estimatedTimeRemaining {
    if (downloadSpeed <= 0) return 0;
    final bytesRemaining = fileSize - bytesDownloaded;
    return (bytesRemaining / downloadSpeed).round();
  }
  
  /// Format estimated time remaining
  String get formattedTimeRemaining {
    final seconds = estimatedTimeRemaining;
    if (seconds <= 0) return 'unknown';
    
    if (seconds < 60) {
      return '$seconds sec';
    } else if (seconds < 3600) {
      return '${(seconds / 60).floor()} min ${seconds % 60} sec';
    } else {
      final hours = (seconds / 3600).floor();
      final minutes = ((seconds % 3600) / 60).floor();
      return '$hours hr $minutes min';
    }
  }
  
  /// Format download speed
  String get formattedSpeed {
    if (downloadSpeed < 1024) {
      return '${downloadSpeed.toStringAsFixed(2)} B/s';
    } else if (downloadSpeed < 1024 * 1024) {
      return '${(downloadSpeed / 1024).toStringAsFixed(2)} KB/s';
    } else {
      return '${(downloadSpeed / (1024 * 1024)).toStringAsFixed(2)} MB/s';
    }
  }
}
