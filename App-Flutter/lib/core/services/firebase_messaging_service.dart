import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:fe_mobile/core/network/api_client.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Đảm bảo Firebase được khởi tạo khi nhận thông báo ở background/terminated
  await Firebase.initializeApp();
  debugPrint('[FCM] Handling background message: ${message.messageId}');
}

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Khởi tạo Firebase
      await Firebase.initializeApp();
      
      // 2. Thiết lập background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Yêu cầu quyền thông báo (đặc biệt cho Android 13+)
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('[FCM] User granted permission: ${settings.authorizationStatus}');

      // 4. Lắng nghe tin nhắn khi ứng dụng ở Foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM] Got a message whilst in the foreground!');
        debugPrint('[FCM] Message data: ${message.data}');
        
        if (message.notification != null) {
          debugPrint('[FCM] Message also contained a notification: ${message.notification?.title}');
        }
      });

      // 5. Lắng nghe khi người dùng bấm vào thông báo từ background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM] A new onMessageOpenedApp event was published!');
        debugPrint('[FCM] Message data: ${message.data}');
      });

      // 6. Đăng ký tự động cập nhật token khi nó thay đổi
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed: $newToken');
        registerTokenWithBackend(newToken);
      });

      _isInitialized = true;
      debugPrint('[FCM] Firebase Messaging initialized successfully.');
    } catch (e) {
      debugPrint('[FCM] Failed to initialize Firebase Messaging: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('[FCM] Failed to get FCM token: $e');
      return null;
    }
  }

  Future<void> registerTokenWithBackend([String? token]) async {
    try {
      final fcmToken = token ?? await getToken();
      if (fcmToken == null) {
        debugPrint('[FCM] Cannot register token because token is null.');
        return;
      }

      debugPrint('[FCM] Registering FCM token with backend...');
      final response = await ApiClient().dio.post(
        '/Notification/register-fcm-token',
        data: {'token': fcmToken},
      );

      if (response.statusCode == 200) {
        debugPrint('[FCM] FCM Token registered with backend successfully.');
      } else {
        debugPrint('[FCM] Failed to register FCM Token. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[FCM] Error registering FCM token with backend: $e');
    }
  }
}
