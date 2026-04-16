import 'package:burma/Dashboard/Dashboard.dart';
import 'package:burma/Products/ProductDetails.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:localstorage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Common/colors.dart' as custom_color;

class Favourites extends StatefulWidget {
  const Favourites({super.key});

  @override
  State<Favourites> createState() => _FavouritesState();
}

class _FavouritesState extends State<Favourites> {

  final LocalStorage storage = LocalStorage('app_store');

  late SharedPreferences pref;

  bool isLoading = false;
  var userResponse;
  var accesstoken;
  var customer_id;
  List favorites_list = [];
  String sizeText = "";
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
    final box = await Hive.openBox('favorites_list');

  List<dynamic> favList = box.get('favorites', defaultValue: []);

  setState(() {
    favorites_list = favList.map((e) => e['product_data']).toList();
  });

  print(favorites_list);

  }

  Future<void> removeFavorite(String variantId) async {

  final box = await Hive.openBox('favorites_list');

  List<dynamic> favList = box.get('favorites', defaultValue: []);

  favList.removeWhere(
    (item) => item['product_variant_id'].toString() == variantId
  );

  await box.put('favorites', favList);

  setState(() {
    favorites_list = favList.map((e) => e['product_data']).toList();
  });

}
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        Navigator.push(context, MaterialPageRoute(builder: (context)=>Dashboard()));
      },
      child: Scaffold(
         appBar: AppBar(
        backgroundColor: custom_color.app_color,
        title: const Text("Favourites", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => Dashboard()));
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
            : favorites_list.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/AppLogo.png",
                  height: 120,
                ),
                const SizedBox(height: 10),
                const Text(
                  "No Favourites Yet",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Start adding products to favourites ❤️",
                ),
              ],
            ),
          )
          : GridView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: favorites_list.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: .65,
              ),
              itemBuilder: (context, index) {

                var p = favorites_list[index];

                var variant = (p['vars'] != null && p['vars'].length > 0)
                    ? p['vars'][0]
                    : null;

if (variant != null && variant['size'] != null) {
  sizeText = variant['size'].toString().split(',')[0].trim();
}
                return buildProductCard(p, variant);
              },
            ),
      ),
    );
  }

Widget buildProductCard(var p, var variant) {
  String variantId =
    variant != null ? variant['product_variant_id'].toString() : "";

// int qty = cartQty[variantId] ?? 0;
  return InkWell(
    
    onTap: ()async {
       await storage.setItem('favourites_page',"favourites_page");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Productdetails(selected_data: p,selecteddata_title:"",),
        ),
      );
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
     Align(
        alignment: Alignment.topRight,
        child: GestureDetector(
          onTap: () async{
            // removeFavorite(variantId);
             bool? confirm = await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Remove Favourite"),
        content: const Text("Are you sure you want to remove this item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Remove"),
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    removeFavorite(variantId);
  }
          },
          child: const Icon(
            Icons.favorite,
            color: Colors.red,
            size: 20,
          ),
        ),
     ),
            /// PRODUCT IMAGE
            // Expanded(
            //   child: Center(
            //     child: safeNetworkImage(
            //       p['prod_img'],
            //       fit: BoxFit.contain,
            //     ),
            //   ),
            // ),
    SizedBox(
  height: MediaQuery.of(context).size.width * 0.24,
  width: double.infinity,
  child: safeNetworkImage(
    p['prod_img'],
    fit: BoxFit.contain,
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
          //  SizedBox(height: 1),
            // if (variant != null)
            //   Text(
            //     variant['size'] ?? "",
            //     maxLines: 1,
            //     overflow: TextOverflow.ellipsis,
            //     style: const TextStyle(
            //       fontSize: 11,
            //       color: Colors.grey,
            //     ),
            //   ),
            if (sizeText.isNotEmpty)
              Text(
                'Size : ${sizeText}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ) else  Text(
                '',
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
    
            SizedBox(
  width: double.infinity,
  height: 34,
  child: 
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
  //       )
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
        )
         : ElevatedButton(
              onPressed: () async{
                // updateCart(variantId, 1);
                await storage.setItem('favourites_page',"favourites_page");
                 Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Productdetails(selected_data: p,selecteddata_title:"",),
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