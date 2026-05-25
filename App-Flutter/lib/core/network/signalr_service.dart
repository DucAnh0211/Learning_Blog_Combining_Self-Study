import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:fe_mobile/core/network/api_client.dart';
import 'package:fe_mobile/features/notifications/data/models/notification_model.dart';

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  HubConnection? _hubConnection;
  Function(NotificationModel)? onNotificationReceived;

  HubConnectionState? get state => _hubConnection?.state;

  Future<void> initConnection(String token) async {
    if (_hubConnection != null && _hubConnection!.state != HubConnectionState.Disconnected) {
      debugPrint('[SignalR] Already connected or connecting.');
      return;
    }

    // Lấy hubUrl từ ApiClient.baseUrl
    // Ví dụ: ApiClient.baseUrl = http://10.0.2.2:5080/api -> http://10.0.2.2:5080/hubs/notification
    final apiBaseUrl = ApiClient.baseUrl;
    final hubUrl = apiBaseUrl.replaceAll('/api', '/hubs/notification');
    
    debugPrint('[SignalR] Initializing connection to $hubUrl');

    _hubConnection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    // Lắng nghe sự kiện kết nối lại thành công hoặc mất kết nối
    _hubConnection!.onreconnecting(({error}) {
      debugPrint('[SignalR] Connection lost. Reconnecting... Error: $error');
    });

    _hubConnection!.onreconnected(({connectionId}) {
      debugPrint('[SignalR] Reconnected successfully. ConnectionId: $connectionId');
    });

    _hubConnection!.onclose(({error}) {
      debugPrint('[SignalR] Connection closed. Error: $error');
    });

    // Lắng nghe sự kiện nhận thông báo thời gian thực từ Backend
    _hubConnection!.on('ReceiveNotification', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        try {
          debugPrint('[SignalR] ReceiveNotification raw data: ${arguments[0]}');
          final data = arguments[0] as Map<String, dynamic>;
          final notification = NotificationModel.fromJson(data);
          
          if (onNotificationReceived != null) {
            onNotificationReceived!(notification);
          }
        } catch (e) {
          debugPrint('[SignalR] Error parsing incoming notification: $e');
        }
      }
    });

    try {
      await _hubConnection!.start();
      debugPrint('[SignalR] Connection started successfully. State: ${_hubConnection!.state}');
    } catch (e) {
      debugPrint('[SignalR] Error starting connection: $e');
    }
  }

  Future<void> stopConnection() async {
    if (_hubConnection != null && _hubConnection!.state != HubConnectionState.Disconnected) {
      debugPrint('[SignalR] Stopping connection.');
      await _hubConnection!.stop();
      _hubConnection = null;
    }
  }
}
