import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:localstorage/localstorage.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;
  final LocalStorage storage = LocalStorage('app_store');

  Future<void> initNotifications() async {
     final fcmToken = await _firebaseMessaging.getToken();
    await storage.ready;
    await _firebaseMessaging.requestPermission();
    // final fcmToken = await _firebaseMessaging.getToken();
    await storage.setItem('fcmToken', fcmToken);
    print('Token:$fcmToken');
  }
}
