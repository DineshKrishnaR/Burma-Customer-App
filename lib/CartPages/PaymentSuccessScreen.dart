import 'package:burma/Dashboard/Dashboard.dart';
import 'package:flutter/material.dart';
import '../Common/colors.dart' as custom_color;

class PaymentSuccessScreen extends StatelessWidget {
  final String paymentId;

  const PaymentSuccessScreen({super.key, required this.paymentId});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => Dashboard()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: custom_color.app_color,
          title: const Text("Payment Success",
              style: TextStyle(color: Colors.white)),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 100),
                const SizedBox(height: 20),
                const Text(
                  "Payment Successful!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Your order has been placed successfully",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Transaction ID",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        paymentId,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: custom_color.button_color,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => Dashboard()),
                      (route) => false,
                    );
                  },
                  child: const Text("Continue Shopping",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}