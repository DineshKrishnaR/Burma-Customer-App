
import 'package:burma/Common/NetworkHandler.dart';
import 'package:burma/Common/UrlPath.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class Api {
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

  Future<Map<String, dynamic>?> loginApi(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + userLogin), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> Register(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + newregister), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> RegisterSentOTP(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + registersendotp), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> UserRegister(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + userregister), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> LoginsendOTP(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + loginsendotp), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> postApi(String endpoint, Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + endpoint), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> getApi(String endpoint) =>
      NetworkHandler.safeGet(Uri.parse(base_url + endpoint), headers: _headers());
}
