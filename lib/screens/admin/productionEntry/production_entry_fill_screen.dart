import 'package:flutter/material.dart';
import '../../../services/production_entry_service.dart';

double parsePrice(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

// Handles BOTH the web app's "Fill Entry" page (editMode: false — starts
// with one empty row per section, POSTs and appends to any existing entry)
// and its "Edit Production Entry" page (editMode: true — loads and
// pre-fills existing items, PUTs and replaces the entry entirely, reversing
// old stock movements first). Same form, same row logic either way — the
// only real differences are the initial data and which HTTP verb is used.
class ProductionEntryFillScreen extends StatefulWidget {
  final int productionId;
  final bool editMode;

  const ProductionEntryFillScreen({
    super.key,
    required this.productionId,
    this.editMode = false,
  });

  @override
  State<ProductionEntryFillScreen> createState() => _ProductionEntryFillScreenState();
}

class _ProductionEntryFillScreenState extends State<ProductionEntryFillScreen> {
  static const Color bgColor = Color(0xFF0C1F3F);
  static const Color cardColor = Color(0xFF0F2847);
  static const Color accentColor = Color(0xFF2F5DA8);
  static const Color subtitleColor = Color(0xFF8FAADC);

  bool loading = true;
  bool savingInputs = false;
  bool savingOutputs = false;
  bool savingLosses = false;

  Map<String, dynamic>? production;
  List products = [];
  List units = [];

  // Each row: input -> {itemId, quantity, unit}
  //           output -> {itemName, quantity, unitId, price}
  //           loss -> {itemName, quantity, unit, price}
  final List<Map<String, dynamic>> inputRows = [];
  final List<Map<String, dynamic>> outputRows = [];
  final List<Map<String, dynamic>> lossRows = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => loading = true);

    final response = widget.editMode
        ? await ProductionEntryService.getEditData(widget.productionId)
        : await ProductionEntryService.getFillData(widget.productionId);

    if (!mounted) return;

    if (response['status'] != true) {
      setState(() => loading = false);
      return;
    }

    if (response['locked'] == true) {
      setState(() => loading = false);
      _showSnack(_extractMessage(response['message']) ?? 'This feature is not included in your plan', isError: true);
      return;
    }

    final data = Map<String, dynamic>.from(response['data'] ?? {});
    final prod = Map<String, dynamic>.from(data['production'] ?? {});

    setState(() {
      production = prod;
      products = data['products'] ?? [];
      units = data['units'] ?? [];
      loading = false;

      if (widget.editMode) {
        _prefillFromEntries(prod);
      } else {
        inputRows.add({'itemId': null, 'quantity': '', 'unit': ''});
        outputRows.add({'itemName': '', 'quantity': '', 'unitId': null, 'price': ''});
        lossRows.add({'itemName': '', 'quantity': '', 'unit': '', 'price': ''});
      }
    });
  }

  void _prefillFromEntries(Map<String, dynamic> prod) {
    final entries = List.from(prod['entries'] ?? []);

    List _items(String type) {
      final entry = entries.firstWhere((e) => e['entry_type'] == type, orElse: () => null);
      if (entry == null) return [];
      final meta = entry['meta'];
      if (meta is! Map) return [];
      final items = meta['items'];
      if (items is! List) return [];
      return items.where((i) => i is Map).toList();
    }

    final ins = _items('input');
    final outs = _items('output');
    final losses = _items('loss');

    if (ins.isEmpty) {
      inputRows.add({'itemId': null, 'quantity': '', 'unit': ''});
    } else {
      for (final i in ins) {
        inputRows.add({'itemId': i['item_id'], 'quantity': (i['quantity'] ?? '').toString(), 'unit': i['unit'] ?? ''});
      }
    }

    if (outs.isEmpty) {
      outputRows.add({'itemName': '', 'quantity': '', 'unitId': null, 'price': ''});
    } else {
      for (final o in outs) {
        outputRows.add({
          'itemName': o['item_name'] ?? '',
          'quantity': (o['quantity'] ?? '').toString(),
          'unitId': o['unit_id'],
          'price': (o['price'] ?? '').toString(),
        });
      }
    }

    if (losses.isEmpty) {
      lossRows.add({'itemName': '', 'quantity': '', 'unit': '', 'price': ''});
    } else {
      for (final l in losses) {
        lossRows.add({
          'itemName': l['item_name'] ?? '',
          'quantity': (l['quantity'] ?? '').toString(),
          'unit': l['unit'] ?? '',
          'price': (l['price'] ?? '').toString(),
        });
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

  // BOM price is auto-calculated from the product's cost_price — the web
  // app fetched this from a /products/{id}/price endpoint that isn't part
  // of our API. Since 'products' is already loaded with cost_price for the
  // form, this computes it locally instead of an extra round trip.
  double _bomPrice(dynamic itemId, String quantityStr) {
    if (itemId == null) return 0;
    final product = products.firstWhere((p) => p['id'] == itemId, orElse: () => null);
    if (product == null) return 0;
    final qty = double.tryParse(quantityStr) ?? 0;
    return parsePrice(product['cost_price']) * qty;
  }

  Future<void> _saveSection({
    required String entryType,
    required List<Map<String, dynamic>> rows,
    required void Function(bool) setSaving,
  }) async {
    final items = <Map<String, dynamic>>[];

    for (final row in rows) {
      if (entryType == 'input') {
        if (row['itemId'] == null) continue;
        items.add({
          'item_id': row['itemId'],
          'quantity': double.tryParse(row['quantity'].toString()) ?? 0,
          'unit': row['unit'],
          'price': _bomPrice(row['itemId'], row['quantity'].toString()),
        });
      } else {
        if ((row['itemName'] ?? '').toString().trim().isEmpty) continue;
        final item = {
          'item_name': row['itemName'],
          'quantity': double.tryParse(row['quantity'].toString()) ?? 0,
          'price': double.tryParse(row['price'].toString()) ?? 0,
        };
        if (entryType == 'output') {
          item['unit_id'] = row['unitId'];
        } else {
          item['unit'] = row['unit'];
        }
        items.add(item);
      }
    }

    if (items.isEmpty) {
      _showSnack('Add at least one item first', isError: true);
      return;
    }

    setSaving(true);

    final response = widget.editMode
        ? await ProductionEntryService.updateEntry(productionId: widget.productionId, entryType: entryType, items: items)
        : await ProductionEntryService.storeEntry(productionId: widget.productionId, entryType: entryType, items: items);

    if (!mounted) return;
    setSaving(false);

    if (response['status'] == true) {
      _showSnack('Saved successfully');
      if (widget.editMode) Navigator.pop(context, true);
    } else {
      _showSnack(_extractMessage(response['message']) ?? 'Failed to save', isError: true);
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
          production != null
              ? "${widget.editMode ? 'Edit' : 'Fill'} Entry - ${production!['batch_no']}"
              : (widget.editMode ? "Edit Entry" : "Fill Entry"),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionCard(
                  title: "B O M (INPUTS)",
                  color: accentColor,
                  rows: inputRows,
                  saving: savingInputs,
                  onAddRow: () => setState(() => inputRows.add({'itemId': null, 'quantity': '', 'unit': ''})),
                  onSave: () => _saveSection(
                    entryType: 'input',
                    rows: inputRows,
                    setSaving: (v) => setState(() => savingInputs = v),
                  ),
                  buildRow: (row, index) => _inputRow(row, index),
                ),
                const SizedBox(height: 16),

                _sectionCard(
                  title: "OUTPUTS",
                  color: Colors.green,
                  rows: outputRows,
                  saving: savingOutputs,
                  onAddRow: () => setState(() => outputRows.add({'itemName': '', 'quantity': '', 'unitId': null, 'price': ''})),
                  onSave: () => _saveSection(
                    entryType: 'output',
                    rows: outputRows,
                    setSaving: (v) => setState(() => savingOutputs = v),
                  ),
                  buildRow: (row, index) => _outputRow(row, index),
                ),
                const SizedBox(height: 16),

                _sectionCard(
                  title: "LOSSES",
                  color: Colors.redAccent,
                  rows: lossRows,
                  saving: savingLosses,
                  onAddRow: () => setState(() => lossRows.add({'itemName': '', 'quantity': '', 'unit': '', 'price': ''})),
                  onSave: () => _saveSection(
                    entryType: 'loss',
                    rows: lossRows,
                    setSaving: (v) => setState(() => savingLosses = v),
                  ),
                  buildRow: (row, index) => _lossRow(row, index),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Color color,
    required List<Map<String, dynamic>> rows,
    required bool saving,
    required VoidCallback onAddRow,
    required VoidCallback onSave,
    required Widget Function(Map<String, dynamic> row, int index) buildRow,
  }) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                InkWell(
                  onTap: onAddRow,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                ...rows.asMap().entries.map((e) => buildRow(e.value, e.key)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: saving ? null : onSave,
                    child: saving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text("Save ${title.contains('BOM') ? 'Inputs' : title[0] + title.substring(1).toLowerCase()}",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowContainer(List<Widget> children, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...children,
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.close, color: Colors.redAccent, size: 16),
              label: const Text("Remove", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputRow(Map<String, dynamic> row, int index) {
    final price = _bomPrice(row['itemId'], row['quantity'].toString());

    return _rowContainer(
      [
        _dropdownField(
          value: row['itemId'],
          hint: "Select Product",
          items: products,
          onChanged: (v) => setState(() => row['itemId'] = v),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _numberField(row, 'quantity', hint: "Quantity")),
            const SizedBox(width: 8),
            Expanded(child: _textField(row, 'unit', hint: "kg, bags, pcs")),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
          child: Text("Auto-calculated cost: \u20a6${price.toStringAsFixed(2)}", style: const TextStyle(color: subtitleColor, fontSize: 12)),
        ),
      ],
      () => setState(() => inputRows.remove(row)),
    );
  }

  Widget _outputRow(Map<String, dynamic> row, int index) {
    return _rowContainer(
      [
        _textField(row, 'itemName', hint: "Enter item name"),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _numberField(row, 'quantity', hint: "Quantity")),
            const SizedBox(width: 8),
            Expanded(
              child: _dropdownField(
                value: row['unitId'],
                hint: "Select Unit",
                items: units,
                labelBuilder: (u) => "${u['name'] ?? ''} (${u['symbol'] ?? ''})",
                onChanged: (v) => setState(() => row['unitId'] = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _numberField(row, 'price', hint: "Enter cost"),
      ],
      () => setState(() => outputRows.remove(row)),
    );
  }

  Widget _lossRow(Map<String, dynamic> row, int index) {
    return _rowContainer(
      [
        _textField(row, 'itemName', hint: "Enter item name"),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _numberField(row, 'quantity', hint: "Quantity")),
            const SizedBox(width: 8),
            Expanded(child: _textField(row, 'unit', hint: "kg, bags, pcs")),
          ],
        ),
        const SizedBox(height: 8),
        _numberField(row, 'price', hint: "Enter cost"),
      ],
      () => setState(() => lossRows.remove(row)),
    );
  }

  TextEditingController _controllerFor(Map<String, dynamic> row, String key) {
    final cacheKey = '_ctrl_$key';
    if (row[cacheKey] == null) {
      row[cacheKey] = TextEditingController(text: row[key]?.toString() ?? '');
    }
    return row[cacheKey] as TextEditingController;
  }

  Widget _textField(Map<String, dynamic> row, String key, {String? hint}) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
      child: TextField(
        controller: _controllerFor(row, key),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        onChanged: (v) => row[key] = v,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: subtitleColor, fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _numberField(Map<String, dynamic> row, String key, {String? hint}) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
      child: TextField(
        controller: _controllerFor(row, key),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        onChanged: (v) => setState(() => row[key] = v),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: subtitleColor, fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required dynamic value,
    required String hint,
    required List items,
    required void Function(dynamic) onChanged,
    String Function(dynamic)? labelBuilder,
  }) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonFormField<dynamic>(
        value: value,
        dropdownColor: cardColor,
        isExpanded: true,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: subtitleColor, fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: items
            .map<DropdownMenuItem<dynamic>>((item) => DropdownMenuItem(
                  value: item['id'],
                  child: Text(labelBuilder != null ? labelBuilder(item) : (item['product_name'] ?? item['name'] ?? '')),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}