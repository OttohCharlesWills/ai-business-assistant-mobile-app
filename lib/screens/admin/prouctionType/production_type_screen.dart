import 'package:flutter/material.dart';
import '../../../services/production_type_service.dart';
import 'production_type_create_screen.dart';

class ProductionTypeScreen extends StatefulWidget {
  const ProductionTypeScreen({super.key});

  @override
  State<ProductionTypeScreen> createState() => _ProductionTypeScreenState();
}

class _ProductionTypeScreenState extends State<ProductionTypeScreen> {
  static const Color bgColor = Color(0xFF0C1F3F);
  static const Color cardColor = Color(0xFF0F2847);
  static const Color accentColor = Color(0xFF2F5DA8);
  static const Color subtitleColor = Color(0xFF8FAADC);

  bool loading = true;
  bool locked = false;
  String? lockMessage;

  List types = [];
  int currentPage = 1;
  int lastPage = 1;

  @override
  void initState() {
    super.initState();
    fetchTypes();
  }

  Future<void> fetchTypes({int page = 1}) async {
    setState(() => loading = true);
    final response = await ProductionTypeService.getProductionTypes(page: page);
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
    final paginator = data['production_types'] ?? {};

    setState(() {
      locked = false;
      types = paginator['data'] ?? [];
      currentPage = paginator['current_page'] ?? 1;
      lastPage = paginator['last_page'] ?? 1;
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

  Future<void> _confirmDelete(int id, String name) async {
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
                "Delete Production Type",
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
      final response = await ProductionTypeService.deleteProductionType(id);
      if (!mounted) return;

      if (response['locked'] == true) {
        _showSnack(_extractMessage(response['message']) ?? 'This feature is not included in your plan', isError: true);
        return;
      }

      if (response['status'] == true) {
        fetchTypes(page: currentPage);
        _showSnack('Production type deleted');
      } else {
        _showSnack(_extractMessage(response['message']) ?? 'Failed to delete', isError: true);
      }
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
          "Production Types",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => fetchTypes(),
          ),
        ],
      ),
      floatingActionButton: locked
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductionTypeCreateScreen()),
                );
                if (created == true) fetchTypes();
              },
              backgroundColor: accentColor,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : locked
              ? _buildLockedView()
              : types.isEmpty
                  ? const Center(
                      child: Text("No production types found", style: TextStyle(color: subtitleColor)),
                    )
                  : RefreshIndicator(
                      onRefresh: () => fetchTypes(),
                      color: accentColor,
                      backgroundColor: cardColor,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                        children: [
                          ...types.map((type) => _typeCard(type)),
                          if (lastPage > 1) _pagination(),
                        ],
                      ),
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

  Widget _typeCard(Map type) {
    // NOTE: comparing the actual string value here — the web blade's
    // @if($type->status) check is truthy for ANY non-empty string,
    // including "inactive", so its badge is unreliable. This does it right.
    final isActive = type['status'] == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: accentColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.category_rounded, color: subtitleColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        type['name'] ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withOpacity(0.15) : Colors.redAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? "Active" : "Inactive",
                        style: TextStyle(
                          color: isActive ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if ((type['description'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    type['description'],
                    style: const TextStyle(color: subtitleColor, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(type['id'], type['name'] ?? 'this type'),
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
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
            onPressed: currentPage > 1 ? () => fetchTypes(page: currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left, color: subtitleColor),
          ),
          Text("Page $currentPage of $lastPage", style: const TextStyle(color: Colors.white, fontSize: 13)),
          IconButton(
            onPressed: currentPage < lastPage ? () => fetchTypes(page: currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right, color: subtitleColor),
          ),
        ],
      ),
    );
  }
}