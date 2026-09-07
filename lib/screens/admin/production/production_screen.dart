import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/production_service.dart';
import 'production_create_screen.dart';
import '../productionEntry/production_entry_fill_screen.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  static const Color bgColor = Color(0xFF0C1F3F);
  static const Color cardColor = Color(0xFF0F2847);
  static const Color accentColor = Color(0xFF2F5DA8);
  static const Color subtitleColor = Color(0xFF8FAADC);

  bool loading = true;
  bool locked = false;
  String? lockMessage;

  List productions = [];
  List shops = [];
  dynamic selectedShopId;
  final searchController = TextEditingController();
  Timer? _debounce;

  int currentPage = 1;
  int lastPage = 1;

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
      shopId: selectedShopId,
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
      shops = data['shops'] ?? [];
      loading = false;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => fetchProductions());
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
      floatingActionButton: locked
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductionCreateScreen()),
                );
                if (created == true) fetchProductions();
              },
              backgroundColor: accentColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("New Production", style: TextStyle(color: Colors.white)),
            ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : locked
              ? _buildLockedView()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: searchController,
                            onChanged: _onSearchChanged,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search batch no or title...',
                              hintStyle: const TextStyle(color: subtitleColor, fontSize: 13),
                              prefixIcon: const Icon(Icons.search, color: subtitleColor),
                              filled: true,
                              fillColor: cardColor,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
                            child: DropdownButtonFormField<dynamic>(
                              value: selectedShopId,
                              dropdownColor: cardColor,
                              isExpanded: true,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: "All Shops",
                                hintStyle: TextStyle(color: subtitleColor, fontSize: 13),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text("All Shops")),
                                ...shops.map<DropdownMenuItem<dynamic>>((s) => DropdownMenuItem(value: s['id'], child: Text(s['name'] ?? ''))),
                              ],
                              onChanged: (v) {
                                setState(() => selectedShopId = v);
                                fetchProductions();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: productions.isEmpty
                          ? const Center(
                              child: Text("No production batches found", style: TextStyle(color: subtitleColor)),
                            )
                          : RefreshIndicator(
                              onRefresh: () => fetchProductions(),
                              color: accentColor,
                              backgroundColor: cardColor,
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                                children: [
                                  ...productions.map((p) => _productionCard(p)),
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

  Widget _productionCard(Map p) {
    final status = p['status']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['batch_no'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(p['title'] ?? '', style: const TextStyle(color: subtitleColor, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(color: _statusColor(status), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.category_outlined, color: subtitleColor, size: 14),
              const SizedBox(width: 6),
              Text(p['productionType']?['name'] ?? '-', style: const TextStyle(color: subtitleColor, fontSize: 12)),
              const SizedBox(width: 16),
              Icon(Icons.store_outlined, color: subtitleColor, size: 14),
              const SizedBox(width: 6),
              Text(p['shop']?['name'] ?? '-', style: const TextStyle(color: subtitleColor, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: subtitleColor, size: 13),
              const SizedBox(width: 6),
              Text(
                "${p['start_date'] ?? '-'} → ${p['end_date'] ?? '-'}",
                style: const TextStyle(color: subtitleColor, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductionEntryFillScreen(productionId: p['id'])),
                );
              },
              icon: const Icon(Icons.playlist_add_rounded, color: Colors.white, size: 18),
              label: const Text("Fill Entry", style: TextStyle(color: Colors.white)),
            ),
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