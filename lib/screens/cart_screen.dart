import 'package:flutter/material.dart';
import '../utils/format.dart';
import 'package:provider/provider.dart';
import '../state/auth_model.dart';
import '../state/cart_model.dart';
import '../state/region_model.dart';
import '../theme.dart';
import 'checkout_screen.dart';
import 'login_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _continueToCheckout(BuildContext context) {
    if (!context.read<AuthModel>().isLoggedIn) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập để tiếp tục thanh toán')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    final region = context.watch<RegionModel>();
    final total = cart.totalPrice(region.priceFor);
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final narrow = viewportWidth < 520;
    final footerWidth = (viewportWidth - 32).clamp(0.0, 920.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 42, color: AppColors.accentPink.withOpacity(.7)),
                  const SizedBox(height: 12),
                  Text(
                    'Giỏ hàng đang trống',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              itemCount: cart.lines.length,
              itemBuilder: (context, index) {
                final line = cart.lines[index];
                final price = region.priceFor(line.product.priceVnd);
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.checkroom_outlined,
                                color: AppColors.accentPink, size: 25),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${formatVnd(price)} / sản phẩm',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${formatVnd((price * line.quantity))}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: AppColors.accentPink,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _QuantityButton(
                                    icon: Icons.remove,
                                    onPressed: () => context
                                        .read<CartModel>()
                                        .decreaseProduct(line.product),
                                  ),
                                  SizedBox(
                                    width: 32,
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 160),
                                      child: Text(
                                        '${line.quantity}',
                                        key: ValueKey(line.quantity),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ),
                                  _QuantityButton(
                                    icon: Icons.add,
                                    onPressed: () => context
                                        .read<CartModel>()
                                        .addProduct(line.product),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.outline)),
              ),
              child: SafeArea(
                top: false,
                child: Center(
                  heightFactor: 1,
                  child: SizedBox(
                    width: footerWidth,
                    child: narrow
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTotal(context, total),
                              const SizedBox(height: 10),
                              _buildCheckoutButton(context, narrow: true),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: _buildTotal(context, total)),
                              _buildCheckoutButton(context, narrow: false),
                            ],
                          ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTotal(BuildContext context, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Tổng thanh toán',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 2),
        Text(
          '${formatVnd(total)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.accentPink,
                fontSize: 22,
              ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton(BuildContext context, {required bool narrow}) {
    return SizedBox(
      width: narrow ? double.infinity : null,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: () => _continueToCheckout(context),
        icon: const Icon(Icons.arrow_forward, size: 18),
        label: const Text('Thanh toán'),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      padding: EdgeInsets.zero,
      color: AppColors.accentPink,
    );
  }
}

