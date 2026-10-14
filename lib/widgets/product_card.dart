import 'package:flutter/material.dart';
import '../utils/format.dart';
import 'package:provider/provider.dart';
import '../model/product.dart';
import '../screens/product_detail_screen.dart';
import '../state/region_model.dart';
import '../theme.dart';
import 'angel_eye_product_frame.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF29232A), AppColors.surface],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checkroom_outlined,
                size: 38, color: AppColors.accentPink.withOpacity(.72)),
            const SizedBox(height: 8),
            Text('Ảnh đang cập nhật',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(.9),
                  fontSize: 12,
                )),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, _) =>
            ProductDetailScreen(product: product),
        transitionsBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween(begin: .96, end: 1.0).animate(curved),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, .025),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final region = context.watch<RegionModel>();
    final finalPrice = region.priceFor(product.priceVnd);
    final assetPath = product.imagePath == null
        ? null
        : 'asset/images/${product.imagePath}';
    final imagePath = product.imagePath;

    return Card(
      color: AppColors.surface,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.outline, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Hero(
                  tag: 'product-image-${product.id}',
                  child: AngelEyeProductFrame(
                    borderRadius: 9,
                    child: imagePath == null || imagePath.isEmpty
                        ? _buildImagePlaceholder()
                        : (imagePath.startsWith('http://') ||
                                imagePath.startsWith('https://')
                            ? Image.network(
                                imagePath,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildImagePlaceholder(),
                              )
                            : Image.asset(
                                assetPath!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                frameBuilder: (context, child, frame, sync) {
                                  if (sync) return child;
                                  return AnimatedOpacity(
                                    opacity: frame == null ? 0 : 1,
                                    duration: const Duration(milliseconds: 250),
                                    child: child,
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildImagePlaceholder(),
                              )),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          height: 1.15,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${formatVnd(finalPrice)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: region.isInternational
                              ? AppColors.accentRed
                              : AppColors.accentPink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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

