import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../model/product.dart';
import '../service/product_service.dart';
import '../state/cart_model.dart';
import '../state/region_model.dart';
import '../state/auth_model.dart';
import '../widgets/product_card.dart';
import '../theme.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
 
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});
 
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}
 
class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();
 
  bool isLoading = true;
  String? errorMessage;
  List<Product> products = [];
 
  @override
  void initState() {
    super.initState();
    _loadData();
  }
 
  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
 
    // Chạy song song: check IP vùng + tải sản phẩm từ API
    await Future.wait([
      _checkUserLocation(),
      _loadProducts(),
    ]);
 
    if (mounted) setState(() => isLoading = false);
  }
 
  Future<void> _loadProducts() async {
    try {
      final data = await _productService.fetchAll();
      if (mounted) setState(() => products = data);
    } catch (e) {
      if (mounted) setState(() => errorMessage = 'Không tải được sản phẩm. Kiểm tra backend đã chạy chưa.');
    }
  }
 
  Future<void> _checkUserLocation() async {
    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 2));
 
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final countryCode = data['country_code'] ?? 'VN';
        if (mounted) {
          context.read<RegionModel>().setFromCountryCode(countryCode);
        }
      }
    } catch (e) {
      // Không sao nếu lỗi, mặc định giữ giá VN
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
          IconButton(
            icon: Icon(context.watch<AuthModel>().isLoggedIn
                ? Icons.person
                : Icons.person_outline),
            onPressed: () {
              final auth = context.read<AuthModel>();
              if (auth.isLoggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Xin chào, ${auth.fullName}')),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
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
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(errorMessage!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: products[index]);
                  },
                ),
    );
  }
}
