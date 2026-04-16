import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class NetworkHandler {
  static void _showError(String msg) {
    Fluttertoast.showToast(msg: msg);
  }

  static Future<Map<String, dynamic>?> safePost(
    Uri url, {
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on TimeoutException {
      _showError("Slow internet. Please try again");
      return null;
    } on SocketException {
      _showError("No internet connection");
      return null;
    } catch (e) {
      _showError("Something went wrong");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> safeGet(
    Uri url, {
    required Map<String, String> headers,
  }) async {
    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on TimeoutException {
      _showError("Slow internet. Please try again");
      return null;
    } on SocketException {
      _showError("No internet connection");
      return null;
    } catch (e) {
      _showError("Something went wrong");
      return null;
    }
  }

  static Future<List<dynamic>?> safeGetList(
    Uri url, {
    required Map<String, String> headers,
  }) async {
    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return jsonDecode(response.body);
      _showError("Server error");
      return null;
    } on TimeoutException {
      _showError("Slow internet. Please try again");
      return null;
    } on SocketException {
      _showError("No internet connection");
      return null;
    } catch (e) {
      _showError("Something went wrong");
      return null;
    }
  }

  static Map<String, dynamic>? _handleResponse(http.Response response) {
    if (response.statusCode == 200) return jsonDecode(response.body);
    _showError("Server error");
    return null;
  }
}
