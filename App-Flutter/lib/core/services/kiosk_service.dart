import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class KioskService {
  static const MethodChannel _channel = MethodChannel('com.example.fe_mobile/kiosk');

  /// Kích hoạt Kiosk Mode (Ghim màn hình)
  static Future<bool> startKiosk() async {
    try {
      final bool result = await _channel.invokeMethod('startKiosk');
      return result;
    } on PlatformException catch (e) {
      debugPrint("Lỗi kích hoạt Kiosk Mode: ${e.message}");
      return false;
    }
  }

  /// Tắt Kiosk Mode (Bỏ ghim màn hình)
  static Future<bool> stopKiosk() async {
    try {
      final bool result = await _channel.invokeMethod('stopKiosk');
      return result;
    } on PlatformException catch (e) {
      debugPrint("Lỗi tắt Kiosk Mode: ${e.message}");
      return false;
    }
  }

  /// Kiểm tra xem Kiosk Mode (Ghim màn hình) có đang hoạt động hay không
  static Future<bool> isKioskEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isKioskEnabled');
      return result;
    } on PlatformException catch (e) {
      debugPrint("Lỗi kiểm tra Kiosk Mode: ${e.message}");
      return false;
    }
  }
}
