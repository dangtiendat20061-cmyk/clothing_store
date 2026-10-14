import 'package:flutter/material.dart';
import '../utils/format.dart';
import 'package:provider/provider.dart';
import '../service/auth_service.dart';
import '../service/order_service.dart';
import '../state/auth_model.dart';
import '../theme.dart';

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  State<AdminOrderScreen> createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> {
  final _service = OrderService();
  List<OrderResult> _orders = [];
  final Set<int> _updatingOrderIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = context.read<AuthModel>().token;
      if (token == null || token.isEmpty) {
        throw ApiException('Phiên đăng nhập hết hạn. Hãy đăng nhập lại.');
      }
      final orders = await _service.fetchAllOrders(token);
      if (mounted) setState(() => _orders = orders);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không tải được danh sách đơn hàng.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel(OrderResult order) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Hủy đơn #${order.id}'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          maxLength: 500,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Lý do hủy',
            hintText: 'Ví dụ: Sản phẩm gặp vấn đề về chất lượng',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () {
              final value = reasonController.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('Hủy đơn và báo khách'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || !mounted) return;

    try {
      final token = context.read<AuthModel>().token;
      if (token == null || token.isEmpty) {
        throw ApiException('Phiên đăng nhập hết hạn. Hãy đăng nhập lại.');
      }
      await _service.cancelOrder(token: token, orderId: order.id, reason: reason);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy đơn và lưu thông báo cho khách.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _deleteCancelledHistory(OrderResult order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Xóa lịch sử hủy?'),
        content: Text(
          'Xóa vĩnh viễn đơn #${order.id} và các dòng sản phẩm trong đơn này? '
          'Khách hàng cũng sẽ không còn thấy lịch sử đó.',
        ),
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
    setState(() => _updatingOrderIds.add(order.id));
    try {
      await _service.deleteCancelledHistory(token: token, orderId: order.id);
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
      if (mounted) setState(() => _updatingOrderIds.remove(order.id));
    }
  }

  String _statusLabel(String status) => switch (status.toLowerCase()) {
        'pending' => 'Chờ xử lý',
        'packing' => 'Đang chuẩn bị',
        'shipping' => 'Đang giao',
        'completed' => 'Hoàn thành',
        'cancelled' => 'Đã hủy',
        _ => status,
      };

  bool _canCancel(String status) =>
      status.toLowerCase() == 'pending' || status.toLowerCase() == 'packing';

  ({String status, String label, String confirmation, IconData icon})?
      _nextStep(String status) => switch (status.toLowerCase()) {
        'pending' => (
            status: 'Packing',
            label: 'Xác nhận đơn',
            confirmation: 'Xác nhận đơn này và chuyển sang khâu chuẩn bị?',
            icon: Icons.check_circle_outline,
          ),
        'packing' => (
            status: 'Shipping',
            label: 'Bắt đầu giao',
            confirmation: 'Chuyển đơn này sang trạng thái đang giao?',
            icon: Icons.local_shipping_outlined,
          ),
        'shipping' => (
            status: 'Completed',
            label: 'Xác nhận đã giao',
            confirmation: 'Xác nhận khách đã nhận được đơn hàng này?',
            icon: Icons.task_alt,
          ),
        _ => null,
      };

  Future<void> _advanceOrder(OrderResult order) async {
    final next = _nextStep(order.status);
    if (next == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(next.label),
        content: Text('Đơn #${order.id}: ${next.confirmation}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận'),
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

    setState(() => _updatingOrderIds.add(order.id));
    try {
      await _service.updateOrderStatus(
        token: token,
        orderId: order.id,
        status: next.status,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật đơn #${order.id}: ${_statusLabel(next.status)}.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _updatingOrderIds.remove(order.id));
    }
  }

  Widget _orderCard(OrderResult order) {
    final canCancel = _canCancel(order.status);
    final next = _nextStep(order.status);
    final isCancelled = order.status.toLowerCase() == 'cancelled';
    final isUpdating = _updatingOrderIds.contains(order.id);
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text('Đơn #${order.id} · ${order.customerName ?? 'Khách hàng'}',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Text(_statusLabel(order.status),
                style: const TextStyle(color: AppColors.accentPink)),
          ]),
          const SizedBox(height: 8),
          Text('${order.phone ?? 'Chưa có số điện thoại'} · ${formatVnd(order.totalPrice)}',
              style: const TextStyle(color: AppColors.textSecondary)),
          if ((order.shippingAddress ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(order.shippingAddress!,
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
          const Divider(height: 22, color: AppColors.outline),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '${item.productName}${item.size == null ? '' : ' · ${item.size}'} × ${item.quantity}',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              )),
          if (order.cancellationReason?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text('Lý do hủy: ${order.cancellationReason}',
                style: const TextStyle(color: AppColors.accentRed)),
          ],
          if (canCancel || next != null || isCancelled) ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 8,
              children: [
                if (canCancel)
                  OutlinedButton.icon(
                    onPressed: isUpdating ? null : () => _cancel(order),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Hủy đơn và báo khách'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.accentRed),
                  ),
                if (next != null)
                  FilledButton.icon(
                    onPressed: isUpdating ? null : () => _advanceOrder(order),
                    icon: isUpdating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(next.icon),
                    label: Text(isUpdating ? 'Đang cập nhật...' : next.label),
                  ),
                if (isCancelled)
                  OutlinedButton.icon(
                    onPressed: isUpdating ? null : () => _deleteCancelledHistory(order),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Xóa lịch sử hủy'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.accentRed),
                  ),
              ],
            ),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý đơn hàng'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, textAlign: TextAlign.center))
              : _orders.isEmpty
                  ? const Center(child: Text('Chưa có đơn hàng.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.accentPink,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: _orders.length,
                        itemBuilder: (_, index) => _orderCard(_orders[index]),
                      ),
                    ),
    );
  }
}
