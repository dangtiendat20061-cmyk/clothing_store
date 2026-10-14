import 'package:flutter/material.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài Đặt')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: SwitchListTile(
              value: true,
              onChanged: null, // app cố định dark theme, để sẵn UI cho sau này
              activeColor: AppColors.accentPink,
              title: const Text('Chế độ tối'),
              subtitle: const Text('DEAD ROSES™ chỉ có 1 theme tối'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined,
                  color: AppColors.accentPink),
              title: const Text('Thông báo'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tính năng đang được xây dựng 🛠️')),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.accentPink),
              title: const Text('Phiên bản'),
              trailing: const Text('1.0.0', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }
}