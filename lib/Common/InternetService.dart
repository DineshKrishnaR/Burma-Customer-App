import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class InternetService {
  static final InternetService _instance = InternetService._internal();
  factory InternetService() => _instance;

  InternetService._internal();

  StreamSubscription? _subscription;

  void start() {
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        Fluttertoast.showToast(
          msg: "Internet is OFF ❌",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Internet Connected ✅",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
  }
}