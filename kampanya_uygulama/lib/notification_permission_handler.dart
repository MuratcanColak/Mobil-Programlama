import 'dart:io'; // Platform kontrolü için
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationPermissionHandler {
  static Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Android 13 ve üzeri sürümler için bildirim izni iste
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Bildirim izni verildi!');
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Bildirim izni reddedildi.');
      } else {
        debugPrint('Bildirim izni verilmedi.');
      }
    }
  }
}
