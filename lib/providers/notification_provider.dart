import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  int unreadCount = 0;

  // Call this on app start and after any notification action
  Future<void> fetchUnreadCount() async {
    final data = await NotificationService.getNotifications(refresh: true);
    if (data != null) {
      unreadCount = data['unread_count'] ?? 0;
      notifyListeners();
    }
  }

  void decrement() {
    if (unreadCount > 0) {
      unreadCount--;
      notifyListeners();
    }
  }

  void reset() {
    unreadCount = 0;
    notifyListeners();
  }
}