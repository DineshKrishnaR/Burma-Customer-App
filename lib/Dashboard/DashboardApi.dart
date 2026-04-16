
import 'package:burma/Common/NetworkHandler.dart';
import 'package:burma/Common/UrlPath.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class DashboardApi {
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

  Future<Map<String, dynamic>?> HomeBanner(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + homebanner), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> MainCategory(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + maincategory), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> AllProducts(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + allproducts), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> WalletDetails(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + walletdetails), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> ProfileDetails(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + profiledetails), headers: _headers(), body: body);

  Future<List<dynamic>?> HomeFeatureSections() =>
      NetworkHandler.safeGetList(Uri.parse(base_url + homefeaturesections), headers: _headers());

  Future<List<dynamic>?> getRelatedProducts(Map<String, dynamic> body) async {
    final data = await NetworkHandler.safePost(Uri.parse(base_url + allproducts), headers: _headers(), body: body);
    return data?['res'] ?? [];
  }

  Future<Map<String, dynamic>?> DeleteAccount(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + deleteaccount), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> Stylecatageory(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + stylecatageory), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> getNotification(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + getnotification), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> PopupOfferImage(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + popupofferimage), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> SearchProducts(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + allproducts), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> getApi(String endpoint) =>
      NetworkHandler.safeGet(Uri.parse(base_url + endpoint), headers: _headers());
}
