import 'dart:async';

import 'package:burma/CartPages/Cart.dart';
import 'package:burma/CartPages/CartApi.dart';
import 'package:burma/Common/DeviceInfo.dart';
import 'package:burma/Common/FirebaseApi.dart';
import 'package:burma/Dashboard/Dashboardmenu.dart';
import 'package:burma/Dashboard/DashboardApi.dart';
import 'package:burma/Notification/Notification.dart';
import 'package:burma/Products/Category.dart';
import 'package:burma/Products/MainCategorytoSub.dart';
import 'package:burma/Products/ProductDetails.dart';
import 'package:burma/Products/SectionStyleCategory.dart';
import 'package:burma/Products/SubCategory.dart';
import 'package:burma/Products/SearchPage.dart';
import 'package:burma/Products/sectionproducts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:localstorage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Common/colors.dart' as custom_color;
import '../Api/Api.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
final LocalStorage storage = new LocalStorage('app_store');
 
  late SharedPreferences pref;
  int step = 1; // 1 mobile, 2 send otp, 3 verify otp
  bool isCustomer = true;
  var device_id;
  bool isLoading = true;
  var Otp;
  var user_logtype;
  var fcmToken;
  var deviceName;
  var deviceModel;
  var osVersion;
  var userResponse;
  var accesstoken;
  var customer_id;
  // List banners = [
  //   "assets/images/banner1.jpg",
  //   "assets/images/banner2.jpg",
  //   "assets/images/banner3.jpg",
  //   "assets/images/banner4.jpg",
  //   "assets/images/banner5.jpg"
  // ];
  List banners = [];
  List main_category = [];
  List Home_Feature_Sections_Styles = [];
  List homeSections = [];
  Map<int, ScrollController> _horizontalControllers = {};
  Map<int, Timer> _horizontalTimers = {};
  Map<String, int> cartQty = {};
  int unreadNotifCount = 0;


  var offer_image;
  bool isOfferShown = false;
  @override
  void initState() {
    super.initState();
    initPreferencess();
  }
@override
void dispose() {
  _horizontalTimers.forEach((key, timer) => timer.cancel());
  _horizontalControllers.forEach((key, controller) => controller.dispose());
  super.dispose();
}
 initPreferencess() async {
    await storage.ready;
    pref = await SharedPreferences.getInstance();
    userResponse = await storage.getItem('userResponse');

  if (userResponse != null) {
    accesstoken = userResponse['api_token'];
    customer_id = userResponse['customer_id'].toString();
  }
    var device_info = await Device().initPlatformState();
    device_id = await storage.getItem('device_id');
     deviceName = storage.getItem('device_name') ?? "";
     deviceModel = storage.getItem('device_model') ?? "";
     osVersion = storage.getItem('os_version') ?? "";
      await FirebaseApi().initNotifications();  
      fcmToken = await storage.getItem('fcmToken');
      // await  storage.deleteItem('cartItems');
      print('FCM Token: $fcmToken');
      print('Device ID: $device_id');
      await PopupOfferImage();
      await HomeBanner();
      await loadCartQty();
      await loadUnreadNotifCount();
      await MainCategory();
      await HomeFeatureSections();

      setState(() {});
  }
  /// 🔥 LOAD HOME API
  Future<void> HomeBanner() async {
    setState(() => isLoading = true);
   var data = {
         "action": "get_banner",
         "accesskey":"90336",
         "banner_id": "1",
         "token":accesstoken,
         "act_type":userResponse['act_type'].toString(),
         "customer_id": customer_id.toString(),
   };
    final response = await DashboardApi().HomeBanner(data);

    print(response);

    if(response != null){
      // banners = response['res'] ?? [];
      banners = (response['res'] ?? [])
    .map((e) => e['img'])
    .toList();
    }

    setState(() => isLoading = false);
  }

 Future<void> MainCategory() async {
    setState(() => isLoading = true);
   var data = {
         "action": "get_maincategory_list",
         "accesskey":"90336",
         "token":accesstoken,
         "act_type":userResponse['act_type'].toString(),
   };
    final response = await DashboardApi().MainCategory(data);

    print(response);

    if(response != null){
      main_category = response['data'] ?? [];
   

    setState(() => isLoading = false);
  }
 }

Future<void> PopupOfferImage() async {

  var data = {
    "action": "home_img_ad",
    "accesskey": "90336",
    "token": accesstoken,
    "act_type": userResponse['act_type'].toString(),
    "customer_id": customer_id.toString(),
  };

  final response = await DashboardApi().PopupOfferImage(data);

  if (response != null) {
    offer_image = response['img'];

    bool alreadyShown = pref.getBool("offerShown") ?? false;

    if (!alreadyShown && offer_image != null && offer_image != "") {
      Future.delayed(Duration.zero, () {
        showOfferPopup();
      });
    }
  }
}
void showOfferPopup() {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black87,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              /// OFFER IMAGE CARD
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    offer_image,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: custom_color.app_color,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_offer, size: 60, color: Colors.grey),
                            const SizedBox(height: 10),
                            Text(
                              "Special Offer",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              /// CLOSE BUTTON
              Positioned(
                right: -10,
                top: -10,
                child: GestureDetector(
                  onTap: () async {
                    await pref.setBool("offerShown", true);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: custom_color.app_color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// List homeSections = [];

Future<void> HomeFeatureSections() async {
  final response = await DashboardApi().HomeFeatureSections();

  if (response is List) {
    homeSections = response;

    // Sort by priority
    homeSections.sort((a, b) =>
        int.parse(a['priority'].toString())
            .compareTo(int.parse(b['priority'].toString())));
  }

  setState(() {});
}

Future<void> loadUnreadNotifCount() async {
  var data = {
    "action": "notification",
    "accesskey": "90336",
    "customer_id": customer_id.toString(),
    "act_type": userResponse['act_type'].toString(),
    "limit": '100',
    "offset": "0",
    "token": accesstoken,
  };
  final response = await DashboardApi().getNotification(data);
  if (response != null) {
    int total = (response['data'] ?? []).length;
    int lastRead = pref.getInt('notif_last_read') ?? 0;
    setState(() {
      unreadNotifCount = (total - lastRead).clamp(0, total);
    });
  }
}

Future<void> loadCartQty() async {
  final box = Hive.box('cart');
  List<dynamic> cartList = box.get('cartItems', defaultValue: []);

  cartQty.clear();

  for (var item in cartList) {
    cartQty[item['product_variant_id'].toString()] =
        int.parse(item['qty'].toString());
  }

  setState(() {});
}

// Future<void> updateCart(String variantId, int qty) async {
//   final box = Hive.box('cart');
//   var data={
//      "action" : "check_stock",
//      "product_variant_id": variantId,
//      "qty": qty,
//      "accesskey":"90336",
//      "token": accesstoken,
//      "act_type": userResponse['act_type'],
//      "customer_id": customer_id,
//   };
//   var stockResponse = await Cartapi().CheckStock(data);
//   List<dynamic> cartList = box.get('cartItems', defaultValue: []);

//   int index = cartList.indexWhere(
//       (item) => item['product_variant_id'].toString() == variantId);

//   if (index != -1) {
//     if (qty == 0) {
//       cartList.removeAt(index);
//       cartQty.remove(variantId);
//     } else {
//       cartList[index]['qty'] = qty.toString();
//       cartQty[variantId] = qty;
//     }
//   } else {
//     if (qty > 0) {
//       cartList.add({
//         "qty": qty.toString(),
//         "product_variant_id": variantId,
        
//       });
//       cartQty[variantId] = qty;
//     }
//   }

//   await box.put('cartItems', cartList);

//   setState(() {});
// }

Future<void> updateCart(String variantId, int qty) async {
  final box = Hive.box('cart');

  var data = {
    "action": "check_stock",
    "product_variant_id": variantId,
    "qty": qty.toString(),
    "accesskey": "90336",
    "token": accesstoken,
    "act_type": userResponse['act_type'].toString(),
    "customer_id": customer_id.toString(),
  };

  var stockResponse = await Cartapi().CheckStock(data);

  if (stockResponse == null) return;

  /// 🚨 Check stock status
  if (stockResponse['stock_status'] == "No Stock") {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(content: Text("Product out of stock")),
    // );
    Fluttertoast.showToast(msg: "Product out of stock");
    return;
  }

  int stockQty = int.parse(stockResponse['stock_qty']);

  if (qty > stockQty) {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text("Only $stockQty items available")),
    // );
    Fluttertoast.showToast(msg: "Only $stockQty items available");
    return;
  }

  List<dynamic> cartList = box.get('cartItems', defaultValue: []);

  int index = cartList.indexWhere(
      (item) => item['product_variant_id'].toString() == variantId);

  if (index != -1) {
    if (qty == 0) {
      cartList.removeAt(index);
      cartQty.remove(variantId);
    } else {
      cartList[index]['qty'] = qty.toString();
      cartQty[variantId] = qty;
    }
  } else {
    if (qty > 0) {
      cartList.add({
        "qty": qty.toString(),
        "product_variant_id": variantId,
      });
      cartQty[variantId] = qty;
    }
  }

  await box.put('cartItems', cartList);

  setState(() {});
}
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      // backgroundColor: Colors.grey[100],
      backgroundColor: Colors.white,
       drawer: const Dashboardmenu(),
      appBar: AppBar(
        backgroundColor: custom_color.app_color,
        elevation: 0,
        title: const Text("Home",style: TextStyle(color: Colors.white)),
       leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Cart(selected_data : '',selecteddata_title :""))).then((_) => loadCartQty());
                },
              ),
              if (cartQty.values.fold(0, (sum, qty) => sum + qty) > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      cartQty.values.fold(0, (sum, qty) => sum + qty).toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Notificationpage()))
                      .then((_) => loadUnreadNotifCount());
                },
              ),
              if (unreadNotifCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadNotifCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
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
                   SizedBox(height: 20),
                   CircularProgressIndicator(color: custom_color.app_color,),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [

                  /// 🔍 SEARCH
                  // GestureDetector(
                  //   onTap: () => Navigator.push(
                  //     context,
                  //     MaterialPageRoute(builder: (context) => const SearchPage()),
                  //   ),
                  //   child: Container(
                  //     margin: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                  //     padding: const EdgeInsets.symmetric(horizontal: 15),
                  //     height: 50,
                  //     decoration: BoxDecoration(
                  //       color: Colors.white,
                  //       borderRadius: BorderRadius.circular(30),
                  //       boxShadow: [
                  //         BoxShadow(
                  //           color: Colors.black.withOpacity(0.06),
                  //           blurRadius: 15,
                  //           offset: const Offset(0, 4),
                  //         )
                  //       ],
                  //       border: Border.all(color: Colors.grey.shade200),
                  //     ),
                  //     child: Row(
                  //       children: [
                  //         Icon(Icons.search, color: Colors.grey.shade500),
                  //         const SizedBox(width: 10),
                  //         Text("Search products...",
                  //             style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  SizedBox(height: screenHeight * 0.02),
                  Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14), // 🔥 rounded look
                    child: CarouselSlider.builder(
                      itemCount: banners.length,
                      itemBuilder: (context, index, realIdx) {
                        final banner = banners[index];
                        // final imageUrl = banner['image'];
                        final imageUrl = banner;
                        return GestureDetector(
                          onTap: () {
                            
                          },

                          child: Image.network(
                            Uri.encodeFull(imageUrl),
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Image.asset(
                              "assets/images/AppLogo.jpg",
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                          // child: Image.asset(
                          //   imageUrl,
                          //   width: double.infinity,
                          //   fit: BoxFit.fill,
                          // ),
                        );
                      },
                      options: CarouselOptions(
                        height: screenHeight * 0.22,
                        viewportFraction: 1.0,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 3),
                      ),
                    ),
                  ),
                ),

                  const SizedBox(height: 20),

                  /// 🔥 CATEGORY TITLE
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Shop by Category",
                          style: TextStyle(
                              fontSize: 20,fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// 🔥 CATEGORY GRID
                  GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: main_category.length,
                    gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                      childAspectRatio: .9,
                    ),
                    itemBuilder: (context,index){
                      var cat = main_category[index];

                      return GestureDetector(
                        onTap: (){
                          print(cat['main_category_id']);
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>Maincategorytosub(selected_data : cat)));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                            border: Border(
                              right: BorderSide(
                              color: Colors.grey.shade300, // light color
                              width: 3,
                            ),
                            bottom: BorderSide(
                              color: Colors.grey.shade300, // light color
                              width: 3,
                            ),
                          ),
                          ),
                          child: Column(
                            children: [
                              /// IMAGE
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(18)),
                                  
                                    child:  safeNetworkImage(cat['img'])
                                ),
                              ),

                              /// NAME
                              // Padding(
                              //   padding: const EdgeInsets.all(10),
                              //   child: Text(
                              //     cat['name'],
                              //      maxLines: 2, // ✅ limit lines
                              //      overflow: TextOverflow.ellipsis, 
                              //     style: const TextStyle(
                              //         fontWeight: FontWeight.bold),
                              //   ),
                              // )
                              Container(
                                height: 45, // ✅ fixed space for 2 lines
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  cat['name'] ?? "",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        // child:   Column(
                        //       children: [

                        //         SizedBox(
                        //           height: 100,
                        //           width: double.infinity,
                        //           child: ClipRRect(
                        //             borderRadius: BorderRadius.circular(12),
                        //             child: safeNetworkImage(
                        //               cat['img'],
                        //               fit: BoxFit.contain,
                        //             ),
                        //           ),
                        //         ),

                        //         const SizedBox(height: 5),

                        //         Text(
                        //           cat['name'],
                        //           textAlign: TextAlign.center,
                        //           maxLines: 2,
                        //           overflow: TextOverflow.ellipsis,
                        //           style: const TextStyle(
                        //             fontWeight: FontWeight.bold,
                        //             fontSize: 12,
                        //           ),
                        //         ),
                        //       ],
                        //     )
                        ),
                      );
                    },
                  ),

                  // const SizedBox(height: 30)
                  const SizedBox(height: 20),

Column(
  children: homeSections.asMap().entries.map((entry) {

    int sectionIndex = entry.key;
    var section = entry.value;

    String type = section['type'] ?? "";
    String style = section['style_type'] ?? "";
    List data = section['data'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// SECTION TITLE
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        //   child: Text(
        //     section['title'] ?? "",
        //     style: const TextStyle(
        //       fontSize: 20,
        //       fontWeight: FontWeight.bold,
        //     ),
        //   ),
        // ),
        Padding(
  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [

      /// SECTION TITLE
      Text(
        section['title'] ?? "",
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      /// VIEW ALL BUTTON
      if (type == "product_price")
        GestureDetector(
          onTap: () {
            print("View all clicked");
            print(section);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Sectionproducts(
                  selected_data: section,
                ),
              ),
            );
          },
          child: Row(
            children: const [
              Text(
                "View All",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue),
            ],
          ),
        ),
    ],
  ),
),
  /// TYPE BASED UI
        // if (type == "product_price")
        //   buildHorizontalProducts(data, sectionIndex)

        // else if (type == "category")
        //   buildCategoryHorizontal(data, sectionIndex)

        // else if (type == "products_grid")
        //   buildProductsGridStyle(data, sectionIndex)
        // else if(type == "sub_category")
        // buildSubCategoryGridStyle(data, sectionIndex),
        /// TYPE BASED UI
        if (type == "product_price") ...[  
          if (style == "style_6")
            buildProductsGridStyle(data, sectionIndex,type,6)
          else if (style == "style_7")
            buildHorizontalProducts(data, sectionIndex,)
          else if (style == "style_8")
            buildProductsGridStyle(data, sectionIndex,type,3)
        ] else if (type == "category" || type == "main_category") ...[  
          if (style == "style_1")
            // buildProductsGridStyle(data, sectionIndex,type,6)
            buildCategoryHorizontal(data, sectionIndex,type)
          else if (style == "style_2")
            buildProductsGridStyle(data, sectionIndex,type,4)
          else if (style == "style_3")
            buildProductsGridStyle(data, sectionIndex,type,3)
          else if (style == "style_4")
            // buildCategoryHorizontal(data, sectionIndex,)
            buildCategoryBannerHorizontal(data, sectionIndex,type)
          else if (style == "style_5")
            // buildCategoryHorizontal(data, sectionIndex,type)
            buildCategoryBannerHorizontal(data, sectionIndex,type)
        ] else if (type == "products_grid")
          buildProductsGridStyle(data, sectionIndex,type,3)
        else if (type == "sub_category")
          // buildSubCategoryGridStyle(data, sectionIndex),
           buildSubCategoryGridStyleHorizontal(data, sectionIndex,type),
        const SizedBox(height: 20),
      ],
    );
  }).toList(),
)
                ],
              ),
            ),

              // floatingActionButton: FloatingActionButton(
              //   backgroundColor: const Color(0xFF25D366),
              //   onPressed: () {
              //     print("WhatsApp click");
              //   },
              //   child: const FaIcon(
              //     FontAwesomeIcons.whatsapp,
              //     color: Colors.white,
              //   ),
              // ),
    );
  }

Widget buildHorizontalProducts(List products, int sectionIndex) {
  final limitedProducts = products.length > 5 ? products.sublist(0, 5) : products;
Map? getLowestVariant(List vars) {
  if (vars.isEmpty) return null;

  vars.sort((a, b) => int.parse(a['discounted_price'])
      .compareTo(int.parse(b['discounted_price'])));

  return vars.first;
}
  if (!_horizontalControllers.containsKey(sectionIndex)) {
    _horizontalControllers[sectionIndex] = ScrollController();
    
    _horizontalTimers[sectionIndex] = Timer.periodic(const Duration(seconds: 3), (timer) {
      final controller = _horizontalControllers[sectionIndex];
      if (controller != null && controller.hasClients) {
        double maxScroll = controller.position.maxScrollExtent;
        double current = controller.offset;

        if (current >= maxScroll) {
          controller.jumpTo(0);
        } else {
          controller.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  return SizedBox(
    height: 260,
    child: ListView.builder(
      controller: _horizontalControllers[sectionIndex],
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      itemCount: limitedProducts.length,
      itemBuilder: (context, index) {
        var p = limitedProducts[index];
        var variant = (p['vars'] != null && p['vars'].length > 0) ? p['vars'][0] : null;
        return Container(
          width: 170,
          margin: const EdgeInsets.only(right: 12),
           decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),

    // Right & Bottom light shadow
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.2),
        offset: Offset(3, 3), // RIGHT + BOTTOM
        blurRadius: 6,
      ),
    ],

    // Optional border for sharp edge effect
    border: Border(
      right: BorderSide(
        color: Colors.grey.shade300,
        // color: custom_color.app_color.withOpacity(0.3),
        width: 3,
      ),
      bottom: BorderSide(
        color: Colors.grey.shade300,
        // color: custom_color.app_color.withOpacity(0.3), 
        width: 3,
      ),
    ),
  ),
          child: buildHorizontalProductCard(p, variant),
        );
      },
    ),
  );
}

Widget buildHorizontalProductCard(var p, var variant) {
  String sizeText = "";

if (variant != null && variant['size'] != null) {
  // sizeText = variant['size'];
  sizeText = variant['size'].toString().split(',')[0];
  print(sizeText);
}
  String variantId = variant?['product_variant_id']?.toString() ?? "";
int qty = cartQty[variantId] ?? 0;
  return GestureDetector(
     onTap: () {
      // print(p);
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => Productdetails(selected_data: p),
      //   ),
      // );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Productdetails(selected_data: p,selecteddata_title :""),
        ),
      ).then((value) {
        loadCartQty();
      });
    },
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
    
            /// 🔥 IMAGE + DISCOUNT BADGE
            Expanded(
              child: Stack(
                children: [
    
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      // child: Image.network(
                      //   p['prod_img'] ?? "",
                      //   fit: BoxFit.contain,
                      //   errorBuilder: (_, __, ___) =>
                      //       const Icon(Icons.image_not_supported),
                      // ),
                      child: safeNetworkImage(p['prod_img'], fit: BoxFit.contain),
                    ),
                  ),
    
                  /// Discount badge
                  if (variant != null &&
                      variant['disc_amt'] != "0")
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${variant['disc_amt']} OFF",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    
            const SizedBox(height: 8),
    
            /// 🔥 PRODUCT NAME
            Text(
              p['name'] ?? "",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
    // const SizedBox(height: 4),
    
    if (sizeText.isNotEmpty)
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        sizeText,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
            // const SizedBox(height: 4),
    
            /// 🔥 PRICE ROW
            if (variant != null)
              Row(
                children: [
                  Text(
                    "₹ ${variant['discounted_price']}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: custom_color.app_color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (variant['disc_amt'] != "0")
                    Text(
                      "₹ ${variant['price']}",
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
    
            const SizedBox(height: 8),
    
            /// 🔥 ADD BUTTON
            // SizedBox(
            //   width: double.infinity,
            //   height: 34,
            //   child: ElevatedButton(
            //     onPressed: variant != null &&
            //             variant['stock_status'] != "Sold Out"
            //         ? () {
            //             print("Add ${p['product_id']}");
            //             // Navigator.push(context, MaterialPageRoute(builder: (context)=>Productdetails(selected_data : p)));
            //           }
            //         : null,
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: custom_color.app_color,
            //       elevation: 2,
            //       shadowColor: custom_color.app_color.withOpacity(0.3),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(10),
            //       ),
            //     ),
            //     child: const Text(
            //       "Add to Cart",
            //       style: TextStyle(fontSize: 13, color: Colors.white),
            //     ),
            //   ),
            // ),
          

SizedBox(
  width: double.infinity,
  height: 34,
  child: 
  // qty == 0
  //     ? 
  //  (variant != null &&
  //       (variant['stock_status'] == "Sold Out" ||
  //        variant['stock_status'] == "No Stock"))?
  //                       ElevatedButton(
                         
  //         onPressed: null,
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: Colors.grey,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(10),
  //           ),
  //         ),
  //         child: 
  //         variant['stock_status'] == "Sold Out" ? Text(
  //           "Sold Out",
  //           style: TextStyle(color: Colors.white),
  //         ):Text(
  //           "Out of Stock",
  //           style: TextStyle(color: Colors.white),
  //         )
  //       ):
  (variant['stock_status'] != "Available")?  ElevatedButton(
                         
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text("Buy Now",
          style: TextStyle(color: Colors.white),
          ),
        ):
      ElevatedButton(
          onPressed: () {
            // updateCart(variantId, 1);
             Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Productdetails(selected_data: p,selecteddata_title:""),
        ),
      );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: custom_color.button_color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            "Buy Now",
            style: TextStyle(color: Colors.white),
          ),
        )
      // : Container(
      //     decoration: BoxDecoration(
      //       color: custom_color.app_color,
      //       borderRadius: BorderRadius.circular(10),
      //     ),
      //     child: Row(
      //       mainAxisAlignment: MainAxisAlignment.spaceAround,
      //       children: [

      //         /// MINUS
      //         GestureDetector(
      //           onTap: () {
      //             updateCart(variantId, qty - 1);
      //           },
      //           child: const Icon(Icons.remove, color: Colors.white),
      //         ),

      //         /// QTY
      //         Text(
      //           qty.toString(),
      //           style: const TextStyle(
      //               color: Colors.white, fontWeight: FontWeight.bold),
      //         ),

      //         /// PLUS
      //         GestureDetector(
      //           onTap: () {
      //             updateCart(variantId, qty + 1);
      //           },
      //           child: const Icon(Icons.add, color: Colors.white),
      //         ),
      //       ],
      //     ),
      //   ),
)
          ],
        ),
      ),
    ),
  );
}
Widget buildProductCard(var p, var variant) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          if (variant != null && variant['stock_status'] == "Sold Out" || variant['stock_status'] == "No Stock" )
            const Text(
              "Not Available",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),

          Expanded(
            child: Center(
              // child: Image.network(
              //   p['prod_img'] ?? "",
              //   fit: BoxFit.contain,
              //   errorBuilder: (_, __, ___) =>
              //       const Icon(Icons.image_not_supported),
              // ),
//               child: Image.network(
//   p['prod_img'] ?? "",
//   fit: BoxFit.contain,
//   loadingBuilder: (context, child, loadingProgress) {
//     if (loadingProgress == null) return child;
//     return const Center(
//       child: CircularProgressIndicator(strokeWidth: 2),
//     );
//   },
//   errorBuilder: (context, error, stackTrace) {
//      return Image.asset(
//       "assets/images/AppLogo.png",
//       fit: BoxFit.contain,
//     );
//   },
// ),
 child:  safeNetworkImage(p['prod_img'], fit: BoxFit.contain)
            ),
          ),

          Text(
            p['name'] ?? "",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 4),

          if (variant != null)
            Text(
              "Rs.${variant['discounted_price']}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: variant != null &&
                      variant['stock_status'] != "Sold Out"
                  ? () {
                      print("Add cart ${p['product_id']}");
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: custom_color.button_color,
                elevation: 2,
                shadowColor: custom_color.app_color.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Add",
                style: TextStyle(fontSize: 15, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildCategoryHorizontal(List categories, int sectionIndex,type) {
  
  return SizedBox(
    height: 140,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      itemCount: categories.length,
      itemBuilder: (context, index) {

        var cat = categories[index];
        return GestureDetector(
            onTap: () {
              print("Section Index: $sectionIndex");
              print("Category Index: $index");
              print("Category ID: ${cat['category_id']}");
              //  Navigator.push(context, MaterialPageRoute(builder: (context)=>Sectionstylecategory(selected_data : cat)));
               if(type == "product_price" || type == "products_grid"){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>Sectionproducts(selected_data : cat)));
            }else if(type == "category"){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>Categorypage(selected_data : cat)));
            }
            else if(type == "main_category"){
             Navigator.push(context, MaterialPageRoute(builder: (context)=>Sectionstylecategory(selected_data : cat)));
            } 
            },
          child: Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),

    // Right & Bottom light shadow
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.2),
        offset: Offset(3, 3), // RIGHT + BOTTOM
        blurRadius: 6,
      ),
    ],

    // Optional border for sharp edge effect
    border: Border(
      right: BorderSide(
        color: Colors.grey.shade300,
        // color: custom_color.app_color.withOpacity(0.3),
        width: 3,
      ),
      bottom: BorderSide(
        color: Colors.grey.shade300,
        // color: custom_color.app_color.withOpacity(0.3), 
        width: 3,
      ),
    ),
  ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // CENTER CONTENT
            crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    // child: Image.network(
                    //   cat['img'],
                    //   fit: BoxFit.cover,
                    // ),
                   child:  safeNetworkImage(cat['img'])
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  cat['category_name'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                )
              ],
            ),
          ),
        );
      },
    ),
  );
}

Widget buildCategoryBannerHorizontal(List categories, int sectionIndex,type) {

  double screenWidth = MediaQuery.of(context).size.width;
  double bannerWidth = screenWidth * 0.85;
  return SizedBox(
    height: 180,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      // padding: const EdgeInsets.symmetric(horizontal: 15),
      padding: type == "main_category"?EdgeInsets.symmetric(
        horizontal: (screenWidth - bannerWidth) / 2, // center first & last item
      ): EdgeInsets.symmetric(horizontal: 15),
      itemCount: categories.length,
      itemBuilder: (context, index) {

        var cat = categories[index];

        return GestureDetector(
          onTap: () {
            print(type);
            if(type == "category"){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>Categorypage(selected_data : cat)));
            }else if(type == "main_category"){
             Navigator.push(context, MaterialPageRoute(builder: (context)=>Sectionstylecategory(selected_data : cat)));
            } 
            // Navigator.push(
            //   context,
            //   MaterialPageRoute(
            //     builder: (context) =>
            //         Sectionstylecategory(selected_data: cat),
            //   ),
            // );
          },

          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            margin: const EdgeInsets.only(right: 12),
            // decoration: BoxDecoration(
            //   borderRadius: BorderRadius.circular(16),
            //   boxShadow: [
            //     BoxShadow(
            //       color: Colors.black.withOpacity(.15),
            //       blurRadius: 10,
            //       offset: const Offset(0, 5),
            //     )
            //   ],
            // ),
 decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),

    // Right & Bottom light shadow
    boxShadow: [
      BoxShadow(
                  color: Colors.black.withOpacity(.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
    ],

    // Optional border for sharp edge effect
    border: Border(
      right: BorderSide(
        color: Colors.grey.shade300,
        // color: custom_color.app_color.withOpacity(0.3),
        width: 3,
      ),
      bottom: BorderSide(
        color: Colors.grey.shade300,
        // color: custom_color.app_color.withOpacity(0.3), 
        width: 3,
      ),
    ),
  ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [

                  /// IMAGE
                  safeNetworkImage(
                    cat['img'],
                    fit: BoxFit.cover,
                  ),

                  /// DARK OVERLAY
                  // Container(
                  //   color: Colors.black.withOpacity(0.25),
                  // ),

                  /// CATEGORY TITLE
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Text(
                      cat['category_name'] ?? "",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget buildProductsGridStyle(List items, int sectionIndex,type,int columns) {
  return GridView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: items.length,
    gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
      // crossAxisCount: 3,
      crossAxisCount: columns,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: .8,
    ),
    itemBuilder: (context, index) {

      var item = items[index];

      return GestureDetector(
          onTap: () {
            print("Section Index: $sectionIndex");
            print("Item Index: $index");
            print("Item Data: $item");
            if(type == "product_price" || type == "products_grid"){
            Navigator.push(context, MaterialPageRoute(builder: (context)=>Sectionproducts(selected_data : item)));
            }else if(type == "category"){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>Categorypage(selected_data : item)));
            }
            else{
             Navigator.push(context, MaterialPageRoute(builder: (context)=>Sectionstylecategory(selected_data : item)));
            } 
          },

        child: Container(
          decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),

    // Right & Bottom light shadow
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.2),
        offset: Offset(3, 3), // RIGHT + BOTTOM
        blurRadius: 6,
      ),
    ],

    // Optional border for sharp edge effect
    border: Border(
      right: BorderSide(
        color: Colors.grey.shade300,
        // color: custom_color.app_color.withOpacity(0.3),
        width: 3,
      ),
      bottom: BorderSide(
        color: Colors.grey.shade300,
        // color: custom_color.app_color.withOpacity(0.3), 
        width: 3,
      ),
    ),
  ),
          child: Column( 
            mainAxisAlignment: MainAxisAlignment.center, // CENTER CONTENT
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  // child: Image.network(
                  //   item['image'],
                  //   fit: BoxFit.cover,
                  // ),
                  child: safeNetworkImage(item['image'] ?? item['img']),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                // item['title'],
                //  item['title'] ?? "",
                item['title'] ?? item['category_name'] ?? "",
                style: const TextStyle(fontSize: 12),
              )
            ],
          ),
        ),
      );
    },
  );
}
Widget buildSubCategoryGridStyle(List items, int sectionIndex) {
  return GridView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: items.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: .8,
    ),
    itemBuilder: (context, index) {

      var item = items[index];

      return GestureDetector(
        onTap: () {
          print("Section Index: $sectionIndex");
          print("Category Index: $index");
          print("Category Data: $item");

          // Navigate if needed
          Navigator.push(context,
           MaterialPageRoute(builder: (context) => Subcategory(selected_data: item)));
        },

        child: Center(
          child: Column(
            children: [
          
              /// IMAGE
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: safeNetworkImage(
                    item['img'],
                    fit: BoxFit.fill,
                  ),
                ),
              ),
          
              const SizedBox(height: 5),
          
              /// CATEGORY NAME
              Text(
                item['category_name'] ?? "",
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget buildSubCategoryGridStyleHorizontal(List categories, int sectionIndex, type) {
  return SizedBox(
    height: 180,
    child: PageView.builder(
      controller: PageController(viewportFraction: 0.85), // 🔥 key line
      itemCount: categories.length,
      itemBuilder: (context, index) {
        var cat = categories[index];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Subcategory(selected_data: cat),
                ),
              );
            },
            child: Container(
              // decoration: BoxDecoration(
              //   borderRadius: BorderRadius.circular(16),
              //   boxShadow: [
              //     BoxShadow(
              //       color: Colors.black.withOpacity(.15),
              //       blurRadius: 10,
              //       offset: const Offset(0, 5),
              //     )
              //   ],
              // ),
              decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),

    // Right & Bottom light shadow
    boxShadow: [
      BoxShadow(
                  color: Colors.black.withOpacity(.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
    ],

    // Optional border for sharp edge effect
    border: Border(
      right: BorderSide(
        color: Colors.grey.shade300,
        // color: custom_color.app_color.withOpacity(0.3),
        width: 3,
      ),
      bottom: BorderSide(
        color: Colors.grey.shade300,
        // color: custom_color.app_color.withOpacity(0.3), 
        width: 3,
      ),
    ),
  ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [

                    /// IMAGE
                    safeNetworkImage(
                      cat['img'],
                      fit: BoxFit.cover,
                    ),

                    /// TITLE
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: Text(
                        cat['category_name'] ?? "",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
Widget safeNetworkImage(
  String? url, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  double borderRadius = 0,
}) {
  // Fix double slashes in URL
  String cleanUrl = (url ?? "").replaceAll(RegExp(r'(?<!:)//+'), '/');
  
  // Check if URL is valid
  if (cleanUrl.isEmpty || !cleanUrl.startsWith('http')) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        "assets/images/AppLogo.png",
        width: 90,
        height: 90,
        fit: BoxFit.contain,
      ),
    );
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: SizedBox(
      width: width,
      height: height,
      child: Image.network(
        cleanUrl,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: Image.asset(
              "assets/images/AppLogo.png",
              width: 90,
              height: 90,
              fit: BoxFit.contain,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            width: width,
            height: height,
            child: Image.asset(
              "assets/images/AppLogo.png",
              width: 90,
              height: 90,
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    ),
  );
}
}
