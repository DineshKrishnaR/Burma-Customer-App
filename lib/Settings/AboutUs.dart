import 'package:burma/Settings/AboutApi.dart';
import 'package:burma/Common/DeviceInfo.dart';
import 'package:burma/Common/FirebaseApi.dart';
import 'package:burma/Common/UrlPath.dart';
import 'package:burma/Dashboard/Dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:localstorage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Common/colors.dart' as custom_color;

class Aboutus extends StatefulWidget {
  const Aboutus({super.key});

  @override
  State<Aboutus> createState() => _AboutusState();
}

class _AboutusState extends State<Aboutus> {
  
final LocalStorage storage = new LocalStorage('app_store');
 
  late SharedPreferences pref;
  

  bool isLoading = false;
  var userResponse;
  var accesstoken;
  var customer_id;
  var aboutus_us;
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
      await AboutUs();
      setState(() {});
  }

  Future<void> AboutUs() async {
    setState(() => isLoading = true);
   var data = {
         "method": "about_us",
         "accesskey":"90336",
         "token":accesstoken,
   };
    final response = await Aboutapi().AboutUs(data);

    print(response);

    if(response != null){
      aboutus_us = response['message'] ?? [];
   

    setState(() => isLoading = false);
  }else{
    aboutus_us = [];
  }
    setState(() => isLoading = false);
 }
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        Navigator.push(context, MaterialPageRoute(builder: (context)=>Dashboard()));
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: custom_color.app_color,
          title: Text("About Us",style: TextStyle(color: Colors.white),),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios,color: Colors.white,),
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>Dashboard()));
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
             : aboutus_us == null || aboutus_us.toString().isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined,
                      size: 80, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text(
                    "No Aboutus Us Found",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  )
                ],
              ),
            )
            : SingleChildScrollView(
                child: Column(
                  children: [
          
                    /// 🔥 TOP GRADIENT CARD
                    Container(
                      margin: const EdgeInsets.all(15),
                      padding: const EdgeInsets.symmetric(vertical: 35),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            // Color(0xFF1FAF8B),
                            // Color(0xFF39C2A2),
                            custom_color.app_color,
                            custom_color.app_color.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
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
                      child: Column(
                        children: const [
                          Icon(
                            Icons.info_outline,
                            size: 80,
                            color: Colors.white,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "About Us",
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ),
                    ),
          
                    /// 🔥 CONTENT BOX
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.05),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Html(
                        data: aboutus_us ?? "",
                        style: {
                          "p": Style(
                            fontSize: FontSize(16),
                            color: Colors.black87,
                            lineHeight: const LineHeight(1.6),
                          ),
                        },
                      ),
                    ),
          
                    const SizedBox(height: 25),
                  ],
                ),
              ),
        ),
      ));
  }
}