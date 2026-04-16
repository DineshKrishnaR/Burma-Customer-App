import 'package:burma/Common/DeviceInfo.dart';
import 'package:burma/Dashboard/Dashboard.dart';
import 'package:burma/Settings/AboutApi.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Common/colors.dart' as custom_color;

class Contactus extends StatefulWidget {
  const Contactus({super.key});

  @override
  State<Contactus> createState() => _ContactusState();
}

class _ContactusState extends State<Contactus> {

final LocalStorage storage = new LocalStorage('app_store');
 
  late SharedPreferences pref;
  
  var device_id;
  bool isLoading = false;
  var userResponse;
  var accesstoken;
  var customer_id;
  var contacy_us;
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
      await ContactUs();
      setState(() {});
  }
  
  Future<void> ContactUs() async {
    setState(() => isLoading = true);
   var data = {
         "action": "contact_us",
         "accesskey":"90336",
         "token":accesstoken,
         "customer_id":customer_id,
         "act_type":userResponse['act_type'],
   };
    final response = await Aboutapi().ContactUs(data);

    print(response);

    if(response != null){
      contacy_us = response ?? [];
 setState(() => isLoading = false);
  }else{
    contacy_us = [];
  }
    setState(() => isLoading = false);
 }
  @override
  Widget build(BuildContext context) {
    const TextStyle valueStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: Colors.black87,
);

const TextStyle labelStyle = TextStyle(
  fontSize: 14,
  color: Colors.grey,
);
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        Navigator.push(context, MaterialPageRoute(builder: (context)=>Dashboard()));
      },
      child: Scaffold(
         appBar: AppBar(
          backgroundColor: custom_color.app_color,
          title: Text("Contact Us",style: TextStyle(color: Colors.white),),
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
             : contacy_us == null || contacy_us.toString().isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined,
                      size: 80, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text(
                    "No Contacy Us Found",
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
                      Icons.call,
                      size: 80,
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Contact Us",
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),

              /// 🔥 CONTACT DETAILS CARD
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 12,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// 📞 PHONE
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.phone, color: Colors.grey),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Contact number",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                contacy_us?['mobile'] ?? "",
                                // style: const TextStyle(
                                //   fontSize: 18,
                                //   fontWeight: FontWeight.bold,
                                // ),
                                 style: valueStyle,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 25),

                    /// 📧 EMAIL
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.email, color: Colors.grey),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Email",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                contacy_us?['mail']?.trim() ?? "",
                                // style: const TextStyle(
                                //   fontSize: 16,
                                //   fontWeight: FontWeight.w600,
                                // ),
                                 style: valueStyle,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 25),

                    /// 📍 ADDRESS
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: Colors.grey),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Address",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                contacy_us?['address']?.trim() ?? "",
                                // style: const TextStyle(
                                //   fontSize: 15,
                                // ),
                                 style: valueStyle,
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
),
      ));
  }
  
}