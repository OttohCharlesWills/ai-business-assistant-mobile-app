import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';

import '../models/receipt_data.dart';
import '../services/receipt_printer.dart';

/// Shown right after a sale: the receipt as it will print, with the
/// transaction ID on it, and buttons to print or share it.
class ReceiptScreen extends StatefulWidget {
  final ReceiptData receipt;

  const ReceiptScreen({super.key, required this.receipt});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  static const _bg = Color(0xFF0C1F3F);
  static const _accent = Color(0xFF2F5DA8);
  static const _muted = Color(0xFF8FAADC);

  static const _ink = TextStyle(
    fontFamily: 'monospace',
    color: Color(0xFF1A1A1A),
    fontSize: 12.5,
    height: 1.35,
  );

  bool _busy = false;

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
      );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      debugPrint('Receipt action failed: $e');
      _snack('Could not print. Check that a printer is available and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Receipt',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Center(child: _buildPaper()),
            ),
          ),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _row(String left, String right, {bool bold = false, double size = 12.5}) {
    final style = _ink.copyWith(
      fontSize: size,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(left, style: style)),
          const SizedBox(width: 8),
          Text(right, style: style),
        ],
      ),
    );
  }

  Widget _buildPaper() {
    final r = widget.receipt;

    return Container(
      width: 330,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            r.businessName,
            textAlign: TextAlign.center,
            style: _ink.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'SALES RECEIPT',
            textAlign: TextAlign.center,
            style: _ink.copyWith(fontSize: 11, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          const _DashedLine(),
          const SizedBox(height: 8),
          _row('Receipt no.', r.transactionId ?? '-'),
          _row('Date', formatReceiptDate(r.date)),
          if (r.cashierName != null) _row('Cashier', r.cashierName!),
          if (r.customerName != null) _row('Customer', r.customerName!),
          if (r.customerPhone != null) _row('Phone', r.customerPhone!),
          _row('Payment', paymentLabel(r.paymentMethod)),
          const SizedBox(height: 8),
          const _DashedLine(),
          const SizedBox(height: 8),
          for (final line in r.lines) ...[
            Text(line.name, style: _ink.copyWith(fontWeight: FontWeight.w700)),
            _row('${line.quantity} x ${formatMoney(line.unitPrice)}',
                formatMoney(line.gross)),
            if (line.discount > 0)
              _row('  Discount', '-${formatMoney(line.discount)}'),
            const SizedBox(height: 6),
          ],
          const _DashedLine(),
          const SizedBox(height: 8),
          _row('Subtotal', formatMoney(r.subtotal)),
          if (r.totalDiscount > 0)
            _row('Discount', '-${formatMoney(r.totalDiscount)}'),
          const SizedBox(height: 4),
          _row('TOTAL', formatMoney(r.total), bold: true, size: 16),
          const SizedBox(height: 12),
          const _DashedLine(),
          const SizedBox(height: 12),
          Text(
            'Thank you for your patronage',
            textAlign: TextAlign.center,
            style: _ink,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final outlined = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      foregroundColor: _muted,
      side: BorderSide(color: _accent.withOpacity(0.5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  disabledBackgroundColor: _accent.withOpacity(0.35),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _busy
                    ? null
                    : () => _run(() => ReceiptPrinter.printReceipt(widget.receipt)),
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.print_rounded, color: Colors.white),
                label: const Text(
                  'Print receipt',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: outlined,
                    onPressed: _busy
                        ? null
                        : () => _run(() => ReceiptPrinter.shareReceipt(widget.receipt)),
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: const Text('Share PDF'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: outlined,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('New sale'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A dashed rule, like the ones on a thermal receipt.
class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dash = 4.0;
        const gap = 3.0;
        final count = (constraints.maxWidth / (dash + gap)).floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => const SizedBox(
              width: dash,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black45),
              ),
            ),
          ),
        );
      },
    );
  }
}