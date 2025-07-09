import 'package:flutter/foundation.dart';

/// Handles message logging for the MQTT service
class MessageLogger {
  final List<String> _messages = [];
  
  /// Get all messages
  List<String> get messages => _messages;
  
  /// Add a new message with timestamp
  void addMessage(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    _messages.add('[$timestamp] $message');
    if (_messages.length > 100) {
      _messages.removeAt(0);
    }
  }
  
  /// Log a message (adds to message list and prints to console in debug mode)
  void log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logMessage = '[$timestamp] MQTT: $message';
    if (kDebugMode) {
      print(logMessage); // This will show in terminal/console
    }
    addMessage(message);
  }
  
  /// Clear all messages
  void clearMessages() {
    log('🧹 Clearing message log');
    _messages.clear();
  }
}
