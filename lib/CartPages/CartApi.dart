
import 'package:burma/Common/NetworkHandler.dart';
import 'package:burma/Common/UrlPath.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class Cartapi {
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

  Future<Map<String, dynamic>?> getViewCart(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + getviewcart), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> CheckStock(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + checkstock), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> DeliveryCharges(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + deliverycharges), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> getRazorpayDetails(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + getrazorpaydetails), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> RAZORPAYORDERCREATEAPI(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + razorpayordercreated), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> getPaymentStatus(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + getpaymentstatus), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> getAddress(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + getaddress), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> SaveDeliveryAddress(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + savedeliveryaddress), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> PromoCodeValidaction(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + promocodevalidaction), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> SaveOrders(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + saveorders), headers: _headers(), body: body);


      Future<Map<String, dynamic>?> EditDeliveryAddress(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + editdeliveryaddress), headers: _headers(), body: body);

      Future<Map<String, dynamic>?> deleteAddress(Map<String, dynamic> body) =>
      NetworkHandler.safePost(Uri.parse(base_url + deleteaddress), headers: _headers(), body: body);

  Future<Map<String, dynamic>?> getApi(String endpoint) =>
      NetworkHandler.safeGet(Uri.parse(base_url + endpoint), headers: _headers());
}
