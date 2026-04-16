import 'package:burma/Dashboard/Dashboard.dart';
import 'package:burma/OrdersPages/OrderDetailsPage.dart';
import 'package:burma/OrdersPages/OrdersApi.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Common/colors.dart' as custom_color;

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {

  final LocalStorage storage = LocalStorage('app_store');

  late SharedPreferences pref;

  bool isLoading = false;
  var userResponse;
  var accesstoken;
  var customer_id;

  List orders_list = [];

  String selectedTab = "All";

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

    await getOrders();
  }

  Future<void> getOrders() async {

    setState(() => isLoading = true);

    var data = {
      "action": "get_orders",
      "customer_id": customer_id,
      "accesskey": "90336",
      "act_type": userResponse['act_type'],
      "token": accesstoken,
    };

    final response = await Ordersapi().getOrders(data);

    if (response != null) {
      orders_list = response['res'] ?? [];
    }

    setState(() => isLoading = false);
  }

  /// FILTER ORDERS
  // List getFilteredOrders() {

  //   if (selectedTab == "All") return orders_list;

  //   if (selectedTab == "In Process") {
  //     return orders_list.where((order) {
  //       return order['order_dtl'][0]['order_status'] == "Received" ||
  //           order['order_dtl'][0]['order_status'] == "Processed";
  //     }).toList();
  //   }

  //   if (selectedTab == "Shipped") {
  //     return orders_list.where((order) {
  //       return order['order_dtl'][0]['order_status'] == "Shipped";
  //     }).toList();
  //   }

  //   if (selectedTab == "Delivered") {
  //     return orders_list.where((order) {
  //       return order['order_dtl'][0]['order_status'] == "Delivered";
  //     }).toList();
  //   }
  //    if (selectedTab == "Cancelled") {
  //     return orders_list.where((order) {
  //       return order['order_dtl'][0]['order_status'] == "Cancelled";
  //     }).toList();
  //   }

  //   return orders_list;
  // }
List getFilteredOrders() {
  if (selectedTab == "All") return orders_list;

  return orders_list.where((order) {
    String status = getStatusFromId(order['order_status_id']);

    if (selectedTab == "In Process") {
      return status == "Received" || status == "Processed";
    }

    if (selectedTab == "Shipped") {
      return status == "Shipped";
    }

    if (selectedTab == "Delivered") {
      return status == "Delivered";
    }

    if (selectedTab == "Cancelled") {
      return status == "Cancelled";
    }

    return true;
  }).toList();
}
String getStatusFromId(String id) {
  switch (id) {
    case "1":
      return "Received";
    case "2":
      return "Processed";
    case "3":
      return "Shipped";
    case "4":
      return "Delivered";
    case "5":
      return "Cancelled";
    case "7":
      return "Delivered"; // based on your API
    default:
      return "Received";
  }
}
  @override
  Widget build(BuildContext context) {
    
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
bool isStepDone(String current, String step) {
  List flow = ["Received", "Processed", "Shipped", "Delivered"];

  int currentIndex = flow.indexOf(current);
  int stepIndex = flow.indexOf(step);

  return currentIndex >= stepIndex;
}

    return Scaffold(

      appBar: AppBar(
        backgroundColor: custom_color.app_color,
        title: const Text("Track Order", style: TextStyle(color: Colors.white)),
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
            CircularProgressIndicator(color: custom_color.app_color),
          ],
        ),
      )
          : Column(
        children: [
          
          /// STATUS TABS
          orderTabs(),

          Expanded(
            
            child: getFilteredOrders().isEmpty
                ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/AppLogo.png", // ✅ add image
              height: 120,
            ),
            const SizedBox(height: 15),
            const Text(
              "No Orders Found",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "You haven’t placed any orders yet",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
                : ListView.builder(

              padding: const EdgeInsets.all(12),

              itemCount: getFilteredOrders().length,

              itemBuilder: (context, index) {

                var order = getFilteredOrders()[index];
                // var product = order['order_dtl'][0];
                var product = (order['order_dtl'] != null &&
                    order['order_dtl'] is List &&
                    order['order_dtl'].isNotEmpty)
                ? order['order_dtl'][0]
                : {};
                // String currentStatus =
                //     (product['order_status'] ?? "Received").toString();
                String currentStatus = getStatusFromId(order['order_status_id']);

                // Fix lowercase
                currentStatus =
                    currentStatus[0].toUpperCase() + currentStatus.substring(1);
                    double promo = double.tryParse(order['promo_disc_amt'].toString()) ?? 0;
double wallet = double.tryParse(order['wallet_balance'].toString()) ?? 0;
                return Column(
                  children: [

                    /// ORDER CARD
                    Card(
                      color: Colors.white,
                      elevation: 3,

                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),

                      child: Padding(
                        padding: const EdgeInsets.all(12),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            /// HEADER
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,

                              children: [

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                    children: [

                                      Text(
                                        "Order ID : ${order['orders_id']}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),

                                      Text(
                                        "Ordered Date : ${order['created_date']}",
                                        style: const TextStyle(
                                            color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    custom_color.button_color,
                                  ),
                                  onPressed: () {
                                    print(order);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Orderdetailspage(orderData: order),
                                      ),
                                    );
                                  },

                                  child: const Text("View Details",style: TextStyle(color: Colors.white),),
                                )
                              ],
                            ),

                            const Divider(height: 25),

                            /// PRODUCT ROW
                            Row(
                              children: [

                                ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(8),

                                  // child: Image.network(
                                  //   product['img'],
                                  //   width: screenWidth * .22,
                                  //   height: screenWidth * .22,
                                  //   fit: BoxFit.cover,
                                  // ),
                                   child: safeNetworkImage(product['img'], fit: BoxFit.cover),
                                  
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                    children: [

                                      Text(
                                        // product['name'],
                                        product['name']?.toString() ?? "No Product",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                          "Quantity : ${product['qty']}"),

                                      const SizedBox(height: 4),

                                      Text(
                                        "Rs.${order['final_amt']}",
                                        style: const TextStyle(
                                            fontWeight:
                                            FontWeight.bold),
                                      ),
if (promo > 0)
  Text("Promo: - Rs.$promo",
      style: TextStyle(color: Colors.green, fontSize: 12)),

if (wallet > 0)
  Text("Wallet: - Rs.$wallet",
      style: TextStyle(color: Colors.green, fontSize: 12)),
                                      const SizedBox(height: 4),

                                      Text(
                                        "Via Online Payment",
                                        style: TextStyle(
                                            color: custom_color.app_color,
                                            fontWeight:
                                            FontWeight.w600),
                                      ),

                                      const SizedBox(height: 4),

                                      Row(
                                        children: [

                                          Text(
                                              "Payment Status : "),
                                          Text(
                                            order['pay_status'],
                                            style: TextStyle(
                                              color: order['pay_status'] ==
                                                  "Pending"
                                                  ? Colors.red
                                                  : Colors.green,
                                              fontWeight:
                                              FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 4),

                                      Text(
                                        // product['order_status'],
                                        product['order_status']?.toString() ?? "",
                                        style: const TextStyle(
                                            color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),

                    /// TRACKING CARD
                    Card(
                      color: Colors.white,
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),

                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),

                      child: Padding(
                        padding: const EdgeInsets.all(12),

                        child: Column(
                          children: [

                            // Row(
                            //   mainAxisAlignment:
                            //   MainAxisAlignment.spaceBetween,

                            //   children: [

                            //     orderStep("Order Placed", true),

                            //     orderLine(),

                            //     orderStep("Processed", false),

                            //     orderLine(),

                            //     orderStep("Shipped", false),

                            //     orderLine(),

                            //     orderStep("Delivered", false),
                            //     orderLine(),

                            //     orderStep("Cancelled", false),
                            //   ],
                            // ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                orderStep("Received", isStepDone(currentStatus, "Received")),
                                orderLine(),
                                orderStep("Processed", isStepDone(currentStatus, "Processed")),
                                orderLine(),
                                orderStep("Shipped", isStepDone(currentStatus, "Shipped")),
                                orderLine(),
                                orderStep("Delivered", isStepDone(currentStatus, "Delivered")),
                                if (currentStatus == "Cancelled") ...[
                                  orderLine(),
                                  orderStep("Cancelled", true),
                                ]
                              ],
                            ),
                            const SizedBox(height: 8),

                            Align(
                              alignment: Alignment.centerLeft,

                              child: Text(
                                order['created_date'],
                                style: const TextStyle(
                                    color: Colors.grey),
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }

  /// STEP ICON
  // Widget orderStep(String title, bool done) {

  //   return Column(
  //     children: [

  //       Container(
  //         height: 22,
  //         width: 22,

  //         decoration: BoxDecoration(
  //           shape: BoxShape.circle,

  //           border: Border.all(
  //               color: done ? Colors.teal : Colors.grey, width: 2),

  //           color: done ? Colors.teal : Colors.white,
  //         ),
  //       ),

  //       const SizedBox(height: 4),

  //       Text(title, style: const TextStyle(fontSize: 10))
  //     ],
  //   );
  // }
Widget orderStep(String title, bool done) {

  bool isCancelled = title == "Cancelled";

  return Column(
    children: [

      Container(
        height: 22,
        width: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isCancelled
                ? Colors.red
                : done
                    ? Colors.teal
                    : Colors.grey,
            width: 2,
          ),
          color: isCancelled
              ? Colors.red
              : done
                  ? Colors.teal
                  : Colors.white,
        ),
      ),

      const SizedBox(height: 4),

      Text(
        title,
        style: TextStyle(
          fontSize: 10,
          color: isCancelled ? Colors.red : Colors.black,
        ),
      )
    ],
  );
}
  Widget orderLine() {
    return Expanded(
      child: Divider(color: Colors.grey.shade400, thickness: 1),
    );
  }

  /// TOP TABS
  Widget orderTabs() {

    List tabs = ["All", "In Process", "Shipped", "Delivered", "Cancelled"];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 45,
      
        child: ListView.builder(
      
          scrollDirection: Axis.horizontal,
      
          itemCount: tabs.length,
      
          itemBuilder: (context, index) {
      
            bool isSelected = selectedTab == tabs[index];
      
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedTab = tabs[index];
                });
              },
      
              child: Container(
      
                margin: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 8),
      
                padding:
                const EdgeInsets.symmetric(horizontal: 18),
      
                alignment: Alignment.center,
      
                decoration: BoxDecoration(
      
                  color: isSelected
                      ? custom_color.app_color
                      : Colors.grey.shade300,
      
                  borderRadius: BorderRadius.circular(20),
                ),
      
                child: Text(
                  tabs[index],
      
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
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
  double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
  // Fix double slashes in URL
  String cleanUrl = (url ?? "").replaceAll(RegExp(r'(?<!:)//+'), '/');
  
  // Check if URL is valid
  if (cleanUrl.isEmpty || !cleanUrl.startsWith('http')) {
    return SizedBox(
       width: screenWidth * .22,
         height: screenWidth * .22,
      child: Image.asset(
        "assets/images/AppLogo.png",
        // width: 90,
        // height: 90,
        // fit: BoxFit.contain,
         width: screenWidth * .22,
         height: screenWidth * .22,
         fit: BoxFit.cover,
      ),
    );
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: SizedBox(
       width: screenWidth * .22,
         height: screenWidth * .22,
      child: Image.network(
        cleanUrl,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: Image.asset(
              "assets/images/AppLogo.png",
              width: screenWidth * .22,
         height: screenWidth * .22,
         fit: BoxFit.cover,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            width: width,
            height: height,
            child: Image.asset(
              "assets/images/AppLogo.png",
              width: screenWidth * .22,
         height: screenWidth * .22,
         fit: BoxFit.cover,
            ),
          );
        },
      ),
    ),
  );
}
}