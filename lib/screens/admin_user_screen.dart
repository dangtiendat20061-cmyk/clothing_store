import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../service/admin_user_service.dart';
import '../service/auth_service.dart';
import '../state/auth_model.dart';
import '../theme.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final _service = AdminUserService();
  List<AdminUser> _users = [];
  final Set<int> _updating = {};
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
      final users = await _service.fetchUsers(token);
      if (mounted) setState(() => _users = users);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Không tải được danh sách tài khoản.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeAccess(AdminUser user) async {
    final isActive = !user.isActive;
    final action = isActive ? 'mở khóa' : 'khóa';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('${isActive ? 'Mở khóa' : 'Khóa'} tài khoản?'),
        content: Text('Bạn muốn $action tài khoản ${user.fullName} (${user.email})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isActive ? 'Mở khóa' : 'Khóa tài khoản'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _updating.add(user.id));
    try {
      final auth = context.read<AuthModel>();
      final token = auth.token;
      if (token == null || token.isEmpty) {
        throw ApiException('Phiên đăng nhập hết hạn. Hãy đăng nhập lại.');
      }
      await _service.setActive(token: token, userId: user.id, isActive: isActive);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã $action tài khoản ${user.fullName}.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _updating.remove(user.id));
    }
  }

  Widget _userCard(AdminUser user, String? currentEmail) {
    final isSelf = user.email.toLowerCase() == currentEmail?.toLowerCase();
    final statusColor = user.isActive ? const Color(0xFF69C9A5) : AppColors.accentRed;
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: AppColors.accentPink.withOpacity(.14),
              child: Icon(
                user.role.toLowerCase() == 'admin'
                    ? Icons.admin_panel_settings_outlined
                    : Icons.person_outline,
                color: AppColors.accentPink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.fullName,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(user.email,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _tag(user.role, AppColors.accentPurple),
            _tag(user.isActive ? 'Đang hoạt động' : 'Đã khóa', statusColor),
            if (user.phone?.isNotEmpty == true) _tag(user.phone!, AppColors.textSecondary),
          ]),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: isSelf || _updating.contains(user.id)
                  ? null
                  : () => _changeAccess(user),
              icon: _updating.contains(user.id)
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(user.isActive ? Icons.lock_outline : Icons.lock_open_outlined),
              label: Text(isSelf
                  ? 'Tài khoản hiện tại'
                  : user.isActive
                      ? 'Khóa tài khoản'
                      : 'Mở khóa tài khoản'),
              style: OutlinedButton.styleFrom(
                foregroundColor: user.isActive ? AppColors.accentRed : const Color(0xFF69C9A5),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _tag(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(.35)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12)),
      );

  @override
  Widget build(BuildContext context) {
    final currentEmail = context.read<AuthModel>().email;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý tài khoản'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, textAlign: TextAlign.center))
              : _users.isEmpty
                  ? const Center(child: Text('Chưa có tài khoản.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.accentPink,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: _users.length,
                        itemBuilder: (_, index) => _userCard(_users[index], currentEmail),
                      ),
                    ),
    );
  }
}
