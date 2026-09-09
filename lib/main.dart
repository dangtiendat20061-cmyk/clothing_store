import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'theme.dart';

void main() {
  runApp(const ClothingStoreApp());
}

class ClothingStoreApp extends StatelessWidget {
  const ClothingStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clothing Store',
      theme: AppTheme.dark,
      home: const ProductListScreen(),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  bool isInternational = false;
  bool isLoading = true;

  // Dùng link ảnh Unsplash nhẹ và ổn định hơn hẳn picsum
  final List<Map<String, dynamic>> products = [
    {
      'name': 'Áo Thun Oversize Streetwear',
      'price_vnd': 250000,
      'image': 'assets/images/ao_thun.jpg' // Đường dẫn ảnh local
    },
    {
      'name': 'Áo Sơ Mi Cổ Tàu Premium',
      'price_vnd': 350000,
      'image': 'assets/images/ao_so_mi.jpg'
    },
    {
      'name': 'Quần Cargo Pants Pocket',
      'price_vnd': 420000,
      'image': 'assets/images/quan_cargo.jpg'
    },
    {
      'name': 'Áo Hoodies Basic Local Brand',
      'price_vnd': 500000,
      'image': 'assets/images/hoodie.jpg'
    },
  ];

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
        String countryCode = data['country_code'] ?? 'VN';
        if (mounted) {
          setState(() {
            isInternational = (countryCode != 'VN');
            isLoading = false;
          });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('DEAD ROSES™'),
        actions: [
          IconButton(
            icon: Icon(isInternational ? Icons.public : Icons.home),
            onPressed: () {
              setState(() {
                isInternational = !isInternational;
              });
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isInternational
                      ? 'Chế độ Quốc tế (Giá x4)'
                      : 'Chế độ Việt Nam (Giá gốc)'),
                  duration: const Duration(milliseconds: 800),
                ),
              );
            },
          )
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
              itemCount: products.length,
              itemBuilder: (context, index) {
                final item = products[index];
                double finalPrice = isInternational
                    ? (item['price_vnd'] * 4).toDouble()
                    : item['price_vnd'].toDouble();

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              item['image'],
                              width: double.infinity,
                              fit: BoxFit.cover,
                              // Chống lag/treo app khi tải ảnh
                              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                if (wasSynchronouslyLoaded) return child;
                                return AnimatedOpacity(
                                  opacity: frame == null ? 0 : 1,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                  child: child,
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.surfaceLight,
                                child: const Center(
                                  child: Icon(Icons.broken_image,
                                      size: 40, color: AppColors.textSecondary),
                                ),
                              ),
                            ),
                            // Lớp gradient tối phía dưới ảnh để chữ nổi hơn nếu ảnh sáng
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: 40,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black87],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            ShaderMask(
                              shaderCallback: (bounds) => (isInternational
                                      ? const LinearGradient(
                                          colors: [
                                            AppColors.accentRed,
                                            AppColors.accentPink
                                          ],
                                        )
                                      : AppColors.neonGradient)
                                  .createShader(bounds),
                              child: Text(
                                '${finalPrice.toStringAsFixed(0)} VNĐ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}