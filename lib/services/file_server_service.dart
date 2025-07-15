import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import 'message_logger.dart';
import 'network_helper.dart';

/// Manages the HTTP file server for sharing files between devices
class FileServerService {
  final MessageLogger _logger;
  final Function()? _onStateChanged;
  final Map<String, _SharedFile> _sharedFiles = {};
  
  HttpServer? _server;
  bool _isServerRunning = false;
  final int _port = 8080;
  String _serverIp = '';
  String _networkAccessibleIp = '';
  
  FileServerService(this._logger, {Function()? onStateChanged}) 
    : _onStateChanged = onStateChanged;
  
  // Getters
  bool get isServerRunning => _isServerRunning;
  String get serverUrl => 'http://$_serverIp:$_port';
  String get networkServerUrl => 'http://$_networkAccessibleIp:$_port';
  int get serverPort => _port;
  String get serverIp => _serverIp;
  String get networkAccessibleIp => _networkAccessibleIp;
  
  /// Start the HTTP file server
  Future<bool> startServer(String ip) async {
    if (_isServerRunning) {
      _logger.log('📡 File server is already running');
      return true;
    }
    
    _serverIp = ip;
    _logger.log('🚀 Starting HTTP file server...');
    
    try {
      // Get the network-accessible IP address
      _networkAccessibleIp = await _getNetworkAccessibleIp(ip);
      _logger.log('🌐 Network accessible IP: $_networkAccessibleIp');
      
      // Create a router for handling requests
      final router = Router();
      
      // Route for getting file info
      router.get('/files/<fileId>/info', _handleFileInfoRequest);
      
      // Route for downloading files
      router.get('/files/<fileId>', _handleFileDownloadRequest);
      
      // Route for listing available files
      router.get('/files', _handleListFilesRequest);
      
      // Create a shelf handler with logging
      final logMiddleware = shelf.logRequests();
      final handler = shelf.Pipeline()
          .addMiddleware(logMiddleware)
          .addHandler(router.call);
      
      // Start the server - bind to any IPv4 address to ensure it's accessible from the network
      _logger.log('🔧 Creating HTTP server on 0.0.0.0:$_port (accessible via $_networkAccessibleIp)');
      _server = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4, // Bind to any address so it's accessible from the network
        _port,
        shared: true,
      );
      
      _isServerRunning = true;
      _logger.log('✅ HTTP file server started on $_networkAccessibleIp:$_port');
      if (_onStateChanged != null) {
        _onStateChanged();
      }
      return true;
    } catch (e) {
      _logger.log('❌ Failed to start HTTP file server: $e');
      return false;
    }
  }
  
  /// Get the network-accessible IP address
  Future<String> _getNetworkAccessibleIp(String ip) async {
    // If the IP is already a valid network IP (not localhost), use it
    if (ip != '127.0.0.1' && ip != 'localhost') {
      return ip;
    }
    
    // Try to get the device's IP address
    final deviceIp = await NetworkHelper.getDeviceIPAddress();
    if (deviceIp != null) {
      _logger.log('🔍 Found device IP: $deviceIp');
      return deviceIp;
    }
    
    // If we can't find a valid IP, default to the input IP
    _logger.log('⚠️ Could not determine network IP, using: $ip');
    return ip;
  }
  
  /// Stop the HTTP file server
  Future<void> stopServer() async {
    _logger.log('🛑 Stopping HTTP file server...');
    
    try {
      if (_server != null) {
        await _server!.close(force: true);
        _server = null;
      }
      
      _isServerRunning = false;
      _sharedFiles.clear();
      _logger.log('✅ HTTP file server stopped');
      if (_onStateChanged != null) {
        _onStateChanged();
      }
    } catch (e) {
      _logger.log('❌ Error stopping HTTP file server: $e');
    }
  }
  
  /// Share a file and get a unique URL for it
  Future<FileShareInfo?> shareFile(File file) async {
    // Clear previous shared files so only the latest file is available
    _sharedFiles.clear();
    if (!_isServerRunning) {
      _logger.log('❌ Cannot share file - server not running');
      return null;
    }
    
    try {
      final fileId = const Uuid().v4();
      final fileName = path.basename(file.path);
      final fileSize = await file.length();
      final fileExtension = path.extension(file.path).toLowerCase();
      final mimeType = _getMimeType(fileExtension);
      
      _logger.log('📂 Preparing to share file: $fileName');
      _logger.log('📊 File size: ${_formatFileSize(fileSize)}');
      
      // Store file information
      _sharedFiles[fileId] = _SharedFile(
        id: fileId,
        file: file,
        name: fileName,
        size: fileSize,
        mimeType: mimeType,
        dateAdded: DateTime.now(),
      );
      
      final url = '$serverUrl/files/$fileId';
      _logger.log('🔗 File available at: $url');
      
      return FileShareInfo(
        fileId: fileId,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
        url: url,
      );
    } catch (e) {
      _logger.log('❌ Error sharing file: $e');
      return null;
    }
  }
  
  /// Handle file info request
  Future<shelf.Response> _handleFileInfoRequest(shelf.Request request, String fileId) async {
    _logger.log('📝 File info requested for ID: $fileId');
    
    if (!_sharedFiles.containsKey(fileId)) {
      _logger.log('❌ File not found: $fileId');
      return shelf.Response.notFound('File not found');
    }
    
    final sharedFile = _sharedFiles[fileId]!;
    
    return shelf.Response.ok(
      jsonEncode({
        'id': sharedFile.id,
        'name': sharedFile.name,
        'size': sharedFile.size,
        'mimeType': sharedFile.mimeType,
        'dateAdded': sharedFile.dateAdded.toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }
  
  /// Handle file download request
  Future<shelf.Response> _handleFileDownloadRequest(shelf.Request request, String fileId) async {
    _logger.log('📥 File download requested for ID: $fileId');
    
    if (!_sharedFiles.containsKey(fileId)) {
      _logger.log('❌ File not found: $fileId');
      return shelf.Response.notFound('File not found');
    }
    
    final sharedFile = _sharedFiles[fileId]!;
    final file = sharedFile.file;
    
    // Check if range request (for resumable downloads)
    final rangeHeader = request.headers['range'];
    if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
      return _handleRangeRequest(rangeHeader, file, sharedFile);
    }
    
    _logger.log('📤 Serving complete file: ${sharedFile.name}');
    
    // Add cache control headers to prevent caching issues with large files
    return shelf.Response.ok(
      file.openRead(),
      headers: {
        'Content-Type': sharedFile.mimeType,
        'Content-Length': sharedFile.size.toString(),
        'Content-Disposition': 'attachment; filename="${sharedFile.name}"',
        'Accept-Ranges': 'bytes',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    );
  }
  
  /// Handle range request for resumable downloads
  Future<shelf.Response> _handleRangeRequest(String rangeHeader, File file, _SharedFile sharedFile) async {
    final range = rangeHeader.substring(6);
    final parts = range.split('-');
    
    int start = int.parse(parts[0]);
    int end = parts.length > 1 && parts[1].isNotEmpty 
        ? int.parse(parts[1]) 
        : sharedFile.size - 1;
    
    // Ensure end is not greater than file size
    if (end >= sharedFile.size) {
      end = sharedFile.size - 1;
    }
    
    // Limit chunk size to prevent memory issues with large files
    const maxChunkSize = 5 * 1024 * 1024; // 5MB max chunk
    if (end - start > maxChunkSize) {
      end = start + maxChunkSize - 1;
    }
    
    final length = end - start + 1;
    
    _logger.log('📤 Serving partial file: ${sharedFile.name}, bytes $start-$end/${sharedFile.size}');
    
    return shelf.Response(
      206,
      body: file.openRead(start, end + 1),
      headers: {
        'Content-Type': sharedFile.mimeType,
        'Content-Length': length.toString(),
        'Content-Range': 'bytes $start-$end/${sharedFile.size}',
        'Content-Disposition': 'attachment; filename="${sharedFile.name}"',
        'Accept-Ranges': 'bytes',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    );
  }
  
  /// Handle list files request
  Future<shelf.Response> _handleListFilesRequest(shelf.Request request) async {
    _logger.log('📋 File list requested');
    
    // Extract the Host header from the request to use client's perspective URL
    final requestHost = request.headers['host'];
    String baseUrl;
    
    if (requestHost != null) {
      // Use the host header from the client's request
      baseUrl = 'http://$requestHost';
      _logger.log('🌐 Using client-provided host header: $requestHost');
    } else {
      // Fallback to our network IP if host header is not available
      baseUrl = 'http://$_networkAccessibleIp:$_port';
      _logger.log('⚠️ No host header, using network IP: $_networkAccessibleIp:$_port');
    }
    
    _logger.log('🌐 Using base URL for response: $baseUrl');
    
    final files = _sharedFiles.values.map((file) => {
      'id': file.id,
      'name': file.name,
      'size': file.size,
      'mimeType': file.mimeType,
      'dateAdded': file.dateAdded.toIso8601String(),
      'url': '$baseUrl/files/${file.id}',
    }).toList();
    
    return shelf.Response.ok(
      jsonEncode(files),
      headers: {'Content-Type': 'application/json'},
    );
  }
  
  /// Get MIME type based on file extension
  String _getMimeType(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
      case '.docx':
        return 'application/msword';
      case '.xls':
      case '.xlsx':
        return 'application/vnd.ms-excel';
      case '.ppt':
      case '.pptx':
        return 'application/vnd.ms-powerpoint';
      case '.mp3':
        return 'audio/mpeg';
      case '.mp4':
        return 'video/mp4';
      case '.zip':
        return 'application/zip';
      case '.txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
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
  
  /// Clean up resources
  void dispose() {
    stopServer();
  }
}

/// Information about a shared file
class _SharedFile {
  final String id;
  final File file;
  final String name;
  final int size;
  final String mimeType;
  final DateTime dateAdded;
  
  _SharedFile({
    required this.id,
    required this.file,
    required this.name,
    required this.size,
    required this.mimeType,
    required this.dateAdded,
  });
}

/// File share information for sending via MQTT
class FileShareInfo {
  final String fileId;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String url;
  
  FileShareInfo({
    required this.fileId,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.url,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'type': 'file_share',
      'fileId': fileId,
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'url': url,
    };
  }
  
  factory FileShareInfo.fromJson(Map<String, dynamic> json) {
    return FileShareInfo(
      fileId: json['fileId'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      mimeType: json['mimeType'],
      url: json['url'],
    );
  }
}
