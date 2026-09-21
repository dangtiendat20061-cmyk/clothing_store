import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/cart_model.dart';
import '../state/region_model.dart';
import '../state/auth_model.dart';
import '../service/order_service.dart';
import '../service/auth_service.dart';
import '../theme.dart';
 
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
 
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}
 
class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final OrderService _orderService = OrderService();
 
  bool _isSubmitting = false;
  String? _errorMessage;
 
  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
 
    final cart = context.read<CartModel>();
    final region = context.read<RegionModel>();
    final auth = context.read<AuthModel>();
 
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
 
    try {
      final cartQuantities = {
        for (final line in cart.lines) line.product: line.quantity,
      };
 
      await _orderService.createOrder(
        token: auth.token!,
        cartQuantities: cartQuantities,
        shippingAddress: _addressCtrl.text.trim(),
        isInternational: region.isInternational,
      );
 
      cart.clear();
 
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đặt hàng thành công! 🎉')),
        );
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Có lỗi xảy ra, thử lại sau.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    final region = context.watch<RegionModel>();
    final total = cart.totalPrice(region.priceFor);
 
    return Scaffold(
      appBar: AppBar(title: const Text('Xác Nhận Đơn Hàng')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tóm tắt đơn hàng',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...cart.lines.map((line) {
                final price = region.priceFor(line.product.priceVnd);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${line.product.name} x${line.quantity}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${(price * line.quantity).toStringAsFixed(0)} VNĐ',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 24, color: AppColors.surfaceLight),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tổng cộng', style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '${total.toStringAsFixed(0)} VNĐ',
                    style: const TextStyle(
                      color: AppColors.accentPink,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Địa chỉ giao hàng'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nhập địa chỉ giao hàng' : null,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!,
                    style: const TextStyle(color: AppColors.accentRed)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _placeOrder,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Đặt Hàng'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}