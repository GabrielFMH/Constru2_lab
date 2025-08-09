import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificacionesService {
  // Singleton
  NotificacionesService._privateConstructor()
      : notificationsPlugin = FlutterLocalNotificationsPlugin();

  // Constructor para inyección de dependencias (test)
  NotificacionesService.withPlugin(this.notificationsPlugin);

  static final NotificacionesService instance =
      NotificacionesService._privateConstructor();

  final FlutterLocalNotificationsPlugin notificationsPlugin;

  bool isInitialized = false;
  bool notificationsEnabled = true;

  void setNotificationsEnabled(bool enabled) {
    notificationsEnabled = enabled;
    print(
        '🔔 [NotificacionesService] notificationsEnabled set to $notificationsEnabled');
  }

  Future<void> initNotification() async {
    print('🔔 [NotificacionesService] initNotification() called');
    if (isInitialized) {
      print('🔔 [NotificacionesService] ya inicializado, saliendo');
      return;
    }

    final status = await Permission.notification.status;
    print(
        '🔔 [NotificacionesService] estado permiso antes de request(): $status');
    if (status.isDenied || status.isPermanentlyDenied) {
      final newStatus = await Permission.notification.request();
      print(
          '🔔 [NotificacionesService] estado permiso después de request(): $newStatus');
      if (!newStatus.isGranted) {
        print('⚠️ [NotificacionesService] permiso denegado, no se inicializa');
        return;
      }
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await notificationsPlugin.initialize(settings,
        onDidReceiveNotificationResponse: (response) {
      print(
          '🔔 [NotificacionesService] onDidReceiveNotificationResponse: ${response.payload}');
    });

    isInitialized = true;
    print('🔔 [NotificacionesService] inicializado con éxito');
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id',
        'Daily Notifications',
        channelDescription: 'Daily Notification Channel',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    print('🔔 [NotificacionesService] showNotification() called');
    if (!notificationsEnabled) {
      print('🔕 [NotificacionesService] notificaciones desactivadas');
      return;
    }
    if (!isInitialized) {
      print(
          '⚠️ [NotificacionesService] no está inicializado, llamando a initNotification()');
      await initNotification();
      if (!isInitialized) {
        print(
            '❌ [NotificacionesService] initNotification falló, no se muestra notificación');
        return;
      }
    }
    await notificationsPlugin.show(id, title, body, notificationDetails());
    print('✅ [NotificacionesService] notificación enviada: $title / $body');
  }
}
