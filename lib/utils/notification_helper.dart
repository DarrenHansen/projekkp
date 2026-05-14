import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Notification Helper - Mengelola notifikasi lokal untuk pengingat invoice
class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
      },
    );
  }

  static Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Show immediate notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'invoice_reminders',
      'Invoice Reminders',
      channelDescription: 'Notifications for invoice due date reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// Schedule notification for a specific time
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'invoice_reminders',
      'Invoice Reminders',
      channelDescription: 'Notifications for invoice due date reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  /// Schedule reminders for an invoice (H-7, H-3, H-1, and overdue)
  static Future<void> scheduleInvoiceReminders({
    required int invoiceId,
    required String invoiceNumber,
    required String customerName,
    required DateTime dueDate,
  }) async {
    // Cancel existing notifications for this invoice
    await cancelNotification(invoiceId * 10);
    await cancelNotification(invoiceId * 10 + 1);
    await cancelNotification(invoiceId * 10 + 2);
    await cancelNotification(invoiceId * 10 + 3);

    final now = DateTime.now();

    // H-7 reminder
    final h7 = dueDate.subtract(const Duration(days: 7));
    if (h7.isAfter(now)) {
      await scheduleNotification(
        id: invoiceId * 10,
        title: 'Pengingat Invoice H-7',
        body:
            'Invoice $invoiceNumber untuk $customerName jatuh tempo dalam 7 hari',
        scheduledDate: h7,
        payload: 'invoice_$invoiceId',
      );
    }

    // H-3 reminder
    final h3 = dueDate.subtract(const Duration(days: 3));
    if (h3.isAfter(now)) {
      await scheduleNotification(
        id: invoiceId * 10 + 1,
        title: 'Pengingat Invoice H-3',
        body:
            'Invoice $invoiceNumber untuk $customerName jatuh tempo dalam 3 hari',
        scheduledDate: h3,
        payload: 'invoice_$invoiceId',
      );
    }

    // H-1 reminder
    final h1 = dueDate.subtract(const Duration(days: 1));
    if (h1.isAfter(now)) {
      await scheduleNotification(
        id: invoiceId * 10 + 2,
        title: 'Pengingat Invoice H-1',
        body: 'Invoice $invoiceNumber untuk $customerName jatuh tempo BESOK!',
        scheduledDate: h1,
        payload: 'invoice_$invoiceId',
      );
    }

    // Overdue notification (on due date + 1 day)
    final overdue = dueDate.add(const Duration(days: 1));
    if (overdue.isAfter(now)) {
      await scheduleNotification(
        id: invoiceId * 10 + 3,
        title: 'Invoice Terlambat!',
        body:
            'Invoice $invoiceNumber untuk $customerName sudah melewati jatuh tempo',
        scheduledDate: overdue,
        payload: 'invoice_$invoiceId',
      );
    }
  }
}
