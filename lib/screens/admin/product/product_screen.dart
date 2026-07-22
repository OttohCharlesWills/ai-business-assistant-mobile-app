import 'package:flutter/material.dart';
import '../../../services/product_service.dart';
import '../../../services/category_service.dart';
import '../../../services/shop_service.dart';
import '../../../widgets/app_loader.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List products = [];
  bool loading = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  final _stockLimitController = TextEditingController();
  final _stockUnitController = TextEditingController();
  final _unitSizeController = TextEditingController();

  bool _showUnitDetails = false;
  bool _submitting = false;

  List categories = [];
  List shops = [];
  int? selectedCategoryId;
  int? selectedShopId;

  static const bgColor = Color(0xFF0C1F3F);
  static const cardColor = Color(0xFF0F2847);
  static const accentBlue = Color(0xFF2F5DA8);
  static const softBlue = Color(0xFF8FAADC);

  @override
  void initState() {
    super.initState();
    fetchProducts();
    fetchDropdowns();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _stockQuantityController.dispose();
    _stockLimitController.dispose();
    _stockUnitController.dispose();
    _unitSizeController.dispose();
    super.dispose();
  }

  Future<void> fetchProducts() async {
    setState(() => loading = true);
    final data = await ProductService.getProducts();
    setState(() {
      products = data;
      loading = false;
    });
  }

  Future<void> fetchDropdowns() async {
    try {
      final cats = await CategoryService.getCategories();
      final shs = await ShopService.getShops();

      setState(() {
        categories = cats;
        shops = shs;
      });
    } catch (e) {
      print("Dropdown Error: $e");
    }
  }

  Future<void> deleteProduct(int id) async {
    final res = await ProductService.deleteProduct(id);
    if (res['status'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Product deleted"),
          backgroundColor: Colors.redAccent,
        ),
      );
      fetchProducts();
    }
  }

  void _generateBarcode() {
    final code = 'BC${DateTime.now().millisecondsSinceEpoch}';
    _barcodeController.text = code;
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _barcodeController.clear();
    _priceController.clear();
    _costPriceController.clear();
    _stockQuantityController.clear();
    _stockLimitController.clear();
    _stockUnitController.clear();
    _unitSizeController.clear();
    setState(() {
      selectedCategoryId = null;
      selectedShopId = null;
      _showUnitDetails = false;
    });
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_barcodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please generate a barcode first"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final res = await ProductService.createProduct(
      categoryId: selectedCategoryId!,
      shopId: selectedShopId!,
      name: _nameController.text.trim(),
      barcode: _barcodeController.text.trim(),
      price: double.parse(_priceController.text),
      costPrice: double.parse(_costPriceController.text),
      stockQuantity: int.parse(_stockQuantityController.text),
      stockLimit: int.tryParse(_stockLimitController.text) ?? 0,
      stockUnit: _stockUnitController.text.trim(),
      unitSize: int.tryParse(_unitSizeController.text),
    );

    setState(() => _submitting = false);

    if (!mounted) return;

    if (res['status'] == true) {
      Navigator.pop(context);
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Product added successfully"),
          backgroundColor: accentBlue,
        ),
      );
      fetchProducts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? "Something went wrong"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _openAddProductSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.92,
            minChildSize: 0.5,
            maxChildSize: 0.97,
            expand: false,
            builder: (_, scrollController) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: softBlue.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const Text(
                        "Add New Product",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // SELECT SHOP
                      _buildLabel("Select Shop"),
                      DropdownButtonFormField<int>(
                        value: selectedShopId,
                        dropdownColor: bgColor,
                        style: const TextStyle(color: Colors.white),
                        hint: const Text("-- Select Shop --",
                            style: TextStyle(color: softBlue)),
                        decoration: _inputDecoration(),
                        items: shops.map<DropdownMenuItem<int>>((shop) {
                          return DropdownMenuItem<int>(
                            value: shop['id'],
                            child: Text(shop['name'],
                                style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setSheetState(() => selectedShopId = val),
                        validator: (val) =>
                            val == null ? "Please select a shop" : null,
                      ),
                      const SizedBox(height: 14),

                      // SELECT CATEGORY
                      _buildLabel("Category"),
                      DropdownButtonFormField<int>(
                        value: selectedCategoryId,
                        dropdownColor: bgColor,
                        style: const TextStyle(color: Colors.white),
                        hint: const Text("-- Select Category --",
                            style: TextStyle(color: softBlue)),
                        decoration: _inputDecoration(),
                        items: categories.map<DropdownMenuItem<int>>((cat) {
                          return DropdownMenuItem<int>(
                            value: cat['id'],
                            child: Text(cat['name'],
                                style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setSheetState(() => selectedCategoryId = val),
                        validator: (val) =>
                            val == null ? "Please select a category" : null,
                      ),
                      const SizedBox(height: 14),

                      _buildLabel("Product Name"),
                      _buildTextField(
                        controller: _nameController,
                        hint: "e.g. Coca-Cola 50cl",
                        validator: (val) =>
                            val!.isEmpty ? "Product name is required" : null,
                      ),
                      const SizedBox(height: 14),

                      _buildLabel("Price (Per Item)"),
                      _buildTextField(
                        controller: _priceController,
                        hint: "0.00",
                        prefix: "₦",
                        keyboardType: TextInputType.number,
                        validator: (val) =>
                            val!.isEmpty ? "Price is required" : null,
                      ),
                      const SizedBox(height: 14),

                      _buildLabel("Cost Price (Per Item)"),
                      _buildTextField(
                        controller: _costPriceController,
                        hint: "0.00",
                        prefix: "₦",
                        keyboardType: TextInputType.number,
                        validator: (val) =>
                            val!.isEmpty ? "Cost price is required" : null,
                      ),
                      const SizedBox(height: 14),

                      _buildLabel("Stock Quantity"),
                      _buildTextField(
                        controller: _stockQuantityController,
                        hint: "0",
                        keyboardType: TextInputType.number,
                        validator: (val) =>
                            val!.isEmpty ? "Stock quantity is required" : null,
                      ),
                      const SizedBox(height: 14),

                      _buildLabel("Stock Limit (Low stock alert threshold)"),
                      _buildTextField(
                        controller: _stockLimitController,
                        hint: "0",
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),

                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: accentBlue.withOpacity(0.5)),
                          foregroundColor: softBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => setSheetState(
                            () => _showUnitDetails = !_showUnitDetails),
                        icon: Icon(
                            _showUnitDetails ? Icons.remove : Icons.add,
                            color: softBlue),
                        label: Text(_showUnitDetails
                            ? "Hide Unit Details"
                            : "Show Unit Details"),
                      ),

                      if (_showUnitDetails) ...[
                        const SizedBox(height: 14),
                        _buildLabel("Stock Unit (e.g. bags, kg, litres)"),
                        _buildTextField(
                          controller: _stockUnitController,
                          hint: "bags",
                        ),
                        const SizedBox(height: 14),
                        _buildLabel("Unit Size (e.g. 1 bag = 50kg, enter 50)"),
                        _buildTextField(
                          controller: _unitSizeController,
                          hint: "50",
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      const SizedBox(height: 14),

                      _buildLabel("Barcode"),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _barcodeController,
                              hint: "Scan or generate",
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _generateBarcode();
                              setSheetState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text("Generate"),
                          ),
                        ],
                      ),

                      if (_barcodeController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: accentBlue.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.qr_code,
                                  size: 32, color: softBlue),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _barcodeController.text,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submitProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Add Product",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint, String? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: softBlue, fontSize: 14),
      prefixText: prefix,
      prefixStyle: const TextStyle(color: Colors.white),
      filled: true,
      fillColor: bgColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
    String? prefix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(hint: hint, prefix: prefix),
      validator: validator,
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: softBlue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Products",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: fetchProducts,
          ),
        ],
      ),
      body: loading
          ? const FullScreenLoader(message: "Loading Products...")
          : products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: accentBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: softBlue,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "No products yet",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Tap + to add your first product",
                        style: TextStyle(color: softBlue, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchProducts,
                  color: accentBlue,
                  backgroundColor: cardColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final p = products[index];
                      final isLowStock = (double.tryParse(
                                  p['stock_quantity'].toString()) ??
                              0) <=
                          (double.tryParse(p['stock_limit'].toString()) ?? 0);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: isLowStock
                              ? Border.all(
                                  color: Colors.orange.withOpacity(0.5))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: accentBlue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.inventory_2_rounded,
                                color: softBlue,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['name'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "₦${p['price']} • Stock: ${p['stock_quantity']}",
                                    style: const TextStyle(
                                      color: softBlue,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (isLowStock)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        "⚠️ Low stock",
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => deleteProduct(p['id']),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddProductSheet,
        backgroundColor: accentBlue,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}