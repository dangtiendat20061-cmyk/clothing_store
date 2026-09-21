import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/product.dart';
import '../state/cart_model.dart';
import '../state/region_model.dart';
import '../theme.dart';
 
class ProductCard extends StatelessWidget {
  final Product product;
 
  const ProductCard({super.key, required this.product});
 
  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceLight, AppColors.surface],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.checkroom,
          size: 44,
          color: AppColors.accentPink.withOpacity(0.5),
        ),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    final region = context.watch<RegionModel>();
    final finalPrice = region.priceFor(product.priceVnd);
    final assetPath = product.imagePath != null
        ? 'assets/images/${product.imagePath}'
        : null;
 
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.read<CartModel>().addProduct(product);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thêm "${product.name}" vào giỏ'),
              duration: const Duration(milliseconds: 700),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  assetPath != null
                      ? Image.asset(
                          assetPath,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded) return child;
                            return AnimatedOpacity(
                              opacity: frame == null ? 0 : 1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              child: child,
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
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
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  ShaderMask(
                    shaderCallback: (bounds) => (region.isInternational
                            ? const LinearGradient(
                                colors: [AppColors.accentRed, AppColors.accentPink],
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
      ),
    );
  }
}