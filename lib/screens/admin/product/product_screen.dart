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
  List filteredProducts = [];

  bool loading = false;

  final TextEditingController _searchController =
      TextEditingController();

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
    _searchController.dispose();

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

  // ============================================================
  // FETCH PRODUCTS
  // ============================================================

  Future<void> fetchProducts() async {
    if (!mounted) return;

    setState(() => loading = true);

    try {
      final data = await ProductService.getProducts();

      if (!mounted) return;

      setState(() {
        products = data;
        filteredProducts = data;
        loading = false;
      });

      // Re-apply search if there is an existing search query.
      if (_searchController.text.trim().isNotEmpty) {
        _searchProducts(_searchController.text);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load products: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ============================================================
  // SEARCH PRODUCTS
  // ============================================================

  void _searchProducts(String query) {
    final search = query.trim().toLowerCase();

    if (search.isEmpty) {
      setState(() {
        filteredProducts = products;
      });
      return;
    }

    setState(() {
      filteredProducts = products.where((product) {
        final name =
            product['name']?.toString().toLowerCase() ?? '';

        final barcode =
            product['barcode']?.toString().toLowerCase() ?? '';

        final stockUnit =
            product['stock_unit']?.toString().toLowerCase() ?? '';

        return name.contains(search) ||
            barcode.contains(search) ||
            stockUnit.contains(search);
      }).toList();
    });
  }

  // ============================================================
  // FETCH CATEGORIES + SHOPS
  // ============================================================

  Future<void> fetchDropdowns() async {
    try {
      final cats = await CategoryService.getCategories();
      final shs = await ShopService.getShops();

      if (!mounted) return;

      setState(() {
        categories = cats;
        shops = shs;
      });
    } catch (e) {
      debugPrint("Dropdown Error: $e");
    }
  }

  // ============================================================
  // DELETE PRODUCT
  // ============================================================

  Future<void> deleteProduct(int id) async {
    try {
      final res = await ProductService.deleteProduct(id);

      if (!mounted) return;

      if (res['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product deleted"),
            backgroundColor: Colors.redAccent,
          ),
        );

        await fetchProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message'] ?? "Failed to delete product",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete product: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ============================================================
  // GENERATE BARCODE
  // ============================================================

  void _generateBarcode() {
    final code = 'BC${DateTime.now().millisecondsSinceEpoch}';
    _barcodeController.text = code;
  }

  // ============================================================
  // CLEAR FORM
  // ============================================================

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

    selectedCategoryId = null;
    selectedShopId = null;
    _showUnitDetails = false;
    _submitting = false;
  }

  // ============================================================
  // ADD PRODUCT
  // ============================================================

  Future<void> _submitProduct(BuildContext sheetContext) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a category"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (selectedShopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a shop"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_barcodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please generate or enter a barcode"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final res = await ProductService.createProduct(
        categoryId: selectedCategoryId!,
        shopId: selectedShopId!,
        name: _nameController.text.trim(),
        barcode: _barcodeController.text.trim(),
        price: double.parse(_priceController.text),
        costPrice: double.parse(_costPriceController.text),

        // CREATE PRODUCT expects int values
        stockQuantity:
            int.tryParse(_stockQuantityController.text) ?? 0,

        stockLimit:
            int.tryParse(_stockLimitController.text) ?? 0,

        stockUnit: _stockUnitController.text.trim(),

        unitSize: _unitSizeController.text.trim().isEmpty
            ? null
            : int.tryParse(_unitSizeController.text),
      );

      if (!mounted) return;

      setState(() => _submitting = false);

      if (res['status'] == true) {
        Navigator.of(sheetContext).pop();

        _clearForm();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product added successfully"),
            backgroundColor: accentBlue,
          ),
        );

        await fetchProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message'] ?? "Something went wrong",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _submitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add product: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ============================================================
  // OPEN ADD PRODUCT SHEET
  // ============================================================

  void _openAddProductSheet() {
    _clearForm();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
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
                    bottom:
                        MediaQuery.of(sheetContext).viewInsets.bottom +
                            20,
                  ),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildSheetHandle(),

                        const Text(
                          "Add New Product",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 20),

                        _buildProductFormFields(
                          setSheetState: setSheetState,
                        ),

                        const SizedBox(height: 24),

                        _buildSubmitButton(
                          text: "Add Product",
                          onPressed: _submitting
                              ? null
                              : () => _submitProduct(
                                    sheetContext,
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
        );
      },
    );
  }

  // ============================================================
  // OPEN EDIT PRODUCT SHEET
  // ============================================================

  void _openEditProductSheet(
    Map<String, dynamic> product,
  ) {
    _nameController.text =
        product['name']?.toString() ?? '';

    _barcodeController.text =
        product['barcode']?.toString() ?? '';

    _priceController.text =
        product['price']?.toString() ?? '';

    _costPriceController.text =
        product['cost_price']?.toString() ?? '';

    _stockQuantityController.text =
        product['stock_quantity']?.toString() ?? '';

    _stockLimitController.text =
        product['stock_limit']?.toString() ?? '';

    _stockUnitController.text =
        product['stock_unit']?.toString() ?? '';

    _unitSizeController.text =
        product['unit_size']?.toString() ?? '';

    selectedCategoryId =
        int.tryParse(
      product['category_id']?.toString() ?? '',
    );

    selectedShopId =
        int.tryParse(
      product['shop_id']?.toString() ?? '',
    );

    _showUnitDetails =
        _stockUnitController.text.trim().isNotEmpty ||
            _unitSizeController.text.trim().isNotEmpty;

    _submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
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
                    bottom:
                        MediaQuery.of(sheetContext).viewInsets.bottom +
                            20,
                  ),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildSheetHandle(),

                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "Edit Product",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    accentBlue.withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                "#${product['id']}",
                                style: const TextStyle(
                                  color: softBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _buildProductFormFields(
                          setSheetState: setSheetState,
                        ),

                        const SizedBox(height: 24),

                        _buildSubmitButton(
                          text: "Update Product",
                          onPressed: _submitting
                              ? null
                              : () => _updateProduct(
                                    product,
                                    sheetContext,
                                    setSheetState,
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
        );
      },
    );
  }

  // ============================================================
  // UPDATE PRODUCT
  // ============================================================

  Future<void> _updateProduct(
    Map<String, dynamic> product,
    BuildContext sheetContext,
    StateSetter setSheetState,
  ) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a category"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (selectedShopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a shop"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_barcodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Barcode is required"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setSheetState(() => _submitting = true);

    try {
      final productId = int.tryParse(
        product['id']?.toString() ?? '',
      );

      if (productId == null) {
        setSheetState(() => _submitting = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid product ID"),
            backgroundColor: Colors.redAccent,
          ),
        );

        return;
      }

      final res = await ProductService.updateProduct(
        id: productId,
        categoryId: selectedCategoryId!,
        shopId: selectedShopId!,
        name: _nameController.text.trim(),
        barcode: _barcodeController.text.trim(),
        price: double.parse(_priceController.text),
        costPrice:
            double.parse(_costPriceController.text),

        // UPDATE PRODUCT expects double values
        stockQuantity:
            double.tryParse(
                  _stockQuantityController.text,
                ) ??
                0.0,

        stockLimit:
            double.tryParse(
                  _stockLimitController.text,
                ) ??
                0.0,

        stockUnit: _stockUnitController.text.trim(),

        unitSize:
            _unitSizeController.text.trim().isEmpty
                ? null
                : double.tryParse(
                    _unitSizeController.text,
                  ),
      );

      if (!mounted) return;

      setSheetState(() => _submitting = false);

      if (res['status'] == true) {
        Navigator.of(sheetContext).pop();

        _clearForm();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Product updated successfully",
            ),
            backgroundColor: accentBlue,
          ),
        );

        await fetchProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message'] ??
                  "Failed to update product",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setSheetState(() => _submitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to update product: $e",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ============================================================
  // COMMON PRODUCT FORM
  // ============================================================

  Widget _buildProductFormFields({
    required StateSetter setSheetState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SELECT SHOP
        _buildLabel("Select Shop"),

        DropdownButtonFormField<int>(
          value: selectedShopId,
          dropdownColor: bgColor,
          style: const TextStyle(color: Colors.white),
          hint: const Text(
            "-- Select Shop --",
            style: TextStyle(color: softBlue),
          ),
          decoration: _inputDecoration(),
          items:
              shops.map<DropdownMenuItem<int>>((shop) {
            final id = int.tryParse(
              shop['id']?.toString() ?? '',
            );

            return DropdownMenuItem<int>(
              value: id,
              child: Text(
                shop['name']?.toString() ?? '',
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setSheetState(() {
              selectedShopId = val;
            });
          },
          validator: (val) {
            return val == null
                ? "Please select a shop"
                : null;
          },
        ),

        const SizedBox(height: 14),

        // SELECT CATEGORY
        _buildLabel("Category"),

        DropdownButtonFormField<int>(
          value: selectedCategoryId,
          dropdownColor: bgColor,
          style: const TextStyle(color: Colors.white),
          hint: const Text(
            "-- Select Category --",
            style: TextStyle(color: softBlue),
          ),
          decoration: _inputDecoration(),
          items:
              categories.map<DropdownMenuItem<int>>((cat) {
            final id = int.tryParse(
              cat['id']?.toString() ?? '',
            );

            return DropdownMenuItem<int>(
              value: id,
              child: Text(
                cat['name']?.toString() ?? '',
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setSheetState(() {
              selectedCategoryId = val;
            });
          },
          validator: (val) {
            return val == null
                ? "Please select a category"
                : null;
          },
        ),

        const SizedBox(height: 14),

        // PRODUCT NAME
        _buildLabel("Product Name"),

        _buildTextField(
          controller: _nameController,
          hint: "e.g. Coca-Cola 50cl",
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return "Product name is required";
            }

            return null;
          },
        ),

        const SizedBox(height: 14),

        // PRICE
        _buildLabel("Price (Per Item)"),

        _buildTextField(
          controller: _priceController,
          hint: "0.00",
          prefix: "₦",
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return "Price is required";
            }

            if (double.tryParse(val) == null) {
              return "Enter a valid price";
            }

            return null;
          },
        ),

        const SizedBox(height: 14),

        // COST PRICE
        _buildLabel("Cost Price (Per Item)"),

        _buildTextField(
          controller: _costPriceController,
          hint: "0.00",
          prefix: "₦",
          keyboardType:
              const TextInputType.numberWithOptions(
            decimal: true,
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return "Cost price is required";
            }

            if (double.tryParse(val) == null) {
              return "Enter a valid cost price";
            }

            return null;
          },
        ),

        const SizedBox(height: 14),

        // STOCK QUANTITY
        _buildLabel("Stock Quantity"),

        _buildTextField(
          controller: _stockQuantityController,
          hint: "0",
          keyboardType: TextInputType.number,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return "Stock quantity is required";
            }

            final value = int.tryParse(val);

            if (value == null || value < 0) {
              return "Enter a valid whole number";
            }

            return null;
          },
        ),

        const SizedBox(height: 14),

        // STOCK LIMIT
        _buildLabel(
          "Stock Limit (Low stock alert threshold)",
        ),

        _buildTextField(
          controller: _stockLimitController,
          hint: "0",
          keyboardType: TextInputType.number,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return null;
            }

            final value = int.tryParse(val);

            if (value == null || value < 0) {
              return "Enter a valid whole number";
            }

            return null;
          },
        ),

        const SizedBox(height: 14),

        // UNIT DETAILS BUTTON
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: accentBlue.withOpacity(0.5),
            ),
            foregroundColor: softBlue,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            setSheetState(() {
              _showUnitDetails =
                  !_showUnitDetails;
            });
          },
          icon: Icon(
            _showUnitDetails
                ? Icons.remove
                : Icons.add,
            color: softBlue,
          ),
          label: Text(
            _showUnitDetails
                ? "Hide Unit Details"
                : "Show Unit Details",
          ),
        ),

        // UNIT DETAILS
        if (_showUnitDetails) ...[
          const SizedBox(height: 14),

          _buildLabel(
            "Stock Unit (e.g. bags, kg, litres)",
          ),

          _buildTextField(
            controller: _stockUnitController,
            hint: "bags",
          ),

          const SizedBox(height: 14),

          _buildLabel(
            "Unit Size (e.g. 1 bag = 50kg, enter 50)",
          ),

          _buildTextField(
            controller: _unitSizeController,
            hint: "50",
            keyboardType: TextInputType.number,
            validator: (val) {
              if (val == null ||
                  val.trim().isEmpty) {
                return null;
              }

              final value = int.tryParse(val);

              if (value == null || value < 0) {
                return "Enter a valid whole number";
              }

              return null;
            },
          ),
        ],

        const SizedBox(height: 14),

        // BARCODE
        _buildLabel("Barcode"),

        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                controller: _barcodeController,
                hint: "Scan or generate",
                validator: (val) {
                  if (val == null ||
                      val.trim().isEmpty) {
                    return "Barcode is required";
                  }

                  return null;
                },
              ),
            ),

            const SizedBox(width: 8),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  _generateBarcode();
                  setSheetState(() {});
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      accentBlue,
                  foregroundColor:
                      Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
                child: const Text(
                  "Generate",
                ),
              ),
            ),
          ],
        ),

        // BARCODE PREVIEW
        if (_barcodeController
            .text
            .isNotEmpty) ...[
          const SizedBox(height: 8),

          Container(
            padding:
                const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius:
                  BorderRadius.circular(10),
              border: Border.all(
                color:
                    accentBlue.withOpacity(
                  0.3,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.qr_code,
                  size: 32,
                  color: softBlue,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    _barcodeController.text,
                    style:
                        const TextStyle(
                      fontFamily:
                          'monospace',
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // SHEET HANDLE
  // ============================================================

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin:
            const EdgeInsets.only(
          bottom: 16,
        ),
        decoration: BoxDecoration(
          color:
              softBlue.withOpacity(0.4),
          borderRadius:
              BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ============================================================
  // SUBMIT BUTTON
  // ============================================================

  Widget _buildSubmitButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style:
            ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor:
              Colors.white,
          disabledBackgroundColor:
              accentBlue.withOpacity(0.5),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _submitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child:
                    CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style:
                    const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    String? hint,
    String? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(
        color: softBlue,
        fontSize: 14,
      ),
      prefixText: prefix,
      prefixStyle:
          const TextStyle(
        color: Colors.white,
      ),
      filled: true,
      fillColor: bgColor,
      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            BorderSide.none,
      ),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

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
      style:
          const TextStyle(
        color: Colors.white,
      ),
      decoration:
          _inputDecoration(
        hint: hint,
        prefix: prefix,
      ),
      validator: validator,
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(String text) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 6,
      ),
      child: Text(
        text,
        style:
            const TextStyle(
          fontWeight:
              FontWeight.w600,
          fontSize: 13,
          color: softBlue,
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        8,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _searchProducts,
        style:
            const TextStyle(
          color: Colors.white,
        ),
        decoration:
            InputDecoration(
          hintText:
              "Search products...",
          hintStyle:
              const TextStyle(
            color: softBlue,
          ),
          prefixIcon:
              const Icon(
            Icons.search_rounded,
            color: softBlue,
          ),
          suffixIcon:
              _searchController
                      .text
                      .isNotEmpty
                  ? IconButton(
                      icon:
                          const Icon(
                        Icons
                            .clear_rounded,
                        color:
                            softBlue,
                      ),
                      onPressed: () {
                        _searchController
                            .clear();

                        _searchProducts(
                          '',
                        );
                      },
                    )
                  : null,
          filled: true,
          fillColor: cardColor,
          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            borderSide:
                BorderSide.none,
          ),
          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            borderSide:
                BorderSide.none,
          ),
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            borderSide:
                const BorderSide(
              color: accentBlue,
              width: 1.2,
            ),
          ),
          contentPadding:
              const EdgeInsets
                  .symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT CARD
  // ============================================================

  Widget _buildProductCard(
    Map<String, dynamic> p,
  ) {
    final stockQuantity =
        double.tryParse(
              p['stock_quantity']
                      ?.toString() ??
                  '0',
            ) ??
            0.0;

    final stockLimit =
        double.tryParse(
              p['stock_limit']
                      ?.toString() ??
                  '0',
            ) ??
            0.0;

    final isLowStock =
        stockLimit > 0 &&
            stockQuantity <=
                stockLimit;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border: isLowStock
            ? Border.all(
                color: Colors.orange
                    .withOpacity(0.5),
              )
            : null,
      ),
      child: Row(
        children: [
          // PRODUCT ICON
          Container(
            width: 46,
            height: 46,
            decoration:
                BoxDecoration(
              color: accentBlue
                  .withOpacity(0.2),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child:
                const Icon(
              Icons
                  .inventory_2_rounded,
              color: softBlue,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          // PRODUCT INFORMATION
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  p['name']
                          ?.toString() ??
                      '',
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontWeight:
                        FontWeight.w600,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  "₦${p['price']} • Stock: ${p['stock_quantity']}",
                  maxLines: 1,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      const TextStyle(
                    color: softBlue,
                    fontSize: 13,
                  ),
                ),

                if (isLowStock)
                  const Padding(
                    padding:
                        EdgeInsets.only(
                      top: 4,
                    ),
                    child: Text(
                      "⚠️ Low stock",
                      style:
                          TextStyle(
                        color:
                            Colors.orange,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // EDIT
          IconButton(
            tooltip:
                "Edit Product",
            icon:
                const Icon(
              Icons
                  .edit_outlined,
              color: softBlue,
            ),
            onPressed: () {
              _openEditProductSheet(
                Map<String,
                        dynamic>.from(
                    p),
              );
            },
          ),

          // DELETE
          IconButton(
            tooltip:
                "Delete Product",
            icon:
                const Icon(
              Icons
                  .delete_outline_rounded,
              color:
                  Colors.redAccent,
            ),
            onPressed: () {
              _showDeleteConfirmation(
                p,
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH EMPTY STATE
  // ============================================================

  Widget _buildSearchEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          30,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment
                  .center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration:
                  BoxDecoration(
                color: accentBlue
                    .withOpacity(
                  0.1,
                ),
                shape:
                    BoxShape.circle,
              ),
              child:
                  const Icon(
                Icons
                    .search_off_rounded,
                size: 44,
                color: softBlue,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            const Text(
              "No product found",
              style:
                  TextStyle(
                color:
                    Colors.white,
                fontSize: 18,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'No product matches "${_searchController.text}"',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: softBlue,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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

        iconTheme:
            const IconThemeData(
          color: Colors.white,
        ),

        actions: [
          IconButton(
            icon:
                const Icon(
              Icons
                  .refresh_rounded,
              color: Colors.white,
            ),
            onPressed:
                fetchProducts,
          ),
        ],
      ),

      body: loading
          ? const FullScreenLoader(
              message:
                  "Loading Products...",
            )
          : products.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // SEARCH BAR
                    _buildSearchBar(),

                    // SEARCH RESULT COUNT
                    if (_searchController
                        .text
                        .isNotEmpty)
                      Padding(
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          16,
                          4,
                          16,
                          4,
                        ),
                        child: Align(
                          alignment:
                              Alignment
                                  .centerLeft,
                          child: Text(
                            "${filteredProducts.length} product${filteredProducts.length == 1 ? '' : 's'} found",
                            style:
                                const TextStyle(
                              color:
                                  softBlue,
                              fontSize:
                                  12,
                            ),
                          ),
                        ),
                      ),

                    // PRODUCT LIST
                    Expanded(
                      child: filteredProducts
                              .isEmpty
                          ? _buildSearchEmptyState()
                          : RefreshIndicator(
                              onRefresh:
                                  fetchProducts,
                              color:
                                  accentBlue,
                              backgroundColor:
                                  cardColor,
                              child:
                                  ListView
                                      .builder(
                                padding:
                                    const EdgeInsets
                                        .all(
                                  16,
                                ),
                                itemCount:
                                    filteredProducts
                                        .length,
                                itemBuilder:
                                    (context,
                                        index) {
                                  final p =
                                      filteredProducts[
                                          index];

                                  return _buildProductCard(
                                    Map<String,
                                            dynamic>.from(
                                        p),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),

      floatingActionButton:
          FloatingActionButton(
        onPressed:
            _openAddProductSheet,
        backgroundColor:
            accentBlue,
        child:
            const Icon(
          Icons.add_rounded,
          color: Colors.white,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration:
                BoxDecoration(
              color: accentBlue
                  .withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(
              Icons
                  .inventory_2_outlined,
              size: 48,
              color: softBlue,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          const Text(
            "No products yet",
            style:
                TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          const Text(
            "Tap + to add your first product",
            style:
                TextStyle(
              color: softBlue,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================

  void _showDeleteConfirmation(
    Map<String, dynamic> product,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              cardColor,

          title:
              const Text(
            "Delete Product?",
            style:
                TextStyle(
              color: Colors.white,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          content:
              Text(
            "Are you sure you want to delete "
            "\"${product['name'] ?? 'this product'}\"?",
            style:
                const TextStyle(
              color: softBlue,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
                  const Text(
                "Cancel",
                style:
                    TextStyle(
                  color: softBlue,
                ),
              ),
            ),

            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.redAccent,
                foregroundColor:
                    Colors.white,
              ),
              onPressed: () async {
                Navigator.of(
                  dialogContext,
                ).pop();

                final id =
                    int.tryParse(
                  product['id']
                          ?.toString() ??
                      '',
                );

                if (id != null) {
                  await deleteProduct(
                    id,
                  );
                }
              },
              child:
                  const Text(
                "Delete",
              ),
            ),
          ],
        );
      },
    );
  }
}