import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/cart_model.dart';
import '../state/region_model.dart';
import '../state/auth_model.dart';
import '../theme.dart';
import 'checkout_screen.dart';
import 'login_screen.dart';
 
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
 
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    final region = context.watch<RegionModel>();
    final total = cart.totalPrice(region.priceFor);
 
    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body: cart.isEmpty
          ? Center(
              child: Text(
                'Giỏ hàng đang trống',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: cart.lines.length,
              itemBuilder: (context, index) {
                final line = cart.lines[index];
                final linePrice = region.priceFor(line.product.priceVnd);
 
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.checkroom,
                        color: AppColors.accentPink),
                    title: Text(line.product.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    subtitle: Text(
                      '${linePrice.toStringAsFixed(0)} VNĐ x ${line.quantity}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () =>
                              context.read<CartModel>().decreaseProduct(line.product),
                        ),
                        Text('${line.quantity}'),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () =>
                              context.read<CartModel>().addProduct(line.product),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.surfaceLight)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tổng: ${total.toStringAsFixed(0)} VNĐ',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontSize: 18,
                            ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final auth = context.read<AuthModel>();
                        if (!auth.isLoggedIn) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Đăng nhập để tiếp tục thanh toán')),
                          );
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                        );
                      },
                      child: const Text('Thanh Toán'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}