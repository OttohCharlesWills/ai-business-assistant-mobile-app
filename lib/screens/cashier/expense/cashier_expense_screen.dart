import 'package:flutter/material.dart';
import '../../../services/cashier_expense_service.dart';
import '../../../services/shop_service.dart';
import '../../../widgets/app_loader.dart';

class CashierExpenseScreen extends StatefulWidget {
  const CashierExpenseScreen({super.key});

  @override
  State<CashierExpenseScreen> createState() => _CashierExpenseScreenState();
}

class _CashierExpenseScreenState extends State<CashierExpenseScreen> {
  static const Color bgColor = Color(0xFF0C1F3F);
  static const Color cardColor = Color(0xFF0F2847);
  static const Color accentColor = Color(0xFF2F5DA8);
  static const Color subtitleColor = Color(0xFF8FAADC);

  List expenses = [];
  List shops = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchExpenses();
    fetchShops();
  }

  Future<void> fetchExpenses() async {
    setState(() => loading = true);
    final response = await CashierExpenseService.getExpenses();
    setState(() {
      // Page 1 only — expenses['expenses'] is a Laravel paginator object.
      expenses = response['success'] == true ? (response['expenses']?['data'] ?? []) : [];
      loading = false;
    });
  }

  Future<void> fetchShops() async {
    // ASSUMPTION: ShopService.getShops(refresh:) mirrors CategoryService.getCategories(refresh:)
    // and returns a List of shop maps with 'id' and 'name'. Adjust if the real signature differs.
    final data = await ShopService.getShops(refresh: true);
    setState(() => shops = data);
  }

  String formatMoney(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    return "\u20a6${number.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    )}";
  }

  String formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final date = DateTime.parse(raw);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return "${months[date.month - 1]} ${date.day}, ${date.year}";
    } catch (_) {
      return raw;
    }
  }

  Future<void> showAddDialog() async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final dateController = TextEditingController(
      text: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
    );
    final descriptionController = TextEditingController();
    dynamic selectedShopId = shops.isNotEmpty ? shops.first['id'] : null;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.payments_outlined, color: subtitleColor),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Add Expense",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Title, amount, shop and date are required",
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  _dialogField(titleController, "Expense title (e.g. Generator Fuel)"),
                  const SizedBox(height: 10),

                  _dialogField(amountController, "Amount (\u20a6)", keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 10),

                  // SHOP DROPDOWN
                  Container(
                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
                    child: DropdownButtonFormField<dynamic>(
                      value: selectedShopId,
                      dropdownColor: cardColor,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Select shop",
                        hintStyle: TextStyle(color: subtitleColor, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: shops
                          .map<DropdownMenuItem<dynamic>>((shop) => DropdownMenuItem(
                                value: shop['id'],
                                child: Text(shop['name'] ?? 'Shop'),
                              ))
                          .toList(),
                      onChanged: (value) => setStateDialog(() => selectedShopId = value),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // DATE PICKER
                  Container(
                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
                    child: TextField(
                      controller: dateController,
                      readOnly: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Date",
                        hintStyle: TextStyle(color: subtitleColor, fontSize: 14),
                        prefixIcon: Icon(Icons.calendar_today_rounded, color: subtitleColor, size: 18),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.tryParse(dateController.text) ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(primary: accentColor, surface: cardColor),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          dateController.text =
                              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  _dialogField(descriptionController, "Description (optional)", maxLines: 3),

                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: accentColor.withOpacity(0.4)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel", style: TextStyle(color: subtitleColor)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: saving
                                ? null
                                : () async {
                                    if (titleController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Please enter an expense title")),
                                      );
                                      return;
                                    }
                                    final amount = double.tryParse(amountController.text.trim());
                                    if (amount == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Please enter a valid amount")),
                                      );
                                      return;
                                    }
                                    if (selectedShopId == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Please select a shop")),
                                      );
                                      return;
                                    }
                                    if (dateController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Please pick a date")),
                                      );
                                      return;
                                    }

                                    setStateDialog(() => saving = true);

                                    final response = await CashierExpenseService.createExpense(
                                      shopId: selectedShopId,
                                      title: titleController.text.trim(),
                                      amount: amount,
                                      date: dateController.text.trim(),
                                      description: descriptionController.text.trim().isEmpty
                                          ? null
                                          : descriptionController.text.trim(),
                                    );

                                    if (!context.mounted) return;
                                    Navigator.pop(context);

                                    if (response['success'] == true) {
                                      fetchExpenses();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Expense added successfully"),
                                          backgroundColor: accentColor,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(_extractMessage(response['message']) ?? "Failed to add expense"),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  },
                            child: saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text("Save", style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: subtitleColor, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Future<void> confirmDelete(int id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              const Text(
                "Delete Expense",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                "Are you sure you want to delete \"$title\"? This cannot be undone.",
                style: const TextStyle(color: subtitleColor, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: accentColor.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel", style: TextStyle(color: subtitleColor)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Delete", style: TextStyle(color: Colors.white)),
                      ),
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
      final response = await CashierExpenseService.deleteExpense(id);
      if (!mounted) return;

      if (response['success'] == true) {
        fetchExpenses();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Expense deleted"), backgroundColor: Colors.redAccent),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_extractMessage(response['message']) ?? "Failed to delete expense")),
        );
      }
    }
  }

  String? _extractMessage(dynamic message) {
    if (message == null) return null;
    if (message is String) return message;
    if (message is Map) {
      return message.values.expand((v) => v is List ? v : [v]).join(', ');
    }
    return message.toString();
  }

  @override
  Widget build(BuildContext context) {
    final totalOnPage = expenses.fold<double>(
      0,
      (sum, e) => sum + (double.tryParse(e['amount'].toString()) ?? 0),
    );

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Expenses",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: fetchExpenses,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        backgroundColor: accentColor,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: loading
          ? const FullScreenLoader(message: "Loading expenses...")
          : Column(
              children: [
                if (expenses.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total (this page)", style: TextStyle(color: subtitleColor)),
                        Text(
                          formatMoney(totalOnPage),
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: expenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.payments_outlined, size: 48, color: subtitleColor),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "No expenses yet",
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Tap + to record your first expense",
                                style: TextStyle(color: subtitleColor, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: fetchExpenses,
                          color: accentColor,
                          backgroundColor: cardColor,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                            itemCount: expenses.length,
                            itemBuilder: (context, index) {
                              final expense = expenses[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: accentColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.payments_outlined, color: subtitleColor),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            expense['title'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            formatDate(expense['date']),
                                            style: const TextStyle(color: subtitleColor, fontSize: 12),
                                          ),
                                          if ((expense['description'] ?? '').toString().isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                expense['description'],
                                                style: const TextStyle(color: subtitleColor, fontSize: 12),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          formatMoney(expense['amount']),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => confirmDelete(
                                            expense['id'],
                                            expense['title'] ?? 'this expense',
                                          ),
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}