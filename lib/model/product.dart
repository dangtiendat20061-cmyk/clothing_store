class Product {
  final String name;
  final int priceVnd; // giá gốc tính bằng VNĐ
  final String image; // đường dẫn asset local
 
  const Product({
    required this.name,
    required this.priceVnd,
    required this.image,
  });
}