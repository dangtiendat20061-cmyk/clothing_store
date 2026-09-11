import '../model/product.dart';
 
/// Danh sách sản phẩm mẫu. Sau này thay bằng dữ liệu từ Firebase.
final List<Product> sampleProducts = [
  const Product(
    name: 'Áo Thun Oversize Streetwear',
    priceVnd: 250000,
    image: 'assets/images/ao_thun.jpg',
  ),
  const Product(
    name: 'Áo Sơ Mi Cổ Tàu Premium',
    priceVnd: 350000,
    image: 'assets/images/ao_so_mi.jpg',
  ),
  const Product(
    name: 'Quần Cargo Pants Pocket',
    priceVnd: 420000,
    image: 'assets/images/quan_cargo.jpg',
  ),
  const Product(
    name: 'Áo Hoodies Basic Local Brand',
    priceVnd: 500000,
    image: 'assets/images/hoodie.jpg',
  ),
];