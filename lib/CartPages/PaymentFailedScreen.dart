import 'package:burma/CartPages/Cart.dart';
import 'package:burma/CartPages/CheckOut.dart';
import 'package:flutter/material.dart';
import '../Common/colors.dart' as custom_color;

class PaymentFailedScreen extends StatelessWidget {
  final String message;

  const PaymentFailedScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Cart(selected_data: "",selecteddata_title: "",)),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: custom_color.app_color,
          title: const Text("Payment Failed",
              style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Cart(selected_data : "",selecteddata_title: "",)),
                (route) => false,
              );
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cancel, color: Colors.red, size: 100),
                const SizedBox(height: 20),
                const Text(
                  "Payment Failed",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: custom_color.button_color,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const Cart(selected_data : '',selecteddata_title: "",)),
                      (route) => false,
                    );
                  },
                  child: const Text("Back to Cart",
                      style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}