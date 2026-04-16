import 'package:burma/CartPages/Cart.dart';
import 'package:burma/CartPages/CartApi.dart';
import 'package:burma/Dashboard/Dashboard.dart';
import 'package:burma/Dashboard/DashboardApi.dart';
import 'package:burma/Products/MainCategorytoSub.dart';
import 'package:burma/Products/ProductDetails.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:localstorage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Common/colors.dart' as custom_color;

class Sectionstylecategory extends StatefulWidget {
  final selected_data;

  const Sectionstylecategory({super.key, required this.selected_data});

  @override
  State<Sectionstylecategory> createState() => _SectionstylecategoryState();
}

class _SectionstylecategoryState extends State<Sectionstylecategory> {

  final LocalStorage storage = LocalStorage('app_store');

  late SharedPreferences pref;

  bool isLoading = false;

  var userResponse;
  var accesstoken;
  var customer_id;
  var selecteddata;
  var subcaragory_product;
  var Mani_SubCategory;
  Map<String, int> cartQty = {};

  @override
  void initState() {
    super.initState();
    initPreferencess();
  }

  initPreferencess() async {

    await storage.ready;

    pref = await SharedPreferences.getInstance();

    userResponse = await storage.getItem('userResponse');
    Mani_SubCategory = await storage.getItem('Mani_SubCategory');

    if (userResponse != null) {
      accesstoken = userResponse['api_token'];
      customer_id = userResponse['customer_id'].toString();
      selecteddata = widget.selected_data;
    }

    await loadProducts();
    await loadCartQty();
  }

  Future<void> loadProducts() async {

    setState(() => isLoading = true);

    var data = {
      "action": "get_productlist_by_maincategoryid",
      "accesskey": "90336",
      "token": accesstoken,
      "main_category_id": selecteddata['main_category_id'].toString(),
    };

    final response = await DashboardApi().Stylecatageory(data);

    if (response != null) {
      subcaragory_product = response['res'] ?? [];
    } else {
      subcaragory_product = [];
    }

    setState(() => isLoading = false);
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
  List<dynamic> cartList = box.get('cartItems', defaultValue: []);

  int index = cartList.indexWhere(
      (item) => item['product_variant_id'].toString() == variantId);

  int currentQty = cartQty[variantId] ?? 0;

  /// Check stock only when increasing qty
  if (qty > currentQty) {

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
      Fluttertoast.showToast(msg: "Out of stock");
      return;
    }

    int stockQty = int.parse(stockResponse['stock_qty']);

    if (qty > stockQty) {
      Fluttertoast.showToast(msg: "Only $stockQty items available");
      return;
    }
  }

  if (index != -1) {

    if (qty == 0) {
      cartList.removeAt(index);
      cartQty.remove(variantId);
      Fluttertoast.showToast(msg: "Removed from cart");
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
      Fluttertoast.showToast(msg: "Added to cart");
    }

  }

  await box.put('cartItems', cartList);

  setState(() {});
}
  @override
  Widget build(BuildContext context) {

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {

        if (Mani_SubCategory == "Mani_SubCategory") {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => Maincategorytosub(selected_data: selecteddata)));
          storage.deleteItem('Mani_SubCategory');
        } else {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => Dashboard()));
        }
      },

      child: Scaffold(
        //  backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: custom_color.app_color,

          title: Text(
            Mani_SubCategory != "Mani_SubCategory"
                ? (selecteddata?['category_name'] ?? "Products")
                : (selecteddata?['name'] ?? "Products"),
            style: const TextStyle(color: Colors.white),
          ),

          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),

            onPressed: () {

              if (Mani_SubCategory == "Mani_SubCategory") {

                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Maincategorytosub(selected_data: selecteddata)));

                storage.deleteItem('Mani_SubCategory');

              } else {

                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Dashboard()));
              }
            },
          ),
          actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () async{
                  await storage.setItem('sectionstylecat_cart',"sectionstylecat_cart");
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Cart(selected_data : selecteddata,selecteddata_title : ""))).then((_) => loadCartQty());
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
            ]
        ),

        body: isLoading
            ?  Center(child: CircularProgressIndicator(color: custom_color.app_color,))
            : (subcaragory_product == null || subcaragory_product.isEmpty)
                ? const Center(child: Text("No Data Found"))
                : GridView.builder(

                    padding: const EdgeInsets.all(15),

                    itemCount: subcaragory_product.length,

                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                      childAspectRatio: .78,
                    ),

                    itemBuilder: (context, index) {

                      var p = subcaragory_product[index];

                      List vars = p['vars'] ?? [];

                      double minPrice = 0;
                      double maxPrice = 0;

                      if (vars.isNotEmpty) {

                        List prices = vars
                            .map((v) => double.tryParse(
                                    v['discounted_price'].toString()) ??
                                0)
                            .toList();

                        prices.sort();

                        minPrice = prices.first;
                        maxPrice = prices.last;
                      }

                      bool available =
                          vars.any((v) => v['stock_status'] != "Sold Out");

                      return buildProductCard(
                          p, vars, minPrice, maxPrice, available);
                    },
                  ),
      ),
    );
  }

  Widget buildProductCard(
      var p, List vars, double minPrice, double maxPrice, bool available) {
String sizeText = "";
String variantId = vars.isNotEmpty
    ? vars[0]['product_variant_id'].toString()
    : "";

int qty = cartQty[variantId] ?? 0;
// if (vars.isNotEmpty) {
//   sizeText = vars.map((v) => v['size'].toString()).join(", ");
// }
if (vars.isNotEmpty) {
  Set<String> sizes = {};

  for (var v in vars) {
    if (v['size'] != null) {
      // split by comma
      List parts = v['size'].toString().split(',');

      if (parts.isNotEmpty) {
        sizes.add(parts[0].trim()); // ✅ only first part (size)
      }
    }
  }

  sizeText = sizes.join(", "); // ✅ remove duplicates
}
    return GestureDetector(
       onTap: () {
          storage.setItem('section_style_category', "section_style_category");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Productdetails(selected_data: p,selecteddata_title: selecteddata,),
        ),
      );
    },

      child: Container(

        // decoration: BoxDecoration(
        //   color: Colors.white,
        //   borderRadius: BorderRadius.circular(18),
        //   boxShadow: [
        //     BoxShadow(
        //       color: Colors.black.withOpacity(.05),
        //       blurRadius: 12,
        //       offset: const Offset(0, 4),
        //     )
        //   ],
        // ),
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
        child: Padding(
          padding: const EdgeInsets.all(10),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Expanded(
                child: Center(
                  child: safeNetworkImage(
                    p['prod_img'],
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                p['name'] ?? "",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
const SizedBox(height: 4),

if (sizeText.isNotEmpty)
  Text(
    sizeText,
    style: const TextStyle(
      fontSize: 12,
      color: Colors.grey,
    ),
  ),
              const SizedBox(height: 6),

              Text(
                minPrice == maxPrice
                    ? "₹ $minPrice"
                    // : "₹ $minPrice - ₹ $maxPrice",
                    : "₹ $minPrice",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: custom_color.app_color,
                ),
              ),

              if (vars.length > 1)
                Text(
                  "${vars.length} variants available",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),

              const SizedBox(height: 8),

              // SizedBox(
              //   width: double.infinity,
              //   height: 34,

              //   child: ElevatedButton(

              //     onPressed: available
              //         ? () {
              //             print("Add to cart ${p['product_id']}");
              //           }
              //         : null,

              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: custom_color.app_color,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(10),
              //       ),
              //     ),

              //     child: Text(
              //       available ? "Add to Cart" : "Sold Out",
              //       style: const TextStyle(color: Colors.white),
              //     ),
              //   ),
              // )
              SizedBox(
  width: double.infinity,
  height: 34,
  child: !available
      ? ElevatedButton(
          onPressed: null,
          child: const Text("Sold Out"),
        )
      // : qty == 0
      //     ? 
         : ElevatedButton(
              onPressed: () {
                // updateCart(variantId, 1);
                storage.setItem('section_style_category', "section_style_category");
                 Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Productdetails(selected_data: p,selecteddata_title: selecteddata,),
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
          //         GestureDetector(
          //           onTap: () {
          //             updateCart(variantId, qty - 1);
          //           },
          //           child: const Icon(Icons.remove, color: Colors.white),
          //         ),
          //         Text(
          //           qty.toString(),
          //           style: const TextStyle(
          //               color: Colors.white, fontWeight: FontWeight.bold),
          //         ),
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

  Widget safeNetworkImage(
    String? url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {

    return Image.network(

      url ?? "",

      width: width,
      height: height,
      fit: fit,

      loadingBuilder: (context, child, progress) {

        if (progress == null) return child;

        return Center(
          child: Image.asset(
            "assets/images/AppLogo.png",
            width: 70,
            height: 70,
          ),
        );
      },

      errorBuilder: (context, error, stackTrace) {

        return Image.asset(
          "assets/images/AppLogo.png",
          width: 70,
          height: 70,
        );
      },
    );
  }
}