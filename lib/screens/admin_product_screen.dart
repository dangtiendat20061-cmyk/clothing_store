import 'package:flutter/material.dart';
import '../utils/format.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../model/product.dart';
import '../service/auth_service.dart';
import '../service/product_service.dart';
import '../state/auth_model.dart';
import '../theme.dart';

const _productCategories = <String, String>{
  'ao': 'Áo',
  'quan': 'Quần',
  'ao_khoac': 'Áo khoác',
};

String? _categoryValue(String? value) {
  final category = (value ?? '').trim().toLowerCase().replaceAll(' ', '_');
  if (category == 'ao' || category == 'áo') return 'ao';
  if (category == 'quan' || category == 'quần') return 'quan';
  if (category == 'ao_khoac' || category == 'áo_khoác' || category == 'aokhoac') {
    return 'ao_khoac';
  }
  return null;
}

class AdminProductScreen extends StatelessWidget {
  const AdminProductScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Quản lý sản phẩm'),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Sản phẩm'),
                Tab(icon: Icon(Icons.add_box_outlined), text: 'Thêm sản phẩm'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [_AdminProductListTab(), _AdminAddProductTab()],
          ),
        ),
      );
}

class _AdminAddProductTab extends StatefulWidget {
  const _AdminAddProductTab({this.product, this.standalone = false});

  final Product? product;
  final bool standalone;

  @override
  State<_AdminAddProductTab> createState() => _AdminAddProductTabState();
}

class _AdminAddProductTabState extends State<_AdminAddProductTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _styleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _sizesCtrl = TextEditingController();
  final _productService = ProductService();

  bool _isSaving = false;
  bool _freeSizeSelected = false;
  String? _error;
  final List<PlatformFile> _selectedImages = [];
  late final List<String> _existingImages;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _existingImages = product?.displayImages.toList() ?? [];
    if (product != null) {
      _nameCtrl.text = product.name;
      _priceCtrl.text = product.priceVnd.toString();
      _categoryCtrl.text = product.category ?? '';
      _styleCtrl.text = product.style ?? '';
      _descriptionCtrl.text = product.description ?? '';
      _sizesCtrl.text = product.sizes.join(', ');
      _freeSizeSelected = product.sizes.length == 1 &&
          product.sizes.single.toLowerCase() == 'free size';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _categoryCtrl.dispose();
    _styleCtrl.dispose();
    _descriptionCtrl.dispose();
    _sizesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final token = context.read<AuthModel>().token;
    if (token == null || token.isEmpty) {
      setState(() => _error = 'Phiên đăng nhập hết hạn. Hãy đăng nhập lại.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final imagePaths = List<String>.from(_existingImages);
      for (final file in _selectedImages) {
        imagePaths.add(await _productService.uploadImage(token: token, file: file));
      }
      final sizes = _sizesCtrl.text
            .split(',')
            .map((size) => size.trim())
            .where((size) => size.isNotEmpty)
            .toList();
      final price = int.parse(_priceCtrl.text.trim());
      final imagePath = imagePaths.isEmpty ? null : imagePaths.first;
      if (_isEditing) {
        await _productService.updateProduct(
          token: token,
          productId: widget.product!.id,
          name: _nameCtrl.text,
          priceVnd: price,
          imagePath: imagePath,
          category: _categoryCtrl.text,
          style: _styleCtrl.text,
          description: _descriptionCtrl.text,
          sizes: sizes,
          images: imagePaths,
        );
      } else {
        await _productService.createProduct(
          token: token,
          name: _nameCtrl.text,
          priceVnd: price,
          imagePath: imagePath,
          category: _categoryCtrl.text,
          style: _styleCtrl.text,
          description: _descriptionCtrl.text,
          sizes: sizes,
          images: imagePaths,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '${_isEditing ? 'Không sửa' : 'Không thêm'} được sản phẩm: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: true,
        withData: true,
      );
      if (!mounted || result == null || result.files.isEmpty) return;
      final accepted = result.files.where((file) =>
          file.size <= 5 * 1024 * 1024 && file.bytes != null).toList();
      final rejectedCount = result.files.length - accepted.length;
      setState(() {
        _selectedImages.addAll(accepted);
        _error = rejectedCount > 0
            ? '$rejectedCount ảnh không đọc được hoặc vượt quá 5 MB nên đã bỏ qua.'
            : null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Không mở được trình chọn ảnh: $e');
    }
  }

  void _removeImage(int index) => setState(() {
        if (index < _existingImages.length) {
          _existingImages.removeAt(index);
        } else {
          _selectedImages.removeAt(index - _existingImages.length);
        }
      });

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: _decoration(label, hint: hint),
        validator: validator,
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Có thể chọn nhiều ảnh JPG, PNG hoặc WebP (mỗi ảnh tối đa 5 MB). Ảnh đầu tiên làm ảnh đại diện.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    _field(
                      _nameCtrl,
                      'Tên sản phẩm',
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Nhập tên sản phẩm'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      _priceCtrl,
                      'Giá (VNĐ)',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final price = int.tryParse(value?.trim() ?? '');
                        return price == null || price <= 0
                            ? 'Nhập giá lớn hơn 0'
                            : null;
                      },
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _pickImages,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(_existingImages.isEmpty && _selectedImages.isEmpty
                          ? 'Chọn nhiều ảnh từ thiết bị'
                          : 'Thêm ảnh (${_existingImages.length + _selectedImages.length} ảnh)'),
                    ),
                    if (_existingImages.isNotEmpty || _selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(_existingImages.length + _selectedImages.length, (index) {
                          final isExisting = index < _existingImages.length;
                          final existingImage = isExisting ? _existingImages[index] : null;
                          final selectedImage = isExisting ? null : _selectedImages[index - _existingImages.length];
                          return SizedBox(
                            width: 112,
                            height: 112,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: isExisting
                                      ? (existingImage!.startsWith('http://') || existingImage.startsWith('https://')
                                          ? Image.network(existingImage, fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined))
                                          : Image.asset('asset/images/$existingImage', fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined)))
                                      : Image.memory(selectedImage!.bytes!, fit: BoxFit.cover),
                                ),
                                if (index == 0)
                                  const Positioned(
                                    left: 5,
                                    bottom: 5,
                                    child: Chip(
                                      label: Text('Ảnh bìa'),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: IconButton.filledTonal(
                                    tooltip: 'Bỏ ảnh này',
                                    onPressed: _isSaving ? null : () => _removeImage(index),
                                    icon: const Icon(Icons.close, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _categoryValue(_categoryCtrl.text),
                      decoration: _decoration('Danh mục'),
                      items: _productCategories.entries
                          .map((entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ))
                          .toList(),
                      onChanged: _isSaving
                          ? null
                          : (value) => _categoryCtrl.text = value ?? '',
                      validator: (value) => value == null ? 'Chọn danh mục' : null,
                    ),
                    const SizedBox(height: 14),
                    _field(_styleCtrl, 'Phong cách', hint: 'Goth, Y2K...'),
                    const SizedBox(height: 14),
                    _field(
                      _sizesCtrl,
                      'Size',
                      hint: 'S, M, L, XL — để trống nếu không có size',
                      onChanged: (value) => setState(() {
                        _freeSizeSelected = value.trim().toLowerCase() == 'free size';
                      }),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilterChip(
                        selected: _freeSizeSelected,
                        label: const Text('Free size'),
                        avatar: const Icon(Icons.checkroom_outlined, size: 18),
                        onSelected: _isSaving
                            ? null
                            : (selected) => setState(() {
                                  _freeSizeSelected = selected;
                                  _sizesCtrl.text = selected ? 'Free size' : '';
                                }),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _field(
                      _descriptionCtrl,
                      'Mô tả',
                      maxLines: 4,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(_error!, style: const TextStyle(color: AppColors.accentRed)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_box_outlined),
                        label: Text(_isSaving ? 'Đang lưu...' : (_isEditing ? 'Lưu thay đổi' : 'Thêm sản phẩm')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ),
    );
  }
}

class _AdminProductListTab extends StatefulWidget {
  const _AdminProductListTab();

  @override
  State<_AdminProductListTab> createState() => _AdminProductListTabState();
}

class _AdminProductListTabState extends State<_AdminProductListTab> {
  final _service = ProductService();
  List<Product> _products = [];
  bool _loading = true;
  String? _error;
  int? _deletingId;

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
      final products = await _service.fetchAll();
      if (mounted) setState(() => _products = products);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Không tải được sản phẩm: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Gỡ sản phẩm?'),
        content: Text('Bạn muốn gỡ “${product.name}” khỏi cửa hàng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gỡ sản phẩm'),
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
    setState(() => _deletingId = product.id);
    try {
      await _service.deleteProduct(token: token, productId: product.id);
      if (mounted) {
        setState(() => _products.removeWhere((item) => item.id == product.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gỡ sản phẩm.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  Future<void> _edit(Product product) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Sửa sản phẩm')),
          body: _AdminAddProductTab(product: product, standalone: true),
        ),
      ),
    );
    if (saved == true && mounted) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật sản phẩm.')),
        );
      }
    }
  }

  Widget _thumbnail(Product product) {
    final path = product.displayImages.isNotEmpty
        ? product.displayImages.first
        : product.imagePath;
    if (path == null || path.isEmpty) {
      return const Icon(Icons.checkroom_outlined, color: AppColors.accentPink);
    }
    final image = path.startsWith('http://') || path.startsWith('https://')
        ? Image.network(path, width: 64, height: 76, fit: BoxFit.cover)
        : Image.asset('asset/images/$path', width: 64, height: 76, fit: BoxFit.cover);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: image,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ]),
      );
    }
    if (_products.isEmpty) return const Center(child: Text('Chưa có sản phẩm.'));
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accentPink,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final product = _products[index];
          final imageCount = product.displayImages.length;
          return Card(
            color: AppColors.surface,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              leading: SizedBox(width: 64, height: 76, child: _thumbnail(product)),
              title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${formatVnd(product.priceVnd)} · ${imageCount == 0 ? 'Chưa có ảnh' : '$imageCount ảnh'}',
              ),
              trailing: Wrap(
                spacing: 0,
                children: [
                  IconButton(
                    tooltip: 'Sửa sản phẩm',
                    onPressed: _deletingId == product.id ? null : () => _edit(product),
                    color: AppColors.accentPink,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Gỡ sản phẩm',
                    onPressed: _deletingId == product.id ? null : () => _delete(product),
                    color: AppColors.accentRed,
                    icon: _deletingId == product.id
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
