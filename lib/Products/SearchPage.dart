import 'package:burma/Dashboard/DashboardApi.dart';
import 'package:burma/Products/ProductDetails.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import '../Common/colors.dart' as custom_color;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final LocalStorage storage = LocalStorage('app_store');
  final TextEditingController _searchController = TextEditingController();

  var userResponse;
  var accesstoken;
  var customer_id;

  List results = [];
  bool isLoading = false;
  bool hasSearched = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await storage.ready;
    userResponse = await storage.getItem('userResponse');
    if (userResponse != null) {
      accesstoken = userResponse['api_token'];
      customer_id = userResponse['customer_id'].toString();
    }
  }

  Future<void> _search(String keyword) async {
    if (keyword.trim().isEmpty) return;
    setState(() {
      isLoading = true;
      hasSearched = true;
    });

    var data = {
      "action": "search_products",
      "accesskey": "90336",
      "token": accesstoken,
      "act_type": userResponse['act_type'].toString(),
      "customer_id": customer_id.toString(),
      "keyword": keyword.trim(),
    };

    final response = await DashboardApi().SearchProducts(data);
    setState(() {
      results = response?['res'] ?? [];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: custom_color.app_color,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: "Search products...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onSubmitted: _search,
          textInputAction: TextInputAction.search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _search(_searchController.text),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: custom_color.app_color))
          : !hasSearched
              ? const Center(
                  child: Text("Search for products", style: TextStyle(color: Colors.grey)),
                )
              : results.isEmpty
                  ? const Center(
                      child: Text("No products found", style: TextStyle(color: Colors.grey)),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(15),
                      itemCount: results.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                        childAspectRatio: .75,
                      ),
                      itemBuilder: (context, index) {
                        var p = results[index];
                        var variant = (p['vars'] != null && p['vars'].length > 0)
                            ? p['vars'][0]
                            : null;
                        return _buildProductCard(p, variant);
                      },
                    ),
    );
  }

  Widget _buildProductCard(var p, var variant) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Productdetails(selected_data: p, selecteddata_title: ""),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12, offset: const Offset(0, 4))
          ],
          border: Border(
            right: BorderSide(color: Colors.grey.shade300, width: 3),
            bottom: BorderSide(color: Colors.grey.shade300, width: 3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _safeImage(p['prod_img']),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                p['name'] ?? "",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              if (variant != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "₹ ${variant['discounted_price']}",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: custom_color.app_color),
                    ),
                    const SizedBox(width: 6),
                    if (variant['disc_amt'] != "0")
                      Text(
                        "₹ ${variant['price']}",
                        style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 11),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 34,
                child: ElevatedButton(
                  onPressed: variant != null && variant['stock_status'] == "Available"
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Productdetails(selected_data: p, selecteddata_title: ""),
                            ),
                          )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: variant != null && variant['stock_status'] == "Available"
                        ? custom_color.button_color
                        : Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Buy Now", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _safeImage(String? url) {
    String clean = (url ?? "").replaceAll(RegExp(r'(?<!:)//+'), '/');
    if (clean.isEmpty || !clean.startsWith('http')) {
      return Image.asset("assets/images/AppLogo.png", fit: BoxFit.contain);
    }
    return Image.network(
      clean,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Image.asset("assets/images/AppLogo.png", fit: BoxFit.contain),
    );
  }
}
