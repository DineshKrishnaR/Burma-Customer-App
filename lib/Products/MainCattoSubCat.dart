import 'package:burma/CartPages/Cart.dart';
import 'package:burma/CartPages/CartApi.dart';
import 'package:burma/Dashboard/Dashboard.dart';
import 'package:burma/Products/MainCategorytoSub.dart';
import 'package:burma/Products/MainSubCattoProduct.dart';
import 'package:burma/Products/ProductApi.dart';
import 'package:burma/Products/ProductDetails.dart';
import 'package:burma/Products/SubCategory.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:localstorage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Common/colors.dart' as custom_color;

class Maincattosubcat extends StatefulWidget {
  final selected_data;
  
  const Maincattosubcat({super.key,required this.selected_data,});

  @override
  State<Maincattosubcat> createState() => _MaincattosubcatState();
}

class _MaincattosubcatState extends State<Maincattosubcat> {

final LocalStorage storage = new LocalStorage('app_store');
 
  late SharedPreferences pref;
  

  bool isLoading = false;
  var userResponse;
  var accesstoken;
  var customer_id;
  var aboutus_us;
  var selecteddata;
  var selecteddata_title;
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
      await getSubCategoryProducts();
      await loadCartQty();
      setState(() {});
  }
  Future<void> getSubCategoryProducts() async {
    setState(() => isLoading = true);
   var data = {
         "action": "get_subcategorylist_by_category_id",
         "accesskey":"90336",
         "token":accesstoken,
         "act_type":userResponse['act_type'],
         "category_id":selecteddata['category_id'].toString(),
         "main_category_id":selecteddata['main_category_id'].toString(),
   };
    final response = await Productapi().getSubCategoryProducts(data);

    print(response);

    if(response != null){
      subcaragory_product = response['data'] ?? [];
 
  }else{
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
      onPopInvoked: (didPop) async{
        // if(Mani_SubCategory == "Mani_SubCategory"){
        //   Navigator.push(context, MaterialPageRoute(builder: (context)=>Maincategorytosub(selected_data: selecteddata,)));
        //   await storage.deleteItem('Mani_SubCategory');
        // }else{
        // Navigator.push(context, MaterialPageRoute(builder: (context)=>Dashboard()));
        // }
         Navigator.push(context, MaterialPageRoute(builder: (context)=>Maincategorytosub(selected_data: selecteddata,)));
      },
      child: Scaffold(
         appBar: AppBar(
          backgroundColor: custom_color.app_color,
          // title: Text(selecteddata?['category_name'] ?? "Products",style: TextStyle(color: Colors.white),),
          title: Text(
              
                   (selecteddata?['name'] ?? "Products"),
              style: const TextStyle(color: Colors.white),
            ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios,color: Colors.white,),
            onPressed: ()async{
              // if(Mani_SubCategory == "Mani_SubCategory"){
              //   Navigator.push(context, MaterialPageRoute(builder: (context)=>Maincategorytosub(selected_data: selecteddata,)));
              //   await storage.deleteItem('Mani_SubCategory');
              // }else{
              // Navigator.push(context, MaterialPageRoute(builder: (context)=>Dashboard()));
              // }
               Navigator.push(context, MaterialPageRoute(builder: (context)=>Maincategorytosub(selected_data: selecteddata,)));
            },
          ),
          actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () async{
                  await storage.setItem('maincattosub_cart',"maincattosub_cart");
                  Navigator.push(context, MaterialPageRoute(builder: (context) => Cart(selected_data : selecteddata,selecteddata_title:""))).then((_) => loadCartQty());
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
                  const SizedBox(height: 20),
                   CircularProgressIndicator(color: custom_color.app_color,),
                ],
              ),
            ) : (subcaragory_product == null || subcaragory_product.isEmpty)
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 70,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 10),
                const Text(
                  "No Data Found",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )
          : GridView.builder(
  padding: const EdgeInsets.all(15),
  itemCount: subcaragory_product?.length ?? 0,
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 15,
    crossAxisSpacing: 15,
    childAspectRatio: .9,
  ),
  itemBuilder: (context, index) {

    var sub = subcaragory_product[index];

    return InkWell(
      onTap: () async{
        // await storage.setItem('Mani_SubCategory',"Mani_SubCategory");
        print(sub);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Mainsubcattoproduct(
              selected_data: sub, selecteddata_title :selecteddata
            ),
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
        //       offset: const Offset(0,4),
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
              offset: const Offset(0,4),
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
        child: Column(
          children: [

            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18)),
                child: safeNetworkImage(
                  sub['img'],
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Padding(
            //   padding: const EdgeInsets.all(10),
            //   child: Text(
            //     sub['name'] ?? "",
            //          maxLines: 2,
            //   overflow: TextOverflow.ellipsis,
            //     style: const TextStyle(
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            // )
            Container(
  height: 45, // ✅ fixed space for 2 lines
  alignment: Alignment.center,
  padding: const EdgeInsets.symmetric(horizontal: 8),
  child: Text(
    sub['name'] ?? "",
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
      ),
    );
  },
)
                  ));
              }
Widget buildProductCard(var p, var variant) {
  String variantId = variant['product_variant_id'].toString();
int qty = cartQty[variantId] ?? 0;
  return InkWell(
        onTap: () {
          storage.setItem('main_to_sub_category', "main_to_sub_category");
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => Productdetails(selected_data: p),
      //   ),
      // );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Productdetails(selected_data: p,selecteddata_title: selecteddata,),
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
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
    
            /// PRODUCT IMAGE
            Expanded(
              child: Center(
                child: safeNetworkImage(
                  p['prod_img'],
                  fit: BoxFit.contain,
                ),
              ),
            ),
    
            const SizedBox(height: 8),
    
            /// PRODUCT NAME
            Text(
              p['name'] ?? "",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            // SizedBox(height: 3),
            if (variant != null)
              Text(
                variant['size'] ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            const SizedBox(height: 6),
    
            /// PRICE
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
    
            /// ADD TO CART BUTTON
            // SizedBox(
            //   width: double.infinity,
            //   height: 34,
            //   child: ElevatedButton(
            //     onPressed: variant != null &&
            //             variant['stock_status'] != "Sold Out"
            //         ? () {
            //             print("Add ${p['product_id']}");
            //           }
            //         : null,
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: custom_color.app_color,
            //       elevation: 2,
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
             storage.setItem('main_to_sub_category', "main_to_sub_category");
             Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Productdetails(selected_data: p,selecteddata_title : selecteddata),
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
      //             color: Colors.white,
      //             fontWeight: FontWeight.bold,
      //           ),
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
Widget safeNetworkImage(
  String? url, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  double borderRadius = 0,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: SizedBox(
      width: width,
      height: height,
      child: Image.network(
        url ?? "",
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
              // fit: fit,
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