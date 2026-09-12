import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/cashier_dashboard_service.dart';
import '../../../widgets/app_loader.dart';

/// ---------------------------------------------------------------------
/// BRAND COLORS (matches DashboardScreen)
/// ---------------------------------------------------------------------
const kBgColor = Color(0xFF0C1F3F);
const kCardColor = Color(0xFF0F2847);
const kPrimaryColor = Color(0xFF2F5DA8);
const kMutedColor = Color(0xFF8FAADC);
const kSuccessColor = Color(0xFF4CAF50);

/// ---------------------------------------------------------------------
/// MODEL
/// Mirrors the fields used in the Blade view:
/// product->name, product->category->name, quantity, total_price,
/// payment_method, created_at, shop->name, transaction_id,
/// discount_value, customer_name, customer_phone, sale_type.
///
/// Adjust the JSON keys below if your API's actual response shape
/// differs (e.g. flat "product_name" instead of nested "product.name").
/// ---------------------------------------------------------------------
class CashierSale {
  final String productName;
  final String categoryName;
  final int quantity;
  final double totalPrice;
  final double discountValue;
  final String paymentMethod;
  final DateTime? createdAt;
  final String shopName;
  final String transactionId;
  final String customerName;
  final String customerPhone;
  final String saleType;

  CashierSale({
    required this.productName,
    required this.categoryName,
    required this.quantity,
    required this.totalPrice,
    required this.discountValue,
    required this.paymentMethod,
    required this.createdAt,
    required this.shopName,
    required this.transactionId,
    required this.customerName,
    required this.customerPhone,
    required this.saleType,
  });

  factory CashierSale.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) =>
        v == null ? 0.0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0);

    final product = json['product'] as Map<String, dynamic>?;
    final category = product?['category'] as Map<String, dynamic>?;
    final shop = json['shop'] as Map<String, dynamic>?;

    return CashierSale(
      productName: product?['name']?.toString() ?? 'Product Deleted',
      categoryName: category?['name']?.toString() ?? 'Category Missing',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      totalPrice: toDouble(json['total_price']),
      discountValue: toDouble(json['discount_value']),
      paymentMethod: (json['payment_method']?.toString() ?? '-'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      shopName: shop?['name']?.toString() ?? 'Unknown Shop',
      transactionId: json['transaction_id']?.toString() ?? 'Unknown Transaction',
      customerName: json['customer_name']?.toString() ?? 'Empty',
      customerPhone: json['customer_phone']?.toString() ?? 'Empty',
      saleType: json['sale_type']?.toString() ?? '',
    );
  }
}

/// ---------------------------------------------------------------------
/// SCREEN
/// ---------------------------------------------------------------------
class CashierSalesScreen extends StatefulWidget {
  const CashierSalesScreen({super.key});

  @override
  State<CashierSalesScreen> createState() => _CashierSalesScreenState();
}

class _CashierSalesScreenState extends State<CashierSalesScreen> {
  final _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _activeQuick; // 'today' | 'yesterday' | 'week' | 'month'

  bool _loading = false;
  String? _error;
  List<CashierSale> _sales = [];
  double _grandTotal = 0;

  final _dateFmt = DateFormat('yyyy-MM-dd');
  final _currencyFmt = NumberFormat.currency(locale: 'en_NG', symbol: '₦');

  @override
  void initState() {
    super.initState();
    _fetch(); // load unfiltered/default on open
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await CashierDashboardService.getCashierSales(
      search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      startDate: _activeQuick == null && _startDate != null ? _dateFmt.format(_startDate!) : null,
      endDate: _activeQuick == null && _endDate != null ? _dateFmt.format(_endDate!) : null,
      quick: _activeQuick,
    );

    if (!mounted) return;

    if (result['success'] == false) {
      setState(() {
        _loading = false;
        _error = result['message']?.toString() ?? 'Failed to load sales';
        _sales = [];
        _grandTotal = 0;
      });
      return;
    }

    final list = (result['data'] ?? result['sales'] ?? []) as List<dynamic>;
    final sales = list
        .whereType<Map<String, dynamic>>()
        .map(CashierSale.fromJson)
        .toList();

    setState(() {
      _loading = false;
      _sales = sales;
      _grandTotal = sales.fold(0.0, (sum, s) => sum + s.totalPrice);
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: kPrimaryColor,
              onPrimary: Colors.white,
              surface: kCardColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _activeQuick = null; // manual date picking overrides quick filter
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  void _applyQuick(String quick) {
    setState(() {
      _activeQuick = quick;
      _startDate = null;
      _endDate = null;
    });
    _fetch();
  }

  void _clearFilters() {
    setState(() {
      _activeQuick = null;
      _startDate = null;
      _endDate = null;
      _searchController.clear();
    });
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Cashier Sales',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: kPrimaryColor,
        backgroundColor: kCardColor,
        child: Column(
          children: [
            _buildFilters(),
            _buildTotalBanner(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search product, customer, transaction...',
              hintStyle: const TextStyle(color: kMutedColor, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: kMutedColor),
              filled: true,
              fillColor: kCardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: kMutedColor),
                      onPressed: () {
                        _searchController.clear();
                        _fetch();
                      },
                    )
                  : null,
            ),
            onSubmitted: (_) => _fetch(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _dateButton(
                  label: _startDate == null ? 'Start date' : _dateFmt.format(_startDate!),
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dateButton(
                  label: _endDate == null ? 'End date' : _dateFmt.format(_endDate!),
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _fetch,
                child: const Text('Filter', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickChip('Today', 'today'),
              _quickChip('Yesterday', 'yesterday'),
              _quickChip('This Week', 'week'),
              _quickChip('This Month', 'month'),
              ActionChip(
                backgroundColor: kCardColor,
                side: BorderSide.none,
                avatar: const Icon(Icons.clear_all, size: 16, color: kMutedColor),
                label: const Text('Clear', style: TextStyle(color: kMutedColor, fontSize: 12)),
                onPressed: _clearFilters,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _dateButton({required String label, required VoidCallback onTap}) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: kPrimaryColor, width: 1),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today, size: 14, color: kMutedColor),
      label: Text(
        label,
        style: const TextStyle(color: kMutedColor, fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _quickChip(String label, String value) {
    final selected = _activeQuick == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : kMutedColor,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedColor: kPrimaryColor,
      backgroundColor: kCardColor,
      side: BorderSide.none,
      onSelected: (_) => _applyQuick(value),
    );
  }

  Widget _buildTotalBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Total Sales',
            style: TextStyle(color: kMutedColor, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            _currencyFmt.format(_grandTotal),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const FullScreenLoader(message: "Loading sales...");
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kMutedColor),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _fetch,
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }
    if (_sales.isEmpty) {
      return const Center(
        child: Text(
          'No sales found for the selected filters',
          style: TextStyle(color: kMutedColor),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: _sales.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _SaleCard(sale: _sales[index], currencyFmt: _currencyFmt),
    );
  }
}

class _SaleCard extends StatelessWidget {
  final CashierSale sale;
  final NumberFormat currencyFmt;

  const _SaleCard({required this.sale, required this.currencyFmt});

  @override
  Widget build(BuildContext context) {
    final hasDiscount = sale.discountValue > 0;
    final originalPrice = sale.totalPrice + sale.discountValue;
    final dateStr = sale.createdAt != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(sale.createdAt!)
        : 'Unknown date';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sale.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
              if (hasDiscount) ...[
                Text(
                  currencyFmt.format(originalPrice),
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.redAccent,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                currencyFmt.format(sale.totalPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kSuccessColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${sale.categoryName} • Qty: ${sale.quantity} • ${sale.saleType}',
            style: const TextStyle(color: kMutedColor, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            '${sale.shopName} • ${_titleCase(sale.paymentMethod)}',
            style: const TextStyle(color: kMutedColor, fontSize: 12),
          ),
          Text(
            dateStr,
            style: const TextStyle(color: kMutedColor, fontSize: 12),
          ),
          Divider(height: 20, color: Colors.white.withOpacity(0.08)),
          Text(
            'Txn: ${sale.transactionId}',
            style: const TextStyle(color: kMutedColor, fontSize: 12),
          ),
          if (sale.customerName != 'Empty' || sale.customerPhone != 'Empty')
            Text(
              'Customer: ${sale.customerName} (${sale.customerPhone})',
              style: const TextStyle(color: kMutedColor, fontSize: 12),
            ),
        ],
      ),
    );
  }

  String _titleCase(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}