import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/receipt_data.dart';

/// Turns a [ReceiptData] into a thermal-roll PDF and prints or shares it.
///
/// This is the ONLY file that knows how printing happens. To print straight
/// to a POS machine's built-in printer (Sunmi, PAX, Telpo ...), replace the
/// body of [printReceipt] with that machine's printer SDK; the receipt page
/// and data stay exactly as they are.
class ReceiptPrinter {
  /// Paper width. Handheld POS terminals almost always use 58 mm rolls.
  /// Use PdfPageFormat.roll80 for 80 mm printers.
  static const PdfPageFormat paper = PdfPageFormat.roll57;

  /// The built-in PDF font has no naira sign, so printed amounts use "N".
  static const String _currency = 'N';

  /// Opens Android's print dialog with the receipt ready to print.
  static Future<void> printReceipt(ReceiptData receipt) async {
    await Printing.layoutPdf(
      name: 'Receipt ${receipt.transactionId ?? ''}'.trim(),
      format: paper,
      onLayout: (format) => buildPdf(receipt, format: format),
    );
  }

  /// Share / save the receipt as a PDF (WhatsApp, email, Drive ...).
  static Future<void> shareReceipt(ReceiptData receipt) async {
    final bytes = await buildPdf(receipt);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'receipt-${receipt.transactionId ?? 'sale'}.pdf',
    );
  }

  static Future<Uint8List> buildPdf(
    ReceiptData r, {
    PdfPageFormat format = paper,
  }) async {
    final doc = pw.Document(title: 'Receipt ${r.transactionId ?? ''}'.trim());
    const mm = PdfPageFormat.mm;

    String money(double v) => formatMoney(v, symbol: _currency);

    pw.Widget dash() => pw.Padding(
          padding: pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Divider(
            borderStyle: pw.BorderStyle.dashed,
            thickness: 0.6,
            height: 1,
          ),
        );

    pw.Widget text(
      String value, {
      double size = 8,
      bool bold = false,
      pw.TextAlign align = pw.TextAlign.left,
    }) {
      return pw.Text(
        value,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: size,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      );
    }

    pw.Widget row(
      String left,
      String right, {
      double size = 8,
      bool bold = false,
    }) {
      return pw.Padding(
        padding: pw.EdgeInsets.symmetric(vertical: 1),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: text(left, size: size, bold: bold)),
            pw.SizedBox(width: 6),
            text(right, size: size, bold: bold),
          ],
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: format.copyWith(
          marginLeft: 3 * mm,
          marginRight: 3 * mm,
          marginTop: 4 * mm,
          marginBottom: 8 * mm,
        ),
        build: (context) => pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            text(r.businessName,
                size: 12, bold: true, align: pw.TextAlign.center),
            pw.SizedBox(height: 1),
            text('SALES RECEIPT', size: 7, align: pw.TextAlign.center),
            dash(),
            row('Receipt no.', r.transactionId ?? '-'),
            row('Date', formatReceiptDate(r.date)),
            if (r.cashierName != null) row('Cashier', r.cashierName!),
            if (r.customerName != null) row('Customer', r.customerName!),
            if (r.customerPhone != null) row('Phone', r.customerPhone!),
            row('Payment', paymentLabel(r.paymentMethod)),
            dash(),
            for (final line in r.lines) ...[
              text(line.name, bold: true),
              row('${line.quantity} x ${money(line.unitPrice)}',
                  money(line.gross)),
              if (line.discount > 0)
                row('  Discount', '-${money(line.discount)}'),
              pw.SizedBox(height: 3),
            ],
            dash(),
            row('Subtotal', money(r.subtotal)),
            if (r.totalDiscount > 0)
              row('Discount', '-${money(r.totalDiscount)}'),
            pw.SizedBox(height: 2),
            row('TOTAL', money(r.total), size: 11, bold: true),
            dash(),
            pw.SizedBox(height: 2),
            text('Thank you for your patronage',
                size: 7.5, align: pw.TextAlign.center),
          ],
        ),
      ),
    );

    return doc.save();
  }
}