import 'dart:convert';

import 'package:burma/CartPages/CartApi.dart';
import 'package:burma/CartPages/PaymentFailedScreen.dart';
import 'package:burma/CartPages/PaymentSuccessScreen.dart';
import 'package:burma/Dashboard/DashboardApi.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:localstorage/localstorage.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Common/colors.dart' as custom_color;
import 'Cart.dart';

class Checkout extends StatefulWidget {

  final Map userDetails;
  final List cartData;
  final double deliveryCharge;
  final double gstPercent;
  final double totalAmount;

  const Checkout({
    super.key,
    required this.userDetails,
    required this.cartData,
    required this.deliveryCharge,
    required this.gstPercent,
    required this.totalAmount,
  });

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {

  TextEditingController promoController = TextEditingController();
  final LocalStorage storage = LocalStorage('app_store');
  var userResponse;
  var accesstoken;
  bool isLoading = false;
  late SharedPreferences pref;
  var customer_id;
  var wallet_amount;
  bool useWallet = false;
  double walletUsed = 0;
  var Razorpay_Details;
  late Razorpay _razorpay;
  String orderId = "";
  double finalAmount = 0;
  bool isPaying = false;
  bool isProcessingPayment = false;

  double discountAmount = 0;
  bool couponApplied = false;
  String appliedCoupon = "";
  double walletBalance = 0;
  double totalTax = 0;
  @override
  void initState() {
    super.initState();
     isPaying = false;
  isProcessingPayment = false;
    _razorpay = Razorpay();

  _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
  _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    initPreferences();
  }
@override
void dispose() {
  _razorpay.clear();
  super.dispose();
}
  initPreferences() async {
    pref = await SharedPreferences.getInstance();
    await storage.ready;
    userResponse = await storage.getItem('userResponse');
   
    if (userResponse != null) {
      accesstoken = userResponse['api_token'];
      customer_id = userResponse['customer_id'].toString();

    }
    
    await WalletDetails();
  }

 Future<void> WalletDetails() async {
    setState(() => isLoading = true);
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
   
      walletBalance =
    double.tryParse(wallet_amount['amount'].toString()) ?? 0;
    setState(() => isLoading = false);
  }
 }
 late BuildContext rootContext;
  @override
  Widget build(BuildContext context) {
rootContext = context;
    // double subTotal = widget.totalAmount;

    // double gst = (subTotal * widget.gstPercent) / 100;

    // double finalTotal = subTotal + gst + widget.deliveryCharge;

// double subTotal = 0;
// double productGST = 0;

// /// Calculate product subtotal + product GST
// for (var item in widget.cartData) {

//   double price = double.parse(item['discounted_price'].toString());
//   int qty = int.parse(item['qty'].toString());
//   double gstPercent = double.parse(item['gst_percentage'].toString());

//   double itemTotal = price * qty;

//   double itemGST = (itemTotal * gstPercent) / 100;

//   subTotal += itemTotal;
//   productGST += itemGST;
// }
double subTotalExcl = 0;
double productGST = 0;

for (var item in widget.cartData) {

  double amt = double.tryParse(item['amt'].toString()) ?? 0;
  double gstPercent = double.tryParse(item['gst_percentage'].toString()) ?? 0;

  double basePrice = 0;
  double gstAmount = 0;

  if (item['gst_enabled'] == "1" && gstPercent > 0) {

    /// ✅ CORRECT LOGIC (same as cart)
    basePrice = amt / (1 + gstPercent / 100);
    gstAmount = amt - basePrice;

  } else {
    basePrice = amt;
  }

  subTotalExcl += basePrice;
  productGST += gstAmount;
}

/// ✅ FINAL VALUES
double subTotal = subTotalExcl + productGST;
/// Delivery GST calculation
double deliveryBase = widget.deliveryCharge;
double deliveryGST = 0;

if (widget.gstPercent > 0) {
  deliveryBase = widget.deliveryCharge / (1 + widget.gstPercent / 100);
  deliveryGST = widget.deliveryCharge - deliveryBase;
}
 totalTax = productGST + deliveryGST;
/// Final total
// double finalTotal =
//     subTotal + productGST + widget.deliveryCharge;

// double finalTotal =
//     subTotal + productGST + widget.deliveryCharge - discountAmount;
double finalTotal =
    subTotal + widget.deliveryCharge - discountAmount;
    // double walletBalance = 0;

if (wallet_amount != null) {
  walletBalance = double.tryParse(wallet_amount['amount'].toString()) ?? 0;
}

// if (useWallet) {
//   walletUsed = walletBalance >= finalTotal ? finalTotal : walletBalance;
//   finalTotal = finalTotal - walletUsed;
// } 

if (useWallet) {

  double maxWalletUse = finalTotal;

  walletUsed = walletBalance >= maxWalletUse
      ? maxWalletUse
      : walletBalance;

  // Extra safety (IMPORTANT)
  if (walletUsed > finalTotal) {
    walletUsed = finalTotal;
  }

  finalTotal = finalTotal - walletUsed;
}
else {
  walletUsed = 0;
}
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context)=>const Cart(selected_data : '',selecteddata_title: "",)));
      },

      child: Scaffold(

        appBar: AppBar(
          backgroundColor: custom_color.app_color,
          title: const Text("Check Out",
              style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: Colors.white),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context)=>const Cart(selected_data: '',selecteddata_title: "",)));
            },
          ),
        ),

        body: SingleChildScrollView(
          child: Column(
            children: [

              /// DELIVERY ADDRESS
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Delivery Address",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const SizedBox(width: 80, child: Text("Name",style: TextStyle(fontWeight: FontWeight.bold),)),
                        Text(widget.userDetails['name'] ?? ""),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 80, child: Text("Address",style: TextStyle(fontWeight: FontWeight.bold),)),
                        Expanded(
                          child: Text(
                            "${widget.userDetails['address']}, ${widget.userDetails['address2']}\n"
                            "${widget.userDetails['city']}, ${widget.userDetails['state']}\n"
                            "${widget.userDetails['pin']}",
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        const SizedBox(width: 80, child: Text("Mobile",style: TextStyle(fontWeight: FontWeight.bold),)),
                        Text(widget.userDetails['mobile'] ?? ""),
                      ],
                    ),

                  ],
                ),
              ),

              /// PROMO CODE
              Container(
                margin: const EdgeInsets.symmetric(horizontal:16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Have a Promo Code?",
                      style: TextStyle(
                        fontSize:20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(height:12),

                    Row(
                      children: [

                        Expanded(
                          child: TextField(
                            controller: promoController,
                            decoration: InputDecoration(
                              hintText: "Enter the promo code",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(30),
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
                        ),

                        const SizedBox(width:10),

                        // ElevatedButton(
                        //   style: ElevatedButton.styleFrom(
                        //     // backgroundColor:
                        //     // custom_color.button_color,
                        //     backgroundColor: couponApplied
                        //     ? Colors.grey // disabled color
                        //     : custom_color.button_color,

                        //   ),
                        //   onPressed:couponApplied  ? null : () async{
                        //      applyCoupon(finalTotal);
                        //   },
                        //   child:  Text(
                        //     // "APPLY",
                        //     couponApplied ? "APPLIED" : "APPLY",
                        //       style: TextStyle(
                        //           color: Colors.white)),
                        // )
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: couponApplied
                                  ? Colors.grey
                                  : custom_color.button_color,
                            ),
                            onPressed: couponApplied
                                ? null
                                : () async {
                                    await applyCoupon(finalTotal);
                                  },
                            child: Text(
                              couponApplied ? "APPLIED" : "APPLY",
                              style: const TextStyle(color: Colors.white),
                            ),
                          )
                      ],
                    )

                  ],
                ),
              ),

              const SizedBox(height:16),

              /// ORDER SUMMARY
              Container(
                margin: const EdgeInsets.symmetric(horizontal:16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Order Summary",
                      style: TextStyle(
                        fontSize:22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(height:20),

                    const Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Product Name",
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),
                        Text("Qty",
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),
                        Text("Price",
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),
                        Text("Sub Total",
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),
                      ],
                    ),

                    const Divider(),

                    Column(
                      children: widget.cartData.map((item) {

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),

                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              /// PRODUCT NAME
                              Expanded(
                                flex: 4,
                                child: Text(
                                  "${item['product_name']} ${item['size']}",
                                  style: const TextStyle(fontSize: 14),
                                  softWrap: true,
                                ),
                              ),

                              const SizedBox(width: 10),

                              /// QTY
                              SizedBox(
                                width: 35,
                                child: Text(
                                  item['qty'].toString(),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              /// PRICE
                              SizedBox(
                                width: 70,
                                child: Text(
                                  "Rs.${item['discounted_price']}",
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              /// SUBTOTAL
                              SizedBox(
                                width: 80,
                                child: Text(
                                  "Rs.${item['amt']}",
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );

                      }).toList(),
                    ),
                     Divider(),

                    // priceRow("Sub Total", "Rs.${subTotal.toStringAsFixed(2)}"),
                    // priceRow("GST (${widget.gstPercent}%)",
                    //     "Rs.${gst.toStringAsFixed(2)}"),
                    // priceRow("Delivery Charge",
                    //     "Rs.${widget.deliveryCharge}"),
                    // priceRow("Sub Total", "Rs.${subTotal.toStringAsFixed(2)}"),

                    // priceRow("Product GST",
                    //     "Rs.${productGST.toStringAsFixed(2)}"),

                    priceRow("Items Amount", "Rs.${subTotalExcl.toStringAsFixed(2)}"),
priceRow("Product GST", "Rs.${productGST.toStringAsFixed(2)}"),
priceRow("Items Total", "Rs.${subTotal.toStringAsFixed(2)}"),

                    priceRow("Delivery Charge + ",
                        "Rs.${deliveryBase.toStringAsFixed(2)}"),

                    priceRow("Delivery GST",
                        "Rs.${deliveryGST.toStringAsFixed(2)}"),

                    if(useWallet)
                    // priceRow("Wallet Used","Rs.${walletUsed.toStringAsFixed(2)}"),   
                    priceRow("Wallet Used","- Rs.${walletUsed.toStringAsFixed(2)}"),

                    // if (couponApplied)
                    if (appliedCoupon.isNotEmpty)
                    priceRow(
                      "Coupon ($appliedCoupon)",
                      "- Rs.${discountAmount.toStringAsFixed(2)}",
                    ), 

                  ],
                ),
              ),

               SizedBox(height:16),
/// WALLET BALANCE
Container(
  margin: const EdgeInsets.symmetric(horizontal: 16),
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
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Text(
        "Wallet Balance :",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),

      const SizedBox(height: 16),

      Row(
        children: [

          Icon(Icons.account_balance_wallet,
              color: custom_color.app_color, size: 30),

          const SizedBox(width: 10),

           Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  "Wallet Balance :",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),

                SizedBox(height: 4),

                Text(
                 "Total Balance : Rs ${wallet_amount?['amount'] ?? 0}",
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),

          Checkbox(
            value: useWallet,
            activeColor: custom_color.app_color,
            onChanged: (value) {
              setState(() {
                useWallet = value!;
              });
            },
          )

        ],
      )

    ],
  ),
),
/// PAYMENT METHOD
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
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Text(
        "Payment Method",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),

      const SizedBox(height: 16),

      Row(
        children: [

          Icon(Icons.payments,
              color: custom_color.app_color,
              size: 32),

          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              "Online Payment",
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ),

          Radio(
            value: 1,
            groupValue: 1,
            onChanged: (value) {},
            activeColor: custom_color.app_color,
          )

        ],
      )

    ],
  ),
),
              /// TOTAL + PROCEED
              // Container(
              //   padding: const EdgeInsets.all(16),

              //   child: Row(
              //     mainAxisAlignment:
              //     MainAxisAlignment.spaceBetween,
              //     children: [

              //       Text(
              //         "Total : Rs.${finalTotal.toStringAsFixed(2)}",
              //         style: const TextStyle(
              //             fontSize:22,
              //             fontWeight: FontWeight.bold),
              //       ),

              //       ElevatedButton(
              //         style: ElevatedButton.styleFrom(
              //           backgroundColor:
              //           custom_color.app_color,
              //           padding: const EdgeInsets.symmetric(
              //               horizontal:30,vertical:14),
              //         ),
              //         onPressed: () {
              //           showConfirmDialog(finalTotal);
              //         },
              //         child: const Text(
              //           "Proceed",
              //           style: TextStyle(
              //               color: Colors.white,
              //               fontSize:16),
              //         ),
              //       )

              //     ],
              //   ),
              // )
              
            ],
          ),
        ),
           bottomNavigationBar: Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 10,
        offset: Offset(0, -2),
      )
    ],
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [

      Text(
        "Total : Rs.${finalTotal.toStringAsFixed(2)}",
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),

      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: custom_color.button_color,
          padding: const EdgeInsets.symmetric(
              horizontal: 30, vertical: 14),
        ),
        // onPressed: () {
        //   showConfirmDialog(finalTotal);
        // },
        //  onPressed: () async {
         onPressed: (isPaying || isProcessingPayment)
      ? null
      : () async {
  if (finalTotal == 0) {

    await SaveOrders("WALLET_ONLY", finalTotal, {"status": "success"});
    await clearCart();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(paymentId: "WALLET"),
      ),
      (route) => false,
    );

  } else {
    showConfirmDialog(finalTotal);
  }
},
        child: const Text(
          "Proceed",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      )

    ],
  ),
),
      ),
    );
  }

  Widget priceRow(String title,String value){

    return Padding(
      padding: const EdgeInsets.symmetric(vertical:4),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold)),

          Text(value)

        ],
      ),
    );
  }

void showConfirmDialog(double finalTotal) {
  if (isPaying) return;

  // double subTotal = 0;
  // for (var item in widget.cartData) {
  //   subTotal += double.parse(item['amt'].toString());
  // }
double subTotalExcl = 0;
double productGST = 0;

for (var item in widget.cartData) {
  double amt = double.tryParse(item['amt'].toString()) ?? 0;
  double gstPercent = double.tryParse(item['gst_percentage'].toString()) ?? 0;

  if (item['gst_enabled'] == "1" && gstPercent > 0) {
    double base = amt / (1 + gstPercent / 100);
    productGST += amt - base;
    subTotalExcl += base;
  } else {
    subTotalExcl += amt;
  }
}

double subTotal = subTotalExcl + productGST;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Confirm Order Amount",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  // priceRow("Items Amount", "Rs.${subTotal.toStringAsFixed(2)}"),
                  priceRow("Items Amount", "Rs.${subTotalExcl.toStringAsFixed(2)}"),
                  priceRow("Product GST", "Rs.${productGST.toStringAsFixed(2)}"),
                  priceRow("Items Total", "Rs.${subTotal.toStringAsFixed(2)}"),
                  priceRow("Delivery Charge", "Rs.${widget.deliveryCharge}"),
                  if (useWallet)
                    priceRow("Wallet Used", "Rs.${walletUsed.toStringAsFixed(2)}"),
                  priceRow("Total", "Rs.${finalTotal.toStringAsFixed(2)}"),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Final Total :",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Rs.${finalTotal.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: custom_color.app_color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (isPaying)
                    Column(
                      children: [
                        CircularProgressIndicator(color: custom_color.app_color),
                        const SizedBox(height: 10),
                        const Text("Processing payment..."),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: custom_color.app_color),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () {
                              // Navigator.pop(context);
                              Navigator.of(rootContext, rootNavigator: true).pop();
                            },
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: custom_color.button_color,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () async {
                              setDialogState(() => isPaying = true);
                              setState(() => isPaying = true);
                              await getRazorpayDetails(finalTotal);
                            },
                            child: const Text(
                              "Confirm",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> getRazorpayDetails(double finalTotal) async {
  try {
    var data = {
      "action": "get_razorpay_details",
      "accesskey": "90336",
      "token": accesstoken,
      "act_type": userResponse['act_type'],
      "customer_id": customer_id,
    };

    final response = await Cartapi().getRazorpayDetails(data);

    if (response != null && response['keyid'] != null) {
      Razorpay_Details = response;
      await RAZORPAYORDERCREATEAPI(finalTotal);
    } else {
      setState(() => isPaying = false);
      // Navigator.pop(context);
      Navigator.of(rootContext, rootNavigator: true).pop();
      Fluttertoast.showToast(msg: "Failed to get payment details");
    }
  } catch (e) {
    setState(() => isPaying = false);
    // Navigator.pop(context);
    Navigator.of(rootContext, rootNavigator: true).pop();
    Fluttertoast.showToast(msg: "Error: ${e.toString()}");
  }
}

Future<void> RAZORPAYORDERCREATEAPI(double finalTotal) async {
  try {
    var data = {
      "action": "razorpay_order",
      "accesskey": "90336",
      "token": accesstoken,
      "act_type": userResponse['act_type'],
      "customer_id": customer_id,
      "amount": ((finalTotal * 100).toInt()).toString(),
    };

    final response = await Cartapi().RAZORPAYORDERCREATEAPI(data);

    if (response != null && response['id'] != null) {
      orderId = response['id'];
      finalAmount = finalTotal;
      // Navigator.pop(context);
      Navigator.of(rootContext, rootNavigator: true).pop();
      openRazorpay(orderId, finalTotal);
    } else {
      setState(() => isPaying = false);
      // Navigator.pop(context);
      Navigator.of(rootContext, rootNavigator: true).pop();
      Fluttertoast.showToast(msg: "Failed to create order");
    }
  } catch (e) {
    setState(() => isPaying = false);
    // Navigator.pop(context);
    Navigator.of(rootContext, rootNavigator: true).pop();
    Fluttertoast.showToast(msg: "Error creating order: ${e.toString()}");
  }
}
void openRazorpay(String orderId, double amount) {
   try {
    setState(() {
      isPaying = true; // ✅ ADD THIS
    });
 
    var options = {
      'key': Razorpay_Details?['keyid'] ?? '',
      'amount': (amount * 100).toInt(),
      'order_id': orderId,
      'name': 'Burma Traders',
      'description': 'Order Payment',
      'prefill': {
        'contact': widget.userDetails['mobile'] ?? '',
        'email': widget.userDetails['email'] ?? ''
      },
      'theme': {
        'color': '#4CAF50'
      }
    };
    _razorpay.open(options);
  } catch (e) {
    setState(() => isPaying = false);
    debugPrint("Razorpay Error: $e");
    Fluttertoast.showToast(msg: "Failed to open payment gateway");
  }
}
// void _handlePaymentSuccess(PaymentSuccessResponse response) {
//   setState(() => isProcessingPayment = true);
  
//   String paymentId = response.paymentId ?? "";
//   String razorOrderId = response.orderId ?? "";
//   String signature = response.signature ?? "";

//   debugPrint("Payment Success - ID: $paymentId");
  
//   if (paymentId.isEmpty || razorOrderId.isEmpty || signature.isEmpty) {
//     setState(() {
//       isPaying = false;
//       isProcessingPayment = false;
//     });
//     Fluttertoast.showToast(msg: "Invalid payment response");
//     return;
//   }
//   // SaveOrders(paymentId, finalAmount);
//   verifyPayment(paymentId, razorOrderId, signature);
// }
void _handlePaymentSuccess(PaymentSuccessResponse response) {
  setState(() {
    isProcessingPayment = true;
    isPaying = false; // ✅ reset
  });

  String paymentId = response.paymentId ?? "";
  String razorOrderId = response.orderId ?? "";
  String signature = response.signature ?? "";

  if (paymentId.isEmpty || razorOrderId.isEmpty || signature.isEmpty) {
    setState(() {
      isProcessingPayment = false;
    });

    Fluttertoast.showToast(msg: "Invalid payment response");
    return;
  }

  verifyPayment(paymentId, razorOrderId, signature);
}
Future<void> SaveOrders(String paymentId, double finalTotal,payResponse) async {

  try {

    String address =
        "${widget.userDetails['address']}, ${widget.userDetails['address2']}, "
        "${widget.userDetails['city']}, ${widget.userDetails['state']} - ${widget.userDetails['pin']}";

    var data = {
      "action": "save_order",
      "accesskey": "90336",
      "token": accesstoken,
      "act_type": userResponse['act_type'],

      "customer_id": customer_id,
      "customer_address": address,

      "cart_items": jsonEncode(widget.cartData),

      // "tot_amt": (finalTotal + walletUsed - widget.deliveryCharge).toStringAsFixed(2),
      "tot_amt": (finalTotal + walletUsed).toStringAsFixed(2),
      "delivery_charge": widget.deliveryCharge.toString(),

      // "tax_amt": '',
      "tax_amt": totalTax.toStringAsFixed(2),

      "tax_percent": widget.gstPercent.toString(),

      "final_amt": finalTotal.toStringAsFixed(2),

      // "pay_type": "online",
      "pay_type": finalTotal == 0 ? "wallet" : "online",

      "txn_id": paymentId,

      "razorpay_order_id": orderId,

      "mobile": widget.userDetails['mobile'] ?? "",

      "name": widget.userDetails['name'] ?? "",

      "wallet_used": walletUsed.toStringAsFixed(2),
      // "wallet_balance": walletBalance.toStringAsFixed(2),
      "wallet_balance": (walletBalance - walletUsed).toStringAsFixed(2),

      "pay_status": payResponse['status'],

      "promo_code": appliedCoupon,

      "promo_disc_amt": discountAmount.toStringAsFixed(2),
    };

    final response = await Cartapi().SaveOrders(data);

    print(response);

    if (response != null && response["status"] == "success") {

      

    } else {

      Fluttertoast.showToast(msg: "Order save failed");

    }

  } catch (e) {

    debugPrint("Save Order Error: $e");
    Fluttertoast.showToast(msg: "Error saving order");

  }
}
Future<void> verifyPayment(String paymentId, String razorOrderId, String signature) async {
  try {
    var data = {
      "action": "get_pay_status",
      "accesskey": "90336",
      "customer_id": customer_id,
      "orders_id": razorOrderId,
      "final_amt": finalAmount.toStringAsFixed(2),
      "pay_type": "online",
      "txn_id": paymentId,
      "signature": signature,
      "token": accesstoken,
      "act_type": userResponse['act_type'],
      "pay_status": "success"
    };

    final response = await Cartapi().getPaymentStatus(data);

    setState(() {
      isPaying = false;
      isProcessingPayment = false;
    });

    if (response != null && response["status"].toString().toLowerCase() == "success") {
       await SaveOrders(paymentId, finalAmount, response);
      await clearCart();
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(
              paymentId: paymentId,
            ),
          ),
          (route) => false,
        );
      }
    } else {
       await SaveOrders(paymentId, finalAmount, response);
      //  await clearCart();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const PaymentFailedScreen(
              message: "Payment verification failed",
            ),
          ),
        );
      }
    }
  } catch (e) {
    setState(() {
      isPaying = false;
      isProcessingPayment = false;
    });
    
    debugPrint("Verification Error: $e");
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentFailedScreen(
            message: "Error: ${e.toString()}",
          ),
        ),
      );
    }
  }
}
// void _handlePaymentError(PaymentFailureResponse response) {
//   setState(() {
//     isPaying = false;
//     isProcessingPayment = false;
//   });
  
//   debugPrint("Payment Error: ${response.code} - ${response.message}");
  
//   String errorMessage = "Payment failed";
  
//   if (response.code == 0) {
//     errorMessage = "Payment cancelled by user";
//   } else if (response.code == 2) {
//     errorMessage = "Network error. Please check your connection";
//   } else {
//     errorMessage = response.message ?? "Payment failed";
//   }
  
//   Fluttertoast.showToast(msg: errorMessage);
  
//   if (mounted) {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (_) => PaymentFailedScreen(
//           message: errorMessage,
//         ),
//       ),
//     );
//   }
// }
void _handlePaymentError(PaymentFailureResponse response) {
  setState(() {
    isPaying = false;
    isProcessingPayment = false;
  });

  debugPrint("Payment Error: ${response.code} - ${response.message}");

  String errorMessage;

  if (response.code == 0) {
    errorMessage = "Payment cancelled by user";
  } else {
    // ✅ Always show actual Razorpay message if available
    errorMessage = response.message?.isNotEmpty == true
        ? response.message!
        : "Payment failed. Please try again";
  }

  Fluttertoast.showToast(msg: errorMessage);

  if (mounted) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentFailedScreen(
          message: errorMessage,
        ),
      ),
    );
  }
}
void _handleExternalWallet(ExternalWalletResponse response) {
  debugPrint("External Wallet Selected: ${response.walletName}");
  Fluttertoast.showToast(msg: "External wallet: ${response.walletName}");
}

Future<void> clearCart() async {
  final box = await Hive.openBox('cart');
  await box.delete('cartItems');
}
// Future<void> applyCoupon(double totalAmount) async {

//   if (promoController.text.trim().isEmpty) {
//     Fluttertoast.showToast(msg: "Enter promo code");
//     return;
//   }

//   var data = {
//     "action": "get_promo",
//     "accesskey": "90336",
//     "token": accesstoken,
//     "customer_id": customer_id,
//     "act_type": userResponse['act_type'],
//     "tot_amt": totalAmount.toString(),
//     "code": promoController.text.trim(),
//   };

//   final response = await Cartapi().PromoCodeValidaction(data);

//   print(response);

//   if (response != null && response['status'] == "success") {

//     setState(() {
//       discountAmount =
//           double.tryParse(response['discount_amt'].toString()) ?? 0;
//       appliedCoupon = promoController.text.trim();
//       couponApplied = true;
//     });

//     Fluttertoast.showToast(
//       msg: response['message'] ?? "Promo applied successfully",
//     );

//   } else {

//     Fluttertoast.showToast(
//       msg: response?['message'] ?? "Invalid Promo code",
//     );
//   }
// }

Future<void> applyCoupon(double totalAmount) async {

  if (couponApplied) return;

  if (promoController.text.trim().isEmpty) {
    Fluttertoast.showToast(msg: "Enter promo code");
    return;
  }

  var data = {
    "action": "get_promo",
    "accesskey": "90336",
    "token": accesstoken,
    "customer_id": customer_id,
    "act_type": userResponse['act_type'],
    "tot_amt": totalAmount.toString(),
    "code": promoController.text.trim(),
  };

  final response = await Cartapi().PromoCodeValidaction(data);

  if (response != null && response['status'] == "success") {

    // setState(() {
    //   // discountAmount =
    //   //     double.tryParse(response['discount_amt'].toString()) ?? 0;
    //   if (response['discount_amt'] != null &&
    //       response['discount_amt'].toString().isNotEmpty) {
    //     discountAmount =
    //         double.parse(response['discount_amt'].toString());
    //   }
    //   appliedCoupon = promoController.text.trim();
    //   couponApplied = true;
    // });
setState(() {
  discountAmount = double.tryParse(
        response['discount_amt']?.toString() ?? "0",
      ) ?? 0;

  appliedCoupon = promoController.text.trim();
  couponApplied = true;
});
    // Fluttertoast.showToast(
    //   msg: "Promo code applied successfully",
    // );
     ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text("Promo code applied successfully"),
  ),);

  } else {
    // Fluttertoast.showToast(
    //   msg: response?['message'] ?? "Invalid promo code",
    // );
     ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text("Invalid promo code"),
  ),);
  }
}
}