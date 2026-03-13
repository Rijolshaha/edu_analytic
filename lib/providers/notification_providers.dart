// lib/providers/notification_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

// Notifications list provider
final notificationsProvider =
    FutureProvider<List<NotificationModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getNotifications();
});

// Unread notification count provider
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

// Notification refresh provider
final notificationRefreshProvider = StateProvider<int>((ref) => 0);

// Force refresh notifications
void refreshNotifications(WidgetRef ref) {
  ref.invalidate(notificationsProvider);
}
