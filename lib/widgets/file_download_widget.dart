import 'package:flutter/material.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import '../services/mqtt_service.dart';
import '../services/file_download_service.dart';
import '../services/message_logger.dart';

class FileDownloadWidget extends StatefulWidget {
  final MqttService mqttService;
  
  const FileDownloadWidget({
    super.key,
    required this.mqttService,
  });

  @override
  State<FileDownloadWidget> createState() => _FileDownloadWidgetState();
}

class _FileDownloadWidgetState extends State<FileDownloadWidget> {
  final MessageLogger _logger = MessageLogger();
  
  @override
  void initState() {
    super.initState();
    // Add listener to MqttService to update progress
    widget.mqttService.addListener(_onDownloadUpdate);
  }

  @override
  void dispose() {
    // Remove listener when widget is disposed
    widget.mqttService.removeListener(_onDownloadUpdate);
    super.dispose();
  }

  // Update UI when download progress changes
  void _onDownloadUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get active downloads from service
    final downloads = widget.mqttService.activeDownloads;
    
    if (downloads.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'File Downloads',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Shared files will appear here for download',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'File Downloads',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...downloads.map((task) => _buildDownloadItem(task, context)),
      ],
    );
  }
  
  Widget _buildDownloadItem(FileDownloadTask task, BuildContext context) {
    // Calculate progress
    final progress = task.bytesDownloaded / task.fileSize;
    final percentage = (progress * 100).toStringAsFixed(0);
    
    // Format download status
    String statusText;
    IconData statusIcon;
    Color statusColor;
    
    switch (task.status) {
      case DownloadStatus.inProgress:
        statusText = 'Downloading...';
        statusIcon = Icons.download_rounded;
        statusColor = Colors.blue;
        break;
      case DownloadStatus.completed:
        statusText = 'Download Complete';
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case DownloadStatus.failed:
        statusText = 'Download Failed';
        statusIcon = Icons.error;
        statusColor = Colors.red;
        break;
      case DownloadStatus.cancelled:
        statusText = 'Download Canceled';
        statusIcon = Icons.cancel;
        statusColor = Colors.grey;
        break;
      case DownloadStatus.paused:
        statusText = 'Download Paused';
        statusIcon = Icons.pause;
        statusColor = Colors.orange;
        break;
      case DownloadStatus.pending:
        statusText = 'Waiting...';
        statusIcon = Icons.hourglass_empty;
        statusColor = Colors.orange;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (task.status == DownloadStatus.inProgress) ...[
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${_formatFileSize(task.bytesDownloaded)} / ${_formatFileSize(task.fileSize)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 14,
                  color: statusColor,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (task.status == DownloadStatus.inProgress)
                  TextButton.icon(
                    onPressed: () => _cancelDownload(task.fileId),
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  )
                else if (task.status == DownloadStatus.completed)
                  FileOpenButton(
                    task: task, 
                    logger: _logger,
                  )
                else if (task.status == DownloadStatus.failed)
                  RetryDownloadButton(
                    fileId: task.fileId, 
                    onRetry: _retryDownload,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _cancelDownload(String fileId) {
    widget.mqttService.cancelDownload(fileId);
    setState(() {});
  }
  
  void _retryDownload(String fileId) {
    // This could be implemented in the future
    // For now, show a message that this feature is coming soon
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Retry functionality coming soon')),
    );
  }
  
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
}

// Separate stateful widget to handle file opening with its own BuildContext
class FileOpenButton extends StatefulWidget {
  final FileDownloadTask task;
  final MessageLogger logger;

  const FileOpenButton({
    super.key,
    required this.task,
    required this.logger,
  });

  @override
  State<FileOpenButton> createState() => _FileOpenButtonState();
}

class _FileOpenButtonState extends State<FileOpenButton> {
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _openFile,
      icon: const Icon(Icons.open_in_new, size: 16),
      label: const Text('Open'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Future<void> _openFile() async {
    try {
      // Check if file exists first
      if (!await widget.task.destinationFile.exists()) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File not found: ${widget.task.fileName}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Show file path in a toast
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening file: ${widget.task.fileName}')),
      );
      
      // Log detailed file info for debugging
      widget.logger.log('Opening file at path: ${widget.task.destinationFile.path}');
      widget.logger.log('File exists: ${await widget.task.destinationFile.exists()}');
      widget.logger.log('File size: ${await widget.task.destinationFile.length()} bytes');
      
      // Open the file using open_file package
      final result = await OpenFile.open(widget.task.destinationFile.path);
      
      widget.logger.log('Open file result: ${result.type}, ${result.message}');
      
      if (result.type != ResultType.done && mounted) {
        // Show error if file couldn't be opened
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Try a fallback method if available based on platform
        if (Platform.isAndroid) {
          try {
            final result = await OpenFile.open(
              widget.task.destinationFile.path,
              type: _getMimeTypeFromFileName(widget.task.fileName),
            );
            widget.logger.log('Fallback open result: ${result.type}, ${result.message}');
          } catch (e) {
            widget.logger.log('Fallback open failed: $e');
          }
        }
      }
    } catch (e) {
      // Show error if exception occurs
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: $e'),
          backgroundColor: Colors.red,
        ),
      );
      widget.logger.log('Exception opening file: $e');
    }
  }
  
  // Helper to determine MIME type from file name
  String _getMimeTypeFromFileName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      default:
        return '';
    }
  }
}

// Separate stateful widget to handle retry with its own BuildContext
class RetryDownloadButton extends StatelessWidget {
  final String fileId;
  final Function(String) onRetry;

  const RetryDownloadButton({
    super.key,
    required this.fileId,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => onRetry(fileId),
      icon: const Icon(Icons.refresh, size: 16),
      label: const Text('Retry'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
