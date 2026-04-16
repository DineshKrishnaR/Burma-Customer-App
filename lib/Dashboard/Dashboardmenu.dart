import 'package:burma/Common/UrlPath.dart';
import 'package:burma/Favourites/Favourites.dart';
import 'package:burma/Login/LoginScreen.dart';
import 'package:burma/Notification/Notification.dart';
import 'package:burma/OrdersPages/Orders.dart';
import 'package:burma/ProfilePage/ProfilePage.dart';
import 'package:burma/Settings/AboutUs.dart';
import 'package:burma/Settings/ContactUs.dart';
import 'package:burma/Settings/DeliveryPolicy.dart';
import 'package:burma/Settings/PrivicyPolicy.dart';
import 'package:burma/Settings/ReturnRefundPolicy.dart';
import 'package:burma/Settings/TermsAndCondictions.dart';
import 'package:burma/Common/DeviceInfo.dart';
import 'package:burma/Common/FirebaseApi.dart';
import 'package:burma/Common/Utils.dart';
import 'package:burma/Dashboard/Dashboard.dart';
import 'package:burma/Dashboard/DashboardApi.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:localstorage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Common/colors.dart' as custom_color;

class Dashboardmenu extends StatefulWidget {
  const Dashboardmenu({super.key});

  @override
  State<Dashboardmenu> createState() => _DashboardmenuState();
}

class _DashboardmenuState extends State<Dashboardmenu> {
  final LocalStorage storage = LocalStorage('app_store');
  var userResponse;
  var accesstoken;
  bool isLoading = false;
  late SharedPreferences pref;
  var user_details;
  var fcmToken;
  var device_id;
  var user_logtype;
  var deviceName;
  var deviceModel;
  var osVersion;
  var customer_id;
  var wallet_amount;

  bool isProfileLoaded = false;
  @override
  void initState() {
    super.initState();
    initPreferences();
  }

  initPreferences() async {
    pref = await SharedPreferences.getInstance();
    await storage.ready;
    userResponse = await storage.getItem('userResponse');
    //  await FirebaseApi().initNotifications();
    // fcmToken = await storage.getItem('fcmToken');
     var device_info = await Device().initPlatformState();
    device_id = await storage.getItem('device_id');
    deviceName = storage.getItem('device_name') ?? "";
     deviceModel = storage.getItem('device_model') ?? "";
     osVersion = storage.getItem('os_version') ?? "";
      await FirebaseApi().initNotifications();  
      fcmToken = await storage.getItem('fcmToken');
      user_details = storage.getItem('user_details');
wallet_amount = storage.getItem('wallet_amount');
      print('FCM Token: $fcmToken');
      print('Device ID: $device_id');
    print(fcmToken);
    if (userResponse != null) {
      accesstoken = userResponse['api_token'];
      customer_id = userResponse['customer_id'].toString();

    }
    await ProfileDetails();
    await WalletDetails();
    // if(user_details == null){
    //   await ProfileDetails();
    // }

    // if(wallet_amount == null){
    //   await WalletDetails();
    // }
    setState(() {});
  }
  

 Future<void> ProfileDetails() async {
    setState(() => isLoading = true);
   var data = {
         "action": "get_profile",
         "customer_id":customer_id,
         "accesskey":"90336",
         "token":accesstoken,
         "act_type":userResponse['act_type'],
   };
    final response = await DashboardApi().ProfileDetails(data);

    print(response);

    if(response != null){
      user_details = response ?? [];
     await storage.setItem('user_details', response);
isProfileLoaded = true;
    setState(() => isLoading = false);
  }
 }
 
 Future<void> WalletDetails() async {
    setState(() => isLoading = true);
   var data = {
         "action": "wallet_dtl",
         "accesskey":"90336",
         "token":accesstoken,
         "customer_id":customer_id,
         "act_type":userResponse['act_type'],
   };
    final response = await DashboardApi().WalletDetails(data);

    print(response);

    if(response != null){
      wallet_amount = response ?? [];
    await storage.setItem('wallet_amount', response);

    setState(() => isLoading = false);
  }
 }
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height; 
    double screenWidth = MediaQuery.of(context).size.width;
    
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [

          // ================= HEADER =================
          Container(
            height: 180,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      // color: custom_color.app_color,
              gradient: LinearGradient(
                colors: [
                  custom_color.app_color,
                  Colors.lightBlueAccent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                // Center(
                //   child: Container(
                //      height: screenHeight * 0.04,
                //      width: screenWidth * 0.12,
                //      decoration:  BoxDecoration(
                //        image: DecorationImage(
                         
                //          image:  AssetImage("assets/images/user.png") as ImageProvider,
                //          fit: BoxFit.fill,
                //        ),
                //      ),
                //    ),
                // ),
                SizedBox(height: screenHeight * 0.04,),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // const CircleAvatar(
                    //   radius: 28,
                    //   backgroundColor: Colors.white,
                    //   child: Icon(Icons.person, size: 30, color: Colors.grey),
                    // ),
                    CircleAvatar(
                       radius: 28,
                      backgroundColor: Colors.white,
                        backgroundImage: 
                            (user_details != null && user_details['profileimage'] != null && user_details['profileimage'].isNotEmpty)
                                ? NetworkImage(user_details['profileimage'])
                                : AssetImage('assets/images/user.png') as ImageProvider,
                        // radius: 70.0,
                      ),
                    // (user_details != null && user_details['profileimage'] != null && user_details['profileimage'].isNotEmpty) ? NetworkImage(user_details['profileimage'])
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:  [
                          Text(
                            // "${user_details != null && user_details['name'] != null ? user_details['name'].toString() : ''}",
                            user_details != null && user_details['name'] != null
                            ? user_details['name'].toString()
                            : '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                           maxLines: 2,
                           overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.account_balance_wallet,
                                  size: 14, color: Colors.white70),
                              SizedBox(width: 6),
                              Text(
                                // "Wallet Balance : ₹ ${Helper().isvalidElement(wallet_amount) ? wallet_amount['amount'] :'0'}",
                                 wallet_amount != null && wallet_amount['amount'] != null
                                  ? "Wallet Balance : ₹ ${wallet_amount['amount']}"
                                  : '',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),

          // ================= MENU =================
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _menu(Icons.home_outlined, "Home", () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Dashboard()));
                }),

                _menu(Icons.person_outline, "Profile", () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>Profilepage()));
                }),

                // _menu(Icons.language_outlined, "Language", () {}),

                _menu(Icons.shopping_bag_outlined, "My Orders", () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>Orders()));
                }),

                _menu(Icons.notifications_outlined, "Notifications", () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>Notificationpage()));
                }),

                // _menu(Icons.account_balance_wallet_outlined, "Request Withdrawal", () {}),

                _menu(Icons.favorite_border_outlined, "Favourites", () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>Favourites()));
                }),

                // _menu(Icons.card_giftcard_outlined, "Refer & Earn", () {}),

                _menu(Icons.info_outline, "About Us", () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>Aboutus()));
                }),

                _menu(Icons.contact_mail_outlined, "Contact Us", () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>Contactus()));
                }),

                _menu(Icons.description_outlined, "Terms & Conditions", () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>Termsandcondictions()));
                }),

                _menu(Icons.local_shipping_outlined, "Delivery Policy", () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>Deliverypolicy()));
                }),

                _menu(Icons.privacy_tip_outlined, "Privacy Policy", () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>Privicypolicy()));
                }),

                _menu(Icons.assignment_return_outlined, "Return/Refund Policy", () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>Returnrefundpolicy()));
                }),

                // _menu(Icons.star_rate_outlined, "Rate Us", () {
                //   _openPlayStore();
                // }),

                // _menu(Icons.share_outlined, "Share App", () {}),

                _menu(Icons.logout_outlined, "Logout", () {
                  _logoutDialog(context);
                }),

                _menu(Icons.delete_outline, "Delete Account", () {
                  _deleteAccountDialog(context,customer_id,userResponse);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= MENU TILE =================
  static Widget _menu(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54, size: 22),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15),
      ),
      onTap: onTap,
      horizontalTitleGap: 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  static void _logoutDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // TITLE
              Text(
                "Logout",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: custom_color.app_color,
                ),
              ),

              const SizedBox(height: 12),

              // MESSAGE
              const Text(
                "Are you sure you want to logout ?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 24),

              // BUTTONS
              Row(
                children: [

                  // CANCEL BUTTON
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: custom_color.app_color,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: custom_color.app_color,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // LOGOUT BUTTON
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Helper().logout(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: custom_color.button_color,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        "Logout",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Future<void> _openPlayStore() async {
  final Uri url = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.liwapads',
  );

  if (!await launchUrl(
    url,
    mode: LaunchMode.externalApplication,
  )) {
    throw 'Could not launch $url';
  }
}

void _deleteAccountDialog(BuildContext context,customer_id,userResponse,) {
   bool isDeleting = false;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // WARNING ICON
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Colors.red.shade600,
                  size: 48,
                ),
              ),

              const SizedBox(height: 20),

              // TITLE
              Text(
                "Delete Account?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),

              const SizedBox(height: 12),

              // MESSAGE
              const Text(
                "This action cannot be undone. All your data including orders, wallet balance, and personal information will be permanently deleted.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // BUTTONS
              Row(
                children: [

                  // CANCEL BUTTON
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.grey.shade400,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                   SizedBox(width: 12),

                  // DELETE BUTTON
    //               Expanded(
    //                 child: ElevatedButton(
    //                   onPressed: isDeleting
    // ? null // 🚫 disable button
    // : () async {
    //   setState(() => isDeleting = true);

    //                     Navigator.pop(context);
    //                     // TODO: Add delete account API call here
    //                     var data ={
    //                       "user_id":customer_id,
    //                       "user_type": userResponse['act_type']
    //                     };
    //                      final response = await DashboardApi().DeleteAccount(data);

    //                       print(response);

    //                       if (response != null && response['status'] == "success") {

    //                         Fluttertoast.showToast(
    //                           msg: "Account deleted successfully",
    //                           backgroundColor: Colors.green,
    //                         );
    //                         //  Navigator.push(context, MaterialPageRoute(builder: (con)))
    //                         Helper().logout(context);
    //                       } else {

    //                         Fluttertoast.showToast(
    //                           msg: response['message'] ?? "Delete failed",
    //                           backgroundColor: Colors.red,
    //                         );
    //                       }
    //                        isDeleting = false;
    //                   },
    //                   style: ElevatedButton.styleFrom(
    //                     backgroundColor: Colors.red.shade600,
    //                     elevation: 0,
    //                     shape: RoundedRectangleBorder(
    //                       borderRadius: BorderRadius.circular(12),
    //                     ),
    //                     padding: const EdgeInsets.symmetric(vertical: 14),
    //                   ),
    //                   child:  isDeleting
    // ? const SizedBox(
    //     height: 18,
    //     width: 18,
    //     child: CircularProgressIndicator(
    //       color: Colors.white,
    //       strokeWidth: 2,
    //     ),
    //   )
    // : const Text("Delete",style: TextStyle(color: Colors.white),)
    //                 ),
    //               ),
     Expanded(
                        child: ElevatedButton(
                          onPressed: isDeleting
                              ? null
                              : () async {
                                  setState(() => isDeleting = true); // ✅ lock

                                  try {
                                    var data = {
                                      "user_id": customer_id,
                                      "user_type": userResponse['act_type']
                                    };

                                    final response = await DashboardApi()
                                        .DeleteAccount(data)
                                        .timeout(
                                            const Duration(seconds: 15));

                                    Navigator.pop(context);

                                    if (response != null &&
                                        response['status'] == "success") {
                                      Fluttertoast.showToast(
                                        msg: "Account deleted successfully",
                                        backgroundColor: Colors.green,
                                      );
                                        Helper().clearAllData();

                                          final pref = await SharedPreferences.getInstance();
                                          await pref.clear();

                                          // 🔥 remove all previous pages (Dashboard, Profile etc)
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            MaterialPageRoute(builder: (context) => const Loginscreen()),
                                            (route) => false,   // removes all old routes
  );
                                    } else {
                                      Fluttertoast.showToast(
                                        msg: response?['message'] ??
                                            "Delete failed",
                                        backgroundColor: Colors.red,
                                      );
                                    }

                                  } catch (e) {
                                    Navigator.pop(context);

                                    Fluttertoast.showToast(
                                      msg:
                                          "Slow internet. Please try again.",
                                      backgroundColor: Colors.red,
                                    );
                                  } finally {
                                    setState(() => isDeleting = false); // unlock
                                  }
                                },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                          ),

                          child: isDeleting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Delete",
                                  style: TextStyle(color: Colors.white)),
                        ),
                      ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

}
