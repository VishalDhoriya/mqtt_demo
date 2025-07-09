import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'message_logger.dart';
import 'mqtt_client_manager.dart';
import 'mqtt_broker_manager.dart';
import 'client_tracker.dart';
import 'connected_client.dart';
import 'file_server_service.dart';
import 'file_download_service.dart';
import 'topic_manager.dart';

/// Main MQTT service that orchestrates client and broker operations
class MqttService extends ChangeNotifier {
  late final MessageLogger _logger;
  late final MqttClientManager _clientManager;
  late final MqttBrokerManager _brokerManager;
  late final ClientTracker _clientTracker;
  late final FileServerService _fileServerService;
  late final FileDownloadService _fileDownloadService;
  late final TopicManager _topicManager;
  
  // Current mode
  AppMode _currentMode = AppMode.none;
  
  // Flag to track if a monitoring client is connected when in broker mode
  bool _brokerMonitoringClientConnected = false;
  
  MqttService() {
    _logger = MessageLogger();
    _topicManager = TopicManager();
    _clientManager = MqttClientManager(_logger, 
      onStateChanged: notifyListeners,
      onMessageReceived: _handleIncomingMessage,
    );
    _clientTracker = ClientTracker(_logger);
    _brokerManager = MqttBrokerManager(_logger, _clientTracker, 
      onStateChanged: notifyListeners,
    );
    _fileServerService = FileServerService(_logger, onStateChanged: notifyListeners);
    _fileDownloadService = FileDownloadService(_logger, onStateChanged: notifyListeners);
    
    // Listen to client tracker changes
    _clientTracker.addListener(notifyListeners);
    // Listen to topic manager changes
    _topicManager.addListener(notifyListeners);
  }
  
  // Getters
  bool get isConnected => _clientManager.isConnected;
  bool get isSubscribed => _clientManager.isSubscribed;
  bool get isBrokerRunning => _brokerManager.isBrokerRunning;
  bool get isFileServerRunning => _fileServerService.isServerRunning;
  String get brokerIp => _clientManager.brokerIp;
  List<String> get messages => _logger.messages;
  AppMode get currentMode => _currentMode;
  List<ConnectedClient> get connectedClients => _clientTracker.connectedClients;
  int get connectedClientsCount => _clientTracker.connectedCount;
  bool get canPublishFromHost => isBrokerRunning && (_brokerMonitoringClientConnected || isConnected);
  String get defaultTopic => _clientManager.defaultTopic;
  String get shareTopic => _clientManager.shareTopic;
  Set<String> get subscribedTopics => _clientManager.subscribedTopics;
  List<FileDownloadTask> get activeDownloads => _fileDownloadService.activeTasks;
  TopicManager get topicManager => _topicManager;
  
  // Set mode
  void setMode(AppMode mode) {
    _logger.log('Setting mode to: $mode');
    _currentMode = mode;
    notifyListeners();
  }
  
  // MQTT Broker functionality
  Future<bool> startBroker() async {
    final success = await _brokerManager.startBroker();
    
    if (success) {
      // Connect a local client for the host to be able to publish messages
      await _setupHostPublishingClient();
      
      // Start the file server on the same IP
      await _fileServerService.startServer(brokerIp);
    }
    
    return success;
  }
  
  // Set up a client for the host to publish messages while in broker mode
  Future<void> _setupHostPublishingClient() async {
    _logger.log('🔧 Setting up host publishing client...');
    // Use the client manager to connect to the local broker
    final success = await _clientManager.connect('127.0.0.1');
    
    if (success) {
      _logger.log('✅ Host publishing client connected successfully');
      await _clientManager.subscribe();
      await _clientManager.subscribeToTopic(_clientManager.shareTopic);
      
      // Subscribe to system topics so broker host can see connection/disconnection events
      await _clientManager.subscribeToTopic('client/connect');
      await _clientManager.subscribeToTopic('client/disconnect');
      
      _brokerMonitoringClientConnected = true;
    } else {
      _logger.log('❌ Failed to set up host publishing client');
      _brokerMonitoringClientConnected = false;
    }
    
    notifyListeners();
  }
  
  Future<void> stopBroker() async {
    // Stop the file server
    await _fileServerService.stopServer();
    
    // Disconnect the host publishing client first
    if (_brokerMonitoringClientConnected) {
      await _clientManager.disconnect();
      _brokerMonitoringClientConnected = false;
    }
    
    await _brokerManager.stopBroker();
  }
  
  /// Connect to MQTT broker as a client
  Future<bool> connect(String brokerIp) async {
    final success = await _clientManager.connect(brokerIp);
    
    if (success) {
      // Register handler for file share messages
      _clientManager.setFileShareMessageHandler(_handleFileShareMessage);
      _logger.log('🔧 File share message handler registered');
    }
    
    return success;
  }
  
  /// Handle incoming file share messages
  Future<void> _handleFileShareMessage(String message) async {
    _logger.log('📥 File notification received');
    
    try {
      // Parse the message as JSON
      final messageJson = jsonDecode(message);
      
      // Check if it's a file notification message
      if (messageJson is Map<String, dynamic> && 
          messageJson.containsKey('type') && 
          messageJson['type'] == 'file_notification') {
        
        final serverUrl = messageJson['server_url'] as String;
        _logger.log('🔍 Server URL: $serverUrl');
        
        // Fetch file list from the server
        final fileListUrl = '$serverUrl/files';
        _logger.log('🔍 Fetching file list from: $fileListUrl');
        
        // Download file list
        try {
          final response = await http.get(Uri.parse(fileListUrl));
          
          if (response.statusCode == 200) {
            final fileList = jsonDecode(response.body) as List;
            _logger.log('✅ Received file list with ${fileList.length} files');
            
            // Process each file in the list (usually just the latest one)
            for (final fileInfo in fileList) {
              if (fileInfo is Map<String, dynamic>) {
                // Create a FileShareInfo
                final shareInfo = FileShareInfo(
                  fileId: fileInfo['id'],
                  fileName: fileInfo['name'],
                  fileSize: fileInfo['size'],
                  mimeType: fileInfo['mimeType'],
                  url: fileInfo['url'],
                );
                
                _logger.log('📦 File available: ${shareInfo.fileName}');
                _logger.log('📊 File size: ${_formatFileSize(shareInfo.fileSize)}');
                _logger.log('🔗 Download URL: ${shareInfo.url}');
                
                // Start download
                await _fileDownloadService.downloadFile(shareInfo);
              }
            }
          } else {
            _logger.log('❌ Failed to fetch file list: ${response.statusCode}');
          }
        } catch (e) {
          _logger.log('❌ Error fetching file list: $e');
        }
      } else {
        _logger.log('⚠️ Not a file notification message: ${messageJson['type']}');
      }
    } catch (e) {
      _logger.log('❌ Error processing file notification: $e');
    }
    
    notifyListeners();
  }
  
  Future<void> disconnect() async {
    await _clientManager.disconnect();
  }
  
  Future<void> subscribe() async {
    // Subscribe to both default and share topics
    await _clientManager.subscribe();
    await _clientManager.subscribeToTopic(_clientManager.shareTopic);
    
    // Subscribe to system topics so all clients can see connection/disconnection events
    await _clientManager.subscribeToTopic('client/connect');
    await _clientManager.subscribeToTopic('client/disconnect');
  }
  
  Future<void> subscribeToTopic(String topic) async {
    await _clientManager.subscribeToTopic(topic);
  }
  
  Future<void> unsubscribe() async {
    await _clientManager.unsubscribe();
    await _clientManager.unsubscribeFromTopic(_clientManager.shareTopic);
    
    // Unsubscribe from system topics
    await _clientManager.unsubscribeFromTopic('client/connect');
    await _clientManager.unsubscribeFromTopic('client/disconnect');
  }
  
  Future<void> unsubscribeFromTopic(String topic) async {
    await _clientManager.unsubscribeFromTopic(topic);
  }
  
  Future<void> publishMessage({String? message, String? topic}) async {
    final usedTopic = topic ?? _clientManager.defaultTopic;
    final usedMessage = message ?? 'Hello, MQTT!';
    
    // Send the original message as-is to avoid payload size issues
    // The sender identification will be handled when the message comes back
    await _clientManager.publishMessage(message: usedMessage, topic: topic);
    
    // Don't add to TopicManager here - wait for the message to come back from broker
    // This ensures consistent behavior across all devices and prevents duplicates
    
    // If we're running a broker, also log the message as received by broker
    if (_brokerManager.isBrokerRunning) {
      _logger.log('📨 [BROKER] Message published to topic: $usedTopic');
      _logger.log('📝 [BROKER] Message content: "$usedMessage"');
      _logger.log('🔄 [BROKER] Broadcasting to all connected clients...');
    }
  }
  
  // File sharing functionality
  
  /// Share a file with all connected clients
  Future<bool> shareFile(File file) async {
    if (!isFileServerRunning) {
      _logger.log('❌ Cannot share file - file server not running');
      return false;
    }
    
    try {
      // Share the file via HTTP server
      final shareInfo = await _fileServerService.shareFile(file);
      
      if (shareInfo != null) {
        // Use the network-accessible IP for the server URL
        final networkServerUrl = _fileServerService.networkServerUrl;
        
        _logger.log('🌐 Using network-accessible server URL for notification: $networkServerUrl');
        
        // Create a minimal notification - ONLY sending notification
        // No file metadata through MQTT to avoid broker size limits
        final notification = {
          'type': 'file_notification',
          'message': 'New file available',
          'server_url': networkServerUrl,
        };
        
        // Convert notification to JSON
        final notificationJson = jsonEncode(notification);
        
        // Publish notification to share topic
        await publishMessage(message: notificationJson, topic: shareTopic);
        
        _logger.log('📤 File share notification published');
        return true;
      } else {
        _logger.log('❌ Failed to prepare file for sharing');
        return false;
      }
    } catch (e) {
      _logger.log('❌ Error sharing file: $e');
      return false;
    }
  }
  
  /// Get server URL for file sharing
  String get serverUrl => _fileServerService.networkServerUrl;
  
  /// Process incoming file share message - deprecated but kept for compatibility
  Future<FileDownloadTask?> processFileShareMessage(String message) async {
    try {
      _logger.log('📥 Processing file share message');
      
      // Parse the message as JSON
      final messageJson = jsonDecode(message);
      
      // If it's a file notification, handle with the new method
      if (messageJson is Map<String, dynamic> && 
          messageJson.containsKey('type') && 
          messageJson['type'] == 'file_notification') {
        
        _logger.log('📥 File notification received');
        await _handleFileShareMessage(message);
        return null;
      } else if (messageJson is Map<String, dynamic> && 
          messageJson.containsKey('type') && 
          messageJson['type'] == 'file_share') {
        
        // Legacy handling for old file_share messages
        // Extract required fields
        final fileId = messageJson['fileId'] as String? ?? '';
        final fileName = messageJson['fileName'] as String? ?? 'unknown.file';
        final fileSize = messageJson['fileSize'] as int? ?? 0;
        final url = messageJson['url'] as String? ?? '';
        
        if (fileId.isNotEmpty && url.isNotEmpty) {
          // Create a FileShareInfo object
          final shareInfo = FileShareInfo(
            fileId: fileId,
            fileName: fileName,
            fileSize: fileSize,
            url: url,
            mimeType: _guessMimeTypeFromFileName(fileName),
          );
          
          _logger.log('📦 File share received: ${shareInfo.fileName}');
          _logger.log('📊 File size: ${_formatFileSize(shareInfo.fileSize)}');
          _logger.log('🔗 Download URL: ${shareInfo.url}');
          
          // Start download
          return await _fileDownloadService.downloadFile(shareInfo);
        }
      } else {
        _logger.log('⚠️ Not a recognized file share message');
      }
      
      return null;
    } catch (e) {
      _logger.log('❌ Error processing file share message: $e');
      return null;
    }
  }
  
  /// Guess MIME type from file name
  String _guessMimeTypeFromFileName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.ms-powerpoint';
      case 'mp3':
        return 'audio/mpeg';
      case 'mp4':
        return 'video/mp4';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }
  
  /// Cancel a file download
  Future<bool> cancelDownload(String fileId) async {
    return await _fileDownloadService.cancelDownload(fileId);
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
  
  void clearMessages() {
    _logger.clearMessages();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _logger.log('🧹 Disposing MqttService');
    _clientTracker.removeListener(notifyListeners);
    _clientManager.dispose();
    _brokerManager.dispose();
    _fileServerService.dispose();
    _fileDownloadService.dispose();
    _topicManager.dispose();
    _logger.log('✅ MqttService disposed');
    super.dispose();
  }
  
  /// Handle incoming messages from MQTT
  void _handleIncomingMessage(String topic, String message) {
    _logger.log('📥 Message received on topic "$topic": $message');
    
    // Parse message content to extract sender info if possible
    String senderId = 'unknown';
    String senderName = 'Unknown Device';
    String actualContent = message;
    
    try {
      // Try to parse as JSON to extract sender info (for structured messages)
      final Map<String, dynamic> messageData = jsonDecode(message);
      if (messageData.containsKey('senderId')) {
        senderId = messageData['senderId'];
      }
      if (messageData.containsKey('senderName')) {
        senderName = messageData['senderName'];
      }
      if (messageData.containsKey('content')) {
        actualContent = messageData['content'];
      } else if (messageData.containsKey('message')) {
        actualContent = messageData['message'];
      }
    } catch (e) {
      // If not JSON, treat the entire message as content
      // Use simple sender identification based on connection state
      if (isConnected || (_currentMode == AppMode.broker && _brokerMonitoringClientConnected)) {
        // This could be our own message echoed back, but we'll treat all as external
        // since we can't reliably distinguish without structured messages
        senderId = 'device';
        senderName = 'Connected Device';
      } else if (_currentMode == AppMode.broker && _clientTracker.connectedClients.isNotEmpty) {
        // In broker mode, this is from a remote client
        senderId = 'remote_client';
        senderName = 'Remote Client';
      }
    }
    
    // Forward to TopicManager
    _topicManager.addMessage(
      topic: topic,
      content: actualContent,
      senderId: senderId,
      senderName: senderName,
      type: MessageType.user,
    );
    
    // Notify listeners about the new message
    notifyListeners();
  }
}

enum AppMode {
  none,
  broker,
  client,
}