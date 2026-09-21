class Product {
  final int id; // phải khớp với id thật trong bảng products (MySQL)
  final String name;
  final int priceVnd; // giá gốc tính bằng VNĐ
  final String? imagePath; // đường dẫn ảnh trả về từ API (có thể null)
  final String? category;
 
  const Product({
    required this.id,
    required this.name,
    required this.priceVnd,
    this.imagePath,
    this.category,
  });
 
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      priceVnd: json['priceVnd'],
      imagePath: json['imagePath'],
      category: json['category'],
    );
  }
}