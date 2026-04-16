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

class Deliverypolicy extends StatefulWidget {
  const Deliverypolicy({super.key});

  @override
  State<Deliverypolicy> createState() => _DeliverypolicyState();
}

class _DeliverypolicyState extends State<Deliverypolicy> {
  
final LocalStorage storage = new LocalStorage('app_store');
 
  late SharedPreferences pref;
  

  bool isLoading = false;
  var userResponse;
  var accesstoken;
  var customer_id;
  var delivery_policy;
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
      await DeliveryPolicy();
      setState(() {});
  }
  Future<void> DeliveryPolicy() async {
    setState(() => isLoading = true);
   var data = {
         "method": "delivery_policy",
         "accesskey":"90336",
         "token":accesstoken,
   };
    final response = await Aboutapi().DeliveryPolicy(data);

    print(response);

    if(response != null){
      delivery_policy = response['message'] ?? [];
   

    setState(() => isLoading = false);
  }
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
          title: Text("Delivery Policy",style: TextStyle(color: Colors.white),),
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
            ) : delivery_policy == null || delivery_policy.toString().isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined,
                      size: 80, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text(
                    "No Delivery Policy Found",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  )
                ],
              ),
            )
            : _buildContent(),
        ),
      ));
  }
  Widget _buildContent() {
  return SingleChildScrollView(
    child: Column(
      children: [

        /// HEADER CARD
        Container(
          margin: const EdgeInsets.all(15),
          padding: const EdgeInsets.symmetric(vertical: 30),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                custom_color.app_color,
                custom_color.app_color.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: const [
              Icon(Icons.local_shipping_outlined,
                  size: 70, color: Colors.white),
              SizedBox(height: 10),
              Text(
                "Delivery Policy",
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              )
            ],
          ),
        ),

        /// POLICY CONTENT
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.08),
                blurRadius: 8,
              )
            ],
          ),
          child: Html(
            data: delivery_policy,
            style: {

              "p": Style(
                fontSize: FontSize(15),
                lineHeight: LineHeight(1.6),
                color: Colors.black87,
              ),

              "h3": Style(
                fontSize: FontSize(18),
                fontWeight: FontWeight.bold,
                color: custom_color.app_color,
                margin: Margins(top: Margin(15), bottom: Margin(8)),
              ),

              "ul": Style(
                margin: Margins(left: Margin(10)),
              ),

              "li": Style(
                fontSize: FontSize(15),
                lineHeight: LineHeight(1.6),
              ),
            },
          ),
        ),

        const SizedBox(height: 25)
      ],
    ),
  );
}
}