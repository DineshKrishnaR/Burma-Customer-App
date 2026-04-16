import 'dart:convert';
import 'package:burma/CartPages/Cart.dart';
import 'package:burma/CartPages/CartApi.dart';
import 'package:burma/Dashboard/Dashboard.dart';
import 'package:burma/Dashboard/DashboardApi.dart';
import 'package:burma/Favourites/Favourites.dart';
import 'package:burma/Products/Category.dart';
import 'package:burma/Products/MainSubCattoProduct.dart';
import 'package:burma/Products/ProductApi.dart';
import 'package:burma/Products/SectionStyleCategory.dart';
import 'package:burma/Products/SubCategory.dart';
import 'package:burma/Products/sectionproducts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:localstorage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../Common/colors.dart' as custom_color;
class Productdetails extends StatefulWidget {
  final selected_data;
  final selecteddata_title;
  const Productdetails({super.key, required this.selected_data, required this.selecteddata_title});

  @override
  State<Productdetails> createState() => _ProductdetailsState();
}

class _ProductdetailsState extends State<Productdetails> {

final LocalStorage storage = new LocalStorage('app_store');
 
  late SharedPreferences pref;
  

  bool isLoading = false;
  var userResponse;
  var accesstoken;
  var customer_id;
  var product_details;
  var selecteddata;
  int qty = 0;
  bool isFavorite = false;
  var main_to_sub_category;
  var section_style_category;
  var section_product;
  var cartItems;
  var favourites_page;
  var main_to_sub_category_product;
  var category_page;
  var selecteddata_title;
  var product_varient;


  Map selectedAttributes = {};
  Map variantsList = {};
  Map variantsCombo = {};
  List relatedProducts = [];
  Map<int, ScrollController> _horizontalControllers = {};
  Map<String, int> cartQty = {};
  var selectedVariant;

  bool isProcessingCart = false;
  @override
  void initState() {
    super.initState();
    initPreferencess();
  }

 initPreferencess() async {
    await storage.ready;
    pref = await SharedPreferences.getInstance();
    userResponse = await storage.getItem('userResponse');
    main_to_sub_category = await storage.getItem('main_to_sub_category');
    section_style_category = await storage.getItem('section_style_category');
    section_product = await storage.getItem('section_product');
    favourites_page = await storage.getItem('favourites_page');
    cartItems = await storage.getItem('cartItems');
    main_to_sub_category_product = await storage.getItem('main_to_sub_category_product');
    category_page = await storage.getItem('category_page');
    selecteddata = widget.selected_data;
    selecteddata_title = widget.selecteddata_title;
    if (userResponse != null) {
      accesstoken = userResponse['api_token'];
      customer_id = userResponse['customer_id'].toString();
    }
      await GetProductDetails();
      await GetProductvarients();
      await loadCartQty();
      setState(() {});
  }

  Future<void> GetProductDetails() async {
    setState(() => isLoading = true);
      var data = {
          "action": "get_product_dtl",
          "accesskey": "90336",
          "product_id": selecteddata['product_id'],
          "act_type": userResponse?['act_type'] ?? "",
          "customer_id": customer_id ?? "",
          "token": accesstoken ?? "",
      };
    final response = await Productapi().GetProductDetails(data);

    print(response);

    if(response != null){
      product_details = response['res'] ?? [];
   
    await checkCartQty();  
    await checkFavorite();
    await HomeFeatureSections();
    setState(() => isLoading = false);
  }else{
    product_details = [];
  }
    setState(() => isLoading = false);
 }

  Future<void> GetProductvarients() async {
    setState(() => isLoading = true);
   var data = {
          
          "accesskey": "90336",
          "product_id": selecteddata['product_id'],
          "act_type": userResponse?['act_type'] ?? "",
          "token": accesstoken ?? "",

   };
    final response = await Productapi().GetProductvarients(data);

    print(response);

  // if (response != null) {
  //   product_varient = response['attributes_list'] ?? [];
  //   variantsList = Map<String, dynamic>.from(response['variants_list'] ?? {});
  //   variantsCombo = Map<String, dynamic>.from(response['variants_combo_list'] ?? {});
  // } else {
  //   product_varient = [];
  // }
  if (response != null) {
  product_varient = response['attributes_list'] ?? [];
  variantsList = Map<String, dynamic>.from(response['variants_list'] ?? {});
  variantsCombo = Map<String, dynamic>.from(response['variants_combo_list'] ?? {});

  /// AUTO SELECT FIRST SIZE
  if (product_varient.isNotEmpty) {
   
    var firstGroup = product_varient[0];
List attrs = List.from(firstGroup['attributes']);

// sort sizes alphabetically (L, XL, XXL)
attrs.sort((a, b) => a['value'].length.compareTo(b['value'].length));

var smallestSize = attrs.first;

selectedAttributes[firstGroup['group_id']] = smallestSize['id'];

selectAttribute(firstGroup['group_id'], smallestSize['id']);
  }
  /// ✅ AUTO SELECT TYPE
var typeGroup = product_varient.firstWhere(
  (g) => g['group_name'] == "Type",
  orElse: () => null,
);

if (typeGroup != null) {
  for (var variant in variantsList.values) {
    List ids = variant['id_array'];

    bool match = selectedAttributes.values.every((id) => ids.contains(id));

    if (match) {
      for (var attr in typeGroup['attributes']) {
        if (ids.contains(attr['id'])) {
          selectedAttributes[typeGroup['group_id']] = attr['id'];
          break;
        }
      }
      break;
    }
  }
}
}
    setState(() => isLoading = false);
 }

Future<void> HomeFeatureSections() async {
  try {
    final response = await DashboardApi().HomeFeatureSections();
    final List sections = response ?? [];
    final currentId = selecteddata['product_id'].toString();

    List allProducts = [];
    for (var section in sections) {
      if (section['type'] == "product_price" && section['style_type'] == "style_7") {
        List data = section['data'] ?? [];
        allProducts.addAll(data);
      }
    }

    final filtered = allProducts
        .where((p) => p['product_id'].toString() != currentId)
        .toList();

    setState(() {
      relatedProducts = filtered.length > 5 ? filtered.sublist(0, 5) : filtered;
    });
  } catch (_) {
    setState(() => relatedProducts = []);
  }
}
 Future<void> AddFavorite() async {

  final box = await Hive.openBox('favorites_list');

  List<dynamic> favList = box.get('favorites', defaultValue: []);

  // String variantId =
  //     product_details[0]['vars'][0]['product_variant_id'].toString();
  String variantId = selectedVariant != null
    ? selectedVariant['product_variant_id'].toString()
    : product_details[0]['vars'][0]['product_variant_id'].toString();

  int index = favList.indexWhere(
      (item) => item['product_variant_id'].toString() == variantId);

  if (index != -1) {
    /// REMOVE FROM FAVORITE
    favList.removeAt(index);
    Fluttertoast.showToast(msg: "Removed from Favorites");

    setState(() {
      isFavorite = false;
    });

  } else {
      favList.add({
        "product_variant_id": variantId,
        "product_data": product_details[0]
      });
    Fluttertoast.showToast(msg: "Added to Favorites");

    setState(() {
      isFavorite = true;
    });
  }

  await box.put('favorites', favList);

  print(box.get('favorites'));
}

Future<void> checkFavorite() async {

  final box = await Hive.openBox('favorites_list');

  List<dynamic> favList = box.get('favorites', defaultValue: []);

  // String variantId =
  //     product_details[0]['vars'][0]['product_variant_id'].toString();
  String variantId =
    (product_details is List &&
            product_details.isNotEmpty &&
            product_details[0]['vars'] is List &&
            product_details[0]['vars'].isNotEmpty)
        ? product_details[0]['vars'][0]['product_variant_id']?.toString() ?? ""
        : "";

  int index = favList.indexWhere(
      (item) => item['product_variant_id'].toString() == variantId);

  setState(() {
    isFavorite = index != -1;
  });
}
Future<void> checkCartQty() async {

  final box = await Hive.openBox('cart');
  List<dynamic> cartList = box.get('cartItems', defaultValue: []);

  String variantId;

  if (selectedVariant != null) {
    variantId = selectedVariant['product_variant_id'].toString();
  } else {
    // variantId = product_details[0]['vars'][0]['product_variant_id'].toString();
     variantId = product_details.isNotEmpty &&
                product_details[0]['vars'] != null &&
                product_details[0]['vars'].isNotEmpty
    ? product_details[0]['vars'][0]['product_variant_id'].toString()
    : "";
  }

  int existingQty = 0;

  for (var item in cartList) {
    if (item['product_variant_id'].toString() == variantId) {
      existingQty = int.parse(item['qty'].toString());
      break;
    }
  }

  setState(() {
    qty = existingQty;
  });
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
Future<void> addToCart() async {
  final box = await Hive.openBox('cart');
  List<dynamic> cartList = box.get('cartItems', defaultValue: []);

  String variantId =
      product_details[0]['vars'][0]['product_variant_id'].toString();

  /// find product index
  int index = cartList.indexWhere(
      (item) => item['product_variant_id'].toString() == variantId);

  if (index != -1) {
    /// PRODUCT EXISTS
    if (qty == 0) {
      cartList.removeAt(index);
      Fluttertoast.showToast(msg: "Removed from cart");
    } else {
      cartList[index]['qty'] = qty.toString();
      Fluttertoast.showToast(msg: "Cart Updated");
    }
  } else {
    /// NEW PRODUCT
    if (qty > 0) {
      cartList.add({
        "qty": qty.toString(),
        "product_variant_id": variantId,
      });

      Fluttertoast.showToast(msg: "Added to cart");
    }
  }

  await box.put('cartItems', cartList);
 var data =  box.get('cartItems');
 print(data);

}

  Future<void> updateCart(String variantId, int newQty,activeVariant) async {

  final box = Hive.box('cart');
  List<dynamic> cartList = box.get('cartItems', defaultValue: []);

  int index = cartList.indexWhere(
      (item) => item['product_variant_id'].toString() == variantId);

  int currentQty = 0;
  if (index != -1) {
    currentQty = int.parse(cartList[index]['qty']);
  }
   /// ✅ SAFE min qty
  int minQty = int.tryParse(
          activeVariant?['min_order_qty']?.toString() ?? "0") ??
      0;

  /// ❗ MIN QTY CHECK (Correct)
  if (currentQty == 0 && newQty > 0 && newQty < minQty) {
  newQty = minQty;
  Fluttertoast.showToast(msg: "Minimum order is $minQty");
}

// if (newQty > 0 && newQty < minQty && newQty < currentQty) {
//   Fluttertoast.showToast(msg: "Minimum order is $minQty");
// }
if (newQty > 0 && newQty < minQty && newQty < currentQty) {
  Fluttertoast.showToast(msg: "Minimum order is $minQty");
  return;
}

  /// 🚀 Check stock only when qty increases
  if (newQty > currentQty) {

    var data = {
      "action": "check_stock",
      "product_variant_id": variantId,
      "qty": newQty.toString(),
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

    if (newQty > stockQty) {
      Fluttertoast.showToast(msg: "Only $stockQty items available");
      return;
    }
  }

  if (index != -1) {

    if (newQty == 0) {

      cartList.removeAt(index);
      Fluttertoast.showToast(msg: "Removed from cart");

    } else {

      cartList[index]['qty'] = newQty.toString();
    }

  } else {

    if (newQty > 0) {

      cartList.add({
        "product_variant_id": variantId,
        "qty": newQty.toString(),
      });

      Fluttertoast.showToast(msg: "Added to cart");
    }
  }

  await box.put('cartItems', cartList);

  setState(() {
    qty = newQty;
  });
}


// Future<void> selectAttribute(int groupId, int attrId) async{

//   // Save selected attribute
//   // selectedAttributes[groupId] = attrId;
// selectedAttributes[groupId] = attrId;

// /// remove other selections after size change
// if (groupId == product_varient[0]['group_id']) {
//   selectedAttributes.removeWhere((key, value) => key != groupId);
// }
//   // Build combination list
//   List<int> ids = selectedAttributes.values
//       .map((e) => int.parse(e.toString()))
//       .toList();

//   ids.sort();
//   String key = ids.join("_");

//   // Exact match
//   if (variantsCombo.containsKey(key)) {

//     String variantId = variantsCombo[key].toString();
//     selectedVariant = variantsList[variantId];

//   } else {

//     // If combination incomplete, find best match
//     for (var variant in variantsList.values) {

//       List variantIds = variant['id_array'];

//       bool match = ids.every((id) => variantIds.contains(id));

//       if (match) {
//         selectedVariant = variant;
//         break;
//       }
//     }
//   }
// await checkCartQty();
//   setState(() {});
// }

// Future<void> selectAttribute(int groupId, int attrId) async {

//   selectedAttributes[groupId] = attrId;

//   /// ✅ If SIZE changed → remove ONLY color
//   if (groupId == product_varient[0]['group_id']) {

//     var colorGroup = product_varient.firstWhere(
//       (g) => g['group_name'] == "Colour",
//       orElse: () => null,
//     );

//     if (colorGroup != null) {
//       selectedAttributes.remove(colorGroup['group_id']);
//     }

//     /// ✅ AUTO SELECT NEW COLOR
//     if (colorGroup != null) {

//       for (var variant in variantsList.values) {

//         List ids = variant['id_array'];

//         if (ids.contains(attrId) && ids.length > 1) {

//           for (var attr in colorGroup['attributes']) {

//             if (ids.contains(attr['id'])) {

//               selectedAttributes[colorGroup['group_id']] = attr['id'];
//               break;
//             }
//           }

//           break;
//         }
//       }
//     }
//   }

//   /// Build combination
//   List<int> ids = selectedAttributes.values
//       .map((e) => int.parse(e.toString()))
//       .toList();

//   ids.sort();
//   String key = ids.join("_");

//   selectedVariant = null;

//   /// Exact match
//   if (variantsCombo.containsKey(key)) {

//     String variantId = variantsCombo[key].toString();
//     selectedVariant = variantsList[variantId];

//   } else {

//     for (var variant in variantsList.values) {

//       List variantIds = variant['id_array'];

//       bool match = ids.every((id) => variantIds.contains(id));

//       if (match) {
//         selectedVariant = variant;
//         break;
//       }
//     }
//   }

//   await checkCartQty();
//   setState(() {});
// }
Future<void> selectAttribute(int groupId, int attrId) async {

  bool isDeselecting = selectedAttributes[groupId] == attrId;

  /// ✅ TOGGLE
  if (isDeselecting) {
    selectedAttributes.remove(groupId);
  } else {
    selectedAttributes[groupId] = attrId;
  }

  /// 🚫 IMPORTANT: stop auto logic when deselect
  if (!isDeselecting) {

    /// SIZE → COLOR AUTO SELECT
    if (groupId == product_varient[0]['group_id']) {

      var colorGroup = product_varient.firstWhere(
        (g) => g['group_name'] == "Colour",
        orElse: () => null,
      );

      if (colorGroup != null) {
        selectedAttributes.remove(colorGroup['group_id']);
      }

      if (colorGroup != null) {
        for (var variant in variantsList.values) {

          List ids = variant['id_array'];

          if (ids.contains(attrId) && ids.length > 1) {

            for (var attr in colorGroup['attributes']) {

              if (ids.contains(attr['id'])) {
                selectedAttributes[colorGroup['group_id']] = attr['id'];
                break;
              }
            }
            break;
          }
        }
      }
    }
  }

  /// ✅ If nothing selected → reset
  if (selectedAttributes.isEmpty) {
    selectedVariant = null;
    await checkCartQty();
    setState(() {});
    return;
  }

  /// 🔄 Build combination
  List<int> ids = selectedAttributes.values
      .map((e) => int.parse(e.toString()))
      .toList();

  ids.sort();
  String key = ids.join("_");

  selectedVariant = null;

  if (variantsCombo.containsKey(key)) {
    String variantId = variantsCombo[key].toString();
    selectedVariant = variantsList[variantId];
  } else {
    for (var variant in variantsList.values) {
      List variantIds = variant['id_array'];

      bool match = ids.every((id) => variantIds.contains(id));

      if (match) {
        selectedVariant = variant;
        break;
      }
    }
  }

  await checkCartQty();
  setState(() {});
}
  void _handleBack(BuildContext context) async {
    if (main_to_sub_category == "main_to_sub_category") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => Subcategory(selected_data: selecteddata_title)));
      await storage.deleteItem('main_to_sub_category');
    } else if (section_style_category == "section_style_category") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => Sectionstylecategory(selected_data: selecteddata_title)));
      await storage.deleteItem('section_style_category');
    } else if (section_product == "section_product") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => Sectionproducts(selected_data: selecteddata_title)));
      await storage.deleteItem('section_product');
    } else if (favourites_page == "favourites_page") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => Favourites()));
      await storage.deleteItem('favourites_page');
    } else if (main_to_sub_category_product == "main_to_sub_category_product") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => Mainsubcattoproduct(selected_data: selecteddata_title, selecteddata_title: selecteddata_title)));
      await storage.deleteItem('main_to_sub_category_product');
    }else if (category_page == "category_page") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => Categorypage(selected_data: selecteddata_title)));
      await storage.deleteItem('category_page');
    }
     else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => Dashboard()));
    }
  }

  @override
  Widget build(BuildContext context) {
    var product = product_details != null && product_details.isNotEmpty ? product_details[0] : null;
    // var variant = selectedVariant ?? (product != null && product['vars'].isNotEmpty ? (product['vars'] != null && product['vars'].isNotEmpty)
    // ? product['vars'][0]
    // : null: null);
    var variant = selectedVariant ??
    (product != null &&
            product['vars'] != null &&
            product['vars'].isNotEmpty
        ? product['vars'][0]
        : null);
    // final activeVariant = selectedVariant ?? variant;
    // final activeVariant = selectedVariant ??
    final activeVariant = getSafeVariant(product);
    (product != null &&
            product['vars'] != null &&
            product['vars'].isNotEmpty
        ? product['vars'][0]
        : null);
    final String variantId = activeVariant != null ? activeVariant['product_variant_id'].toString() : '';
    // double price = double.tryParse(
    //     activeVariant?['discounted_price']?.toString() ?? "") ??
    // double.tryParse(
    //     activeVariant?['price']?.toString() ?? "") ??
    // double.tryParse(
    //     product?['vars']?[0]?['discounted_price']?.toString() ?? "") ??  
    // 0;
    var vars = product?['vars'];

double price =
    double.tryParse(activeVariant?['discounted_price']?.toString() ?? "") ??
    double.tryParse(activeVariant?['price']?.toString() ?? "") ??
    (
      (vars != null && vars is List && vars.isNotEmpty)
          ? double.tryParse(vars[0]['discounted_price']?.toString() ?? "") ?? 0.0
          : 0.0
    );

double mrp = double.tryParse(
        activeVariant?['price']?.toString() ?? "") ??
    price;

    bool isOutOfStock = activeVariant?['stock_status'] != "Available";
    return PopScope(
      // canPop: false,
      // canPop: true,
      // onPopInvoked: (didPop) => _handleBack(context),
      onPopInvoked: (didPop) {
    if (didPop) return; // ✅ Already popped → DO NOTHING

    _handleBack(context); // only fallback
  },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: custom_color.app_color,
          elevation: 0,
          title: const Text("Product Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            // onPressed: () => _handleBack(context),
            onPressed: () {
              // if (Navigator.canPop(context)) {
              //   Navigator.pop(context); // ✅ go to previous product
              // } else {
                _handleBack(context); // fallback
              // }
            },
          ),
          actions: [
             Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: ()async {
                  await storage.setItem('productdetails_cart',"productdetails_cart");
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Cart(selected_data : selecteddata,selecteddata_title :selecteddata_title))).then((_) => loadCartQty());
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
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.white,
              ),
              onPressed: AddFavorite,
            ),
          ],
        ),
        body: isLoading
            // ? Center(child: CircularProgressIndicator(color: custom_color.app_color))
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
            : product == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset("assets/images/AppLogo.png", width: 100, height: 100),
                        const SizedBox(height: 20),
                        CircularProgressIndicator(color: custom_color.app_color),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// IMAGE SECTION
                              Container(
                                width: double.infinity,
                                color: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                child: Center(
                                  child: SizedBox(
                                    height: 220,
                                    child:
                                    //  safeNetworkImage(
                                    //   selectedVariant != null ? selectedVariant['images'][0] : product['prod_img'],
                                     
                                    //   fit: BoxFit.contain,
                                    // ),
                                  
                                      
                                      safeNetworkImage(
                                        (selectedVariant != null && selectedVariant['images'] != null && selectedVariant['images'].isNotEmpty)
                      ? selectedVariant['images'][0]
                      : (product['prod_img'] ?? ""),
                                        fit: BoxFit.contain,
                                      ),
                                  ),
                                ),
                              ),
                                      
                              /// PRODUCT INFO CARD
                              Container(
                                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'],
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                                    ),
                                    const SizedBox(height: 12),
                                    // Row(
                                    //   children: [
                                    //     Container(
                                    //       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    //       decoration: BoxDecoration(
                                    //         color: custom_color.app_color,
                                    //         borderRadius: BorderRadius.circular(10),
                                    //       ),
                                    //       child: Text(
                                    //         "Rs. ${activeVariant['discounted_price']}",
                                    //         style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    //       ),
                                    //     ),
                                    //   ],
                                    // ),
                                    // const SizedBox(height: 12),
                                    //  if (activeVariant['price'].toString() !=
                                    //     activeVariant['discounted_price'].toString())
                                    //   Text(
                                    //     "MRP: ₹${activeVariant['price']}",
                                    //     style: const TextStyle(
                                    //       fontSize: 16,
                                    //       color: Colors.grey,
                                    //       decoration: TextDecoration.lineThrough,
                                    //     ),
                                    //   ),
                                    // // _infoRow(Icons.layers_outlined, "Pieces per pack", "${activeVariant['no_of_pads']}"),
                                    // const SizedBox(height: 6),
                            if (activeVariant != null)        Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          /// 🔥 Selling Price
                                          Text(
                      // "₹${activeVariant['discounted_price']}",
                       "₹${price.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                                          ),
                                      
                                          const SizedBox(width: 10),
                                      
                                          /// 🔥 MRP (only if different)
                                          if (activeVariant['price'].toString() !=
                        activeVariant['discounted_price'].toString())
                      Text(
                        "₹${activeVariant['price']}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                                      
                                          const SizedBox(width: 8),
                                      
                                          /// 🔥 Discount %
                                          if (activeVariant['price'].toString() !=
                        activeVariant['discounted_price'].toString())
                      // Text(
                      //   // "${(((int.parse(activeVariant['price']) - int.parse(activeVariant['discounted_price'])) / int.parse(activeVariant['price'])) * 100).round()}% OFF",
                      //   "${(((double.parse(activeVariant['price'].toString()) - double.parse(activeVariant['discounted_price'].toString())) / double.parse(activeVariant['price'].toString())) * 100).round()}% OFF",
                      //   style: const TextStyle(
                      //     color: Colors.green,
                      //     fontWeight: FontWeight.bold,
                      //   ),
                      // ),
                      Text(
                                          activeVariant['disc_type'] == "Amount"
                        ? "₹${(double.parse(activeVariant['price'].toString()) - double.parse(activeVariant['discounted_price'].toString())).toStringAsFixed(0)} OFF"
                        : "${(((double.parse(activeVariant['price'].toString()) - double.parse(activeVariant['discounted_price'].toString())) / double.parse(activeVariant['price'].toString())) * 100).round()}% OFF",
                                          style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                                          ),
                      )
                                        ],
                                      ),
                                    // _infoRow(Icons.shopping_bag_outlined, "Min. Order Qty", "${activeVariant['min_order_qty']}"),
                                    _infoRow(
                                      Icons.shopping_bag_outlined,
                                      "Min. Order Qty",
                                      "${activeVariant?['min_order_qty'] ?? ''}",
                                    ),
                                  ],
                                ),
                              ),
                                      
                              /// VARIANTS CARD
                              if (product_varient != null && product_varient.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: List.generate(product_varient.length, (i) {
                                      var group = product_varient[i];
                                      final isLast = i == product_varient.length - 1;
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 4,
                                                  height: 18,
                                                  decoration: BoxDecoration(
                                                    color: custom_color.app_color,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  group['group_name'],
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF1A1A2E),
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                if (selectedAttributes[group['group_id']] != null)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: custom_color.app_color.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      (group['attributes'] as List).firstWhere(
                                                        (a) => a['id'] == selectedAttributes[group['group_id']],
                                                        orElse: () => {'value': ''},
                                                      )['value'],
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: custom_color.app_color,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                            child: Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: (group['attributes'] as List).map<Widget>((attr) {
                                                final bool enabled = group['group_name'] == 'Size'
                                                    ? true
                                                    : isAttributeAvailable(group['group_id'], attr['id']);
                                                final bool selected = selectedAttributes[group['group_id']] == attr['id'];
                                                return GestureDetector(
                                                  // onTap: enabled ? () => selectAttribute(group['group_id'], attr['id']) : null,
                                                  onTap: enabled
                                                    ? () => selectAttribute(group['group_id'], attr['id'])
                                                    : () {
                                                        Fluttertoast.showToast(msg: "Out of Stock");
                                                      },
                                                  child: AnimatedContainer(
                                                    duration: const Duration(milliseconds: 180),
                                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                                    decoration: BoxDecoration(
                                                      color: selected
                                                          ? custom_color.app_color
                                                          : enabled
                                                              ? Colors.white
                                                              : const Color(0xFFF5F5F5),
                                                      borderRadius: BorderRadius.circular(30),
                                                      border: Border.all(
                                                        color: selected
                                                            ? custom_color.app_color
                                                            : enabled
                                                                ? Colors.grey.shade300
                                                                : Colors.grey.shade200,
                                                        width: selected ? 1.5 : 1,
                                                      ),
                                                      boxShadow: selected
                                                          ? [BoxShadow(color: custom_color.app_color.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]
                                                          : [],
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        if (selected) ...
                                                          [
                                                            const Icon(Icons.check, size: 13, color: Colors.white),
                                                            const SizedBox(width: 4),
                                                          ],
                                                        Text(
                                                          attr['value'],
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                                            color: selected
                                                                ? Colors.white
                                                                : enabled
                                                                    ? const Color(0xFF333333)
                                                                    : Colors.grey.shade400,
                                                            decoration: enabled ? null : TextDecoration.lineThrough,
                                                            decorationColor: Colors.grey.shade400,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                          if (!isLast)
                                            Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
                                        ],
                                      );
                                    }),
                                  ),
                                ),
                                      
                              /// RELATED PRODUCTS SECTION
                              if (relatedProducts.isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                                      child: Text(
                                        "Related Products",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1A2E),
                                        ),
                                      ),
                                    ),
                                    buildHorizontalProducts(relatedProducts, 0),
                                  ],
                                ),

                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                      /// STICKY BOTTOM BAR
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
                        ),
                        child: SafeArea(
                          top: false,
                          child: qty == 0
                              // ? SizedBox(
                              //     width: double.infinity,
                              //     height: 52,
                              //     child: ElevatedButton.icon(
                              //       onPressed: () => updateCart(variantId, 1),
                                    
                              //       icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                              //       label: const Text("Buy Now", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              //       style: ElevatedButton.styleFrom(
                              //         backgroundColor: custom_color.button_color,
                              //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              //         elevation: 2,
                              //       ),
                              //     ),
                              //   )
                               ? SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          // onPressed: isOutOfStock 
                          //     ? null // ❌ DISABLE BUTTON
                          //     : () => updateCart(variantId, 1,activeVariant),
                          onPressed: (isOutOfStock || isProcessingCart)
                            ? null
                            : () async {
                                if (product_varient != null &&
                                    product_varient.isNotEmpty &&
                                    selectedVariant == null) {
                                  Fluttertoast.showToast(
                                      msg: "Please select all required options");
                                  return;
                                }
                                setState(() => isProcessingCart = true);

                                await updateCart(variantId, 1, activeVariant);

                                setState(() => isProcessingCart = false);
                              },
                          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                          label: isProcessingCart
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                          :Text(
                            // isOutOfStock ? "Out of Stock" : "Buy Now",
                             isOutOfStock ? "Out of Stock" : "Add to Cart",
                            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isOutOfStock
                ? Colors.grey // 🔥 show disabled color
                : custom_color.button_color,
                            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                        ),
                      )
                              : Row(
                                  children: [
                                    const Text("Quantity:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Container(
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: custom_color.button_color,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            GestureDetector(
                                              // onTap: () => updateCart(variantId, qty - 1),
                                              onTap: isOutOfStock
                                                ? null
                                                : () => updateCart(variantId, qty - 1,activeVariant),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                child: const Icon(Icons.remove, color: Colors.white, size: 20),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                qty.toString(),
                                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            GestureDetector(
                                              // onTap: () => updateCart(variantId, qty + 1),
                                              onTap: isOutOfStock
                    ? () {
                        Fluttertoast.showToast(msg: "Out of Stock");
                      }
                    : () => updateCart(variantId, qty + 1,activeVariant),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                child: const Icon(Icons.add, color: Colors.white, size: 20),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text("$label: ", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
      ],
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

// bool isAttributeAvailable(int groupId, int attrId) {

//   // clone selected attributes
//   Map temp = Map.from(selectedAttributes);

//   // update this group
//   temp[groupId] = attrId;

//   List selectedIds = temp.values.map((e) => int.parse(e.toString())).toList();

//   for (var variant in variantsList.values) {

//     List ids = variant['id_array'];

//     bool valid = selectedIds.every((id) => ids.contains(id));

//     if (valid) {
//       return true;
//     }
//   }

//   return false;
// }
bool isAttributeAvailable(int groupId, int attrId) {

  Map temp = Map.from(selectedAttributes);
  temp[groupId] = attrId;

  List selectedIds = temp.values
      .map((e) => int.parse(e.toString()))
      .toList();

  for (var variant in variantsList.values) {

    List ids = variant['id_array'];

    bool match = selectedIds.every((id) => ids.contains(id));

    /// ✅ ALSO CHECK STOCK
    if (match && variant['stock_status'] == "Available") {
      return true;
    }
  }

  return false;
}
dynamic getSafeVariant(var product) {
  if (selectedVariant != null) return selectedVariant;

  if (product != null &&
      product['vars'] != null &&
      product['vars'].isNotEmpty) {
    return product['vars'][0];
  }

  return null;
}


Widget buildHorizontalProducts(List products, int sectionIndex) {
  final limitedProducts = products.length > 5 ? products.sublist(0, 5) : products;

  if (!_horizontalControllers.containsKey(sectionIndex)) {
    _horizontalControllers[sectionIndex] = ScrollController();
    
    // _horizontalTimers[sectionIndex] = Timer.periodic(const Duration(seconds: 3), (timer) {
    //   final controller = _horizontalControllers[sectionIndex];
    //   if (controller != null && controller.hasClients) {
    //     double maxScroll = controller.position.maxScrollExtent;
    //     double current = controller.offset;

    //     if (current >= maxScroll) {
    //       controller.jumpTo(0);
    //     } else {
    //       controller.animateTo(
    //         maxScroll,
    //         duration: const Duration(milliseconds: 800),
    //         curve: Curves.easeInOut,
    //       );
    //     }
    //   }
    // });
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
    borderRadius: BorderRadius.circular(18),

    // Right & Bottom light shadow
    boxShadow: [
      BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
          child: buildHorizontalProductCard(p, variant),
        );
      },
    ),
  );
}

Widget buildHorizontalProductCard(var p, var variant) {
  String sizeText = "";

if (variant != null && variant['size'] != null) {
  sizeText = variant['size'];
}
  String variantId = variant?['product_variant_id']?.toString() ?? "";
// int qty = cartQty[variantId] ?? 0;
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
        // loadCartQty();
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
  //         child: variant['stock_status'] == "Sold Out" ? Text(
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
}