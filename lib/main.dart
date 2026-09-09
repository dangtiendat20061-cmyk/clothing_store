import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
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

  // Danh sách sản phẩm quần áo mẫu (Giá gốc VNĐ)
  final List<Map<String, dynamic>> products = [
    {
      'name': 'Áo Thun Oversize Streetwear',
      'price_vnd': 250000,
      'image': 'https://picsum.photos/300/300?random=1'
    },
    {
      'name': 'Áo Sơ Mi Cổ Tàu Premium',
      'price_vnd': 350000,
      'image': 'https://picsum.photos/300/300?random=2'
    },
    {
      'name': 'Quần Cargo Pants Pocket',
      'price_vnd': 420000,
      'image': 'https://picsum.photos/300/300?random=3'
    },
    {
      'name': 'Áo Hoodies Basic Local Brand',
      'price_vnd': 500000,
      'image': 'https://picsum.photos/300/300?random=4'
    },
  ];

  @override
  void initState() {
    super.initState();
    checkUserLocation();
  }

  // Tự động kiểm tra IP để xác định quốc gia
  Future<void> checkUserLocation() async {
    try {
      final response = await http.get(Uri.parse('https://ipapi.co/json/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String countryCode = data['country_code'] ?? 'VN';

        setState(() {
          // Nếu không phải VN -> Đánh dấu là khách quốc tế (x4 giá)
          isInternational = (countryCode != 'VN');
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clothing Store Portfolio'),
        actions: [
          // Nút toggle giả lập đổi qua lại giữa khách VN và Quốc tế
          IconButton(
            icon: Icon(isInternational ? Icons.public : Icons.home),
            onPressed: () {
              setState(() {
                isInternational = !isInternational;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isInternational
                      ? 'Chế độ Quốc tế (Giá x4)'
                      : 'Chế độ Việt Nam (Giá gốc)'),
                  duration: const Duration(seconds: 1),
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
                    ? (item['price_vnd'] * 4)
                    : item['price_vnd'].toDouble();

                return Card(
                  elevation: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Image.network(
                          item['image'],
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${finalPrice.toStringAsFixed(0)} VNĐ',
                              style: TextStyle(
                                color: isInternational
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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