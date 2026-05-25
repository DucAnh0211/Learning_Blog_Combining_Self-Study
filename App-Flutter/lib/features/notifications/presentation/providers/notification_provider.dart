import 'package:flutter/material.dart';
import 'package:fe_mobile/features/notifications/data/models/notification_model.dart';
import 'package:fe_mobile/features/notifications/data/repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider(this._repository);

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _repository.getNotifications();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          title: _notifications[index].title,
          content: _notifications[index].content,
          type: _notifications[index].type,
          targetId: _notifications[index].targetId,
          actorId: _notifications[index].actorId,
          actorName: _notifications[index].actorName,
          actorAvatar: _notifications[index].actorAvatar,
          isRead: true,
          createdAt: _notifications[index].createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      _notifications = _notifications.map((n) => NotificationModel(
        id: n.id,
        title: n.title,
        content: n.content,
        type: n.type,
        targetId: n.targetId,
        actorId: n.actorId,
        actorName: n.actorName,
        actorAvatar: n.actorAvatar,
        isRead: true,
        createdAt: n.createdAt,
      )).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void addNotification(NotificationModel notification) {
    // Tránh trùng lặp nếu trùng id
    if (_notifications.any((n) => n.id == notification.id)) return;
    _notifications.insert(0, notification);
    notifyListeners();
  }
}
