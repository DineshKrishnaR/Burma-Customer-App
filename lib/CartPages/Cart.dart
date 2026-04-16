
import 'dart:convert';
import 'dart:math';
import 'package:burma/CartPages/CartApi.dart';
import 'package:burma/CartPages/CheckOut.dart';
import 'package:burma/Dashboard/Dashboard.dart';
import 'package:burma/Dashboard/DashboardApi.dart';
import 'package:burma/Products/Category.dart';
import 'package:burma/Products/MainCategorytoSub.dart';
import 'package:burma/Products/MainCattoSubCat.dart';
import 'package:burma/Products/MainSubCattoProduct.dart';
import 'package:burma/Products/ProductDetails.dart';
import 'package:burma/Products/SectionStyleCategory.dart';
import 'package:burma/Products/SubCategory.dart';
import 'package:burma/Products/sectionproducts.dart';
import 'package:burma/ProfilePage/ProfilePageApi.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:localstorage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Common/colors.dart' as custom_color;

class Cart extends StatefulWidget {
  final selected_data;
  final selecteddata_title;
  const Cart({super.key, required this.selected_data, required this.selecteddata_title});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {

  final LocalStorage storage = LocalStorage('app_store');
  TextEditingController nameController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController address2Controller = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController areaController = TextEditingController();
  TextEditingController pinController = TextEditingController();
  TextEditingController landmarkController = TextEditingController();





  TextEditingController editnameController = TextEditingController();
  TextEditingController editmobileController = TextEditingController();
  TextEditingController editaddressController = TextEditingController();
  TextEditingController editaddress2Controller = TextEditingController();
  TextEditingController editcityController = TextEditingController();
  TextEditingController editstateController = TextEditingController();
  TextEditingController editareaController = TextEditingController();
  TextEditingController editpinController = TextEditingController();
  TextEditingController editlandmarkController = TextEditingController();


  late SharedPreferences pref;

  bool isLoading = false;

  var userResponse;
  var accesstoken;
  var customer_id;
  var wallet_amount;
  var user_details;
  // var delivery_charges;
  List view_cart_data = [];
  List cartItems = [];
  List get_address = [];
  List StateList = [];
  int? selectedAddressIndex;

  double delivery_charges = 0;
  double gst_percentage = 0;
  double totalAmount = 0;
  bool isDataLoaded = false;
  
  var selecteddata;
  var selecteddatatitle;
  var maincategory_cart;
  var maincattosub_cart;
  var mainsubproducts_cart;
  var productdetails_cart;
  var sectionproducts_cart;
  var sectionstylecat_cart;
  var category_cart;
  var subcategory_cart;
  
  @override
  void initState() {
    super.initState();
    initPreferencess();
  }

  initPreferencess() async {

    await storage.ready;

    final box = await Hive.openBox('cart');

    pref = await SharedPreferences.getInstance();

    userResponse = await storage.getItem('userResponse');
    maincategory_cart = await storage.getItem('maincategory_cart');
    maincattosub_cart = await storage.getItem('maincattosub_cart');
    mainsubproducts_cart = await storage.getItem('mainsubproducts_cart');
    productdetails_cart = await storage.getItem('productdetails_cart');
    sectionproducts_cart = await storage.getItem('sectionproducts_cart');
    sectionstylecat_cart = await storage.getItem('sectionstylecat_cart');
    category_cart = await storage.getItem('category_cart');
    subcategory_cart = await storage.getItem('subcategory_cart');

    selecteddata = widget.selected_data;
    selecteddatatitle = widget.selecteddata_title;

    cartItems = box.get('cartItems', defaultValue: []);

    if (userResponse != null) {
      accesstoken = userResponse['api_token'];
      customer_id = userResponse['customer_id'].toString();
    }
    
    await ProfileDetails();
    await getAddress();
    var savedAddress = await storage.getItem('selected_address');
  if (savedAddress != null) {
    user_details = savedAddress;
  }
    await WalletDetails();
    await getViewCart();
    calculateTotal(); 
    await DeliveryCharges();
    await gerStateList();
    setState(() {
  isDataLoaded = true;
});
  }
void calculateTotal() {

  totalAmount = 0;

  for (var item in view_cart_data) {
    totalAmount += double.parse(item['amt'].toString());
  }

}
  /// GET CART
  Future<void> getViewCart() async {

    // setState(() => isLoading = true);

    var data = {
      "action": "view_cart",
      "accesskey": "90336",
      "cart_items": jsonEncode(cartItems),
      "customer_id": customer_id,
      "token": accesstoken,
      "act_type": userResponse['act_type'],
    };

    final response = await Cartapi().getViewCart(data);

    if (response != null) {
      view_cart_data = response['res'] ?? [];
    } else {
      view_cart_data = [];
    }

    setState(() => isLoading = false);
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
  Future<void> DeliveryCharges() async {

  var data = {
    "accesskey": "90336",
    "cart_items": jsonEncode(cartItems),
    "fin_amt": totalAmount.toString(),   // FIX
    "token": accesstoken.toString(),     // safe
    "state": user_details['state'].toString(),
    "act_type": userResponse['act_type'].toString(),
  };

  final response = await Cartapi().DeliveryCharges(data);

  if (response != null) {
    setState(() {
      // delivery_charges = double.parse(response['deliv_charge'].toString());
      // gst_percentage = double.parse(response['gst_percentage'].toString());
      delivery_charges = double.tryParse(
        response['deliv_charge']?.toString() ?? "0") ?? 0;

gst_percentage = double.tryParse(
        response['gst_percentage']?.toString() ?? "0") ?? 0;
    });
  }
}
  /// UPDATE QTY
  // Future<void> updateCart(int index, int newQty) async {

  //   final box = Hive.box('cart');

  //   if (newQty <= 0) {
  //     cartItems.removeAt(index);
  //   } else {
  //     cartItems[index]['qty'] = newQty.toString();
  //   }

  //   await box.put('cartItems', cartItems);

  //   await getViewCart();
  // }

Future<void> updateCart(String variantId, int qty) async {

  final box = Hive.box('cart');
/// ❗ MIN QTY CHECK (Correct)
//   if (currentQty == 0 && newQty > 0 && newQty < minQty) {
//   newQty = minQty;
//   Fluttertoast.showToast(msg: "Minimum order is $minQty");
// }

// // if (newQty > 0 && newQty < minQty && newQty < currentQty) {
// //   Fluttertoast.showToast(msg: "Minimum order is $minQty");
// // }
// if (newQty > 0 && newQty < minQty && newQty < currentQty) {
//   Fluttertoast.showToast(msg: "Minimum order is $minQty");
//   return;
// }
  var data = {
    "action": "check_stock",
    "product_variant_id": variantId,
    "qty": qty.toString(),
    "accesskey": "90336",
    "token": accesstoken,
    "act_type": userResponse['act_type'],
    "customer_id": customer_id,
  };

  var stockResponse = await Cartapi().CheckStock(data);

  if (stockResponse == null) return;

  if (stockResponse['stock_status'] == "No Stock") {
    Fluttertoast.showToast(msg: "Product out of stock");
    return;
  }

  int stockQty = int.parse(stockResponse['stock_qty']);

  if (qty > stockQty) {
    Fluttertoast.showToast(msg: "Only $stockQty items available");
    return;
  }

  List<dynamic> cartList = box.get('cartItems', defaultValue: []);

  int index = cartList.indexWhere(
      (item) => item['product_variant_id'].toString() == variantId);

  if (index != -1) {

    if (qty <= 0) {
      cartList.removeAt(index);
    } else {
      cartList[index]['qty'] = qty.toString();
    }

  } else {

    if (qty > 0) {
      cartList.add({
        "product_variant_id": variantId,
        "qty": qty.toString(),
      });
    }

  }

  await box.put('cartItems', cartList);

  cartItems = cartList;

  await getViewCart();
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
    final response = await DashboardApi().ProfileDetails(data);

    print(response);

    if(response != null){
      user_details = response ?? [];
   print(user_details);

    // setState(() => isLoading = false);
  }
 }
 Future<void> getAddress() async {

  var data = {
    "action": "get_address",
    "accesskey": "90336",
    "customer_id": customer_id,
    "act_type": userResponse['act_type'].toString(),
    "token": accesstoken.toString(), 
    
  };

  final response = await Cartapi().getAddress(data);

 if (response != null) {
      get_address = response['res'] ?? [];
    } else {
      get_address = [];
    }
}
 Future<void> WalletDetails() async {
    // setState(() => isLoading = true);
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
   

    // setState(() => isLoading = false);
  }
 }
//  Future<void> deleteCartItem(int index) async {
//   final box = Hive.box('cart');

//   setState(() {
//     cartItems.removeAt(index);
//   });

//   await box.put('cartItems', cartItems);

//   await getViewCart();
// }
Future<void> deleteCartItem(String variantId) async {

  final box = Hive.box('cart');

  cartItems.removeWhere(
    (item) => item['product_variant_id'].toString() == variantId,
  );

  await box.put('cartItems', cartItems);

  await getViewCart();

  calculateTotal();

  await DeliveryCharges();

  setState(() {});
}
  /// SAFE IMAGE
  Widget safeNetworkImage(String? url) {

    if (url == null || url.isEmpty) {
      return Image.asset("assets/images/AppLogo.png", width: 90, height: 90);
    }

    return Image.network(
      url,
      width: 90,
      height: 90,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset("assets/images/AppLogo.png", width: 90, height: 90);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
double screenHeight = MediaQuery.of(context).size.height;
double screenWidth = MediaQuery.of(context).size.width;
   

    // for (var item in view_cart_data) {
    //   totalAmount += double.parse(item['amt'].toString());
    // }
// double subTotal = 0;

// for (var item in view_cart_data) {
//   subTotal += double.parse(item['amt'].toString());
// }

// double gst = (subTotal * gst_percentage) / 100;

// double totalAmount = subTotal + gst + delivery_charges;
double subTotalExcl = 0;
double gstTotal = 0;

for (var item in view_cart_data) {

  double amt = double.tryParse(item['amt'].toString()) ?? 0;
  double gstPercent = double.tryParse(item['gst_percentage'].toString()) ?? 0;

  double basePrice = 0;
  double gstAmount = 0;

  if (item['gst_enabled'] == "1" && gstPercent > 0) {

    /// ✅ REMOVE GST FROM AMOUNT (IMPORTANT)
    basePrice = amt / (1 + gstPercent / 100);
    gstAmount = amt - basePrice;

  } else {
    basePrice = amt;
  }

  subTotalExcl += basePrice;
  gstTotal += gstAmount;
}
// double totalAmount = subTotal + gstTotal + delivery_charges;

// double deliveryBase = delivery_charges;
// double deliveryGST = 0;

// if (gst_percentage > 0) {
//   deliveryBase = delivery_charges / (1 + gst_percentage / 100);
//   deliveryGST = delivery_charges - deliveryBase;
// }
double subTotalIncl = subTotalExcl + gstTotal;
double totalAmount = subTotalIncl + delivery_charges;

double deliveryBase = 0;
double deliveryGST = 0;

if (delivery_charges > 0 && gst_percentage > 0) {
  deliveryBase = delivery_charges / (1 + gst_percentage / 100);
  deliveryGST = delivery_charges - deliveryBase;
}
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async{
        if (maincategory_cart == "maincategory_cart") {
            Navigator.push(context, MaterialPageRoute(builder: (context) => Maincategorytosub(selected_data: selecteddata)));
            await storage.deleteItem('maincategory_cart');
        }else if(maincattosub_cart =="maincattosub_cart"){
            Navigator.push(context, MaterialPageRoute(builder: (context) => Maincattosubcat(selected_data: selecteddata)));
            await storage.deleteItem('maincategory_cart');
        }else if(mainsubproducts_cart == "mainsubproducts_cart") {
            Navigator.push(context, MaterialPageRoute(builder: (context) => Mainsubcattoproduct(selected_data: selecteddata,selecteddata_title:selecteddatatitle)));
            await storage.deleteItem('mainsubproducts_cart');
        }else if(productdetails_cart == "productdetails_cart") {
            Navigator.push(context, MaterialPageRoute(builder: (context) => Productdetails(selected_data: selecteddata,selecteddata_title:selecteddatatitle)));
            await storage.deleteItem('productdetails_cart');
        }else if(sectionproducts_cart == "sectionproducts_cart") {
            Navigator.push(context, MaterialPageRoute(builder: (context) => Sectionproducts(selected_data: selecteddata,)));
            await storage.deleteItem('sectionproducts_cart');
        }else if(sectionstylecat_cart == "sectionstylecat_cart") {
            Navigator.push(context, MaterialPageRoute(builder: (context) => Sectionstylecategory(selected_data: selecteddata,)));
            await storage.deleteItem('sectionstylecat_cart');
        }else if(category_cart == "category_cart") {
            Navigator.push(context, MaterialPageRoute(builder: (context) => Categorypage(selected_data: selecteddata,)));
            await storage.deleteItem('category_cart');
        }else if(subcategory_cart == "subcategory_cart") {
            Navigator.push(context, MaterialPageRoute(builder: (context) => Subcategory(selected_data: selecteddata,)));
            await storage.deleteItem('subcategory_cart');
        }else{
            Navigator.push(context,MaterialPageRoute(builder: (context)=>Dashboard()));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: custom_color.app_color,
          title: const Text("Cart", style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios,color: Colors.white),
            onPressed: ()async {
                if(maincategory_cart == "maincategory_cart") {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Maincategorytosub(selected_data: selecteddata)));
                    await storage.deleteItem('maincategory_cart');
                }else if(maincattosub_cart =="maincattosub_cart"){
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Maincattosubcat(selected_data: selecteddata)));
                    await storage.deleteItem('maincattosub_cart');
                }else if(mainsubproducts_cart == "mainsubproducts_cart") {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Mainsubcattoproduct(selected_data: selecteddata,selecteddata_title:selecteddatatitle)));
                    await storage.deleteItem('mainsubproducts_cart');
                }else if(productdetails_cart == "productdetails_cart") {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Productdetails(selected_data: selecteddata,selecteddata_title:selecteddatatitle)));
                    await storage.deleteItem('productdetails_cart');
                }else if(sectionproducts_cart == "sectionproducts_cart") {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Sectionproducts(selected_data: selecteddata)));
                    await storage.deleteItem('sectionproducts_cart');
                }else if(sectionstylecat_cart == "sectionstylecat_cart") {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Sectionstylecategory(selected_data: selecteddata,)));
                    await storage.deleteItem('sectionstylecat_cart');
                }else if(category_cart == "category_cart") {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Categorypage(selected_data: selecteddata,)));
                    await storage.deleteItem('category_cart');
                }else if(subcategory_cart == "subcategory_cart") {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => Subcategory(selected_data: selecteddata,)));
                    await storage.deleteItem('subcategory_cart');
                }else{
                    Navigator.push(context,MaterialPageRoute(builder: (context)=>Dashboard()));
                }
            },
          ),
        ),
      
        body: !isDataLoaded
      
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
            : view_cart_data.isEmpty
            ? emptyCartUI()
            : Column(
          children: [
      
            /// ADDRESS CARD
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // color: Colors.grey.shade200,
              //  color: Color(0xFFF8F8F8),
               color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                  border: Border(
                 right: BorderSide(
                color: Colors.grey.shade300, // light color
                width: 2.5,
              ),
              bottom: BorderSide(
                color: Colors.grey.shade300, // light color
                width: 2.5,
              ),
            ),
              ),
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      
        const Text(
          "Address :",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      
        const SizedBox(height: 12),
      
        Row(
          children: [
            const SizedBox(width: 80, child: Text("Name",style: TextStyle(fontWeight: FontWeight.bold),)),
            Text(user_details['name'] ?? ""),
          ],
        ),
      
        const SizedBox(height: 6),
      
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 80, child: Text("Address",style: TextStyle(fontWeight: FontWeight.bold),)),
            Expanded(
              child: Text(
                "${user_details['address']}, ${user_details['address2']}\n"
                "${user_details['city']}, ${user_details['state']}\n"
                "${user_details['pin']}",
              ),
            ),
          ],
        ),
      
       SizedBox(height: 6),
      
        Row(
          children: [
            const SizedBox(width: 80, child: Text("Mobile",style: TextStyle(fontWeight: FontWeight.bold),)),
            Text(user_details['mobile'] ?? ""),
          ],
        ),
      
        const SizedBox(height: 12),
      
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
      
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: custom_color.button_color,
              ),
              onPressed: () {
                showAddAddressDialog(StateList);
              },
              child: const Text("Add Address",style: TextStyle(color: Colors.white),),
            ),
      
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: custom_color.button_color,
              ),
              onPressed: () {
                showAddressDialog();
              },
              child: const Text("Choose Address",style: TextStyle(color: Colors.white)),
            ),
          ],
        )
      
      ],
        ),
      ),
      
            /// PRODUCT LIST
            Expanded(
              child: ListView.builder(
                itemCount: view_cart_data.length,
                itemBuilder: (context,index){
      
                  var item = view_cart_data[index];
      
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal:16,vertical:8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      // color: Colors.grey.shade200,
                      // color: Color(0xFFF8F8F8),
                       color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                        border: Border(
                 right: BorderSide(
                color: Colors.grey.shade300, // light color
                width: 2.5,
              ),
              bottom: BorderSide(
                color: Colors.grey.shade300, // light color
                width: 2.5,
              ),
            ),
                    ),
      
                    child: Row(
                      children: [
      
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
      
                              Text(item['product_name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
      
                               SizedBox(height:6),
      
                              Row(
                                children: [
                                  Text("Size : ",style: TextStyle(fontWeight: FontWeight.bold),),
                                  Text("${item['size']}"),
                                ],
                              ),
                               Row(
                                children: [
                                  Text("Quantity : ",style: TextStyle(fontWeight: FontWeight.bold),),
                                  Text("${item['qty']}"),
                                ],
                              ),
                               Row(
                                children: [
                                  Text("Price : ",style: TextStyle(fontWeight: FontWeight.bold),),
                                  Text("${item['discounted_price']}"),
                                ],
                              ),
                              // Text("Quantity : ${item['qty']}"),
                              // Text("Price : Rs.${item['discounted_price']}"),
      
                              const SizedBox(height:10),
      
                              Row(
                                children: [
      
                                  const Text("Qty : ",style: TextStyle(fontWeight: FontWeight.bold),),
      
                                  Container(
                                    decoration: BoxDecoration(
                                      color: custom_color.button_color,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
      
                                    child: Row(
                                      children: [
      
                                        IconButton(
                                          icon: const Icon(Icons.remove,color: Colors.white),
                                          onPressed: (){
                                            // updateCart(index,
                                            //     int.parse(item['qty']) - 1);
                                            updateCart(
                                              item['product_variant_id'].toString(),
                                              int.parse(item['qty']) - 1,
                                            );
                                          },
                                        ),
      
                                        Text(item['qty'].toString(),
                                            style: const TextStyle(color: Colors.white)),
      
                                        IconButton(
                                          icon: const Icon(Icons.add,color: Colors.white),
                                          onPressed: (){
                                            // updateCart(index,
                                            //     int.parse(item['qty']) + 1);
                                             updateCart(
                                                item['product_variant_id'].toString(),
                                                int.parse(item['qty']) + 1,
                                              );
                                          },
                                        ),
      
                                      ],
                                    ),
                                  )
      
                                ],
                              )
      
                            ],
                          ),
                        ),
      
                        Column(
                          children: [
                            // Icon(Icons.delete,color: custom_color.app_color),
                             IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  // deleteCartItem(index);
                                  // deleteCartItem(item['product_variant_id'].toString());
                                  confirmDelete(item['product_variant_id'].toString());
                                },
                              ),
                            // const SizedBox(height:05),
      
                            safeNetworkImage(item['img']),
      
                            const SizedBox(height:10),
      
                            Text(
                              "Total : Rs.${item['amt']}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )
      
                          ],
                        )
      
                      ],
                    ),
                  );
                },
              ),
            ),
      
            /// PRICE SUMMARY
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // color: Colors.grey.shade200,
                // color: Color(0xFFF8F8F8),
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                  border: Border(
                 right: BorderSide(
                color: Colors.grey.shade300, // light color
                width: 2.5,
              ),
              bottom: BorderSide(
                color: Colors.grey.shade300, // light color
                width: 2.5,
              ),
            ),
              ),
      
              child: Column(
                children: [
      
                  // priceRow("Sub Total", "Rs.$subTotal"),
                  // priceRow("GST Total", "Rs.${gstTotal.toStringAsFixed(2)}"),
                  // priceRow(
                  //   "Delivery Charge",
                  //   "Rs.${deliveryBase.toStringAsFixed(2)}",
                  // ),
                  // priceRow(
                  //   "Delivery GST",
                  //   "Rs.${deliveryGST.toStringAsFixed(2)}",
                  // ),
                  // const Divider(),
      
                  // priceRow(
                  //   "Total Amount",
                  //   "Rs.${totalAmount.toStringAsFixed(2)}",
                  //   bold: true,
                  // ),
                  priceRow("Subtotal (Exclusive of Tax)", "₹${subTotalExcl.toStringAsFixed(1)}"),
                  priceRow("Total Tax", "₹${gstTotal.toStringAsFixed(1)}"),
                  priceRow("Subtotal (Inclusive of Tax)", "₹${subTotalIncl.toStringAsFixed(0)}"),
      
                  priceRow(
                    "Delivery Charge (Base: ₹${deliveryBase.toStringAsFixed(1)} + Tax: ₹${deliveryGST.toStringAsFixed(1)})",
                    "₹${delivery_charges.toStringAsFixed(0)}",
                  ),
      
                  Divider(),
      
                  priceRow("Total", "₹${totalAmount.toStringAsFixed(0)}", bold: true),
                  const SizedBox(height:16),
      
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
      
                      Text(
                        // "${view_cart_data.length} Item Total Rs.${totalAmount+30}",
                        "${view_cart_data.length} Item Total Rs.${totalAmount.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,fontSize:18),
                      ),
      
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: custom_color.button_color,
                        ),
                        onPressed: () {
                          //  Navigator.push(context, MaterialPageRoute(builder: (context)=>Checkout()));
                           if (user_details == null ||
                              user_details['address'] == null ||
                              user_details['address'].toString().isEmpty) {

                            Fluttertoast.showToast(
                                msg: "Please add or select a delivery address");

                            return; // ❌ STOP navigation
                          }else{
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Checkout(
                                  userDetails: user_details,
                                  cartData: view_cart_data,
                                  deliveryCharge: delivery_charges,
                                  gstPercent: gst_percentage,
                                  totalAmount: totalAmount,
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text("Buy Now",style: TextStyle(color: Colors.white),),
                      )
      
                    ],
                  )
      
                ],
              ),
            )
      
          ],
        ),
      ),
    );
  }

  Widget priceRow(String title,String value,{bool bold=false}){
    return Padding(
      padding: const EdgeInsets.symmetric(vertical:4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: bold?FontWeight.bold:FontWeight.bold)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold?FontWeight.bold:FontWeight.normal)),
        ],
      ),
    );
  }
  
void showAddAddressDialog(StateList) {
  
double screenHeight = MediaQuery.of(context).size.height;
double screenWidth = MediaQuery.of(context).size.width;
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title:  Text("Add Address",style: TextStyle(color: custom_color.app_color),),
        content: SizedBox(
          height: screenHeight * 0.55, // popup height (75% screen)
          width: screenWidth,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                      controller: nameController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                      ],

                      decoration: InputDecoration(
                        labelText: 'Name *',
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
                      controller: mobileController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Mobile *',
                        counterText: '',
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
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: 'Address *',
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
                      controller: address2Controller,
                      decoration: InputDecoration(
                        labelText: 'Address 2 *',
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
                      controller: cityController,
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
                                    stateController.text = value['state'].toString();
                                  }
                                },
          
                                selectedItem: StateList.isNotEmpty
                                    ? StateList.firstWhere(
                                        (item) => item['state'] == stateController.text,
                                        orElse: () => StateList.first,
                                      )
                                    : null,
                              ),
                            
                          ),
                        ),
                         SizedBox(height: screenHeight*0.02,),
                 TextFormField(
                      controller: areaController,
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
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                       inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Pin *',
                         counterText: '',
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
                      controller: landmarkController,
                      decoration: InputDecoration(
                        labelText: 'Landmark *',
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
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: custom_color.button_color,
            ),
            onPressed: () async{
              if(nameController.text.isEmpty){
                Fluttertoast.showToast(msg: 'Enter your Name');
              } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(nameController.text)) {
                Fluttertoast.showToast(msg: 'Enter valid name');
              } else if(mobileController.text.isEmpty){
                Fluttertoast.showToast(msg: 'Enter your Mobile Number');
              }else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(mobileController.text)) {
                Fluttertoast.showToast(msg: 'Enter valid mobile number');
              }else if(addressController.text.isEmpty){
                Fluttertoast.showToast(msg: 'Enter your Address');
              }else if(address2Controller.text.isEmpty){
                Fluttertoast.showToast(msg: 'Enter your Address2');
              }else if(cityController.text.isEmpty){
                Fluttertoast.showToast(msg: 'Enter your City');
              }else if(stateController.text.isEmpty){
                Fluttertoast.showToast(msg: 'Enter your State');
              }else if(areaController.text.isEmpty){
                Fluttertoast.showToast(msg: 'Enter your Area');
              }else if(pinController.text.isEmpty){
                Fluttertoast.showToast(msg: 'Enter your Pincode');
              }else if(landmarkController.text.isEmpty){
                Fluttertoast.showToast(msg: 'Enter your Landmark');
              }else{
              var data = {
                "action": "save_address",
                'mobile': mobileController.text,
                "customer_id":customer_id,
                "accesskey": "90336",
                'city': cityController.text,
                'state': stateController.text,
                'address': addressController.text,
                'address2': address2Controller.text,
                'name': nameController.text,
                'pin': pinController.text,
                'landmark': landmarkController.text,
                'area': areaController.text,
                "act_type":userResponse['act_type'],
                "token": accesstoken,
              };
              print(data);
              final response =await Cartapi().SaveDeliveryAddress(data);
              if (response == null) return;
              if (response['status'] == "success") {
                  Fluttertoast.showToast(msg: 'Address added successfully!');
                  await getAddress();

  /// ✅ Optional: auto select newly added address
  if (get_address.isNotEmpty) {
    user_details = get_address.last;
    await storage.setItem('selected_address', user_details);
  }
                  Navigator.pop(context);
                } else {
                    Fluttertoast.showToast(msg: response['message'] ?? "Something went wrong");
                }
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}

void showAddressDialog() {
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Choose Address",style: TextStyle(color: custom_color.app_color),),
            // content: SizedBox(
            //   width: double.maxFinite,
            //   height: MediaQuery.of(context).size.height * 0.3, 
            //   child: get_address.isEmpty
            //       ? const Text("No addresses found")
            //       : ListView.builder(
            //           shrinkWrap: true,
            //           itemCount: get_address.length,
            //           itemBuilder: (context, index) {
            //             var address = get_address[index];
            //             return RadioListTile<int>(
            //               value: index,
            //               groupValue: selectedAddressIndex,
            //               activeColor: custom_color.app_color,
            //               onChanged: (value) {
            //                 setDialogState(() {
            //                   selectedAddressIndex = value;
            //                 });
            //               },
            //               title: Text(address['name'] ?? ""),
            //               subtitle: Text(
            //                 "${address['address'] ?? ''}, ${address['address2'] ?? ''}\n"
            //                 "${address['city'] ?? ''}, ${address['state'] ?? ''}\n"
            //                 "${address['pin'] ?? ''}\n"
            //                 "Mobile: ${address['mobile'] ?? ''}",
            //               ),
            //             );
                        
            //           },
            //         ),
            // ),
             content: SizedBox(
              width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.3, 
  child: get_address.isEmpty
      ? const Text("No addresses found")
      : ListView.builder(
          shrinkWrap: true,
          itemCount: get_address.length,
          itemBuilder: (context, index) {
            var address = get_address[index];

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
                color: selectedAddressIndex == index
                    ? Colors.green.shade50
                    : Colors.white,
              ),
              child: Column(
                children: [
                  RadioListTile<int>(
                    value: index,
                    groupValue: selectedAddressIndex,
                    activeColor: custom_color.app_color,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedAddressIndex = value;
                      });
                    },
                    title: Text(address['name'] ?? ""),
                    subtitle: Text(
                      "${address['address'] ?? ''}, ${address['address2'] ?? ''}\n"
                      "${address['city'] ?? ''}, ${address['state'] ?? ''}\n"
                      "${address['pin'] ?? ''}\n"
                      "Mobile: ${address['mobile'] ?? ''}",
                    ),
                  ),

                  /// 🔥 EDIT + DELETE BUTTONS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [

                        /// ✏️ EDIT
                        TextButton.icon(
                          onPressed: () {
                            // Navigator.pop(context);

                           showEditAddressDialog(address);
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text("Edit"),
                        ),

                        /// 🗑 DELETE
                        TextButton.icon(
                          onPressed: () {
                            showDeleteConfirmDialog(index, setDialogState);
                          },
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          label: const Text("Delete", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: custom_color.button_color,
                ),
                // onPressed: () async{
                //   if (selectedAddressIndex != null) {
                //      var selectedAddress = get_address[selectedAddressIndex!];
                //     setState(() {
                //       user_details = Map.from(get_address[selectedAddressIndex!]);
                //     });
                //      await storage.setItem('selected_address', selectedAddress);
                //     Navigator.pop(context);
                //   }
                // },
                onPressed: () async {
                    if (selectedAddressIndex != null) {
                      var selectedAddress = get_address[selectedAddressIndex!];

                      setState(() {
                        user_details = Map.from(selectedAddress);
                      });

                      await storage.setItem('selected_address', selectedAddress);

                      Navigator.pop(context);

                      /// ✅ Force UI refresh after dialog close
                      setState(() {});
                    } else {
                      Fluttertoast.showToast(msg: "Please select address");
                    }
                  },
                child: const Text("Select", style: TextStyle(color: Colors.white)),
              ),
            ],
            
          );
        },
      );
    },
  );
}





void showEditAddressDialog(Map<String, dynamic> address) {
  
      double screenHeight = MediaQuery.of(context).size.height;
      double screenWidth = MediaQuery.of(context).size.width;
      editnameController.text = address['name'] ?? "";
      editmobileController.text = address['mobile'] ?? "";
      editaddressController.text = address['address'] ?? "";
      editaddress2Controller.text = address['address2'] ?? "";
      editcityController.text = address['city'] ?? "";
      editstateController.text = address['state'] ?? "";
      editareaController.text = address['area'] ?? "";
      editpinController.text = address['pin'] ?? "";
      editlandmarkController.text = address['landmark'] ?? "";
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title:  Text("Edit Address",style: TextStyle(color: custom_color.app_color),),
        content: SizedBox(
          height: screenHeight * 0.55,
          width: screenWidth,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                      controller: editnameController,
                      decoration: InputDecoration(
                        labelText: 'Name *',
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
                      controller: editmobileController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      decoration: InputDecoration(
                        labelText: 'Mobile *',
                        counterText: '',
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
                      controller: editaddressController,
                      decoration: InputDecoration(
                        labelText: 'Address *',
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
                      controller: editaddress2Controller,
                      decoration: InputDecoration(
                        labelText: 'Address 2 *',
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
                      controller: editcityController,
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
                                    editstateController.text = value['state'].toString();
                                  }
                                },
          
                                selectedItem: StateList.isNotEmpty
                                    ? StateList.firstWhere(
                                        (item) => item['state'] == editstateController.text,
                                        orElse: () => StateList.first,
                                      )
                                    : null,
                              ),
                            
                          ),
                        ),
                         SizedBox(height: screenHeight*0.02,),
                 TextFormField(
                      controller: editareaController,
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
                      controller: editpinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: 'Pin *',
                          counterText: '',
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
                      controller: editlandmarkController,
                      decoration: InputDecoration(
                        labelText: 'Landmark *',
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
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: custom_color.button_color,
            ),
            onPressed: () async{
              if(editnameController.text.isEmpty){
                Fluttertoast.showToast(msg: 'Enter your Name');
              }else if(editmobileController.text.isEmpty){
                Fluttertoast.showToast(msg: 'Enter your Mobile Number');
              }else if(editaddressController.text.isEmpty){
                Fluttertoast.showToast(msg: 'Enter your Address');
              }else if(editaddress2Controller.text.isEmpty){
                Fluttertoast.showToast(msg: 'Enter your Address2');
              }else if(editcityController.text.isEmpty){
                Fluttertoast.showToast(msg: 'Enter your City');
              }else if(editstateController.text.isEmpty){
                Fluttertoast.showToast(msg: 'Enter your State');
              }else if(editareaController.text.isEmpty){
                Fluttertoast.showToast(msg: 'Enter your Area');
              }else if(editpinController.text.isEmpty){
                Fluttertoast.showToast(msg: 'Enter your Pincode');
              }else if(editlandmarkController.text.isEmpty){
                Fluttertoast.showToast(msg: 'Enter your Landmark');
              }else{
              var data = {
                "customer_address_id": address['customer_address_id'],
                "action": "update_address",
                'mobile': editmobileController.text,
                "customer_id":customer_id,
                "accesskey": "90336",
                'city': editcityController.text,
                'state': editstateController.text,
                'address': editaddressController.text,
                'address2': editaddress2Controller.text,
                'name': editnameController.text,
                'pin': editpinController.text,
                'landmark': editlandmarkController.text,
                'area': editareaController.text,
                "act_type":userResponse['act_type'],
                "token": accesstoken,
              };
              print(data);
              final response =await Cartapi().EditDeliveryAddress(data);
              if (response == null) return;
              if (response['status'] == "success") {
               
                  Fluttertoast.showToast(msg: 'Address updated successfully!');
                    if (get_address.isNotEmpty) {
                  user_details = get_address.last;
                  await storage.setItem('selected_address', user_details);
                }

                   await getAddress(); 
                    setState(() {}); 

                    Navigator.pop(context);

                    showAddressDialog();  
                } else {
                    Fluttertoast.showToast(msg: response['message'] ?? "Something went wrong");
                }
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}
void showDeleteConfirmDialog(int index, StateSetter setDialogState) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Delete Address"),
        content: const Text("Are you sure you want to delete this address?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // close confirm

              var address = get_address[index];

              var data = {
                "action": "delete_address",
                "accesskey": "90336",
                "customer_id": customer_id,
                "act_type": userResponse['act_type'],
                "customer_address_id": address['customer_address_id'],
                "token": accesstoken,
              };

              final response = await Cartapi().deleteAddress(data);
// var response;
              if (response != null && response['status'] == "success") {
                Fluttertoast.showToast(msg: "Deleted successfully");

                setDialogState(() {
                  get_address.removeAt(index);
                });

                /// reset selection if deleted item selected
                if (selectedAddressIndex == index) {
                  selectedAddressIndex = null;
                }

              } else {
                Fluttertoast.showToast(msg: "Delete failed");
              }
            },
            child: const Text("Delete"),
          ),
        ],
      );
    },
  );
}
// Widget emptyCartUI() {
//   return Center(
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [

//         Image.asset(
//           "assets/images/AppLogo.png",
//           height: 180,
//         ),

//         const SizedBox(height: 20),

//         const Text(
//           "Your Cart is empty",
//           style: TextStyle(
//             fontSize: 18,
//             color: Colors.green,
//             fontWeight: FontWeight.w500,
//           ),
//         ),

//         const SizedBox(height: 10),

//         const Text(
//           "No Items Found!",
//           style: TextStyle(
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//           ),
//         ),

//         const SizedBox(height: 20),

//         ElevatedButton(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: custom_color.button_color,
//             padding: const EdgeInsets.symmetric(
//                 horizontal: 30, vertical: 14),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(30),
//             ),
//           ),
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => Dashboard()),
//             );
//           },
//           child: const Text(
//             "Shop Now",
//             style: TextStyle(
//               fontSize: 18,
//               color: Colors.white,
//             ),
//           ),
//         )
//       ],
//     ),
//   );
// }
Widget emptyCartUI() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          /// IMAGE
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: custom_color.app_color,
            ),
          ),

          const SizedBox(height: 25),

          /// TITLE
          const Text(
            "Your cart is empty",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          /// SUBTITLE
          Text(
            "Looks like you haven’t added anything yet.\nStart shopping now!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 30),

          /// BUTTON
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: custom_color.button_color,
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Dashboard()),
              );
            },
            child: const Text(
              "Start Shopping",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
void confirmDelete(String variantId) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Remove Item"),
        content: const Text("Are you sure you want to remove this item from cart?"),
        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(context); // ❌ Cancel
            },
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context); // close dialog
              deleteCartItem(variantId); // ✅ delete
            },
            child: const Text("Remove", style: TextStyle(color: Colors.white)),
          ),

        ],
      );
    },
  );
}
}