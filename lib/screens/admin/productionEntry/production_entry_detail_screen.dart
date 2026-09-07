import 'package:flutter/material.dart';
import '../../../services/production_entry_service.dart';
import 'production_entry_fill_screen.dart';

double parsePrice(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class ProductionEntryDetailScreen extends StatefulWidget {
  final int productionId;
  const ProductionEntryDetailScreen({super.key, required this.productionId});

  @override
  State<ProductionEntryDetailScreen> createState() => _ProductionEntryDetailScreenState();
}

class _ProductionEntryDetailScreenState extends State<ProductionEntryDetailScreen> {
  static const Color bgColor = Color(0xFF0C1F3F);
  static const Color cardColor = Color(0xFF0F2847);
  static const Color accentColor = Color(0xFF2F5DA8);
  static const Color subtitleColor = Color(0xFF8FAADC);

  bool loading = true;
  Map<String, dynamic>? production;
  List inputs = [];
  List outputs = [];
  List losses = [];

  @override
  void initState() {
    super.initState();
    fetchProduction();
  }

  Future<void> fetchProduction() async {
    setState(() => loading = true);
    final response = await ProductionEntryService.getProduction(widget.productionId);
    if (!mounted) return;

    if (response['status'] != true || response['locked'] == true) {
      setState(() => loading = false);
      return;
    }

    final data = Map<String, dynamic>.from(response['data'] ?? {});
    final entries = List.from(data['entries'] ?? []);

    List _extract(String type) {
      final entry = entries.firstWhere((e) => e['entry_type'] == type, orElse: () => null);
      if (entry == null) return [];
      final meta = entry['meta'];
      if (meta is! Map) return [];
      final items = meta['items'];
      if (items is! List) return [];
      return items.where((i) => i is Map).toList();
    }

    setState(() {
      production = data;
      inputs = _extract('input');
      outputs = _extract('output');
      losses = _extract('loss');
      loading = false;
    });
  }

  String _fmtMoney(dynamic v) => "\u20a6${parsePrice(v).toStringAsFixed(0)}";

  String _fmtDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return 'Not recorded';
    try {
      final dt = DateTime.parse(raw);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return "${dt.day} ${months[dt.month - 1]} ${dt.year}, ${hour12.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $ampm";
    } catch (_) {
      return raw;
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
        title: Text(
          production != null ? "Batch ${production!['batch_no']}" : "Batch Details",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      floatingActionButton: production == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductionEntryFillScreen(productionId: widget.productionId, editMode: true),
                  ),
                );
                if (updated == true) fetchProduction();
              },
              backgroundColor: accentColor,
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              label: const Text("Edit Batch", style: TextStyle(color: Colors.white)),
            ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : production == null
              ? const Center(child: Text("Batch not found", style: TextStyle(color: subtitleColor)))
              : RefreshIndicator(
                  onRefresh: fetchProduction,
                  color: accentColor,
                  backgroundColor: cardColor,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _entrySection("INPUTS (BOM)", inputs, accentColor, isInput: true),
                      const SizedBox(height: 16),
                      _entrySection("OUTPUTS", outputs, Colors.green, isOutput: true),
                      const SizedBox(height: 16),
                      _entrySection("LOSSES", losses, Colors.redAccent),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }

  Widget _entrySection(String title, List items, Color color, {bool isInput = false, bool isOutput = false}) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text("No ${title.toLowerCase()} recorded", style: const TextStyle(color: subtitleColor, fontSize: 13)),
            )
          else
            ...items.map((item) => _itemRow(item, isInput: isInput, isOutput: isOutput)),
        ],
      ),
    );
  }

  Widget _itemRow(Map item, {bool isInput = false, bool isOutput = false}) {
    final name = item['item_name'] ?? (isInput ? 'Product #${item['item_id'] ?? '-'}' : 'Unknown');
    final unit = item['unit'] ?? (isOutput ? 'Unit #${item['unit_id'] ?? '-'}' : '-');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF0C1F3F), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(name.toString(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Text(_fmtMoney(item['price']), style: const TextStyle(color: subtitleColor, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text("Qty: ${item['quantity'] ?? '-'} $unit", style: const TextStyle(color: subtitleColor, fontSize: 12)),
              const Spacer(),
              Icon(Icons.access_time_rounded, color: subtitleColor.withOpacity(0.7), size: 12),
              const SizedBox(width: 4),
              Text(_fmtDateTime(item['added_at']), style: TextStyle(color: subtitleColor.withOpacity(0.7), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}