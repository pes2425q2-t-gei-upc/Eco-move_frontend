import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'EmergenciaDetails.dart';
import 'main.dart';

class NotiService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  //Initialize 
  Future<void> iniNotification() async {
    if (_isInitialized) return;

    print("Inicializando NotiService..."); // Agregar print

    //Android
    const initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    //ios
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );
    await notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        onSelectNotification(response.payload);
      },
    );

    _isInitialized = true;
    print("NotiService inicializado."); // Agregar print
  }

  // Notifications detail setup
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channelId',
        'Daily Notifications',
        channelDescription: 'Daily Notification Channel',
        importance: Importance.max,
        priority: Priority.high,
        //playSound: true,
        //icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  //Show
  Future<void> showNotification({int id = 0, String? title, String? body, String? payload}) async {
    print('showNotification called with: id=$id, title=$title, body=$body'); // Agregar print
    return notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails(),
      payload: payload,

    );
  }

  //Clicar
  void onSelectNotification(String? payload) {
  if (payload != null) {
    print('Notificación seleccionada con payload: $payload');
    if (payload.startsWith("navigate_to_screen")) {
      // Extraer los datos de la emergencia del payload
      final parts = payload.split('|');
      print(parts);
      if (parts.length == 7) { // Cambiar a 7 partes
        try {
          final title = parts[1];
          final description = parts[2];
          final lat = double.tryParse(parts[3]) ?? 0.0;
          final lng = double.tryParse(parts[4]) ?? 0.0;
          final timestamp = parts[5];
          final sender = parts[6];

          // Navegar a la pantalla de detalles de emergencia
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => EmergenciaDetails(
                title: title,
                description: description,
                lat: lat,
                lng: lng,
                timestamp: timestamp,
                sender: sender,
              ),
            ),
          );
        } catch (e) {
          print('Error al procesar el payload: $e');
        }
      } else {
        print('Payload no tiene el formato esperado: $payload');
      }
    }
  }
}
}