import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static Timer? _pollingTimer;
  static final List<int> _notifiedIds = [];

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true, // Enabled sound permission
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(settings: initializationSettings);
  }

  static Future<void> showSilentNotification({required int id, required String title, required String body}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'silent_channel_id',
      'Silent Notifications',
      channelDescription: 'Channel for silent notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: false,
      enableVibration: false,
    );

    const DarwinNotificationDetails darwinPlatformChannelSpecifics = DarwinNotificationDetails(
      presentSound: false,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
      macOS: darwinPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  static Future<void> showSuccessNotification({required int id, required String title, required String body}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'success_channel_id',
      'Success Notifications',
      channelDescription: 'Channel for success/action notifications with sound',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails darwinPlatformChannelSpecifics = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
      macOS: darwinPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  static void startPolling(String userId, Function(List<dynamic>) onNotificationsUpdated) {
    _pollingTimer?.cancel();
    
    // Load already seen notification IDs from SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      final stored = prefs.getStringList('notified_ids_$userId') ?? [];
      _notifiedIds.clear();
      _notifiedIds.addAll(stored.map((s) => int.tryParse(s) ?? 0));
    });

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final list = await ApiService.getNotifications(userId);
      onNotificationsUpdated(list);

      bool hasNew = false;
      for (var item in list) {
        final id = item['id'] as int;
        if (!_notifiedIds.contains(id)) {
          _notifiedIds.add(id);
          hasNew = true;
          
          // Trigger the audible push notification
          showSuccessNotification(
            id: id,
            title: item['title'] ?? 'Notifikasi Baru',
            body: item['body'] ?? '',
          );
        }
      }

      if (hasNew) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('notified_ids_$userId', _notifiedIds.map((i) => i.toString()).toList());
      }
    });
  }

  static void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
}
