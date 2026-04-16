import 'package:burma/Common/FirebaseApi.dart';
import 'package:burma/Dashboard/Dashboard.dart';
import 'package:burma/ProfilePage/ProfilePageApi.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:localstorage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Common/colors.dart' as custom_color;

class Profilepage extends StatefulWidget {
  const Profilepage({super.key});

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {

final LocalStorage storage = new LocalStorage('app_store');
  TextEditingController namecontroller = TextEditingController();
  TextEditingController mobilenocontroller = TextEditingController();
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController dobcontroller = TextEditingController();
  TextEditingController gendercontroller = TextEditingController();
  TextEditingController gstcontroller = TextEditingController();
  TextEditingController address1controller = TextEditingController();
  TextEditingController address2controller = TextEditingController();
  TextEditingController areacontroller = TextEditingController();
  TextEditingController landmarkcontroller = TextEditingController();
  TextEditingController citycontroller = TextEditingController();
  TextEditingController statecontroller = TextEditingController();
  TextEditingController pincodecontroller = TextEditingController();
 
  late SharedPreferences pref;
  bool isLoading = false;
  var userResponse;
  var accesstoken;
  var customer_id;
  var fcmToken;
  var profile_details;
  List StateList = [];
  @override
  void initState() {
    super.initState();
    initPreferencess();
  }

 initPreferencess() async {
  setState(() => isLoading = true);
    await storage.ready;
    pref = await SharedPreferences.getInstance();
    userResponse = await storage.getItem('userResponse');
     await FirebaseApi().initNotifications();  
      fcmToken = await storage.getItem('fcmToken');
  if (userResponse != null) {
    accesstoken = userResponse['api_token'];
    customer_id = userResponse['customer_id'].toString();
  }
      await ProfileDetails();
      await gerStateList();
      setState(() => isLoading = false); 
  }
  Future<void> ProfileDetails() async {
    // setState(() => isLoading = true);
   var data = {
         "action": "get_profile",
         "customer_id":customer_id,
         "accesskey":"90336",
         "token":accesstoken,
         "act_type":userResponse['act_type'],
   };
    final response = await Profilepageapi().ProfileDetails(data);

    print(response);

    if(response != null){
      profile_details = response ?? [];
      namecontroller.text = profile_details['name'].toString();
      mobilenocontroller.text = profile_details['mobile'].toString();
      emailcontroller.text = profile_details['email'].toString();
      dobcontroller.text = profile_details['dob'].toString();
      gendercontroller.text = profile_details['gender'].toString();
      gstcontroller.text = profile_details['gst_no'].toString();
      address1controller.text = profile_details['address'].toString();
      address2controller.text = profile_details['address2'].toString();
      areacontroller.text = profile_details['area'].toString();
      landmarkcontroller.text = profile_details['landmark'].toString();
      citycontroller.text = profile_details['city'].toString();
      statecontroller.text = profile_details['state'].toString();
      pincodecontroller.text = profile_details['pin'].toString();

    // setState(() => isLoading = false);
  }
 }
 Future<void> gerStateList() async {
    // setState(() => isLoading = true);
   var data = {
         "action": "get_state",
         "accesskey":"90336",
         "token":accesstoken,
   };
    final response = await Profilepageapi().gerStateList(data);

    print(response);

    if(response != null){
      StateList = response['res'] ?? [];
    // setState(() => isLoading = false);
  }
 }
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => Dashboard()));
      },
      child: Scaffold(
          appBar: AppBar(
          backgroundColor: custom_color.app_color,
          title: Text("Profile",style: TextStyle(color: Colors.white),),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios,color: Colors.white,),
            onPressed: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>Dashboard()));
            },
          ),
        ),
        body: isLoading
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
    
    :SingleChildScrollView(
        child: Column(
          children: [

            /// HEADER
            Stack(
              alignment: Alignment.center,
              children: [

                Container(
                  height: 120,
                  color: custom_color.app_color,
                ),

                Positioned(
                  // bottom: -40,
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage("assets/images/user.png"),
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 50),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [

                  // buildTextField("Name",required:true),
                  TextFormField(
                    controller: namecontroller,
                   inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        return newValue.text.contains("  ") ? oldValue : newValue;
                      }),
                    ],
                        maxLength: 50,
                    decoration: InputDecoration(
                      labelText: 'Name *',
                      counterText: "",
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: custom_color.app_color,
                            width: 1.5,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: custom_color.app_color,
                            width: 2,
                          ),
                        ),
                    ),
                  ),
                  SizedBox(height: screenHeight*0.02,),
                   TextFormField(
                    controller: mobilenocontroller,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Mobile Number *',
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight*0.02,),
                   TextFormField(
                    controller: emailcontroller,
                    decoration: InputDecoration(
                      labelText: 'Email *',
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                       enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: custom_color.app_color,
                            width: 1.5,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: custom_color.app_color,
                            width: 2,
                          ),
                        ),
                    ),
                  ),
                  SizedBox(height: screenHeight*0.02,),
                   
                    Container(
                    child: TextField(
                      controller: dobcontroller,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                           enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: custom_color.app_color,
                            width: 1.5,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: custom_color.app_color,
                            width: 2,
                          ),
                        ),
                          fillColor: Colors.grey.shade100,
                          prefixIcon: Icon(
                            Icons.calendar_month,
                            color: custom_color.app_color,
                          ),
                          
                          labelText: "D.O.B"),
                          
                      readOnly: true,
                      onTap: (() {
                        _selectDate();
                      }),
                    ),
                  ),
                  SizedBox(height: screenHeight*0.02,),

                  const SizedBox(height:10),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Gender",
                        style: TextStyle(
                            fontSize:16,
                            fontWeight: FontWeight.w600)),
                  ),

                  const SizedBox(height:10),

                 Row(
                  children: [
                    genderButton("Male", gendercontroller.text == "male"),
                    const SizedBox(width:10),
                    genderButton("Female", gendercontroller.text == "female"),
                  ],
                ),

                  // const SizedBox(height:16),
                  //   TextFormField(
                  //     controller: gstcontroller,
                  //   decoration: InputDecoration(
                  //     labelText: 'GST No',
                  //     fillColor: Colors.grey.shade100,
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(10),
                  //     ),
                  //      enabledBorder: OutlineInputBorder(
                  //         borderRadius: BorderRadius.circular(10),
                  //         borderSide: BorderSide(
                  //           color: custom_color.app_color,
                  //           width: 1.5,
                  //         ),
                  //       ),

                  //       focusedBorder: OutlineInputBorder(
                  //         borderRadius: BorderRadius.circular(10),
                  //         borderSide: BorderSide(
                  //           color: custom_color.app_color,
                  //           width: 2,
                  //         ),
                  //       ),
                  //   ),
                  // ),
                  SizedBox(height: screenHeight*0.02,),
                   TextFormField(
                    controller: address1controller,
                    decoration: InputDecoration(
                      labelText: 'Address Line 1 *',
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                       enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: custom_color.app_color,
                            width: 1.5,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: custom_color.app_color,
                            width: 2,
                          ),
                        ),
                    ),
                  ),
                  SizedBox(height: screenHeight*0.02,),
                   TextFormField(
                    controller: address2controller,
                    decoration: InputDecoration(
                      labelText: 'Address Line 2 *',
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                       enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: custom_color.app_color,
                            width: 1.5,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: custom_color.app_color,
                            width: 2,
                          ),
                        ),
                    ),
                  ),
                  SizedBox(height: screenHeight*0.02,),
                   TextFormField(
                    controller: areacontroller,
                    decoration: InputDecoration(
                      labelText: 'Area *',
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                       enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: custom_color.app_color,
                            width: 1.5,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: custom_color.app_color,
                            width: 2,
                          ),
                        ),
                    ),
                  ),
                  SizedBox(height: screenHeight*0.02,),
                   TextFormField(
                    controller: landmarkcontroller,
                    decoration: InputDecoration(
                      labelText: 'Landmark',
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                       enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: custom_color.app_color,
                            width: 1.5,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: custom_color.app_color,
                            width: 2,
                          ),
                        ),
                    ),
                  ),
                  SizedBox(height: screenHeight*0.02,),
                   TextFormField(
                    controller: citycontroller,
                    decoration: InputDecoration(
                      labelText: 'City *',
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                       enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: custom_color.app_color,
                            width: 1.5,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: custom_color.app_color,
                            width: 2,
                          ),
                        ),
                    ),
                  ),
                  SizedBox(height: screenHeight*0.02,),
                  //  TextFormField(
                  //   controller: statecontroller,
                  //   decoration: InputDecoration(
                  //     labelText: 'State *',
                  //     fillColor: Colors.grey.shade100,
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(10),
                  //     ),
                  //      enabledBorder: OutlineInputBorder(
                  //         borderRadius: BorderRadius.circular(10),
                  //         borderSide: BorderSide(
                  //           color: custom_color.app_color,
                  //           width: 1.5,
                  //         ),
                  //       ),

                  //       focusedBorder: OutlineInputBorder(
                  //         borderRadius: BorderRadius.circular(10),
                  //         borderSide: BorderSide(
                  //           color: custom_color.app_color,
                  //           width: 2,
                  //         ),
                  //       ),
                  //   ),
                  // ),
                  Container(
                        child: Container(
                          //  decoration: ShapeDecoration(
                          //   shape: RoundedRectangleBorder(
                          //     side: BorderSide(color: custom_color.app_color, width: 1.0),
                          //     borderRadius: BorderRadius.circular(5),
                          //   ),
                          //  ),
                           child: DropdownSearch<Map<String, dynamic>>(
                              items: StateList.cast<Map<String, dynamic>>(),
                              itemAsString: (item) => item['state'].toString(),

                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                  decoration: InputDecoration(
                                    hintText: "Search State",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),

                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: InputDecoration(
                                  
                                  labelText: "State *",
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: custom_color.app_color),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: custom_color.app_color, width: 2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),

                              onChanged: (value) {
                                if (value != null) {
                                  statecontroller.text = value['state'].toString();
                                }
                              },

                              selectedItem: StateList.isNotEmpty
                                  ? StateList.firstWhere(
                                      (item) => item['state'] == statecontroller.text,
                                      orElse: () => StateList.first,
                                    )
                                  : null,
                            ),
                          
                        ),
                      ),
                  SizedBox(height: screenHeight*0.02,),
                  
                   TextFormField(
                    controller: pincodecontroller,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Pincode *',
                      counterText: "",
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                       enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: custom_color.app_color,
                            width: 1.5,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: custom_color.app_color,
                            width: 2,
                          ),
                        ),
                    ),
                  ),
                  SizedBox(height: screenHeight*0.02,),

                  const SizedBox(height:20),

                  /// UPDATE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: custom_color.button_color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
  //                     onPressed: () async{
  //                        String name = namecontroller.text.trim();
  // String email = emailcontroller.text.trim();
  //                      if(namecontroller.text.isEmpty){
  //                       Fluttertoast.showToast(msg: 'Enter your Name');
  //                      } // 👇 Name validation (explained below)
  // RegExp nameRegex = RegExp(r"^[a-zA-Z ]{2,50}$");
  // if(!nameRegex.hasMatch(name)){
  //   Fluttertoast.showToast(msg: 'Enter valid name (only letters)');
  //   return;
  // }
  //                      else if(emailcontroller.text.isEmpty){
  //                       Fluttertoast.showToast(msg: 'Enter your Email');
  //                      }else if (!emailcontroller.text.contains('@') ||
  //                               !emailcontroller.text.contains('.') ||
  //                               !emailcontroller.text.contains('com')) {
  //                        Fluttertoast.showToast(msg: 'Please enter a valid email address');
  //                      }else if(address1controller.text.isEmpty){
  //                       Fluttertoast.showToast(msg: 'Enter Address Line 1');
  //                      }else if(address2controller.text.isEmpty){
  //                       Fluttertoast.showToast(msg: 'Enter Address Line 2');
  //                      }else if(areacontroller.text.isEmpty){
  //                       Fluttertoast.showToast(msg: 'Enter Area');
  //                      }else if(citycontroller.text.isEmpty){
  //                       Fluttertoast.showToast(msg: 'Enter City');
  //                      }
  //                      else if(statecontroller.text.isEmpty){
  //                       Fluttertoast.showToast(msg: 'Enter State');
  //                      }else if(pincodecontroller.text.isEmpty){
  //                       Fluttertoast.showToast(msg: 'Enter Pincode');
  //                      }else if(pincodecontroller.text.length<6){
  //                       Fluttertoast.showToast(msg: 'Enter Valid Pincode');
  //                      }else{
  //                       RegExp gstRegex = RegExp(
  //                       r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');

  //                       if(gstcontroller.text.isNotEmpty &&
  //                         !gstRegex.hasMatch(gstcontroller.text.toUpperCase())){
  //                         Fluttertoast.showToast(msg: "Enter Valid GST Number");
  //                         return;
  //                       }
  //                       setState(() => isLoading = true);
  //                      var data ={
  //                       "action":"save_profile",
  //                       "email":emailcontroller.text.toString(),
  //                       "dob":dobcontroller.text.toString(),
  //                       "mobile":mobilenocontroller.text.toString(),
  //                       "gender":gendercontroller.text.toString(),
  //                       "customer_id":customer_id,
  //                       "accesskey":"90336",
  //                       "city":citycontroller.text.toString(),
  //                       "state":statecontroller.text.toString(),
  //                       "address":address1controller.text.toString(),
  //                       "address2":address2controller.text.toString(),
  //                       "name":namecontroller.text.toString(),
  //                       "pin":pincodecontroller.text.toString(),
  //                       "landmark":landmarkcontroller.text.toString(),
  //                       "area":areacontroller.text.toString(),
  //                       "act_type":userResponse['act_type'],
  //                       "gstno":gstcontroller.text.toString(),
  //                       "token":accesstoken,
  //                       "fcm_id":fcmToken,
                       
  //                      };
  //                      final response =await Profilepageapi().ProfileUpdate(data);
  //                      setState(() => isLoading = false);
  //                      if(response['code'] == 200){
  //                       Fluttertoast.showToast(msg: 'Profile updated successfully');
  //                       ProfileDetails();
                       
  //                      }else{
  //                         Fluttertoast.showToast(msg: response['message']);
  //                       }
  //                      print(response);
  //                      }
  //                     },
                      onPressed: () async {

                      if(isLoading) return; // prevent multiple click

                      String name = namecontroller.text.trim();
                      String email = emailcontroller.text.trim();

                      // ✅ NAME VALIDATION
                      if(name.isEmpty){
                        Fluttertoast.showToast(msg: 'Enter your Name');
                        return;
                      }

                      RegExp nameRegex = RegExp(r"^[a-zA-Z ]{2,50}$");
                      if(!nameRegex.hasMatch(name)){
                        Fluttertoast.showToast(msg: 'Enter valid name (only letters)');
                        return;
                      }

                      // ✅ EMAIL VALIDATION
                      if(email.isEmpty){
                        Fluttertoast.showToast(msg: 'Enter your Email');
                        return;
                      }

                      RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if(!emailRegex.hasMatch(email)){
                        Fluttertoast.showToast(msg: 'Enter valid email');
                        return;
                      }

                      // ✅ ADDRESS VALIDATION
                      if(address1controller.text.trim().isEmpty){
                        Fluttertoast.showToast(msg: 'Enter Address Line 1');
                        return;
                      }

                      if(address2controller.text.trim().isEmpty){
                        Fluttertoast.showToast(msg: 'Enter Address Line 2');
                        return;
                      }

                      if(areacontroller.text.trim().isEmpty){
                        Fluttertoast.showToast(msg: 'Enter Area');
                        return;
                      }

                      if(citycontroller.text.trim().isEmpty){
                        Fluttertoast.showToast(msg: 'Enter City');
                        return;
                      }

                      if(statecontroller.text.trim().isEmpty){
                        Fluttertoast.showToast(msg: 'Enter State');
                        return;
                      }

                      if(pincodecontroller.text.trim().length != 6){
                        Fluttertoast.showToast(msg: 'Enter valid Pincode');
                        return;
                      }

                      // ✅ GST VALIDATION
                      RegExp gstRegex = RegExp(
                        r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$'
                      );

                      if(gstcontroller.text.isNotEmpty &&
                        !gstRegex.hasMatch(gstcontroller.text.toUpperCase())){
                        Fluttertoast.showToast(msg: "Enter Valid GST Number");
                        return;
                      }

                      // ✅ API CALL
                      setState(() => isLoading = true);

                      var data = {
                        "action":"save_profile",
                        "name": name,
                        "email": email,
                        "dob": dobcontroller.text.trim(),
                        "mobile": mobilenocontroller.text.trim(),
                        "gender": gendercontroller.text.trim(),
                        "customer_id": customer_id,
                        "accesskey":"90336",
                        "city": citycontroller.text.trim(),
                        "state": statecontroller.text.trim(),
                        "address": address1controller.text.trim(),
                        "address2": address2controller.text.trim(),
                        "pin": pincodecontroller.text.trim(),
                        "landmark": landmarkcontroller.text.trim(),
                        "area": areacontroller.text.trim(),
                        "act_type": userResponse['act_type'],
                        "gstno": gstcontroller.text.trim(),
                        "token": accesstoken,
                        "fcm_id": fcmToken,
                      };

                      final response = await Profilepageapi().ProfileUpdate(data);

                      setState(() => isLoading = false);

                      if (response == null) return;

                      if(response['code'] == 200){
                          // ProfileDetails();
                        Fluttertoast.showToast(msg: 'Profile updated successfully');
//  ProfileDetails();
                        // ✅ REDIRECT TO HOME
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => Dashboard()),
                          (route) => false,
                        );

                      } else {
                        Fluttertoast.showToast(msg: response?['message'] ?? 'Update failed');
                      }
                    },
                      child: const Text(
                        "Update",
                        style: TextStyle(fontSize:18,color: Colors.white),
                      ),
                    ),
                  ),

                   SizedBox(height:screenHeight*0.05)
                ],
              ),
            )
          ],
        ),
        )
      ));
  }

Widget genderButton(String text,bool selected){
  return Expanded(
    child: GestureDetector(
      onTap: (){
        setState(() {
          gendercontroller.text = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical:14),
        decoration: BoxDecoration(
          color: selected ? custom_color.app_color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: custom_color.app_color),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : custom_color.app_color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),
  );
}
   Future<void> _selectDate() async {
    DateTime? _picked = await showDatePicker(
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (_picked != null) {
      setState(() {
        dobcontroller.text = _picked.toString().split(" ")[0];
      });
    }
  }
}