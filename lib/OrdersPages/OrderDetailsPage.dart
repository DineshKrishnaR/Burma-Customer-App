import 'package:burma/OrdersPages/OrdersApi.dart';
import 'package:burma/Settings/AboutApi.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Common/colors.dart' as custom_color;

class Orderdetailspage extends StatefulWidget {
  final orderData;
  const Orderdetailspage({super.key, required this.orderData});

  @override
  State<Orderdetailspage> createState() => _OrderdetailspageState();
}

class _OrderdetailspageState extends State<Orderdetailspage> {
  final LocalStorage storage = LocalStorage('app_store');

  late SharedPreferences pref;

  bool isLoading = false;
  var userResponse;
  var accesstoken;
  var customer_id;

  List view_details = [];
  var invoice;
 
  var selected_data;
  var contacy_us;

  double promo = 0;
  double wallet = 0;
  @override
  void initState() {
    super.initState();
    initPreferencess();
  }

  initPreferencess() async {

    await storage.ready;

    pref = await SharedPreferences.getInstance();

    userResponse = await storage.getItem('userResponse');
    selected_data = widget.orderData;

    if (userResponse != null) {

      accesstoken = userResponse['api_token'];

      customer_id = userResponse['customer_id'].toString();
    }

    await getOrdersDetails();
    await getInvoice();
    await ContactUs();
  }

  Future<void> getOrdersDetails() async {

    setState(() => isLoading = true);

    var data = {
      "action": "get_order_info",
      "customer_id": customer_id,
      "orders_id" : selected_data['orders_id'],
      "accesskey": "90336",
      "act_type": userResponse['act_type'],
      "token": accesstoken,
    };

    final response = await Ordersapi().getOrdersDetails(data);

    if (response != null) {
      view_details = response['res'] ?? [];
    }

    setState(() => isLoading = false);
  }

  Future<void> getInvoice() async {

    setState(() => isLoading = true);

    var data = {
      "action": "get_invoice",
      // "customer_id": customer_id,
      "customer_id": "3",
      "orders_id" : selected_data['orders_id'],
      "accesskey": "90336",
      "act_type": userResponse['act_type'],
      "token": accesstoken,
    };

    final response = await Ordersapi().getInvoice(data);

    if (response != null) {
      invoice = response['invoice'] ?? [];
    }

    setState(() => isLoading = false);
  }

  Future<void> ContactUs() async {
    setState(() => isLoading = true);
        var data = {
              "action": "contact_us",
              "accesskey":"90336",
              "token":accesstoken,
              "customer_id":customer_id,
              "act_type":userResponse['act_type'],
        };
    final response = await Aboutapi().ContactUs(data);

    print(response);

    if(response != null){
      contacy_us = response ?? [];
   

    setState(() => isLoading = false);
  }else{
    contacy_us = [];
  }
    setState(() => isLoading = false);
 }bool isStepDone(String current, String step) {
  List flow = ["Received", "Processed", "Shipped", "Delivered"];

  int currentIndex = flow.indexOf(current);
  int stepIndex = flow.indexOf(step);

  return currentIndex >= stepIndex;
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
      return "Delivered"; // keep same as orders page
    default:
      return "Received";
  }
}
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
  String currentStatus = "received";

if (view_details.isNotEmpty) {
  currentStatus = getStatusFromId(
      view_details[0]['order_status_id'].toString());
}

if (view_details.isNotEmpty) {
  promo = double.tryParse(
    view_details[0]['promo_disc_amt']?.toString() ?? "0"
  ) ?? 0;

  wallet = double.tryParse(
    view_details[0]['wallet_balance']?.toString() ?? "0"
  ) ?? 0;
}
var img = (view_details.isNotEmpty &&
        view_details[0]['order_dtl'] != null &&
        view_details[0]['order_dtl'].isNotEmpty)
    ? view_details[0]['order_dtl'][0]['img'] ?? ""
    : "";
    var name = (view_details.isNotEmpty &&
        view_details[0]['order_dtl'] != null &&
        view_details[0]['order_dtl'].isNotEmpty)
    ? view_details[0]['order_dtl'][0]['name'] ?? ''
    : '';
    return Scaffold(
         appBar: AppBar(
        backgroundColor: custom_color.app_color,
        title: const Text("View Details", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
    ? Center(child: CircularProgressIndicator(color: custom_color.app_color))
    : view_details.isEmpty
        ? const Center(child: Text("No Details Found"))
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "Order ID : ${view_details[0]['orders_id']}",
                    style: const TextStyle(fontSize: 16,fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "Ordered Date : ${view_details[0]['created_date']}",
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const Divider(height: 30),

                  /// PRODUCT DETAILS
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        // child: Image.network(
                        //   // view_details[0]['order_dtl'][0]['img'],
                        //   img,
                        //   width: 90,
                        //   height: 90,
                        //   fit: BoxFit.cover,
                        // ),
                        child: safeNetworkImage(img, fit: BoxFit.cover),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              // view_details[0]['order_dtl'][0]['name'] ?? '',
                              name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),

                            const SizedBox(height: 5),

                            Text(
                                // "Quantity : ${view_details[0]['order_dtl'][0]['qty'] ?? 0}"
                                 "Quantity : ${(
    view_details.isNotEmpty &&
    view_details[0]['order_dtl'] != null &&
    view_details[0]['order_dtl'].isNotEmpty
  )
      ? view_details[0]['order_dtl'][0]['qty'] ?? 0
      : 0}"
                                ),

                            const SizedBox(height: 5),

                            Text(
                              "Rs.${view_details[0]['final_amt']}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
    
                              if (promo > 0)
                                priceRow("Promo Applied", "- Rs.$promo"),

                              if (wallet > 0)
                                priceRow("Wallet Used", "- Rs.$wallet"),
                            const SizedBox(height: 5),

                            Text(
                              "Via Online Payment",
                              style: TextStyle(
                                  color: custom_color.app_color,
                                  fontWeight: FontWeight.w600),
                            ),

                            const SizedBox(height: 5),

                            Row(
                              children: [

                                const Text("Payment Status : "),

                                Text(
                                  view_details[0]['pay_status'],
                                  style: TextStyle(
                                      color: view_details[0]['pay_status'] == "Pending"
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),

                            const SizedBox(height: 5),

                            Text(
                              // view_details[0]['order_dtl'][0]['order_status'],
                               "${(
    view_details.isNotEmpty &&
    view_details[0]['order_dtl'] != null &&
    view_details[0]['order_dtl'].isNotEmpty
  )
      ? view_details[0]['order_dtl'][0]['order_status'] ?? ''
      : ''}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// ORDER TRACKER
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [

                  //     orderStep("Order Placed", true),

                  //     orderLine(),

                  //     orderStep("Processed", false),

                  //     orderLine(),

                  //     orderStep("Shipped", false),

                  //     orderLine(),

                  //     orderStep("Delivered", false),
                  //   ],
                  // ),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   children: [

                      //     orderStep("Received",
                      //         isStepDone(currentStatus, "Received")),
                      //     orderLine(),

                      //     orderStep("Processed",
                      //         isStepDone(currentStatus, "Processed")),
                      //     orderLine(),

                      //     orderStep("Shipped",
                      //         isStepDone(currentStatus, "Shipped")),
                      //     orderLine(),

                      //     orderStep("Delivered",
                      //         isStepDone(currentStatus, "Delivered")),
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
                  const SizedBox(height: 5),

                  Text(view_details[0]['created_date'],style: const TextStyle(color: Colors.grey)),

                  const SizedBox(height: 20),

                  const Divider(thickness: 2),

                  const SizedBox(height: 10),

                  /// PRICE DETAILS
                  const Text("Price Details :",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16)),

                  const SizedBox(height: 10),

                  priceRow("Item Price", "Rs.${view_details[0]['tot_amt']}"),

                  priceRow("Delivery Charge", "+ Rs.${view_details[0]['delivery_charge']}"),

                  priceRow("Discount", "- Rs.${view_details[0]['disc_amt']}"),

                  priceRow("Promo Applied", "- Rs.${view_details[0]['promo_disc_amt']}"),

                  priceRow("Wallet Balance", "- Rs.${view_details[0]['wallet_balance']}"),

                  const Divider(),

                  priceRow(
                    "Final Total",
                    "Rs.${view_details[0]['final_amt']}",
                    isBold: true,
                  ),

                  const SizedBox(height: 20),

                  const Divider(thickness: 2),

                  const SizedBox(height: 10),

                  /// OTHER DETAILS
                  const Text("Other Details :",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16)),

                  const SizedBox(height: 10),

                  Text("Name : ${view_details[0]['name']}"),

                  const SizedBox(height: 5),

                  Text("Mobile No : ${view_details[0]['mobile']}"),

                  const SizedBox(height: 5),

                  Text(
                    "Address : ${view_details[0]['customer_address']}",
                    style: const TextStyle(color: Colors.grey),
                  ),

                  SizedBox(height: 20),
                  Divider(thickness: 2,color: Colors.grey.shade300),

                  SizedBox(height: 15),

                  Center(
                    child: Container(
                      //  width: screenWidth*0.40,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: custom_color.button_color,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                           downloadInvoice();
                        },
                        icon: const Icon(Icons.download,color: Colors.white),
                        label: const Text("Download Invoice",style: TextStyle(color: Colors.white),),
                      ),
                    ),
                  ),
                  SizedBox(height: 10,),
                  /// BUTTONS
                   Center(
                     child: Container(
                      width: screenWidth*0.48,
                       child: ElevatedButton(
                         style: ElevatedButton.styleFrom(
                           backgroundColor: custom_color.button_color,
                           padding: const EdgeInsets.symmetric(vertical: 14),
                         ),
                         onPressed: () async{
                            String phone = contacy_us?['mobile'] ?? "";
                       
                             if (phone.isNotEmpty) {
                               final Uri url = Uri(scheme: 'tel', path: phone);
                       
                               if (await canLaunchUrl(url)) {
                                 await launchUrl(url);
                               } else {
                                 print("Cannot open dialer");
                               }
                             }
                         },
                         child: const Text("Cancel Order",style: TextStyle(color: Colors.white),),
                       ),
                     ),
                   ),
                  // Row(
                  //   children: [
                  //     Expanded(
                        
                  //       child: ElevatedButton(
                  //         style: ElevatedButton.styleFrom(
                  //           backgroundColor: custom_color.button_color,
                  //           padding: const EdgeInsets.symmetric(vertical: 14),
                  //         ),
                  //         onPressed: () async{
                  //            String phone = contacy_us?['mobile'] ?? "";

                  //             if (phone.isNotEmpty) {
                  //               final Uri url = Uri(scheme: 'tel', path: phone);

                  //               if (await canLaunchUrl(url)) {
                  //                 await launchUrl(url);
                  //               } else {
                  //                 print("Cannot open dialer");
                  //               }
                  //             }
                  //         },
                  //         child: const Text("Cancel Order",style: TextStyle(color: Colors.white),),
                  //       ),
                  //     ),

                  //     const SizedBox(width: 10),

                  //     Expanded(
                  //       child: ElevatedButton(
                  //         style: ElevatedButton.styleFrom(
                  //           backgroundColor: custom_color.button_color,
                  //           padding: const EdgeInsets.symmetric(vertical: 14),
                  //         ),
                  //         onPressed: () {},
                  //         child: const Text("Tracking Details",style: TextStyle(color: Colors.white),),
                  //       ),
                  //     ),
                  //   ],
                  // ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
      );
  }
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
          fontSize: 11,
          color: isCancelled ? Colors.red : Colors.black,
        ),
      )
    ],
  );
}

Widget orderLine() {
  return Expanded(
    child: Divider(
      color: Colors.grey.shade400,
      thickness: 1,
    ),
  );
}

Widget priceRow(String title,String value,{bool isBold=false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        )),
        Text(value,style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: isBold ? Colors.green : Colors.black,
        )),
      ],
    ),
  );
}
Future<void> downloadInvoice() async {

  if (invoice == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Invoice not available")),
    );
    return;
  }

  final Uri url = Uri.parse(invoice);

  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not open invoice');
  }
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