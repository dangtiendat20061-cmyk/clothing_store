import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'state/cart_model.dart';
import 'state/region_model.dart';
import 'state/auth_model.dart';
import 'screens/product_list_screen.dart';
 
void main() {
  runApp(const ClothingStoreApp());
}
 
class ClothingStoreApp extends StatelessWidget {
  const ClothingStoreApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegionModel()),
        ChangeNotifierProvider(create: (_) => CartModel()),
        ChangeNotifierProvider(create: (_) => AuthModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Clothing Store',
        theme: AppTheme.dark,
        home: const ProductListScreen(),
      ),
    );
  }
}