
import 'package:burma/Common/NetworkHandler.dart';
import 'package:burma/Common/UrlPath.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class Aboutapi {
  static const String _jwtSecret =
      "HGgkggjhgvTye15253etV@%\$@kjh87jkgjkfk";
  static const String _issuer = "43A813328129D2F9C25E155BCB833";
  static const String _subject = "Muviereck Authentication";

  String _generateJwtToken() {
    final jwt = JWT({"iss": _issuer, "sub": _subject, "iat": DateTime.now().millisecondsSinceEpoch ~/ 1000});
    return jwt.sign(SecretKey(_jwtSecret), algorithm: JWTAlgorithm.HS256);
  }

  Map<String, String> _headers() => {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Bearer ${_generateJwtToken()}',
      };

  Future<Map<String, dynamic>?> AboutUs(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + aboutus), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> TamesCondictions(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + tamescondictions), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> ContactUs(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + contactus), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> DeliveryPolicy(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + deliverypolicy), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> PrivicyPolicy(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + privicypolicy), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> Returnrefundpolicy(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + returnrefundpolicy), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> getApi(String endpoint) =>
      NetworkHandler.safeGet(Uri.parse(base_url + endpoint), headers: _headers());
}
