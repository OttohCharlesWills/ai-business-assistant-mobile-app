import 'package:flutter/material.dart';
import '../../../services/production_service.dart';

class ProductionCreateScreen extends StatefulWidget {
  const ProductionCreateScreen({super.key});

  @override
  State<ProductionCreateScreen> createState() => _ProductionCreateScreenState();
}

class _ProductionCreateScreenState extends State<ProductionCreateScreen> {
  static const Color bgColor = Color(0xFF0C1F3F);
  static const Color cardColor = Color(0xFF0F2847);
  static const Color accentColor = Color(0xFF2F5DA8);
  static const Color subtitleColor = Color(0xFF8FAADC);

  bool loading = true;
  bool saving = false;
  bool locked = false;
  String? lockMessage;

  List shops = [];
  List productionTypes = [];

  dynamic selectedShopId;
  dynamic selectedTypeId;
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  String status = 'planned';

  @override
  void initState() {
    super.initState();
    fetchCreateData();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }

  Future<void> fetchCreateData() async {
    setState(() => loading = true);
    final response = await ProductionService.getCreateData();
    if (!mounted) return;

    if (response['status'] != true) {
      setState(() => loading = false);
      return;
    }

    if (response['locked'] == true) {
      setState(() {
        locked = true;
        lockMessage = response['message'];
        loading = false;
      });
      return;
    }

    final data = response['data'] ?? {};
    setState(() {
      locked = false;
      shops = data['shops'] ?? [];
      productionTypes = data['production_types'] ?? [];
      loading = false;
    });
  }

  String? _extractMessage(dynamic message) {
    if (message == null) return null;
    if (message is String) return message;
    if (message is Map) {
      return message.values.expand((v) => v is List ? v : [v]).join(', ');
    }
    return message.toString();
  }

  void _showSnack(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.redAccent : accentColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: accentColor, surface: cardColor)),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _submit() async {
    if (selectedShopId == null) {
      _showSnack('Please select a shop', isError: true);
      return;
    }
    if (selectedTypeId == null) {
      _showSnack('Please select a production type', isError: true);
      return;
    }
    if (titleController.text.trim().isEmpty) {
      _showSnack('Please enter a production title', isError: true);
      return;
    }

    setState(() => saving = true);

    final response = await ProductionService.createProduction(
      shopId: selectedShopId,
      productionTypeId: selectedTypeId,
      title: titleController.text.trim(),
      description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
      startDate: startDateController.text.trim().isEmpty ? null : startDateController.text.trim(),
      endDate: endDateController.text.trim().isEmpty ? null : endDateController.text.trim(),
      status: status,
    );

    if (!mounted) return;
    setState(() => saving = false);

    if (response['locked'] == true) {
      _showSnack(_extractMessage(response['message']) ?? 'This feature is not included in your plan', isError: true);
      return;
    }

    if (response['status'] == true) {
      Navigator.pop(context, true);
    } else {
      _showSnack(_extractMessage(response['message']) ?? 'Failed to create batch', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Create Production Batch",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : locked
              ? _buildLockedView()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _label("Shop"),
                    _dropdown(
                      value: selectedShopId,
                      hint: "Select Shop",
                      items: shops,
                      onChanged: (v) => setState(() => selectedShopId = v),
                    ),
                    const SizedBox(height: 16),

                    _label("Production Type"),
                    _dropdown(
                      value: selectedTypeId,
                      hint: "Select Production Type",
                      items: productionTypes,
                      onChanged: (v) => setState(() => selectedTypeId = v),
                    ),
                    const SizedBox(height: 16),

                    _label("Production Title"),
                    _textField(titleController, hint: "Broiler Cycle June 2026"),
                    const SizedBox(height: 16),

                    _label("Description"),
                    _textField(descriptionController, maxLines: 4),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label("Start Date"),
                              _dateField(startDateController),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label("Expected End Date"),
                              _dateField(endDateController),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _label("Status"),
                    Container(
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonFormField<String>(
                        value: status,
                        dropdownColor: cardColor,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'planned', child: Text('Planned')),
                          DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                        ],
                        onChanged: (v) => setState(() => status = v ?? 'planned'),
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: saving ? null : _submit,
                        child: saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text("Create Batch", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildLockedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.lock_rounded, color: Colors.orange, size: 48),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: const Text("PREMIUM FEATURE", style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 14),
            const Text("Production & Manufacturing Locked", style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              lockMessage ?? "This feature is not included in your current plan.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: subtitleColor, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // TODO: navigate to your pricing/upgrade screen
                },
                child: const Text("Upgrade Plan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(color: subtitleColor, fontSize: 13, fontWeight: FontWeight.w600)),
      );

  Widget _dropdown({
    required dynamic value,
    required String hint,
    required List items,
    required void Function(dynamic) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonFormField<dynamic>(
        value: value,
        dropdownColor: cardColor,
        isExpanded: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: subtitleColor, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        items: items
            .map<DropdownMenuItem<dynamic>>((item) => DropdownMenuItem(value: item['id'], child: Text(item['name'] ?? '')))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _textField(TextEditingController controller, {String? hint, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: subtitleColor, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  Widget _dateField(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: const InputDecoration(
          hintText: "YYYY-MM-DD",
          hintStyle: TextStyle(color: subtitleColor, fontSize: 13),
          prefixIcon: Icon(Icons.calendar_today_rounded, color: subtitleColor, size: 16),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        onTap: () => _pickDate(controller),
      ),
    );
  }
}