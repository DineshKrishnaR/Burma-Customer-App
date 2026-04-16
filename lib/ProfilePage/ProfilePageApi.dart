
import 'package:burma/Common/NetworkHandler.dart';
import 'package:burma/Common/UrlPath.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class Profilepageapi {
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

  Future<Map<String, dynamic>?> ProfileDetails(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + profiledetails), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> gerStateList(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + gerstatelist), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> ProfileUpdate(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + profileupdate), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> getApi(String endpoint) =>
      NetworkHandler.safeGet(Uri.parse(base_url + endpoint), headers: _headers());
}
