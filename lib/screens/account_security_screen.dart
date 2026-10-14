import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_model.dart';
import '../theme.dart';

class AccountSecurityScreen extends StatelessWidget {
  const AccountSecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Bảo Mật & Quyền Riêng Tư')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Tài khoản', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.email_outlined, color: AppColors.accentPink),
              title: Text(auth.email ?? '—'),
              subtitle: const Text('Email đăng nhập'),
            ),
          ),
          const SizedBox(height: 24),
          Text('Bảo mật', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline, color: AppColors.accentPink),
              title: const Text('Đổi mật khẩu'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tính năng đang được xây dựng 🛠️')),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Text('Quyền riêng tư', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.accentRed),
              title: const Text('Xóa tài khoản'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tính năng đang được xây dựng 🛠️')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}