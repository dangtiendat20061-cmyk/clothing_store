import 'package:flutter/material.dart';
import 'product_list_screen.dart';
import '../theme.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  static const String gifPath = 'asset/images/death_rose_animation.gif';
  static const Duration introDuration = Duration(seconds: 4);

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(introDuration, _goToApp);
  }

  void _goToApp() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ProductListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Image.asset(
              gifPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.image_not_supported,
                color: AppColors.textSecondary,
                size: 64,
              ),
            ),
          ),
          Positioned(
            top: 48,
            right: 16,
            child: TextButton(
              onPressed: _goToApp,
              style: TextButton.styleFrom(
                backgroundColor: Colors.black45,
                foregroundColor: Colors.white,
              ),
              child: const Text('SKIP'),
            ),
          ),
        ],
      ),
    );
  }
}