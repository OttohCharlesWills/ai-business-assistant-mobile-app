import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../services/stock_transfer_service.dart';
import '../../../services/plan_access_service.dart';
import '../../subscription_screen.dart';

class StockTransferScreen extends StatefulWidget {
  final String baseUrl;
  final String token;

  const StockTransferScreen({
    super.key,
    required this.baseUrl,
    required this.token,
  });

  @override
  State<StockTransferScreen> createState() => _StockTransferScreenState();
}

class _StockTransferScreenState extends State<StockTransferScreen> {
  final StockTransferService _service = StockTransferService();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _quantityController =
      TextEditingController();

  final TextEditingController _costPriceController =
      TextEditingController();

  final TextEditingController _sellingPriceController =
      TextEditingController();

  List<dynamic> _shops = [];
  List<dynamic> _sourceProducts = [];

  int? _sourceShopId;
  int? _destinationShopId;
  int? _productId;

  dynamic _selectedProduct;

  bool _loading = true;
  bool _checkingAccess = true;
  bool _hasAccess = false;
  bool _loadingProducts = false;
  bool _transferring = false;

  String? _errorMessage;

  static const Color _backgroundColor = Color(0xFF0C1F3F);
  static const Color _cardColor = Color(0xFF0F2847);
  static const Color _primaryColor = Color(0xFF2F5DA8);
  static const Color _secondaryText = Color(0xFF8FAADC);
  static const Color _inputColor = Color(0xFF102D50);

  @override
  void initState() {
    super.initState();
    _checkPlanAccess();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // CHECK PLAN ACCESS
  // ---------------------------------------------------------------------------

  Future<void> _checkPlanAccess() async {
    setState(() {
      _checkingAccess = true;
      _loading = true;
    });

    try {
      final allowed = await PlanAccessService.hasFeature(
        'stock_transfer',
      );

      if (!mounted) return;

      setState(() {
        _hasAccess = allowed;
        _checkingAccess = false;
      });

      if (allowed) {
        await _loadShops();
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hasAccess = false;
        _checkingAccess = false;
        _loading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD SHOPS
  // ---------------------------------------------------------------------------

  Future<void> _loadShops() async {
    if (!_hasAccess) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final shops = await _service.getShops(
        baseUrl: widget.baseUrl,
        token: widget.token,
      );

      if (!mounted) return;

      setState(() {
        _shops = shops;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD PRODUCTS FOR SOURCE SHOP
  // ---------------------------------------------------------------------------

  Future<void> _loadProductsForShop(int shopId) async {
    if (!_hasAccess) return;

    setState(() {
      _loadingProducts = true;
      _sourceProducts = [];
      _productId = null;
      _selectedProduct = null;
      _errorMessage = null;
    });

    try {
      final products = await _service.getProductsByShop(
        baseUrl: widget.baseUrl,
        token: widget.token,
        shopId: shopId,
      );

      if (!mounted) return;

      setState(() {
        _sourceProducts = products;
        _loadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingProducts = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  // ---------------------------------------------------------------------------
  // PRODUCT SELECTED
  // ---------------------------------------------------------------------------

  void _selectProduct(int? productId) {
    if (!_hasAccess) return;

    if (productId == null) {
      setState(() {
        _productId = null;
        _selectedProduct = null;
      });
      return;
    }

    dynamic product;

    for (final item in _sourceProducts) {
      if (item['id'] == productId) {
        product = item;
        break;
      }
    }

    setState(() {
      _productId = productId;
      _selectedProduct = product;

      if (product != null) {
        _costPriceController.text =
            (product['cost_price'] ?? '').toString();

        _sellingPriceController.text =
            (product['price'] ?? '').toString();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // TRANSFER
  // ---------------------------------------------------------------------------

  Future<void> _transferStock() async {
    if (!_hasAccess) {
      _showUpgradeMessage();
      return;
    }

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_sourceShopId == null) {
      _showError('Please select the source shop.');
      return;
    }

    if (_destinationShopId == null) {
      _showError('Please select the destination shop.');
      return;
    }

    if (_sourceShopId == _destinationShopId) {
      _showError(
        'Source shop and destination shop cannot be the same.',
      );
      return;
    }

    if (_productId == null) {
      _showError('Please select a product.');
      return;
    }

    final quantity =
        int.tryParse(_quantityController.text.trim());

    final costPrice =
        double.tryParse(_costPriceController.text.trim());

    final sellingPrice =
        double.tryParse(_sellingPriceController.text.trim());

    if (quantity == null || quantity < 1) {
      _showError('Enter a valid quantity.');
      return;
    }

    if (costPrice == null || costPrice < 0) {
      _showError('Enter a valid cost price.');
      return;
    }

    if (sellingPrice == null || sellingPrice < 0) {
      _showError('Enter a valid selling price.');
      return;
    }

    final availableStock =
        _getStockQuantity(_selectedProduct);

    if (quantity > availableStock) {
      _showError(
        'Not enough stock. Available stock: $availableStock',
      );
      return;
    }

    setState(() {
      _transferring = true;
    });

    try {
      final result = await _service.transferStock(
        baseUrl: widget.baseUrl,
        token: widget.token,
        productId: _productId!,
        shopId: _sourceShopId!,
        toShopId: _destinationShopId!,
        quantity: quantity,
        costPrice: costPrice,
        sellingPrice: sellingPrice,
      );

      if (!mounted) return;

      setState(() {
        _transferring = false;
      });

      _showSuccess(
        result['message'] ??
            'Stock transfer completed successfully.',
      );

      _resetForm();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _transferring = false;
      });

      _showError(_cleanError(e));
    }
  }

  // ---------------------------------------------------------------------------
  // RESET FORM
  // ---------------------------------------------------------------------------

  void _resetForm() {
    setState(() {
      _productId = null;
      _selectedProduct = null;
      _destinationShopId = null;

      _quantityController.clear();
      _costPriceController.clear();
      _sellingPriceController.clear();
    });
  }

  // ---------------------------------------------------------------------------
  // OPEN SUBSCRIPTION SCREEN
  // ---------------------------------------------------------------------------

  void _openSubscriptionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubscriptionScreen(
          onActivated: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  int _getStockQuantity(dynamic product) {
    if (product == null) return 0;

    final value = product['stock_quantity'];

    if (value is int) return value;

    return int.tryParse(value.toString()) ?? 0;
  }

  String _getShopName(dynamic shop) {
    return (shop['name'] ??
            shop['shop_name'] ??
            shop['title'] ??
            'Shop ${shop['id']}')
        .toString();
  }

  String _getProductName(dynamic product) {
    return (product['name'] ?? 'Product ${product['id']}')
        .toString();
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _primaryColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showUpgradeMessage() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please upgrade your plan to access this feature.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _primaryColor,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _backgroundColor,
        foregroundColor: Colors.white,
        centerTitle: false,
        title: const Text(
          'Stock Transfer',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: _checkingAccess
          ? const Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
              ),
            )
          : Stack(
              children: [
                _buildPageContent(),

                if (!_hasAccess) _buildLockedOverlay(),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE CONTENT
  // ---------------------------------------------------------------------------

  Widget _buildPageContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _primaryColor,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _hasAccess
          ? _loadShops
          : () async {},
      color: _primaryColor,
      backgroundColor: _cardColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 24),

              _buildTransferCard(),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                _buildErrorBox(),
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LOCK OVERLAY
  // ---------------------------------------------------------------------------

  Widget _buildLockedOverlay() {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 3,
              sigmaY: 3,
            ),
            child: Container(
              color: _backgroundColor.withOpacity(0.72),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: 420,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _primaryColor.withOpacity(0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.16),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: Color(0xFF8FAADC),
                            size: 32,
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Stock Transfer Locked',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'Please upgrade your plan to access this feature.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _secondaryText,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _openSubscriptionScreen,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.workspace_premium_rounded,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Upgrade Plan',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Move stock between shops',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Transfer products from one shop to another without losing track of your inventory.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: _secondaryText,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN CARD
  // ---------------------------------------------------------------------------

  Widget _buildTransferCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _primaryColor.withOpacity(0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.swap_horiz_rounded,
            title: 'Transfer Details',
          ),

          const SizedBox(height: 22),

          _buildLabel('Source Shop'),

          const SizedBox(height: 8),

          _buildShopDropdown(),

          const SizedBox(height: 20),

          _buildLabel('Product'),

          const SizedBox(height: 8),

          _buildProductDropdown(),

          if (_selectedProduct != null) ...[
            const SizedBox(height: 12),
            _buildStockInfo(),
          ],

          const SizedBox(height: 20),

          _buildLabel('Destination Shop'),

          const SizedBox(height: 8),

          _buildDestinationDropdown(),

          const SizedBox(height: 20),

          _buildLabel('Quantity'),

          const SizedBox(height: 8),

          _buildTextField(
            controller: _quantityController,
            hint: 'Enter quantity',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.inventory_2_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Quantity is required';
              }

              final quantity = int.tryParse(value.trim());

              if (quantity == null || quantity < 1) {
                return 'Enter a valid quantity';
              }

              return null;
            },
          ),

          const SizedBox(height: 20),

          _buildLabel('Cost Price'),

          const SizedBox(height: 8),

          _buildTextField(
            controller: _costPriceController,
            hint: 'Enter cost price',
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            prefixIcon: Icons.money_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Cost price is required';
              }

              final price = double.tryParse(value.trim());

              if (price == null || price < 0) {
                return 'Enter a valid cost price';
              }

              return null;
            },
          ),

          const SizedBox(height: 20),

          _buildLabel('Selling Price'),

          const SizedBox(height: 8),

          _buildTextField(
            controller: _sellingPriceController,
            hint: 'Enter selling price',
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            prefixIcon: Icons.sell_outlined,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Selling price is required';
              }

              final price = double.tryParse(value.trim());

              if (price == null || price < 0) {
                return 'Enter a valid selling price';
              }

              return null;
            },
          ),

          const SizedBox(height: 28),

          _buildTransferButton(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHOP DROPDOWN
  // ---------------------------------------------------------------------------

  Widget _buildShopDropdown() {
    return DropdownButtonFormField<int>(
      value: _sourceShopId,
      isExpanded: true,
      dropdownColor: _cardColor,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: _inputDecoration(
        hint: 'Select source shop',
        prefixIcon: Icons.store_outlined,
      ),
      items: _shops.map<DropdownMenuItem<int>>((shop) {
        final id = int.tryParse(
          shop['id'].toString(),
        );

        return DropdownMenuItem<int>(
          value: id,
          child: Text(
            _getShopName(shop),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null || !_hasAccess) return;

        setState(() {
          _sourceShopId = value;
          _destinationShopId = null;
        });

        _loadProductsForShop(value);
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a source shop';
        }

        return null;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // PRODUCT DROPDOWN
  // ---------------------------------------------------------------------------

  Widget _buildProductDropdown() {
    if (_loadingProducts) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          color: _inputColor,
          border: Border.all(
            color: _primaryColor.withOpacity(0.25),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _primaryColor,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Loading products...',
              style: TextStyle(
                color: _secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _productId,
      isExpanded: true,
      dropdownColor: _cardColor,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: _inputDecoration(
        hint: _sourceShopId == null
            ? 'Select a source shop first'
            : _sourceProducts.isEmpty
                ? 'No products found'
                : 'Select product',
        prefixIcon: Icons.inventory_2_outlined,
      ),
      items: _sourceProducts.map<DropdownMenuItem<int>>(
        (product) {
          final id = int.tryParse(
            product['id'].toString(),
          );

          return DropdownMenuItem<int>(
            value: id,
            child: Text(
              _getProductName(product),
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ).toList(),
      onChanged: _sourceShopId == null ||
              _sourceProducts.isEmpty ||
              !_hasAccess
          ? null
          : _selectProduct,
      validator: (value) {
        if (value == null) {
          return 'Please select a product';
        }

        return null;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DESTINATION DROPDOWN
  // ---------------------------------------------------------------------------

  Widget _buildDestinationDropdown() {
    final availableShops = _shops.where((shop) {
      final id = int.tryParse(
        shop['id'].toString(),
      );

      return id != _sourceShopId;
    }).toList();

    return DropdownButtonFormField<int>(
      value: _destinationShopId,
      isExpanded: true,
      dropdownColor: _cardColor,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: _inputDecoration(
        hint: _sourceShopId == null
            ? 'Select source shop first'
            : 'Select destination shop',
        prefixIcon:
            Icons.store_mall_directory_outlined,
      ),
      items: availableShops.map<DropdownMenuItem<int>>(
        (shop) {
          final id = int.tryParse(
            shop['id'].toString(),
          );

          return DropdownMenuItem<int>(
            value: id,
            child: Text(
              _getShopName(shop),
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ).toList(),
      onChanged: _sourceShopId == null || !_hasAccess
          ? null
          : (value) {
              setState(() {
                _destinationShopId = value;
              });
            },
      validator: (value) {
        if (value == null) {
          return 'Please select a destination shop';
        }

        return null;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // STOCK INFO
  // ---------------------------------------------------------------------------

  Widget _buildStockInfo() {
    final stock = _getStockQuantity(_selectedProduct);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _primaryColor.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 20,
            color: Color(0xFF8FAADC),
          ),
          const SizedBox(width: 10),
          const Text(
            'Available stock:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            stock.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF8FAADC),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUTTON
  // ---------------------------------------------------------------------------

  Widget _buildTransferButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _transferring
            ? null
            : _transferStock,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              _primaryColor.withOpacity(.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _transferring
            ? const SizedBox(
                width: 23,
                height: 23,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz_rounded),
                  SizedBox(width: 8),
                  Text(
                    'Transfer Stock',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ERROR BOX
  // ---------------------------------------------------------------------------

  Widget _buildErrorBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.redAccent.withOpacity(.20),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.redAccent,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION TITLE
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF8FAADC),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // LABEL
  // ---------------------------------------------------------------------------

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFFB7C8E5),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TEXT FIELD
  // ---------------------------------------------------------------------------

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
    required IconData prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: Colors.white,
      ),
      cursorColor: _primaryColor,
      decoration: _inputDecoration(
        hint: hint,
        prefixIcon: prefixIcon,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INPUT DECORATION
  // ---------------------------------------------------------------------------

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF6F88AD),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: const Color(0xFF8FAADC),
        size: 21,
      ),
      filled: true,
      fillColor: _inputColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _primaryColor.withOpacity(0.20),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _primaryColor.withOpacity(0.20),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: _primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
      errorStyle: const TextStyle(
        color: Colors.redAccent,
      ),
    );
  }
}