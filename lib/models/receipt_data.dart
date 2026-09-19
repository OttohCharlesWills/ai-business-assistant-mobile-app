/// Shown at the top of every receipt.
/// TODO: replace with the shop's real name/address once the app loads it.
const String kReceiptBusinessName = 'Bloommonie';

/// Laravel sends decimals as strings unless the model casts them,
/// so accept both.
double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class ReceiptLine {
  final String name;
  final int quantity;
  final double unitPrice;

  /// Discount as an amount in naira (already worked out from % or flat).
  final double discount;

  const ReceiptLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0,
  });

  double get gross => unitPrice * quantity;
  double get total => gross - discount < 0 ? 0 : gross - discount;
}

class ReceiptData {
  final String businessName;
  final String? transactionId;
  final DateTime date;
  final String? cashierName;
  final String? customerName;
  final String? customerPhone;
  final String paymentMethod;
  final List<ReceiptLine> lines;

  const ReceiptData({
    required this.businessName,
    required this.transactionId,
    required this.date,
    required this.cashierName,
    required this.customerName,
    required this.customerPhone,
    required this.paymentMethod,
    required this.lines,
  });

  double get subtotal => lines.fold(0.0, (sum, l) => sum + l.gross);
  double get totalDiscount => lines.fold(0.0, (sum, l) => sum + l.discount);
  double get total => lines.fold(0.0, (sum, l) => sum + l.total);

  /// Builds a receipt from the POS cart. Call this BEFORE clearing the cart:
  /// the lines are copied, so clearing the cart afterwards is safe.
  factory ReceiptData.fromCart({
    required List<Map<String, dynamic>> cart,
    required String paymentMethod,
    String? transactionId,
    String? cashierName,
    String? customerName,
    String? customerPhone,
    String businessName = kReceiptBusinessName,
  }) {
    final lines = cart.map((item) {
      final product = item['product'] as Map<String, dynamic>;
      final quantity = item['quantity'] as int;
      final price = _toDouble(product['price']);
      final gross = price * quantity;
      final value = _toDouble(item['discount_value']);

      double discount = 0;
      if (item['discount_type'] == 'percentage') {
        discount = gross * value / 100;
      } else if (item['discount_type'] == 'flat') {
        discount = value;
      }
      if (discount > gross) discount = gross;

      return ReceiptLine(
        name: (product['name'] ?? '').toString(),
        quantity: quantity,
        unitPrice: price,
        discount: discount,
      );
    }).toList();

    String? clean(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();

    return ReceiptData(
      businessName: businessName,
      transactionId: clean(transactionId),
      date: DateTime.now(),
      cashierName: clean(cashierName),
      customerName: clean(customerName),
      customerPhone: clean(customerPhone),
      paymentMethod: paymentMethod,
      lines: lines,
    );
  }
}

/// 1234567.5 -> ₦1,234,567.50
String formatMoney(double value, {String symbol = '₦'}) {
  final parts = value.toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '$symbol$whole.${parts[1]}';
}

/// 19/09/2026  14:05
String formatReceiptDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year}  ${two(d.hour)}:${two(d.minute)}';
}

/// cash -> Cash
String paymentLabel(String method) =>
    method.isEmpty ? '' : method[0].toUpperCase() + method.substring(1);