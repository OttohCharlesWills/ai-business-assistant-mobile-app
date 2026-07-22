import 'package:flutter/material.dart';
import '../../../services/invoice_service.dart';
import 'create_invoice_screen.dart';
import 'invoice_details_screen.dart';
import 'payment_screen.dart';
import '../../../widgets/app_loader.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {

  static const bgColor = Color(0xFF0C1F3F);
  static const cardColor = Color(0xFF0F2847);
  static const accentBlue = Color(0xFF2F5DA8);
  static const softBlue = Color(0xFF8FAADC);

  bool isLoading = true;

  List invoices = [];
  List filteredInvoices = [];

  int totalInvoices = 0;
  int totalPeopleOwing = 0;
  double totalBalance = 0;

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadInvoices();
  }

  Future<void> loadInvoices() async {
    setState(() => isLoading = true);

    final data = await InvoiceService.getInvoices(refresh: true);

    if (data != null) {
      invoices = data["all_invoices"] ?? [];
      filteredInvoices = invoices;
      totalInvoices = data["total_invoices"] ?? 0;
      totalPeopleOwing = (data["owing_invoices"] as List).length;
      totalBalance = double.tryParse(data["total_owing"].toString()) ?? 0;
    }

    setState(() => isLoading = false);
  }

  void search(String value) {
    value = value.toLowerCase();
    setState(() {
      filteredInvoices = invoices.where((invoice) {
        final customer = (invoice["customer"]?["name"] ?? "").toString().toLowerCase();
        final phone = (invoice["customer"]?["phone"] ?? "").toString().toLowerCase();
        return customer.contains(value) || phone.contains(value);
      }).toList();
    });
  }

  String _formatMoney(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    return "₦${number.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    )}";
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
          "Invoices",
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
            onPressed: loadInvoices,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
          ).then((_) => loadInvoices());
        },
        backgroundColor: accentBlue,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),

      // ✅ UPDATED: branded loader instead of plain CircularProgressIndicator
      body: isLoading
          ? const FullScreenLoader(message: "Loading invoices...")
          : RefreshIndicator(
              onRefresh: loadInvoices,
              color: accentBlue,
              backgroundColor: cardColor,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [

                  // STAT CARDS ROW 1
                  Row(
                    children: [
                      _statCard(
                        color: const Color(0xFFE65100),
                        title: "People Owing",
                        value: totalPeopleOwing.toString(),
                        icon: Icons.people_rounded,
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        color: const Color(0xFFB71C1C),
                        title: "Balance",
                        value: _formatMoney(totalBalance),
                        icon: Icons.payments_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // STAT CARDS ROW 2
                  Row(
                    children: [
                      _statCard(
                        color: accentBlue,
                        title: "Total Invoices",
                        value: totalInvoices.toString(),
                        icon: Icons.receipt_long_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // SEARCH
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: search,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Search customer name or phone",
                        hintStyle: TextStyle(color: softBlue, fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: softBlue),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // INVOICE LIST
                  filteredInvoices.isEmpty
                      ? Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: accentBlue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 40,
                                  color: softBlue,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "No invoices yet",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Tap + to create your first invoice",
                                style: TextStyle(color: softBlue, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: filteredInvoices.map((invoice) {
                            final status = invoice["payment_status"] ?? "";
                            final isOwing = status == "owing";

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),

                                leading: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: accentBlue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_rounded,
                                    color: softBlue,
                                  ),
                                ),

                                title: Text(
                                  invoice["customer"]?["name"] ?? "Unknown",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),

                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      "Shop: ${invoice["shop"]?["name"] ?? "N/A"}",
                                      style: const TextStyle(
                                          color: softBlue, fontSize: 12),
                                    ),
                                    Text(
                                      "Total: ${_formatMoney(invoice["total"])} • Paid: ${_formatMoney(invoice["amount_paid"])}",
                                      style: const TextStyle(
                                          color: softBlue, fontSize: 12),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isOwing
                                                ? Colors.redAccent.withOpacity(0.15)
                                                : Colors.green.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isOwing
                                                  ? Colors.redAccent.withOpacity(0.4)
                                                  : Colors.green.withOpacity(0.4),
                                            ),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: isOwing
                                                  ? Colors.redAccent
                                                  : Colors.green,
                                            ),
                                          ),
                                        ),
                                        if (isOwing) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            "Balance: ${_formatMoney(invoice["balance"])}",
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),

                                trailing: PopupMenuButton(
                                  color: bgColor,
                                  icon: const Icon(Icons.more_vert_rounded,
                                      color: softBlue),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 1,
                                      child: Row(
                                        children: [
                                          Icon(Icons.visibility_rounded,
                                              color: Colors.white, size: 18),
                                          SizedBox(width: 10),
                                          Text("Preview",
                                              style: TextStyle(color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 2,
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_rounded,
                                              color: Colors.white, size: 18),
                                          SizedBox(width: 10),
                                          Text("Edit Payment",
                                              style: TextStyle(color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 3,
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle_rounded,
                                              color: Colors.green, size: 18),
                                          SizedBox(width: 10),
                                          Text("Mark Paid",
                                              style: TextStyle(color: Colors.green)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 4,
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline_rounded,
                                              color: Colors.redAccent, size: 18),
                                          SizedBox(width: 10),
                                          Text("Delete",
                                              style:
                                                  TextStyle(color: Colors.redAccent)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) async {

                                    // PREVIEW
                                    if (value == 1) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => InvoiceDetailsScreen(
                                            invoiceId: invoice["id"],
                                          ),
                                        ),
                                      );
                                    }

                                    // EDIT PAYMENT
                                    if (value == 2) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PaymentScreen(
                                            invoice: invoice,
                                          ),
                                        ),
                                      ).then((_) => loadInvoices());
                                    }

                                    // MARK PAID
                                    if (value == 3) {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => Dialog(
                                          backgroundColor: cardColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.check_circle_rounded,
                                                    color: Colors.green, size: 48),
                                                const SizedBox(height: 16),
                                                const Text(
                                                  "Mark as Paid",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18),
                                                ),
                                                const SizedBox(height: 8),
                                                const Text(
                                                  "Mark this invoice as fully paid?",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(color: softBlue),
                                                ),
                                                const SizedBox(height: 24),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: OutlinedButton(
                                                        style: OutlinedButton.styleFrom(
                                                          side: BorderSide(
                                                              color: accentBlue
                                                                  .withOpacity(0.4)),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                      12)),
                                                        ),
                                                        onPressed: () =>
                                                            Navigator.pop(context, false),
                                                        child: const Text("Cancel",
                                                            style: TextStyle(
                                                                color: softBlue)),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.green,
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                      12)),
                                                          elevation: 0,
                                                        ),
                                                        onPressed: () =>
                                                            Navigator.pop(context, true),
                                                        child: const Text("Confirm",
                                                            style: TextStyle(
                                                                color: Colors.white)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );

                                      if (confirm == true) {
                                        await InvoiceService.markPaid(invoice["id"]);
                                        loadInvoices();
                                      }
                                    }

                                    // DELETE
                                    if (value == 4) {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => Dialog(
                                          backgroundColor: cardColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(24),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: Colors.redAccent
                                                        .withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(14),
                                                  ),
                                                  child: const Icon(
                                                      Icons.delete_outline_rounded,
                                                      color: Colors.redAccent),
                                                ),
                                                const SizedBox(height: 16),
                                                const Text(
                                                  "Delete Invoice",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 18),
                                                ),
                                                const SizedBox(height: 8),
                                                const Text(
                                                  "Are you sure? This cannot be undone.",
                                                  style: TextStyle(
                                                      color: softBlue, height: 1.5),
                                                ),
                                                const SizedBox(height: 24),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: OutlinedButton(
                                                        style: OutlinedButton.styleFrom(
                                                          side: BorderSide(
                                                              color: accentBlue
                                                                  .withOpacity(0.4)),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                      12)),
                                                        ),
                                                        onPressed: () =>
                                                            Navigator.pop(context, false),
                                                        child: const Text("Cancel",
                                                            style: TextStyle(
                                                                color: softBlue)),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.redAccent,
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                      12)),
                                                          elevation: 0,
                                                        ),
                                                        onPressed: () =>
                                                            Navigator.pop(context, true),
                                                        child: const Text("Delete",
                                                            style: TextStyle(
                                                                color: Colors.white)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );

                                      if (ok == true) {
                                        await InvoiceService.deleteInvoice(invoice["id"]);
                                        loadInvoices();
                                      }
                                    }
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _statCard({
    required Color color,
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}