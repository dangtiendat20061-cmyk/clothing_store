import 'package:flutter/material.dart';
import '../utils/format.dart';
import 'package:provider/provider.dart';

import '../service/auth_service.dart';
import '../service/order_service.dart';
import '../state/auth_model.dart';
import '../theme.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({
    super.key,
    this.showOrderPlacedMessage = false,
  });

  final bool showOrderPlacedMessage;

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrderService _orderService = OrderService();

  bool isLoading = true;
  String? errorMessage;
  List<OrderResult> orders = [];
  final Set<int> _busyOrderIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }
    try {
      final token = context.read<AuthModel>().token;
      if (token == null || token.isEmpty) {
        throw ApiException('Vui lòng đăng nhập để xem đơn hàng.');
      }
      final data = await _orderService.fetchMyOrders(token);
      data.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) setState(() => orders = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => errorMessage = 'Không tải được lịch sử đơn hàng.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'completed':
        return Colors.greenAccent;
      case 'shipped':
      case 'shipping':
        return AppColors.accentPurple;
      case 'packing':
        return const Color(0xFFFFB74D);
      case 'cancelled':
        return AppColors.accentRed;
      case 'paid':
        return const Color(0xFF69C9A5);
      default:
        return AppColors.accentPink;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase().trim()) {
      case 'pending':
        return 'Chờ xử lý';
      case 'paid':
        return 'Đã thanh toán';
      case 'shipped':
      case 'shipping':
        return 'Đang giao';
      case 'packing':
        return 'Đang chuẩn bị';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} · $hour:$minute';
  }

  Future<void> _cancelMyOrder(OrderResult order) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Hủy đơn #${order.id}?'),
        content: TextField(
          controller: reasonController,
          maxLength: 500,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Lý do (không bắt buộc)',
            hintText: 'Ví dụ: Tôi muốn đổi sản phẩm',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Quay lại'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, reasonController.text.trim()),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || !mounted) return;

    final token = context.read<AuthModel>().token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phiên đăng nhập hết hạn. Hãy đăng nhập lại.')),
      );
      return;
    }
    setState(() => _busyOrderIds.add(order.id));
    try {
      await _orderService.cancelOrder(
        token: token,
        orderId: order.id,
        reason: reason,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đơn hàng đã được hủy.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busyOrderIds.remove(order.id));
    }
  }

  Future<void> _deleteCancelledHistory(OrderResult order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Xóa lịch sử hủy?'),
        content: Text('Xóa vĩnh viễn đơn #${order.id} khỏi lịch sử của bạn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa lịch sử'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final token = context.read<AuthModel>().token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phiên đăng nhập hết hạn. Hãy đăng nhập lại.')),
      );
      return;
    }
    setState(() => _busyOrderIds.add(order.id));
    try {
      await _orderService.deleteCancelledHistory(token: token, orderId: order.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa lịch sử đơn đã hủy.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busyOrderIds.remove(order.id));
    }
  }

  Widget _successBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF17231F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF397A5E)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF72D6A8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Đặt hàng thành công. Đơn mới nhất của bạn ở bên dưới.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context, {required bool hasPlacedOrder}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        if (hasPlacedOrder) _successBanner(context),
        const SizedBox(height: 100),
        Icon(Icons.receipt_long_outlined,
            size: 44, color: AppColors.accentPink.withOpacity(.7)),
        const SizedBox(height: 12),
        Center(
          child: Text(
            hasPlacedOrder
                ? 'Đơn vừa đặt chưa xuất hiện. Kéo xuống để tải lại.'
                : 'Chưa có đơn hàng nào',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }

  Widget _orderCard(BuildContext context, OrderResult order) {
    final statusColor = _statusColor(order.status);
    final itemCount = order.items.fold<int>(0, (sum, item) => sum + item.quantity);
    final isPending = order.status.toLowerCase() == 'pending';
    final isCancelled = order.status.toLowerCase() == 'cancelled';
    final isBusy = _busyOrderIds.contains(order.id);

    return Card(
      color: AppColors.surface,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        collapsedIconColor: AppColors.accentPink,
        iconColor: AppColors.accentPink,
        title: Text(
          'Đơn hàng #${order.id}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 19,
              ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(.6)),
                ),
                child: Text(
                  _statusLabel(order.status),
                  style: TextStyle(color: statusColor, fontSize: 12),
                ),
              ),
              Text(
                _formatDate(order.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              Text(
                '$itemCount món · ${formatVnd(order.totalPrice)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.accentPink,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        children: [
          const Divider(color: AppColors.outline, height: 10),
          if (order.status.toLowerCase() == 'cancelled' &&
              (order.cancellationReason?.trim().isNotEmpty ?? false)) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withOpacity(.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accentRed.withOpacity(.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thông báo từ cửa hàng',
                      style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(order.cancellationReason!,
                      style: TextStyle(color: AppColors.textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (order.shippingAddress != null &&
              order.shippingAddress!.trim().isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 18, color: AppColors.accentPink),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.shippingAddress!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.productName}${item.size == null ? '' : ' · Size ${item.size}'}  × ${item.quantity}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${formatVnd((item.priceAtPurchase * item.quantity))}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (isPending || isCancelled) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: isPending
                  ? OutlinedButton.icon(
                      onPressed: isBusy ? null : () => _cancelMyOrder(order),
                      icon: isBusy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cancel_outlined),
                      label: Text(isBusy ? 'Đang xử lý...' : 'Hủy đơn hàng'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.accentRed),
                    )
                  : OutlinedButton.icon(
                      onPressed: isBusy ? null : () => _deleteCancelledHistory(order),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Xóa lịch sử hủy'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.accentRed),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.accentPink,
        backgroundColor: AppColors.surface,
        child: isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : errorMessage != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      if (widget.showOrderPlacedMessage)
                        _successBanner(context),
                      const SizedBox(height: 80),
                      Center(
                        child: Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  )
                : orders.isEmpty
                    ? _emptyState(
                        context,
                        hasPlacedOrder: widget.showOrderPlacedMessage,
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
                        itemCount:
                            orders.length + (widget.showOrderPlacedMessage ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (widget.showOrderPlacedMessage && index == 0) {
                            return _successBanner(context);
                          }
                          final orderIndex = widget.showOrderPlacedMessage
                              ? index - 1
                              : index;
                          return _orderCard(context, orders[orderIndex]);
                        },
                      ),
      ),
    );
  }
}