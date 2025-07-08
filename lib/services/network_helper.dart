import 'dart:io';
import 'package:flutter/foundation.dart';

class NetworkHelper {
  /// Helper method to log network operations
  static void _log(String message) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toString().substring(11, 19);
      print('[$timestamp] NETWORK: $message');
    }
  }

  static Future<String?> getDeviceIPAddress() async {
    _log('🔍 Starting device IP address detection');
    try {
      // Get all network interfaces
      _log('📡 Fetching network interfaces');
      List<NetworkInterface> interfaces = await NetworkInterface.list();
      _log('📊 Found ${interfaces.length} network interfaces');
      
      // Log all interfaces for debugging
      for (var interface in interfaces) {
        _log('🔗 Interface: ${interface.name} (${interface.addresses.length} addresses)');
        for (var address in interface.addresses) {
          _log('   - ${address.address} (${address.type})');
        }
      }
      
      // Look for Wi-Fi interface IP
      _log('🔎 Searching for Wi-Fi interface');
      for (NetworkInterface interface in interfaces) {
        // Skip loopback and other non-Wi-Fi interfaces
        // Include hotspot interfaces (ap0, wlan, wifi, en0)
        if (interface.name.toLowerCase().contains('wlan') || 
            interface.name.toLowerCase().contains('wifi') ||
            interface.name.toLowerCase().contains('en0') ||
            interface.name.toLowerCase().contains('ap0') ||
            interface.name.toLowerCase().startsWith('ap')) {
          
          _log('📡 Found Wi-Fi/Hotspot interface: ${interface.name}');
          
          for (InternetAddress address in interface.addresses) {
            // Return the first IPv4 address found
            if (address.type == InternetAddressType.IPv4) {
              _log('✅ Wi-Fi IPv4 address found: ${address.address}');
              return address.address;
            }
          }
        }
      }
      
      // Fallback: look for any IPv4 address that's not localhost
      _log('🔄 Wi-Fi interface not found, looking for fallback IPv4 address');
      for (NetworkInterface interface in interfaces) {
        _log('🔍 Checking interface: ${interface.name}');
        for (InternetAddress address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 && 
              !address.isLoopback && 
              address.address.startsWith('192.168.')) {
            _log('✅ Fallback IPv4 address found: ${address.address}');
            return address.address;
          }
        }
      }
      
      _log('⚠️  No suitable IP address found');
      return null;
    } catch (e) {
      _log('❌ Error getting IP address: $e');
      _log('🔍 Error type: ${e.runtimeType}');
      return null;
    }
  }
  
  static bool isValidIPAddress(String ip) {
    _log('✅ Validating IP address: $ip');
    
    // Basic IP address validation
    RegExp ipRegex = RegExp(r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
    bool isValid = ipRegex.hasMatch(ip);
    
    _log('📊 IP validation result: $isValid');
    if (!isValid) {
      _log('⚠️  Invalid IP format detected');
    }
    
    return isValid;
  }
}
