import 'package:flutter/material.dart';
import '../../../services/customer_service.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  List customers = [];
  List filtered = [];
  bool loading = false;

  final TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCustomers();
    searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = searchCtrl.text.toLowerCase();
    setState(() {
      filtered = customers.where((c) {
        return (c['name'] ?? '').toString().toLowerCase().contains(q) ||
            (c['phone'] ?? '').toString().toLowerCase().contains(q) ||
            (c['email'] ?? '').toString().toLowerCase().contains(q) ||
            (c['company'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> fetchCustomers({bool refresh = false}) async {
    setState(() => loading = true);
    final data = await CustomerService.getCustomers(refresh: refresh);
    setState(() {
      customers = data;
      filtered = data;
      loading = false;
    });
  }

  Future<void> deleteCustomer(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Customer"),
        content: const Text("Are you sure you want to delete this customer?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await CustomerService.deleteCustomer(id);

    if (res['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Customer deleted"),
          backgroundColor: Colors.green,
        ),
      );
      fetchCustomers(refresh: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? "Failed to delete"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void openForm({Map? customer}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CustomerFormSheet(
        customer: customer,
        onSaved: () {
          Navigator.pop(context);
          fetchCustomers(refresh: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Customers", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => fetchCustomers(refresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: "Search name, phone, email, company...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF0F0F0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Count
          if (!loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Text(
                    "${filtered.length} customer${filtered.length == 1 ? '' : 's'}",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),

          // List
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              searchCtrl.text.isEmpty
                                  ? "No customers yet.\nTap + to add one."
                                  : "No customers match your search.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => fetchCustomers(refresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final c = filtered[index];
                            return _CustomerCard(
                              customer: c,
                              onEdit: () => openForm(customer: c),
                              onDelete: () => deleteCustomer(c['id']),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text("Add Customer"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
    );
  }
}


// ─── Customer Card ────────────────────────────────────────────────────────────

class _CustomerCard extends StatelessWidget {
  final Map customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final name = c['name'] ?? 'Unknown';
    final phone = c['phone'] ?? '';
    final email = c['email'] ?? '';
    final company = c['company'] ?? '';
    final address = c['address'] ?? '';
    final notes = c['notes'] ?? '';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.black,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (phone.isNotEmpty) _infoRow(Icons.phone_outlined, phone),
                  if (email.isNotEmpty) _infoRow(Icons.email_outlined, email),
                  if (company.isNotEmpty) _infoRow(Icons.business_outlined, company),
                  if (address.isNotEmpty) _infoRow(Icons.location_on_outlined, address),
                  if (notes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          notes,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.blue, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


// ─── Customer Form Bottom Sheet ───────────────────────────────────────────────

class CustomerFormSheet extends StatefulWidget {
  final Map? customer;
  final VoidCallback onSaved;

  const CustomerFormSheet({super.key, this.customer, required this.onSaved});

  @override
  State<CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<CustomerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final companyCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  bool get isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final c = widget.customer!;
      nameCtrl.text = c['name'] ?? '';
      emailCtrl.text = c['email'] ?? '';
      phoneCtrl.text = c['phone'] ?? '';
      addressCtrl.text = c['address'] ?? '';
      companyCtrl.text = c['company'] ?? '';
      notesCtrl.text = c['notes'] ?? '';
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    companyCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    Map<String, dynamic> res;

    if (isEditing) {
      res = await CustomerService.updateCustomer(
        id: widget.customer!['id'],
        name: nameCtrl.text,
        email: emailCtrl.text.isEmpty ? null : emailCtrl.text,
        phone: phoneCtrl.text.isEmpty ? null : phoneCtrl.text,
        address: addressCtrl.text.isEmpty ? null : addressCtrl.text,
        company: companyCtrl.text.isEmpty ? null : companyCtrl.text,
        notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
      );
    } else {
      res = await CustomerService.createCustomer(
        name: nameCtrl.text,
        email: emailCtrl.text.isEmpty ? null : emailCtrl.text,
        phone: phoneCtrl.text.isEmpty ? null : phoneCtrl.text,
        address: addressCtrl.text.isEmpty ? null : addressCtrl.text,
        company: companyCtrl.text.isEmpty ? null : companyCtrl.text,
        notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
      );
    }

    setState(() => loading = false);

    if (res['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? "Customer updated!" : "Customer added!"),
          backgroundColor: Colors.green,
        ),
      );
      widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? "Something went wrong"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  isEditing ? "Edit Customer" : "Add New Customer",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                _label("Full Name"),
                _field(nameCtrl, "e.g. John Doe",
                    validator: (v) =>
                        v == null || v.isEmpty ? "Name is required" : null),
                const SizedBox(height: 14),

                _label("Phone Number"),
                _field(phoneCtrl, "e.g. 08012345678",
                    type: TextInputType.phone),
                const SizedBox(height: 14),

                _label("Email Address"),
                _field(emailCtrl, "e.g. john@example.com",
                    type: TextInputType.emailAddress),
                const SizedBox(height: 14),

                _label("Company (Optional)"),
                _field(companyCtrl, "e.g. ABC Ventures"),
                const SizedBox(height: 14),

                _label("Address (Optional)"),
                _field(addressCtrl, "e.g. 12 Market Street, Lagos"),
                const SizedBox(height: 14),

                _label("Notes (Optional)"),
                TextFormField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: _inputDeco("Any additional notes..."),
                ),
                const SizedBox(height: 28),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isEditing ? "Update Customer" : "Add Customer",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      );

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: validator,
      decoration: _inputDeco(hint),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}