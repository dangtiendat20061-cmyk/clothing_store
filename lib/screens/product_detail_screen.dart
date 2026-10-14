import 'dart:async';
import '../utils/format.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../model/product.dart';
import '../state/cart_model.dart';
import '../state/region_model.dart';
import '../theme.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    final imageCount = widget.product.displayImages.length;
    if (imageCount > 1) {
      _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        final next = (_currentPage + 1) % imageCount;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checkroom_outlined,
                size: 48, color: AppColors.accentPink.withOpacity(.68)),
            const SizedBox(height: 10),
            Text(
              'Chưa có ảnh sản phẩm',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGallery(List<String> images, double height) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.surface),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'product-image-${widget.product.id}',
                child: images.isEmpty
                    ? _buildImagePlaceholder()
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: images.length,
                        onPageChanged: (index) =>
                            setState(() => _currentPage = index),
                        itemBuilder: (context, index) {
                          final image = images[index];
                          final isNetwork = image.startsWith('http://') ||
                              image.startsWith('https://');
                          return isNetwork
                              ? Image.network(
                                  image,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      _buildImagePlaceholder(),
                                )
                              : Image.asset(
                                  'asset/images/$image',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      _buildImagePlaceholder(),
                                );
                        },
                      ),
              ),
              if (images.length > 1)
                Positioned(
                  bottom: 14,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (index) {
                      final selected = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: selected ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accentPink
                              : Colors.white38,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context, RegionModel region) {
    final product = widget.product;
    final finalPrice = region.priceFor(product.priceVnd);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'DEATH ROSES COLLECTION',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.accentPink,
                  letterSpacing: 1.2,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            product.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  height: 1.05,
                ),
          ),
          const SizedBox(height: 14),
          Text(
            '${formatVnd(finalPrice)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: region.isInternational
                      ? AppColors.accentRed
                      : AppColors.accentPink,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (product.description != null &&
              product.description!.trim().isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Divider(color: AppColors.outline, height: 1),
            ),
            Text(
              'Mô tả',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 7),
            Text(
              product.description!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Text(
                'Số lượng',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
              ),
              const Spacer(),
              _quantityButton(
                icon: Icons.remove,
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              SizedBox(
                width: 42,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: Text(
                    '$_quantity',
                    key: ValueKey(_quantity),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              _quantityButton(
                icon: Icons.add,
                onPressed: () => setState(() => _quantity++),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Thêm vào giỏ'),
              onPressed: () {
                context
                    .read<CartModel>()
                    .addProduct(product, quantity: _quantity);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Đã thêm $_quantity "${product.name}" vào giỏ'),
                    duration: const Duration(milliseconds: 900),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({required IconData icon, VoidCallback? onPressed}) {
    return IconButton(
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 19),
      style: IconButton.styleFrom(
        foregroundColor: AppColors.accentPink,
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.outline),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final region = context.watch<RegionModel>();
    final images = widget.product.displayImages;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isWide = screenWidth >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('CHI TIẾT SẢN PHẨM'),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth > 1200
                ? 1200.0
                : constraints.maxWidth;
            final imageHeight = isWide
                ? (screenHeight * .58).clamp(360.0, 500.0).toDouble()
                : (contentWidth * .86).clamp(240.0, 340.0).toDouble();

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isWide ? 28 : 16,
                18,
                isWide ? 28 : 16,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 11,
                              child: _buildGallery(images, imageHeight),
                            ),
                            const SizedBox(width: 28),
                            Expanded(
                              flex: 9,
                              child: _buildProductInfo(context, region),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildGallery(images, imageHeight),
                            const SizedBox(height: 16),
                            _buildProductInfo(context, region),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}