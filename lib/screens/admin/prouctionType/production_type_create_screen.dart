import 'package:flutter/material.dart';
import '../../../services/production_type_service.dart';

class ProductionTypeCreateScreen extends StatefulWidget {
  const ProductionTypeCreateScreen({super.key});

  @override
  State<ProductionTypeCreateScreen> createState() => _ProductionTypeCreateScreenState();
}

class _ProductionTypeCreateScreenState extends State<ProductionTypeCreateScreen> {
  static const Color bgColor = Color(0xFF0C1F3F);
  static const Color cardColor = Color(0xFF0F2847);
  static const Color accentColor = Color(0xFF2F5DA8);
  static const Color subtitleColor = Color(0xFF8FAADC);

  bool saving = false;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  String status = 'active';

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    if (nameController.text.trim().isEmpty) {
      _showSnack('Please enter a production type name', isError: true);
      return;
    }

    setState(() => saving = true);

    final response = await ProductionTypeService.createProductionType(
      name: nameController.text.trim(),
      status: status,
      description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
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
      _showSnack(_extractMessage(response['message']) ?? 'Failed to create production type', isError: true);
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
          "Create Production Type",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _label("Production Type Name"),
          _textField(nameController, hint: "e.g Animal Feed Production"),
          const SizedBox(height: 16),

          _label("Description"),
          _textField(descriptionController, maxLines: 4),
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
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (v) => setState(() => status = v ?? 'active'),
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
                  : const Text("Save Production Type", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(color: subtitleColor, fontSize: 13, fontWeight: FontWeight.w600)),
      );

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
}