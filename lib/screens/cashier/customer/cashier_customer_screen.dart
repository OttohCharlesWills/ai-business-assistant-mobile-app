import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/cashier_customer_service.dart';
import '../../../widgets/app_loader.dart';

class CashierCustomerScreen extends StatefulWidget {
  const CashierCustomerScreen({super.key});

  @override
  State<CashierCustomerScreen> createState() => _CashierCustomerScreenState();
}

class _CashierCustomerScreenState extends State<CashierCustomerScreen> {
  static const Color bgColor = Color(0xFF0C1F3F);
  static const Color cardColor = Color(0xFF0F2847);
  static const Color accentColor = Color(0xFF2F5DA8);
  static const Color subtitleColor = Color(0xFF8FAADC);

  List customers = [];
  bool loading = true;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> fetchCustomers() async {
    setState(() => loading = true);
    final response = await CashierCustomerService.getCustomers();
    setState(() {
      customers = response['status'] == true ? (response['data'] ?? []) : [];
      loading = false;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => loading = true);
      final response = value.trim().isEmpty
          ? await CashierCustomerService.getCustomers()
          : await CashierCustomerService.searchCustomers(value.trim());
      if (!mounted) return;
      setState(() {
        customers = response['status'] == true ? (response['data'] ?? []) : [];
        loading = false;
      });
    });
  }

  Future<void> showAddDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final companyController = TextEditingController();
    final notesController = TextEditingController();
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
                    child: const Icon(Icons.person_add_alt_rounded, color: subtitleColor),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "New Customer",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Name and phone are required",
                    style: TextStyle(color: subtitleColor, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  _dialogField(nameController, "Customer name *"),
                  const SizedBox(height: 10),
                  _dialogField(phoneController, "Phone *", keyboardType: TextInputType.phone),
                  const SizedBox(height: 10),
                  _dialogField(emailController, "Email", keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 10),
                  _dialogField(addressController, "Address", maxLines: 2),
                  const SizedBox(height: 10),
                  _dialogField(companyController, "Company"),
                  const SizedBox(height: 10),
                  _dialogField(notesController, "Notes", maxLines: 2),
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
                                    if (nameController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Please enter customer name")),
                                      );
                                      return;
                                    }
                                    if (phoneController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Please enter phone number")),
                                      );
                                      return;
                                    }

                                    setStateDialog(() => saving = true);

                                    final response = await CashierCustomerService.createCustomer(
                                      name: nameController.text.trim(),
                                      email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                                      phone: phoneController.text.trim(),
                                      address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                                      company: companyController.text.trim().isEmpty ? null : companyController.text.trim(),
                                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                                    );

                                    if (!context.mounted) return;
                                    Navigator.pop(context);

                                    if (response['status'] == true) {
                                      fetchCustomers();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Customer created successfully"),
                                          backgroundColor: accentColor,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(_extractMessage(response['message']) ?? "Failed to create customer"),
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
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
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

  Future<void> confirmDelete(int id, String name) async {
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
                "Delete Customer",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                "Are you sure you want to delete \"$name\"? This cannot be undone.",
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
      final response = await CashierCustomerService.deleteCustomer(id);
      if (!mounted) return;

      if (response['status'] == true) {
        fetchCustomers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Customer deleted"), backgroundColor: Colors.redAccent),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_extractMessage(response['message']) ?? "Failed to delete customer")),
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
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Customers",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: fetchCustomers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        backgroundColor: accentColor,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name, phone, email or company...',
                hintStyle: const TextStyle(color: subtitleColor, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: subtitleColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: subtitleColor),
                        onPressed: () {
                          _searchController.clear();
                          fetchCustomers();
                        },
                      )
                    : null,
                filled: true,
                fillColor: cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const FullScreenLoader(message: "Loading customers...")
                : customers.isEmpty
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
                              child: const Icon(Icons.people_outline, size: 48, color: subtitleColor),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _searchController.text.trim().isNotEmpty
                                  ? "No customers found"
                                  : "No customers yet",
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Tap + to add your first customer",
                              style: TextStyle(color: subtitleColor, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchCustomers,
                        color: accentColor,
                        backgroundColor: cardColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                          itemCount: customers.length,
                          itemBuilder: (context, index) {
                            final customer = customers[index];
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
                                    child: const Icon(Icons.person_rounded, color: subtitleColor),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          customer['name'] ?? 'Unnamed',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if ((customer['phone'] ?? '').toString().isNotEmpty)
                                          _detailRow(Icons.phone_outlined, customer['phone']),
                                        if ((customer['email'] ?? '').toString().isNotEmpty)
                                          _detailRow(Icons.email_outlined, customer['email']),
                                        if ((customer['company'] ?? '').toString().isNotEmpty)
                                          _detailRow(Icons.business_outlined, customer['company']),
                                        if ((customer['address'] ?? '').toString().isNotEmpty)
                                          _detailRow(Icons.location_on_outlined, customer['address']),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => confirmDelete(customer['id'], customer['name'] ?? 'this customer'),
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
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

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: subtitleColor, size: 13),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: subtitleColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}