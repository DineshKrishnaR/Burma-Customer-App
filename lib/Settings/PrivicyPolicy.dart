import 'package:burma/Settings/AboutApi.dart';
import 'package:burma/Dashboard/Dashboard.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Common/colors.dart' as custom_color;

class Privicypolicy extends StatefulWidget {
  const Privicypolicy({super.key});

  @override
  State<Privicypolicy> createState() => _PrivicypolicyState();
}

class _PrivicypolicyState extends State<Privicypolicy> {

  final LocalStorage storage = LocalStorage('app_store');

  late SharedPreferences pref;

  bool isLoading = false;

  var userResponse;
  var accesstoken;
  var customer_id;

  String privacyPolicy = "";

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

    await loadPolicy();
  }

  /// API CALL
  Future<void> loadPolicy() async {

    setState(() => isLoading = true);

    var data = {
      "method": "privacy_policy",
      "accesskey": "90336",
      "token": accesstoken,
    };

    final response = await Aboutapi().PrivicyPolicy(data);

    if (response != null && response['message'] != null) {

      String raw = response['message'];

      raw = raw.replaceAll("&nbsp;", " ");

      privacyPolicy = raw;

      sections = buildSections(raw);

    } else {

      privacyPolicy = "";
      sections = [];

    }

    setState(() => isLoading = false);
  }

  /// BUILD ICON SECTIONS
  List<Map<String, dynamic>> buildSections(String text) {

    List<String> parts = text.split("\r\n\r\n");

    return parts.map((section) {

      IconData icon = Icons.description_outlined;

      String lower = section.toLowerCase();

      if (lower.contains("personal")) {
        icon = Icons.person_outline;
      }
      else if (lower.contains("cookie")) {
        icon = Icons.cookie_outlined;
      }
      else if (lower.contains("third")) {
        icon = Icons.share_outlined;
      }
      else if (lower.contains("right")) {
        icon = Icons.verified_user_outlined;
      }
      else if (lower.contains("information")) {
        icon = Icons.info_outline;
      }

      return {
        "icon": icon,
        "text": section
      };

    }).toList();
  }

  @override
  Widget build(BuildContext context) {

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => Dashboard()));
      },
      child: Scaffold(

        appBar: AppBar(
          backgroundColor: custom_color.app_color,
          title: const Text(
            "Privacy Policy",
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

                  /// NO DATA UI
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          Icon(
                            Icons.policy_outlined,
                            size: 90,
                            color: Colors.grey.shade400,
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            "Privacy Policy Not Available",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )

                  /// POLICY CONTENT
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
                                  custom_color.app_color.withOpacity(0.8),
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
                                  Icons.privacy_tip_outlined,
                                  size: 80,
                                  color: Colors.white,
                                ),

                                SizedBox(height: 10),

                                Text(
                                  "Privacy Policy",
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              ],
                            ),
                          ),

                          /// SECTIONS
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
                                      child: Text(
                                        item["text"]
                                            .replaceAll("\r\n", " "),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          height: 1.6,
                                        ),
                                      ),
                                    ),

                                  ],
                                ),
                              );

                            }).toList(),
                          ),

                          const SizedBox(height: 30),

                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}