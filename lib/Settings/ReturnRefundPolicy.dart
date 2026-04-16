import 'package:burma/Settings/AboutApi.dart';
import 'package:burma/Dashboard/Dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:localstorage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Common/colors.dart' as custom_color;

class Returnrefundpolicy extends StatefulWidget {
  const Returnrefundpolicy({super.key});

  @override
  State<Returnrefundpolicy> createState() => _ReturnrefundpolicyState();
}

class _ReturnrefundpolicyState extends State<Returnrefundpolicy> {

  final LocalStorage storage = LocalStorage('app_store');
  late SharedPreferences pref;

  bool isLoading = false;

  var userResponse;
  var accesstoken;
  var customer_id;

  String returnRefund = "";

  List sections = [];

  @override
  void initState() {
    super.initState();
    initPreferencess();
  }

  initPreferencess() async {

    await storage.ready;

    pref = await SharedPreferences.getInstance();

    userResponse = await storage.getItem('userResponse');

    if (userResponse != null) {
      accesstoken = userResponse['api_token'];
      customer_id = userResponse['customer_id'].toString();
    }

    await loadRefundPolicy();
  }

  /// API CALL
  Future<void> loadRefundPolicy() async {

    setState(() => isLoading = true);

    var data = {
      "method": "refund_policy",
      "accesskey": "90336",
      "token": accesstoken,
    };

    final response = await Aboutapi().AboutUs(data);

    if (response != null && response['message'] != null) {

      returnRefund = response['message'];

      sections = buildSections(returnRefund);

    } else {

      returnRefund = "";
      sections = [];

    }

    setState(() => isLoading = false);
  }

  /// Convert HTML paragraphs into sections
  List<Map<String, dynamic>> buildSections(String html) {

    List<String> parts = html.split("</p>");

    return parts.map((text) {

      text = text.replaceAll("<p>", "").trim();

      IconData icon = Icons.description_outlined;

      String lower = text.toLowerCase();

      if (lower.contains("cancellation")) {
        icon = Icons.cancel_outlined;
      }
      else if (lower.contains("return process")) {
        icon = Icons.assignment_return_outlined;
      }
      else if (lower.contains("refund")) {
        icon = Icons.payments_outlined;
      }
      else if (lower.contains("question")) {
        icon = Icons.help_outline;
      }
      else if (lower.contains("address")) {
        icon = Icons.location_on_outlined;
      }

      return {
        "icon": icon,
        "text": text
      };

    }).toList();
  }

  @override
  Widget build(BuildContext context) {

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => Dashboard()));
      },
      child: Scaffold(

        appBar: AppBar(
          backgroundColor: custom_color.app_color,
          title: const Text(
            "Return & Refund Policy",
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => Dashboard()));
            },
          ),
        ),

        body: SafeArea(

          child: isLoading

              /// LOADING UI
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      Image.asset(
                        "assets/images/AppLogo.png",
                        width: 100,
                        height: 100,
                      ),

                      const SizedBox(height: 20),

                       CircularProgressIndicator(color: custom_color.app_color,),

                    ],
                  ),
                )

              : sections.isEmpty

                  /// EMPTY UI
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          Icon(
                            Icons.assignment_return_outlined,
                            size: 90,
                            color: Colors.grey.shade400,
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            "No Refund Policy Found",
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )

                  /// CONTENT
                  : SingleChildScrollView(
                      child: Column(
                        children: [

                          /// HEADER CARD
                          Container(
                            margin: const EdgeInsets.all(15),
                            padding: const EdgeInsets.symmetric(vertical: 35),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  custom_color.app_color,
                                  custom_color.app_color.withOpacity(.85)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                )
                              ],
                            ),
                            child: const Column(
                              children: [

                                Icon(
                                  Icons.assignment_return_outlined,
                                  size: 80,
                                  color: Colors.white,
                                ),

                                SizedBox(height: 10),

                                Text(
                                  "Return & Refund Policy",
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),

                          /// POLICY SECTIONS
                          Column(
                            children: sections.map((item) {

                              return Container(

                                margin: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 8),

                                padding: const EdgeInsets.all(18),

                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(.06),
                                      blurRadius: 10,
                                    )
                                  ],
                                ),

                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    /// ICON
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: custom_color.app_color
                                            .withOpacity(.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        item["icon"],
                                        color: custom_color.app_color,
                                        size: 26,
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    /// TEXT
                                    Expanded(
                                      child: Html(
                                        data: item["text"],
                                        style: {
                                          "body": Style(
                                            fontSize: FontSize(15),
                                            lineHeight: LineHeight(1.6),
                                          )
                                        },
                                      ),
                                    ),

                                  ],
                                ),
                              );

                            }).toList(),
                          ),

                          const SizedBox(height: 25),

                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}