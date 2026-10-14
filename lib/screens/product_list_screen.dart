import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../model/product.dart';
import '../service/product_service.dart';
import '../state/cart_model.dart';
import '../state/region_model.dart';
import '../state/auth_model.dart';
import '../widgets/product_card.dart';
import '../theme.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'order_history_screen.dart';
import 'account_security_screen.dart';
import 'setting_screen.dart';
import 'admin_product_screen.dart';
import 'admin_order_screen.dart';
import 'admin_user_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool isLoading = true;
  String? errorMessage;
  List<Product> products = [];
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    await Future.wait([
      _checkUserLocation(),
      _loadProducts(),
    ]);

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _loadProducts() async {
    try {
      final data = await _productService.fetchAll();
      if (mounted) setState(() => products = data);
    } catch (e) {
      if (mounted) {
        setState(() =>
            errorMessage = 'Không tải được sản phẩm. Kiểm tra backend đã chạy chưa.');
      }
    }
  }

  Future<void> _checkUserLocation() async {
    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final countryCode = data['country_code'] ?? 'VN';
        if (mounted) {
          context.read<RegionModel>().setFromCountryCode(countryCode);
        }
      }
    } catch (e) {
      // Không sao nếu lỗi, mặc định giữ giá VN
    }
  }

  static const _categories = <String, String>{
    'ao': 'Áo',
    'quan': 'Quần',
    'ao_khoac': 'Áo khoác',
  };

  String _categoryKey(String? value) {
    final category = (value ?? '').trim().toLowerCase().replaceAll(' ', '_');
    if (category == 'áo' || category == 'ao') return 'ao';
    if (category == 'quần' || category == 'quan') return 'quan';
    if (category == 'áo_khoác' || category == 'aokhoac' || category == 'ao_khoac') {
      return 'ao_khoac';
    }
    return category;
  }

  List<Product> get _filteredProducts {
    if (selectedCategory == null) return products;
    return products.where((p) => _categoryKey(p.category) == selectedCategory).toList();
  }

  Widget _buildCategoryChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        showCheckmark: false,
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.accentPink.withOpacity(.2),
        side: BorderSide(
          color: selected ? AppColors.accentPink.withOpacity(.65) : AppColors.outline,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final region = context.watch<RegionModel>();
    final cartCount = context.watch<CartModel>().itemCount;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('DEATH ROSES™'),
        centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Menu',
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      // Drawer dọc, lướt ra từ cạnh phải khi bấm nút Home
      endDrawer: Drawer(
        backgroundColor: AppColors.surface,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 190,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'asset/images/angel_gentle_animation.gif',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, __, ___) =>
                          Container(color: AppColors.surface),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xEE101014)],
                          stops: [0.2, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 16,
                      bottom: 18,
                      child: Text(
                        'DEATH ROSES™',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.surfaceLight, height: 1),
              ListTile(
                leading: Stack(
                  children: [
                    const Icon(Icons.shopping_bag_outlined,
                        color: AppColors.accentPink),
                    if (cartCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.accentPink,
                            shape: BoxShape.circle,
                          ),
                          constraints:
                              const BoxConstraints(minWidth: 14, minHeight: 14),
                          child: Text(
                            '$cartCount',
                            style: const TextStyle(color: Colors.white, fontSize: 9),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                title: const Text('Giỏ hàng'),
                onTap: () {
                  Navigator.of(context).pop(); // đóng drawer
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(region.isInternational ? Icons.public : Icons.flag,
                    color: AppColors.accentPink),
                title: const Text('Đổi vùng giá'),
                subtitle: Text(region.isInternational
                    ? 'Đang: Quốc tế (Giá x4)'
                    : 'Đang: Việt Nam (Giá gốc)'),
                onTap: () {
                  context.read<RegionModel>().toggle();
                  Navigator.of(context).pop();
                },
              ),
              const Divider(color: AppColors.surfaceLight, height: 1),
              Builder(builder: (context) {
                final auth = context.watch<AuthModel>();
                if (!auth.isLoggedIn) {
                  return ListTile(
                    leading: const Icon(Icons.person_outline,
                        color: AppColors.accentPink),
                    title: const Text('Đăng nhập'),
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person, color: AppColors.accentPink),
                      title: Text('Xin chào, ${auth.fullName}'),
                      subtitle: Text(auth.isAdmin ? 'Quản trị viên' : 'Khách hàng'),
                    ),
                    if (auth.isAdmin)
                      ListTile(
                        leading: const Icon(Icons.inventory_2_outlined,
                            color: AppColors.accentPink),
                        title: const Text('Quản lý sản phẩm'),
                        onTap: () async {
                          Navigator.of(context).pop();
                          final added = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => const AdminProductScreen(),
                            ),
                          );
                          if (added == true && mounted) {
                            await _loadData();
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã thêm sản phẩm thành công.'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    if (auth.isAdmin)
                      ListTile(
                        leading: const Icon(Icons.local_shipping_outlined,
                            color: AppColors.accentPink),
                        title: const Text('Quản lý đơn hàng'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AdminOrderScreen(),
                            ),
                          );
                        },
                      ),
                    if (auth.isAdmin)
                      ListTile(
                        leading: const Icon(Icons.manage_accounts_outlined,
                            color: AppColors.accentPink),
                        title: const Text('Quản lý tài khoản'),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AdminUserScreen(),
                            ),
                          );
                        },
                      ),
                    ListTile(
                      leading: const Icon(Icons.receipt_long_outlined,
                          color: AppColors.accentPink),
                      title: const Text('Đơn hàng của tôi'),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const OrderHistoryScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppColors.accentRed),
                      title: const Text('Đăng xuất'),
                      onTap: () {
                        context.read<AuthModel>().logout();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              }),
              const Divider(color: AppColors.surfaceLight, height: 1),
              ListTile(
                leading: const Icon(Icons.shield_outlined, color: AppColors.accentPink),
                title: const Text('Bảo mật & quyền riêng tư'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AccountSecurityScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: AppColors.accentPink),
                title: const Text('Cài đặt'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth > 1440
                ? 1440.0
                : constraints.maxWidth;
            final columns = contentWidth < 560
                ? 2
                : contentWidth < 850
                    ? 3
                    : contentWidth < 1140
                        ? 4
                        : 5;
            final cardAspectRatio = contentWidth < 420
                ? 0.68
                : contentWidth < 700
                    ? 0.72
                    : 0.78;
            final bodyText = Theme.of(context).textTheme.bodyMedium;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        contentWidth < 600 ? 16 : 28,
                        24,
                        contentWidth < 600 ? 16 : 28,
                        20,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DEATH ROSES COLLECTION',
                                  style: bodyText?.copyWith(
                                    color: AppColors.accentPink,
                                    fontSize: 12,
                                    letterSpacing: 1.4,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Sản phẩm',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontSize: 32),
                                ),
                              ],
                            ),
                          ),
                          if (!isLoading && errorMessage == null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.outline),
                              ),
                              child: Text(
                                '${_filteredProducts.length} sản phẩm',
                                style: bodyText?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isLoading && errorMessage == null)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          contentWidth < 600 ? 16 : 28,
                          0,
                          contentWidth < 600 ? 16 : 28,
                          12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Danh mục',
                              style: bodyText?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildCategoryChip(
                                    context,
                                    label: 'Tất cả',
                                    selected: selectedCategory == null,
                                    onSelected: () => setState(
                                        () => selectedCategory = null),
                                  ),
                                  ..._categories.entries.map(
                                    (entry) => _buildCategoryChip(
                                      context,
                                      label: entry.value,
                                      selected: selectedCategory == entry.key,
                                      onSelected: () => setState(
                                          () => selectedCategory = entry.key),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : errorMessage != null
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          errorMessage!,
                                          textAlign: TextAlign.center,
                                          style: bodyText,
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: _loadData,
                                          child: const Text('Thử lại'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadData,
                                  color: AppColors.accentPink,
                                  backgroundColor: AppColors.surface,
                                  child: _filteredProducts.isEmpty
                                      ? ListView(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          children: [
                                            const SizedBox(height: 88),
                                            Icon(
                                              Icons.inventory_2_outlined,
                                              size: 36,
                                              color: AppColors.textSecondary
                                                  .withOpacity(0.65),
                                            ),
                                            const SizedBox(height: 12),
                                            Center(
                                              child: Text(
                                                'Không có sản phẩm trong danh mục này',
                                                style: bodyText,
                                              ),
                                            ),
                                          ],
                                        )
                                      : GridView.builder(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          padding: EdgeInsets.fromLTRB(
                                            contentWidth < 600 ? 16 : 28,
                                            8,
                                            contentWidth < 600 ? 16 : 28,
                                            28,
                                          ),
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: columns,
                                            childAspectRatio: cardAspectRatio,
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 18,
                                          ),
                                          itemCount: _filteredProducts.length,
                                          itemBuilder: (context, index) =>
                                              ProductCard(
                                            product: _filteredProducts[index],
                                          ),
                                        ),
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
