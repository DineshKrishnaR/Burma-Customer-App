
import 'dart:async';
import 'dart:io';

import 'package:burma/Api/Api.dart';
import 'package:burma/Common/DeviceInfo.dart';
import 'package:burma/Common/FirebaseApi.dart';
import 'package:burma/Common/Utils.dart';
import 'package:burma/Dashboard/Dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:localstorage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Common/colors.dart' as custom_color;

class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {

  TextEditingController mobile = TextEditingController();
  final LocalStorage storage = new LocalStorage('app_store');
  TextEditingController nameController = TextEditingController();
TextEditingController referralController = TextEditingController();
  String gender = "";

  List<TextEditingController> otpControllers =
    List.generate(5, (index) => TextEditingController());

List<FocusNode> focusNodes =
  List.generate(5, (index) => FocusNode());
  late SharedPreferences pref;
  int step = 1; // 1 mobile, 2 send otp, 3 verify otp
  bool isCustomer = true;
  var device_id;
  bool isLoading = false;
  var Otp;
  var user_logtype;
  var fcmToken;
  var deviceName;
  var deviceModel;
  var osVersion;
  Timer? _timer;
  bool _canResend = false;
  ValueNotifier<int> secondsNotifier = ValueNotifier<int>(30);
  
  bool _isButtonLocked = false;
  final GlobalKey<_OtpFieldsState> _otpFieldKey = GlobalKey<_OtpFieldsState>();
@override
  void initState() {
    super.initState();
    initPreferencess();

    // listenForCode();
    
  }
  @override
void dispose() {
  nameController.dispose();
  referralController.dispose();
  _timer?.cancel();
  for (var c in otpControllers) {
    c.dispose();
  }

  for (var f in focusNodes) {
    f.dispose();
  }
  secondsNotifier.dispose();

  mobile.dispose();
  super.dispose();
}

 initPreferencess() async {
    await storage.ready;
    pref = await SharedPreferences.getInstance();
    var device_info = await Device().initPlatformState();
    device_id = await storage.getItem('device_id');
     deviceName = storage.getItem('device_name') ?? "";
     deviceModel = storage.getItem('device_model') ?? "";
     osVersion = storage.getItem('os_version') ?? "";
      await FirebaseApi().initNotifications();  
      fcmToken = await storage.getItem('fcmToken');
      print('FCM Token: $fcmToken');
      print('Device ID: $device_id');
      setState(() {});
  }
//   void startResendTimer() {
//   _secondsRemaining = 30;
//   _canResend = false;

//   _timer?.cancel();

//   _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//      if (!mounted) return;
//     if (_secondsRemaining > 0) {
//       setState(() {
//         _secondsRemaining--;
//       });
//     } else {
//       timer.cancel();
//       setState(() {
//         _canResend = true;
//       });
//     }
//   });
// }
void startResendTimer() {
  secondsNotifier.value = 30;
  _canResend = false;

  _timer?.cancel();

  _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (!mounted) return;

    if (secondsNotifier.value > 0) {
      secondsNotifier.value--;
    } else {
      timer.cancel();

      setState(() {
        _canResend = true;
      });
    }
  });
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: custom_color.app_color,
     
      body: Container(
        decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1F3C88), // Blue
            Color(0xFF2E3AA7), // Mid Blue
            Color(0xFF5B2C83), // Purple
          ],
        ),
      ),
        child: SafeArea(
          
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Image.asset("assets/images/AppLogo.png", height: 120),
                   Align(
          alignment: Alignment.topCenter,
          child: Image.asset(
            "assets/images/AppLogo.png",
            height: 120,
          ),
        ),
                  const SizedBox(height: 30),
        
                  if(step==1) sendOtpStep(),
                  if(step==2) mobileStep(),
                  if(step==3) otpStep(),
                  if(step==4) registerStep(), 
        
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ================= STEP 1 =================
  Widget mobileStep(){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: [

          const Text("Enter your mobile number",
              style: TextStyle(color: Colors.white,fontSize: 18)),

          const SizedBox(height: 25),

          // Container(
          //     height: 60,
          //     //  alignment: Alignment.center, 
          //     decoration: BoxDecoration(
          //       color: Colors.grey.shade200,
          //       borderRadius: BorderRadius.circular(40),
          //     ),
          //     child: TextField(
          //       controller: mobile,
          //       keyboardType: TextInputType.number,
          //       maxLength: 10,
          //       textAlignVertical: TextAlignVertical.center,
          //       inputFormatters: [
          //         FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          //         LengthLimitingTextInputFormatter(10),
          //       ],
          //       decoration: const InputDecoration(
          //         counterText: "",
          //         hintText: 'Enter Your Mobile No...',
          //         border: InputBorder.none,
          //         contentPadding: EdgeInsets.symmetric(horizontal: 25),
          //       ),
          //     ),
          //   ),
         Container(
            height: 55,
            alignment: Alignment.center, 
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(40),
            ),
            child: TextField(
              controller: mobile,
              maxLength: 10,
              keyboardType: TextInputType.number,
               inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  LengthLimitingTextInputFormatter(10),
                ],
              // readOnly: true,
              decoration: const InputDecoration(
                counterText: "",
                hintText: 'Enter Your Mobile No...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 25),
              ),
            ),
          ),
          const SizedBox(height: 25),

         Container(
            // width: double.infinity,
            width: MediaQuery.of(context).size.width * 0.55,

            // height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              gradient: const LinearGradient(
                colors:[Color(0xFF1FA45B),Color(0xFF148A49)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0,12),
                )
              ],
            ),
            child: ElevatedButton(
              // onPressed:isLoading ? null : () async {
onPressed: (_isButtonLocked || isLoading)
    ? null
    : () async {
       _isButtonLocked = true;
 _isButtonLocked = true;

if (mobile.text.isEmpty) {
  Fluttertoast.showToast(msg: 'Enter your mobile number');
  _isButtonLocked = false; // ✅ FIX
  return;
}

if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobile.text)) {
  Fluttertoast.showToast(msg: 'Please enter a valid mobile number');
   _isButtonLocked = false; // ✅ FIX
  return;
}
if (mobile.text.length != 10) {
  Fluttertoast.showToast(msg: 'Please enter a valid mobile number');
  _isButtonLocked = false; // ✅ FIX
  return;
}

  var data = {
    "action": "verify_user",
    "mobile": mobile.text.toString(),
    "accesskey": "90336",
    "log_type": "register",
  };

  final response = await Api().Register(data);
  print(response);

  if (response == null) {
    Fluttertoast.showToast(msg: "Server error");
    return;
  }

  /// 🔥 SUCCESS CASES
  if (response['status'] == "success") {

    /// 🟢 NEW USER
    if (response['user_logtype'] == "register") {

      Fluttertoast.showToast(msg: "OTP sent for registration");
      user_logtype = response['user_logtype'];
      await RegisterSentOTP();
      setState(() {
        step = 3; // Open OTP screen
      });
      Future.delayed(const Duration(milliseconds: 200), () {
  focusNodes[0].requestFocus();
});
    }

    /// 🟢 RE-REGISTER (Deleted user)
    else if (response['user_logtype'] == "reregister" &&
        response['user_reregister'] == 1) {

      Fluttertoast.showToast(
          msg: response['message'] ??
              "Verify OTP to reactivate account");
      user_logtype = response['user_logtype'];
      setState(() {
        step = 3; // Open OTP screen
      });
      Future.delayed(const Duration(milliseconds: 200), () {
  focusNodes[0].requestFocus();
});
      ReRegisterSentOTP();
    }
  }

  /// 🔴 ERROR CASES
  else if (response['status'] == "error") {

    String message = response['message'] ?? "Registration not allowed";

    /// 🔴 Already active user
    if (message.contains("already exists")) {
          Fluttertoast.showToast(msg: "This mobile number is already registered. Please login.");
         
    }

    /// 🔴 Not active
    else if (message.contains("not active")) {
showInactiveDialog(context, message);

    }

    /// 🔴 Other errors
    else {
      Fluttertoast.showToast(msg: message);
    }}
    setState(() => isLoading = false);
       
           _isButtonLocked = false; 
},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: isLoading
      ?  CircularProgressIndicator(color: Colors.white)
      :Text('Submit',
                  style: const TextStyle(fontSize:22,fontWeight: FontWeight.bold,color: Colors.white)),
            ),
          ),
          const SizedBox(height: 25),

          // const Text("Already have an Account ? Login",
          //     style: TextStyle(color: Colors.white,decoration: TextDecoration.underline)),
        Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    const Text(
      "Already have an Account ? ",
      style: TextStyle(
        color: Colors.white,
        // decoration: TextDecoration.underline,
      ),
    ),

    GestureDetector(
      onTap: () {
        mobile.clear();
        setState(() {
          step=1;
        });
       
      },
      child: const Text(
        "Login",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18
          // decoration: TextDecoration.underline,
        ),
      ),
    ),
  ],
)
        ],
      ),
    );
  }

  Future<bool> hasInternet() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } on SocketException {
    return false;
  }
}
void showInactiveDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Account Inactive"),
      content: Text(message.isNotEmpty
          ? message
          : "Your account is inactive. Please contact admin."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        )
      ],
    ),
  );
}

Future<void> Login() async {
if (isLoading) return;
  if (mobile.text.isEmpty) {
    Fluttertoast.showToast(msg: "Enter mobile number");
    return;
  }

  if (!RegExp(r'^[0-9]+$').hasMatch(mobile.text)) {
    Fluttertoast.showToast(msg: "Only numbers allowed");
    return;
  }

  if (mobile.text.length != 10) {
    Fluttertoast.showToast(msg: "Enter valid 10-digit mobile number");
    return;
  }

   setState(() {
    isLoading = true;
  });
  var data = {
    "mobile": mobile.text.toString(),
    "log_type": "login",
    "accesskey":"90336",
    "action": "verify_user",
  };

  // final response = await Api().loginApi(data);
  // print(response);
    try {
final response = await Api()
        .loginApi(data)
        .timeout(const Duration(seconds: 15)); // ✅ timeout

    /// ✅ SERVER NULL
    if (response == null) {
      Fluttertoast.showToast(msg: "Server not responding");
      return;
    }
  // setState(() {
  //   isLoading = false;
  // });

  /// 🔥 HANDLE USING user_logtype

  if (response['user_logtype'] == "login") {
setState(() {
      isLoading = false;
    });
    // Fluttertoast.showToast(msg: "Login allowed");
    user_logtype = "login";
    LoginsendOTP();
    setState(() {
      step = 3; // open OTP
    });
     Future.delayed(const Duration(milliseconds: 200), () {
      focusNodes[0].requestFocus();
    });
  } 
  else if (response['user_logtype'] == "register") {

    Fluttertoast.showToast(
        msg: response['message'] ??
            "Your account is not registered. Please register!");
      
  } 
  else {
    // Fluttertoast.showToast(
    //     msg: response['message'] ?? "Something went wrong");   
     String message = response['message'] ?? "";

  if (message.toLowerCase().contains("not active")) {
    showInactiveDialog(context, message); // ✅ FIX HERE
  } else {
    Fluttertoast.showToast(
      msg: message.isNotEmpty ? message : "Something went wrong"
    );
  }
  }
   setState(() {
      isLoading = false;
    });
   } on TimeoutException {
    Fluttertoast.showToast(msg: "Request timeout. Please try again.");
  } on SocketException {
    Fluttertoast.showToast(msg: "No internet connection");
  } catch (e) {
    Fluttertoast.showToast(msg: "Something went wrong");
  } finally {
    /// ✅ ALWAYS STOP LOADING
     setState(() {
    isLoading = false;
    _isButtonLocked = false;
  });
  }
  
}

// Future<void> Login() async {
//   if (isLoading) return;

//   if (mobile.text.isEmpty) {
//     Fluttertoast.showToast(msg: "Enter mobile number");
//     return;
//   }

//   if (!RegExp(r'^[0-9]+$').hasMatch(mobile.text)) {
//     Fluttertoast.showToast(msg: "Only numbers allowed");
//     return;
//   }

//   if (mobile.text.length != 10) {
//     Fluttertoast.showToast(msg: "Enter valid 10-digit mobile number");
//     return;
//   }

//   setState(() {
//     isLoading = true;
//   });

//   var data = {
//     "mobile": mobile.text.toString(),
//     "log_type": "login",
//     "accesskey": "90336",
//     "action": "verify_user",
//   };

//   try {
//     final response = await Api()
//         .loginApi(data)
//         .timeout(const Duration(seconds: 15));

//     if (response == null) {
//       Fluttertoast.showToast(msg: "Server not responding");
//       return;
//     }

//     /// 🔥 HANDLE RESPONSE
//     if (response['user_logtype'] == "login") {
//       Fluttertoast.showToast(msg: "Login allowed");
//       user_logtype = "login";
//       LoginsendOTP();

//       setState(() {
//         step = 3;
//       });

//       Future.delayed(const Duration(milliseconds: 200), () {
//         focusNodes[0].requestFocus();
//       });
//     } else if (response['user_logtype'] == "register") {
//       Fluttertoast.showToast(
//         msg: response['message'] ??
//             "Your account is not registered. Please register!",
//       );
//     } else {
//       Fluttertoast.showToast(
//         msg: response['message'] ?? "Something went wrong",
//       );
//     }
//   } on TimeoutException {
//     Fluttertoast.showToast(msg: "Request timeout. Please try again.");
//   } on SocketException {
//     Fluttertoast.showToast(msg: "No internet connection");
//   } catch (e) {
//     Fluttertoast.showToast(msg: "Something went wrong");
//   } finally {
//     /// ✅ ALWAYS STOP LOADING
//     setState(() {
//       isLoading = false;
//     });
//   }
// }
  
  /// ================= STEP 2 =================
  Widget sendOtpStep(){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: [
 const Text("Enter your mobile number",
              style: TextStyle(color: Colors.white,fontSize: 18)),
              const SizedBox(height: 25),
          Container(
            height: 55,
            alignment: Alignment.center, 
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(40),
            ),
            child: TextField(
              controller: mobile,
              keyboardType: TextInputType.number,
               inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  LengthLimitingTextInputFormatter(10),
                ],
              // readOnly: true,
              decoration: const InputDecoration(
                hintText: 'Enter Your Mobile No...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 25),
              ),
            ),
          ),

          const SizedBox(height: 25),

          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [

          //     Checkbox(
          //       value: isCustomer,
          //       onChanged: (v){
          //         setState(()=>isCustomer=true);
          //       },
          //       activeColor: Colors.white,
          //       checkColor: custom_color.app_color,
          //     ),
          //      Text("Customer",style: TextStyle(color: Colors.white)),

          //     const SizedBox(width: 30),

          //     Checkbox(
          //       value: !isCustomer,
          //       onChanged: (v){
          //         setState(()=>isCustomer=false);
          //       },
          //       activeColor: Colors.white,
          //       checkColor: custom_color.app_color,
          //     ),
          //     const Text("Reseller",style: TextStyle(color: Colors.white)),
          //   ],
          // ),
          // const SizedBox(height: 35),

   Container(
      // width: double.infinity,
      width: MediaQuery.of(context).size.width * 0.55,

      // height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: const LinearGradient(
          colors:[Color(0xFF1FA45B),Color(0xFF148A49)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0,12),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null :(){
            //  setState(() {
            //   step = 3;
            // });
            Login();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: isLoading
    ? const CircularProgressIndicator(
        color: Colors.white,
        strokeWidth: 3,
      )
    :Text('Send OTP',
            style: const TextStyle(fontSize:22,fontWeight: FontWeight.bold,color: Colors.white)),
      ),
    ),
          const SizedBox(height: 25),

         Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an Account? ",
                  style: TextStyle(
                    color: Colors.white,
                    // decoration: TextDecoration.underline,
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    mobile.clear();
                    setState(() {
                      step=2;
                      
                    });
                  },
                  child: const Text(
                    "Create Account Here",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18
                      // decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }

  /// ================= STEP 3 =================
  Widget otpStep(){
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//   if (focusNodes.isNotEmpty) {
//     focusNodes[0].requestFocus();
//   }
// });
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: [

          const Text("Verify OTP",
              style: TextStyle(color: Colors.white,fontSize: 28,fontWeight: FontWeight.bold)),

          const SizedBox(height: 25),

          Text("Please Enter OTP sent via\nSMS on +91 ${mobile.text}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white,fontSize: 16)),

          const SizedBox(height: 30),

//          Row(
//   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//   children: List.generate(5, (index) {
//     return Container(
//       width: 55,
//       height: 60,
//       decoration: BoxDecoration(
//         color: Colors.grey.shade200,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: TextField(
//         controller: otpControllers[index],
//         focusNode: focusNodes[index],
//         textAlign: TextAlign.center,
//         maxLength: 1,
//         keyboardType: TextInputType.number,
//         inputFormatters: [
//           FilteringTextInputFormatter.allow(RegExp(r'[0-9]')), // only number
//         ],
//         decoration: const InputDecoration(
//           counterText: "",
//           border: InputBorder.none,
//         ),

//         onChanged: (value) {

//           /// move next
//           if (value.isNotEmpty && index < 4) {
//             FocusScope.of(context).requestFocus(focusNodes[index + 1]);
//           }

//           /// backspace go previous
//           if (value.isEmpty && index > 0) {
//             FocusScope.of(context).requestFocus(focusNodes[index - 1]);
//           }
//         },
//       ),
//     );
//   }),
// ),
OtpFields(
  key: _otpFieldKey,
  controllers: otpControllers,
  focusNodes: focusNodes,
),

          const SizedBox(height: 20),

         Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    const Text(
      "Don't receive OTP? ",
      style: TextStyle(color: Colors.white70),
    ),
    // _canResend
    //     ? TextButton(
    //         onPressed: () {
    //           if (user_logtype == "register") {
    //             RegisterSentOTP();
    //           } else if (user_logtype == "login") {
    //             LoginsendOTP();
    //           }
    //         },
    //         child: const Text(
    //           "Resend",
    //           style: TextStyle(color: Colors.white),
    //         ),
    //       )
    // _canResend
    // ? TextButton(
    //     onPressed: isLoading
    //         ? null
    //         : () {
    //             if (user_logtype == "register") {
    //               RegisterSentOTP();
    //             } else if (user_logtype == "login") {
    //               LoginsendOTP();
    //             }
    //           },
    //     style: TextButton.styleFrom(
    //       padding: EdgeInsets.zero,
    //     ),
    //     child: const Text(
    //       "Resend OTP",
    //       style: TextStyle(
    //         color: Colors.white,
    //         fontWeight: FontWeight.bold,
    //         decoration: TextDecoration.underline,
    //         fontSize: 16,
    //       ),
    //     ),
    //   )
    //     : Text(
    //         "Resend in $_secondsRemaining sec",
    //         style: const TextStyle(color: Colors.white70),
    //       ),
    AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  child: _canResend
      ? TextButton(
          key: const ValueKey("resend"),
          onPressed: isLoading
              ? null
              : () {
                  _otpFieldKey.currentState?.clearOtp();
                  if (user_logtype == "register") {
                    RegisterSentOTP();
                  } else if (user_logtype == "login") {
                    LoginsendOTP();
                  } else if (user_logtype == "reregister") {
                    ReRegisterSentOTP();
                  }
                },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
          ),
          child: const Text(
            "Resend OTP",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              // decoration: TextDecoration.underline,
              fontSize: 16,
            ),
          ),
        )
      // : Text(
      //     "Resend in $_secondsRemaining sec",
      //     key: const ValueKey("timer"),
      //     style: const TextStyle(color: Colors.white70),
      //   ),
      :ValueListenableBuilder<int>(
         key: const ValueKey("timer"),
  valueListenable: secondsNotifier,
  builder: (context, seconds, child) {
    return Text(
      "Resend in $seconds sec",
      style: const TextStyle(color: Colors.white70),
    );
  },
)
)
  ],
),

          const SizedBox(height: 35),

          Container(
      // width: double.infinity,
      width: MediaQuery.of(context).size.width * 0.55,

      // height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: const LinearGradient(
          colors:[Color(0xFF1FA45B),Color(0xFF148A49)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0,12),
          )
        ],
      ),
      child: ElevatedButton(
        // onPressed: isLoading ? null :(){
        onPressed: (_isButtonLocked || isLoading)
    ? null
    : () async {
        _isButtonLocked = true;

          if (isLoading) return;
           String otp = otpControllers.map((e) => e.text).join();

          if (otp.length < 5) {
            Fluttertoast.showToast(msg: "Enter complete OTP");
            _isButtonLocked = false;
            return;
          }else if(user_logtype == "register"){
           if(Otp == otp){
             Fluttertoast.showToast(msg: "OTP Verified Successfully");
             setState(() {
               step = 4;
             });
          }else{
            Fluttertoast.showToast(msg: "Incorrect OTP");
          }
          }else if(user_logtype == "reregister"){
            if(Otp == otp){
             Fluttertoast.showToast(msg: "OTP Verified Successfully");
             Reregisterverifylogin();
          }else{
            Fluttertoast.showToast(msg: "Incorrect OTP");
          }
          }
          else if(user_logtype == 'login'){
            if(Otp == otp){
             Fluttertoast.showToast(msg: "OTP Verified Successfully");
             verifylogin();
          }else{
            Fluttertoast.showToast(msg: "Incorrect OTP");
          }
          }
          else{
            Fluttertoast.showToast(msg: "Incorrect OTP");
          }
           _isButtonLocked = false;
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: isLoading
      ? const CircularProgressIndicator(color: Colors.white)
      :Text('Submit',
            style: const TextStyle(fontSize:22,fontWeight: FontWeight.bold,color: Colors.white)),
      ),
    ),
        ],
      ),
    );
  }


Widget registerStep(){
  // TextEditingController name = TextEditingController();
  // TextEditingController referral = TextEditingController();


  String userType = "";
String maskMobile(String number){
  if(number.length < 10) return number;
  return "${number.substring(0,3)}****${number.substring(7,10)}";
}
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25),
    child: Column(
      children: [

        /// NAME
        // Container(
        //   height: 55,
        //   decoration: BoxDecoration(
        //     color: Colors.grey.shade200,
        //     borderRadius: BorderRadius.circular(40),
        //   ),
        //   child: TextFormField(
        //     controller: nameController,
        //     textAlign: TextAlign.start,
            
        //      textAlignVertical: TextAlignVertical.center,
        //      inputFormatters: [
        //         FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
        //       ],
        //     decoration: const InputDecoration(
        //       hintText: "Name",
        //       border: InputBorder.none,
        //       // contentPadding: EdgeInsets.only(left :20,top: 20),
        //     ),
        //   ),
        // ),
        
         TextFormField(
  controller: nameController,
  textAlign: TextAlign.left,
  textAlignVertical: TextAlignVertical.center,
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
  ],
  decoration: InputDecoration(
    hintText: "Name",
    isDense: true,
    filled: true,
    fillColor: Colors.grey.shade200,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 14,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: BorderSide.none,
    ),
  ),
),
        const SizedBox(height: 20),

        /// GENDER
        const Align(
          alignment: Alignment.centerLeft,
          child: Text("Gender",
              style: TextStyle(color: Colors.white,fontSize: 18)),
        ),

//        Row(
//   children: [
//     Checkbox(
//       value: gender == "Male",
//       onChanged: (value) {
//         setState(() {
//           gender = "Male";
//         });
//       },
//       activeColor: Colors.green,
//       checkColor: Colors.white,
//     ),
//     const Text("Male", style: TextStyle(color: Colors.white)),

//     const SizedBox(width: 20),

//     Checkbox(
//       value: gender == "Female",
//       onChanged: (value) {
//         setState(() {
//           gender = "Female";
//         });
//       },
//       activeColor: Colors.green,
//       checkColor: Colors.white,
//     ),
//     const Text("Female", style: TextStyle(color: Colors.white)),
//   ],
// ),
Row(
  children: [
    Checkbox(
      value: gender == "Male",
      onChanged: (value) {
         final currentText = nameController.text; 
        setState(() {
          if (gender == "Male") {
            gender = ""; // 🔥 deselect
          } else {
            gender = "Male"; // select
          }
        });
        nameController.text = currentText;
      },
      fillColor: MaterialStateProperty.all(Colors.white),
      // activeColor: Colors.green,
      checkColor: Colors.green,
    ),
    const Text("Male", style: TextStyle(color: Colors.white)),

    const SizedBox(width: 20),

    Checkbox(
      value: gender == "Female",
      onChanged: (value) {
        setState(() {
          if (gender == "Female") {
            gender = ""; // 🔥 deselect
          } else {
            gender = "Female"; // select
          }
        });
      },
      fillColor: MaterialStateProperty.all(Colors.white),
      // activeColor: Colors.green,
      checkColor: Colors.green,
    ),
    const Text("Female", style: TextStyle(color: Colors.white)),
  ],
),

        const SizedBox(height: 20),

      //  Container(
      //     height: 55,
      //     decoration: BoxDecoration(
      //       color: Colors.grey.shade200,
      //       borderRadius: BorderRadius.circular(40),
      //     ),
      //     child: TextField(
      //       controller: mobile,
      //       // textAlign: TextAlign.left, // ✅ left
      //       textAlignVertical: TextAlignVertical.center, 
      //       readOnly: true,
      //       decoration: const InputDecoration(
      //         hintText: "Enter Your Mobile No...",
      //         border: InputBorder.none,
      //         // contentPadding: EdgeInsets.symmetric(horizontal: 25),
              
      //       ),
      //     ),
      //   ),
         TextFormField(
  controller: mobile,
  textAlign: TextAlign.left,
  textAlignVertical: TextAlignVertical.center,
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
  ],
  readOnly: true,
  decoration: InputDecoration(
    hintText: "Enter Your Mobile No...",
    isDense: true,
    filled: true,
    fillColor: Colors.grey.shade200,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 14,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(40),
      borderSide: BorderSide.none,
    ),
  ),
),
        const SizedBox(height: 20),

        /// REFERRAL
        // Container(
        //   height: 60,
        //   decoration: BoxDecoration(
        //     color: Colors.grey.shade200,
        //     borderRadius: BorderRadius.circular(40),
        //   ),
        //   child: TextField(
        //     controller: referralController,
        //     decoration: const InputDecoration(
        //       hintText: "Referral Code (Optional)",
        //       border: InputBorder.none,
        //       contentPadding: EdgeInsets.symmetric(horizontal: 25),
        //     ),
        //   ),
        // ),

        const SizedBox(height: 30),

        /// SIGN UP BUTTON
        Container(
          // width: double.infinity,
          width: MediaQuery.of(context).size.width * 0.55,

          // height: 65,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: const LinearGradient(
              colors:[Color(0xFF1FA45B),Color(0xFF148A49)],
            ),
          ),
          child: ElevatedButton(
            
    //         onPressed: (_isButtonLocked || isLoading)
    // ? null
    // : () async {

    //     _isButtonLocked = true;

    //           if(nameController.text.isEmpty){
    //             Fluttertoast.showToast(msg: "Enter Name");
    //           }else if(gender.isEmpty){
    //             Fluttertoast.showToast(msg: "Select Gender");
    //           }else if(mobile.text.isEmpty){
    //             Fluttertoast.showToast(msg: "Enter Mobile Number");
    //           }else if(mobile.text.length<10){
    //             Fluttertoast.showToast(msg: "Enter Valid Mobile Number");
    //           }else{
    //             var data ={
    //                "action":"register",
    //                "mobile": mobile.text.toString(),
    //                "gender": gender,
    //                "fcm_id": fcmToken,
    //                "name": nameController.text.toString(),
    //                "wtob":"CUST",
    //               //  "reference_code":Helper().isvalidElement(referralController)?referralController.text.toString():"",
    //               "reference_code": Helper().isvalidElement(referralController.text)
    //               ? referralController.text
    //               : "",
    //             };
    //             final response = await Api().UserRegister(data);
    //             if (response == null) { setState(() => isLoading = false); _isButtonLocked = false; return; }
    //             print(response);
    //             if(response['code'] == 200){
    //               Fluttertoast.showToast(msg: response['message'].toString());
                 
    //             storage.setItem('userResponse', response);
    //             await pref.setBool('isLogin', true);
    //             Navigator.push(context, MaterialPageRoute(builder: (context)=>Dashboard()));
    //           }else{
    //             Fluttertoast.showToast(msg: response['message'].toString());
               
    //           }
    //            setState(() => isLoading = false);
    //            _isButtonLocked = false;
    //           }
    //         },
    onPressed: (_isButtonLocked || isLoading)
    ? null
    : () async {

        setState(() {
          _isButtonLocked = true;
        });

        try {
         if (nameController.text.isEmpty) {
            Fluttertoast.showToast(msg: "Enter Name");
            _isButtonLocked = false;
            return;
          } else if (gender.isEmpty) {
            Fluttertoast.showToast(msg: "Select Gender");
            _isButtonLocked = false;
            return;
          } else if (mobile.text.isEmpty) {
            Fluttertoast.showToast(msg: "Enter Mobile Number");
            _isButtonLocked = false;
            return;
          } else if (mobile.text.length < 10) {
            Fluttertoast.showToast(msg: "Enter Valid Mobile Number");
            _isButtonLocked = false;
            return;
          }
          

          var data = {
            "action": "register",
            "mobile": mobile.text.toString(),
            "gender": gender,
            "fcm_id": fcmToken,
            "name": nameController.text.toString(),
            "wtob": "CUST",
            "reference_code": Helper().isvalidElement(referralController.text)
                ? referralController.text
                : "",
          };

          final response = await Api().UserRegister(data);

          if (response == null) {
            Fluttertoast.showToast(msg: "Server error");
            return;
          }

          if (response['code'] == 200) {
            Fluttertoast.showToast(msg: response['message'].toString());

            storage.setItem('userResponse', response);
            await pref.setBool('isLogin', true);

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Dashboard()),
            );
          } else {
            Fluttertoast.showToast(msg: response['message'].toString());
          }

        } catch (e) {
          Fluttertoast.showToast(msg: "Something went wrong");
        } finally {
          /// ✅ ALWAYS UNLOCK BUTTON
          setState(() {
            _isButtonLocked = false;
          });
        }
      },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: isLoading
      ? const CircularProgressIndicator(color: Colors.white)
      : Text('SIGN UP',
                style: TextStyle(fontSize:22,fontWeight: FontWeight.bold,color: Colors.white)),
          ),
        ),
      ],
    ),
  );
}

RegisterSentOTP()async{
    if (isLoading) return; 
  setState(() {
    isLoading = true;
  });

  var data = {
    "mobile": mobile.text.toString(),
    "action": "send_otp",
    "type":"R",
    "device_id": device_id.toString(),
    "apphashkey":""
  };

  final response = await Api().RegisterSentOTP(data);
  if (response == null) { setState(() => isLoading = false); return; }
  print(response['otp']);
  if(response['code'] == 200){
    Fluttertoast.showToast(msg: "OTP sent successfully!");
    Otp = response['otp'].toString();
    startResendTimer(); 
    print(Otp);
    print(Otp);
    print(Otp);
  }
  
  setState(() {
    isLoading = false;
  });
}

ReRegisterSentOTP()async{
    if (isLoading) return; 
  setState(() {
    isLoading = true;
  });

  var data = {
    "mobile": mobile.text.toString(),
    "action": "send_otp",
    "type":"RR",
    "device_id": device_id.toString(),
    "apphashkey":""
  };
// 9865752976
  final response = await Api().RegisterSentOTP(data);
  if (response == null) { setState(() => isLoading = false); return; }
  print(response);
  if(response['code'] == 200){
    Fluttertoast.showToast(msg: "OTP sent successfully!");
    Otp = response['otp'].toString();
    startResendTimer(); 
    print(Otp);
    print(Otp);
    print(Otp);
  }
  
  setState(() {
    isLoading = false;
  });
}
LoginsendOTP()async{
  //  if (isLoading) return;
  setState(() {
    isLoading = true;
  });

  var data = {
    "mobile": mobile.text.toString(),
    "action": "send_otp",
    "type":"L",
    "device_id": device_id.toString(),
    "apphashkey":""
  };

  final response = await Api().LoginsendOTP(data);
  if (response == null) { setState(() => isLoading = false); return; }
  print(response);
  if(response['code'] == 200){
    Fluttertoast.showToast(msg: "OTP sent successfully!");
    Otp = response['otp'].toString();
    startResendTimer(); 
    print(Otp);
    print(Otp);
    print(Otp);
  }
  
  setState(() {
    isLoading = false;
  });
}
verifylogin() async {
  if (isLoading) return; 
  setState(() {
    isLoading = true;
  });

  var data = {
    "action": "login",
    "mobile": mobile.text.toString(),
    "device_name": deviceName, // optional
    "device_model": deviceModel,
    "os_version": osVersion,   // optional
    "act_type": "CUST",
    "fcm_id": fcmToken ?? "",
  };

  final response = await Api().loginApi(data);
  print(response);

  setState(() {
    isLoading = false;
  });

  if (response == null) return;

  if (response['status'] == "success" && response['code'] == 200) {

    Fluttertoast.showToast(msg: response['message']);

    /// ✅ SAVE USER DATA
    await storage.setItem('userResponse', response);
    await pref.setBool('isLogin', true);

    /// ✅ NAVIGATE
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Dashboard()),
      (route) => false,
    );

  } else {
    Fluttertoast.showToast(
        msg: response['message'] ?? "Login failed");
  }
}

Reregisterverifylogin() async {
  if (isLoading) return; 
  setState(() {
    isLoading = true;
  });

  var data = {
    "action": "complete_reregister",
    "mobile": mobile.text.toString(),
    "device_name": deviceName, // optional
    "device_model": deviceModel,
    "os_version": osVersion,   // optional
    // "act_type": "CUST",
    "fcm_id": fcmToken ?? "",
  };

  final response = await Api().loginApi(data);
  print(response);

  setState(() {
    isLoading = false;
  });

  if (response == null) return;

  if (response['status'] == "success" && response['code'] == 200) {

    Fluttertoast.showToast(msg: response['message']);

    /// ✅ SAVE USER DATA
    await storage.setItem('userResponse', response);
    await pref.setBool('isLogin', true);

    /// ✅ NAVIGATE
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Dashboard()),
      (route) => false,
    );

  } else {
    Fluttertoast.showToast(
        msg: response['message'] ?? "Login failed");
  }
}
}



// class OtpFields extends StatelessWidget {
//   final List<TextEditingController> controllers;
//   final List<FocusNode> focusNodes;

//   const OtpFields({
//     super.key,
//     required this.controllers,
//     required this.focusNodes,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: List.generate(5, (index) {
//         return Container(
//           width: 55,
//           height: 60,
//           decoration: BoxDecoration(
//             color: Colors.grey.shade200,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: TextField(
//             controller: controllers[index],
//             focusNode: focusNodes[index],
//             textAlign: TextAlign.center,
//             maxLength: 1,
//             keyboardType: TextInputType.number,
//             textInputAction: TextInputAction.next,
//             inputFormatters: [
//               FilteringTextInputFormatter.digitsOnly,
//             ],
//             decoration: const InputDecoration(
//               counterText: "",
//               border: InputBorder.none,
//             ),
//             onChanged: (value) {
//               // if (value.isNotEmpty && index < 4) {
//               //   FocusScope.of(context).requestFocus(focusNodes[index + 1]);
//               // }

//               // if (value.isEmpty && index > 0) {
//               //   FocusScope.of(context).requestFocus(focusNodes[index - 1]);
//               // }
//               if (value.length == 1 && index < focusNodes.length - 1) {
//     focusNodes[index + 1].requestFocus();
//   }

//   if (value.isEmpty && index > 0) {
//     focusNodes[index - 1].requestFocus();
//   }
//             },
//           ),
//         );
//       }),
//     );
//   }
// }

class OtpFields extends StatefulWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;

  const OtpFields({
    super.key,
    required this.controllers,
    required this.focusNodes,
  });

  @override
  State<OtpFields> createState() => _OtpFieldsState();
}

class _OtpFieldsState extends State<OtpFields> {
  final TextEditingController _hiddenController = TextEditingController();
  final FocusNode _hiddenFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _hiddenFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _hiddenController.dispose();
    _hiddenFocus.dispose();
    super.dispose();
  }

  void clearOtp() {
    _hiddenController.clear();
    for (var c in widget.controllers) {
      c.clear();
    }
    setState(() {});
  }

  // void _onChanged(String value) {
  //   // keep max 5 digits
  //   if (value.length > 5) {
  //     _hiddenController.text = value.substring(0, 5);
  //     _hiddenController.selection = TextSelection.collapsed(offset: 5);
  //     value = _hiddenController.text;
  //   }
  //   // sync into individual controllers so existing submit logic still works
  //   for (int i = 0; i < 5; i++) {
  //     widget.controllers[i].text = i < value.length ? value[i] : '';
  //   }
  //   setState(() {});
  // }

void _onChanged(String value) {
  // 🔥 Detect paste (multiple characters at once)
  if (value.length > 1) {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (value.length > 5) {
      value = value.substring(0, 5);
    }

    _hiddenController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );

    for (int i = 0; i < 5; i++) {
      widget.controllers[i].text = i < value.length ? value[i] : '';
    }

    setState(() {});
    return;
  }

  // 👉 Normal typing
  _hiddenController.value = TextEditingValue(
    text: value,
    selection: TextSelection.collapsed(offset: value.length),
  );

  for (int i = 0; i < 5; i++) {
    widget.controllers[i].text = i < value.length ? value[i] : '';
  }

  setState(() {});
}
  @override
  Widget build(BuildContext context) {
    final String otp = _hiddenController.text;
    return GestureDetector(
      onTap: () => _hiddenFocus.requestFocus(),
      child: Stack(
        children: [
          // hidden real TextField
          Opacity(
            opacity: 0,
            child: TextField(
              controller: _hiddenController,
              focusNode: _hiddenFocus,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              enableSuggestions: false,
              autocorrect: false,
              maxLength: 5,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(counterText: ''),
              onChanged: _onChanged,
            ),
          ),
          // display boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final bool isFocused = _hiddenFocus.hasFocus &&
                  otp.length == index ||
                  (_hiddenFocus.hasFocus && otp.length == 5 && index == 4);
              return Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocused ? Colors.green : Colors.grey.shade300,
                    width: isFocused ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  index < otp.length ? otp[index] : '',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

}