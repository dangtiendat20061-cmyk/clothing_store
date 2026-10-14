import 'package:flutter/material.dart';
import '../utils/format.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:provider/provider.dart';
import '../service/auth_service.dart';
import '../service/order_service.dart';
import '../state/auth_model.dart';
import '../state/cart_model.dart';
import '../state/region_model.dart';
import '../theme.dart';
import 'order_history_screen.dart';
import 'login_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final OrderService _orderService = OrderService();
  final Map<int, String> _selectedSizes = {};

  bool _isSubmitting = false;
  bool _sessionExpired = false;
  String? _errorMessage;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = context.read<CartModel>();
    final region = context.read<RegionModel>();
    final auth = context.read<AuthModel>();

    setState(() {
      _isSubmitting = true;
      _sessionExpired = false;
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
        phone: _phoneCtrl.text.trim(),
        itemSizes: _selectedSizes,
        isInternational: region.isInternational,
      );

      cart.clear();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) =>
                const OrderHistoryScreen(showOrderPlacedMessage: true),
          ),
          (route) => route.isFirst,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.statusCode == 401) auth.logout();
        setState(() {
          _sessionExpired = e.statusCode == 401;
          _errorMessage = e.message;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Checkout order failed: $e\n$stackTrace');
      if (mounted) {
        setState(() => _errorMessage = kDebugMode
            ? 'Lỗi chi tiết: $e'
            : 'Có lỗi xảy ra, thử lại sau.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _loginAgainAndRetry() async {
    final loggedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (loggedIn == true && mounted) {
      await _placeOrder();
    }
  }

  InputDecoration _addressDecoration() {
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.outline),
    );
    return InputDecoration(
      labelText: 'Địa chỉ giao hàng',
      hintText: 'Số nhà, đường, phường/xã, quận/huyện, tỉnh/thành',
      prefixIcon: const Icon(Icons.location_on_outlined),
      alignLabelWithHint: true,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.all(16),
      border: outline,
      enabledBorder: outline,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.accentPink, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.accentRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.accentRed, width: 1.4),
      ),
    );
  }

  Widget _buildOrderSummary(BuildContext context, CartModel cart,
      RegionModel region, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  color: AppColors.accentPink, size: 20),
              const SizedBox(width: 9),
              Text(
                'Tóm tắt đơn hàng',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                    ),
              ),
              const Spacer(),
              Text(
                '${cart.itemCount} món',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.outline),
          const SizedBox(height: 8),
          ...cart.lines.map((line) {
            final price = region.priceFor(line.product.priceVnd);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${line.product.name}  × ${line.quantity}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${formatVnd((price * line.quantity))}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ],
                  ),
                  if (line.product.sizes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedSizes[line.product.id],
                          isExpanded: true,
                          decoration: _addressDecoration().copyWith(
                            labelText: 'Chọn size',
                            hintText: 'Chọn size sản phẩm',
                            prefixIcon: const SizedBox.shrink(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          dropdownColor: AppColors.surface,
                          items: line.product.sizes
                              .map((size) => DropdownMenuItem(
                                    value: size,
                                    child: Text(size),
                                  ))
                              .toList(),
                          onChanged: (size) {
                            if (size != null) {
                              setState(() => _selectedSizes[line.product.id] = size);
                            }
                          },
                          validator: (size) => size == null ? 'Chọn size' : null,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: AppColors.outline),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng cộng',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
              ),
              Text(
                '${formatVnd(total)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.accentPink,
                      fontSize: 22,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    final region = context.watch<RegionModel>();
    final total = cart.totalPrice(region.priceFor);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Xác nhận đơn hàng'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildOrderSummary(context, cart, region, total),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_shipping_outlined,
                                  color: AppColors.accentPink, size: 20),
                              const SizedBox(width: 9),
                              Text(
                                'Thông tin giao hàng',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontSize: 20,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                            decoration: _addressDecoration().copyWith(
                              labelText: 'Số điện thoại nhận hàng',
                              hintText: 'Nhập số điện thoại người nhận',
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                            validator: (value) => value == null || value.trim().isEmpty
                                ? 'Nhập số điện thoại nhận hàng'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _addressCtrl,
                            maxLines: 3,
                            minLines: 2,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.newline,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                            decoration: _addressDecoration(),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Nhập địa chỉ giao hàng'
                                    : null,
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.accentRed,
                              ),
                            ),
                          ],
                          if (_sessionExpired) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: _isSubmitting
                                    ? null
                                    : _loginAgainAndRetry,
                                icon: const Icon(Icons.login),
                                label: const Text('Đăng nhập lại và thử đặt đơn'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isSubmitting ? null : _placeOrder,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.lock_outline, size: 18),
                              label: Text(_isSubmitting
                                  ? 'Đang xử lý...'
                                  : 'Xác nhận đặt hàng'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
