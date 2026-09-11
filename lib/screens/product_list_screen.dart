import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../data/sample_product.dart';
import '../state/cart_model.dart';
import '../state/region_model.dart';
import '../widgets/product_card.dart';
import '../theme.dart';
import 'cart_screen.dart';
 
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});
 
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}
 
class _ProductListScreenState extends State<ProductListScreen> {
  bool isLoading = true;
 
  @override
  void initState() {
    super.initState();
    checkUserLocation();
  }
 
  Future<void> checkUserLocation() async {
    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 2));
 
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final countryCode = data['country_code'] ?? 'VN';
        if (mounted) {
          context.read<RegionModel>().setFromCountryCode(countryCode);
          setState(() => isLoading = false);
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final region = context.watch<RegionModel>();
    final cartCount = context.watch<CartModel>().itemCount;
 
    return Scaffold(
      appBar: AppBar(
        title: const Text('DEAD ROSES™'),
        actions: [
          IconButton(
            icon: Icon(region.isInternational ? Icons.public : Icons.home),
            onPressed: () {
              context.read<RegionModel>().toggle();
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(region.isInternational
                      ? 'Chế độ Việt Nam (Giá gốc)'
                      : 'Chế độ Quốc tế (Giá x4)'),
                  duration: const Duration(milliseconds: 800),
                ),
              );
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
              if (cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.accentPink,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: sampleProducts.length,
              itemBuilder: (context, index) {
                return ProductCard(product: sampleProducts[index]);
              },
            ),
    );
  }
}