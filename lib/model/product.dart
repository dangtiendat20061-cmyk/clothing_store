class Product {
  final int id;
  final String name;
  final int priceVnd;
  final String? imagePath;
  final List<String> images;
  final String? category;
  final String? style;
  final String? description;
  final List<String> sizes;

  const Product({
    required this.id,
    required this.name,
    required this.priceVnd,
    this.imagePath,
    this.images = const [],
    this.category,
    this.style,
    this.description,
    this.sizes = const [],
  });

  List<String> get displayImages =>
      images.isNotEmpty ? images : (imagePath != null ? [imagePath!] : []);

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      priceVnd: json['priceVnd'],
      imagePath: json['imagePath'],
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : const [],
      category: json['category'],
      style: json['style']?.toString(),
      description: json['description'],
      sizes: json['sizes'] is List
          ? List<String>.from(json['sizes'])
          : const [],
    );
  }
}
