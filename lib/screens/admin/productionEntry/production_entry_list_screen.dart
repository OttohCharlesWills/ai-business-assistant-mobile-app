import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/production_service.dart';
import 'production_entry_detail_screen.dart';

class ProductionEntryListScreen extends StatefulWidget {
  const ProductionEntryListScreen({super.key});

  @override
  State<ProductionEntryListScreen> createState() => _ProductionEntryListScreenState();
}

class _ProductionEntryListScreenState extends State<ProductionEntryListScreen> {
  static const Color bgColor = Color(0xFF0C1F3F);
  static const Color cardColor = Color(0xFF0F2847);
  static const Color accentColor = Color(0xFF2F5DA8);
  static const Color subtitleColor = Color(0xFF8FAADC);

  bool loading = true;
  bool locked = false;
  String? lockMessage;

  List productions = [];
  final searchController = TextEditingController();
  Timer? _debounce;
  int currentPage = 1;
  int lastPage = 1;

  final statuses = const ['planned', 'in_progress', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    fetchProductions();
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> fetchProductions({int page = 1}) async {
    setState(() => loading = true);
    final response = await ProductionService.getProductions(
      search: searchController.text.trim(),
      page: page,
    );
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
    final paginator = data['productions'] ?? {};

    setState(() {
      locked = false;
      productions = paginator['data'] ?? [];
      currentPage = paginator['current_page'] ?? 1;
      lastPage = paginator['last_page'] ?? 1;
      loading = false;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => fetchProductions());
  }

  Future<void> _updateStatus(Map production, String newStatus) async {
    final response = await ProductionService.updateStatus(
      productionId: production['id'],
      status: newStatus,
    );
    if (!mounted) return;

    if (response['status'] == true) {
      setState(() => production['status'] = newStatus);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return subtitleColor;
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
          "Production Batches",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => fetchProductions(),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : locked
              ? _buildLockedView()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: searchController,
                        onChanged: _onSearchChanged,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search batch...',
                          hintStyle: const TextStyle(color: subtitleColor, fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: subtitleColor),
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    Expanded(
                      child: productions.isEmpty
                          ? const Center(child: Text("No production batches found", style: TextStyle(color: subtitleColor)))
                          : RefreshIndicator(
                              onRefresh: () => fetchProductions(),
                              color: accentColor,
                              backgroundColor: cardColor,
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                children: [
                                  ...productions.map((p) => _batchRow(p)),
                                  if (lastPage > 1) _pagination(),
                                ],
                              ),
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
            const Text("Production & Manufacturing Locked", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              lockMessage ?? "This feature is not included in your current plan.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: subtitleColor, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _batchRow(Map production) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(production['batch_no'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text(production['title'] ?? '', style: const TextStyle(color: subtitleColor, fontSize: 13)),
          Text(production['productionType']?['name'] ?? '-', style: const TextStyle(color: subtitleColor, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                  child: DropdownButtonFormField<String>(
                    value: production['status'],
                    dropdownColor: cardColor,
                    isExpanded: true,
                    style: TextStyle(color: _statusColor(production['status'] ?? ''), fontSize: 13, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: statuses
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' ').toUpperCase())))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _updateStatus(production, v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProductionEntryDetailScreen(productionId: production['id'])),
                  );
                },
                child: const Text("Open", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentPage > 1 ? () => fetchProductions(page: currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left, color: subtitleColor),
          ),
          Text("Page $currentPage of $lastPage", style: const TextStyle(color: Colors.white, fontSize: 13)),
          IconButton(
            onPressed: currentPage < lastPage ? () => fetchProductions(page: currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right, color: subtitleColor),
          ),
        ],
      ),
    );
  }
}