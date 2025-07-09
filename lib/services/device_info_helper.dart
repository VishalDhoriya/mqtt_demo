import 'dart:io';

/// Helper class for device information
class DeviceInfoHelper {
  /// Get the device name/hostname
  static Future<String?> getDeviceName() async {
    try {
      if (Platform.isWindows) {
        final result = await Process.run('hostname', []);
        if (result.exitCode == 0) {
          return result.stdout.toString().trim();
        }
      } else if (Platform.isLinux || Platform.isMacOS) {
        final result = await Process.run('hostname', []);
        if (result.exitCode == 0) {
          return result.stdout.toString().trim();
        }
      } else if (Platform.isAndroid) {
        // For Android, we can try to get device model
        final result = await Process.run('getprop', ['ro.product.model']);
        if (result.exitCode == 0) {
          return 'Android ${result.stdout.toString().trim()}';
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
