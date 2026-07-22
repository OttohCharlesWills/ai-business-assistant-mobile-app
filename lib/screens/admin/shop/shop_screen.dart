import 'package:flutter/material.dart';
import '../../../services/shop_service.dart';
import '../../../widgets/app_loader.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {

  List shops = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchShops(refresh: true); // ✅ always fresh on open
  }

  Future<void> fetchShops({bool refresh = false}) async {
    setState(() => loading = true);

    final data = await ShopService.getShops(refresh: refresh);

    setState(() {
      shops = data;
      loading = false;
    });
  }

  Future<void> showAddDialog() async {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    bool saving = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          backgroundColor: const Color(0xFF0F2847),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                    color: const Color(0xFF2F5DA8).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    color: Color(0xFF8FAADC),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  "New Shop",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  "Add a new shop or store location",
                  style: TextStyle(
                    color: Color(0xFF8FAADC),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1F3F),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Shop name",
                      hintStyle: TextStyle(
                        color: Color(0xFF8FAADC),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1F3F),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: locationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Location (optional)",
                      hintStyle: TextStyle(
                        color: Color(0xFF8FAADC),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: const Color(0xFF2F5DA8).withOpacity(0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Color(0xFF8FAADC)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2F5DA8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: saving
                              ? null
                              : () async {
                                  if (nameController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Please enter a shop name"),
                                      ),
                                    );
                                    return;
                                  }

                                  setStateDialog(() => saving = true);

                                  final response = await ShopService.createShop(
                                    name: nameController.text.trim(),
                                    location: locationController.text.trim(),
                                  );

                                  if (!context.mounted) return;

                                  Navigator.pop(context);

                                  if (response['status'] == true) {
                                    fetchShops(refresh: true); // ✅ fresh after create
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Shop created successfully"),
                                        backgroundColor: Color(0xFF2F5DA8),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          response['message'] ?? "Failed to create shop",
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                },
                          child: saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Save",
                                  style: TextStyle(color: Colors.white),
                                ),
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
    );
  }

  Future<void> confirmDelete(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0F2847),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "Delete Shop",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Are you sure you want to delete \"$name\"? This cannot be undone.",
                style: const TextStyle(
                  color: Color(0xFF8FAADC),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: const Color(0xFF2F5DA8).withOpacity(0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Color(0xFF8FAADC)),
                        ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.white),
                        ),
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
      final response = await ShopService.deleteShop(id);

      if (!mounted) return;

      if (response['status'] == true) {
        fetchShops(refresh: true); // ✅ fresh after delete
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Shop deleted"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1F3F),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1F3F),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Shops",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => fetchShops(refresh: true),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: showAddDialog,
        backgroundColor: const Color(0xFF2F5DA8),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),

      // ✅ branded loader instead of plain CircularProgressIndicator
      body: loading
          ? const FullScreenLoader(message: "Loading shops...")
          : shops.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F5DA8).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.store_outlined,
                          size: 48,
                          color: Color(0xFF8FAADC),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "No shops yet",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Tap + to create your first shop",
                        style: TextStyle(
                          color: Color(0xFF8FAADC),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => fetchShops(refresh: true), // ✅ fresh on pull
                  color: const Color(0xFF2F5DA8),
                  backgroundColor: const Color(0xFF0F2847),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: shops.length,
                    itemBuilder: (context, index) {
                      final shop = shops[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2847),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2F5DA8).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.store_rounded,
                                color: Color(0xFF8FAADC),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shop['name'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (shop['location'] != null &&
                                      shop['location'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 13,
                                            color: Color(0xFF8FAADC),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            shop['location'],
                                            style: const TextStyle(
                                              color: Color(0xFF8FAADC),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => confirmDelete(
                                shop['id'],
                                shop['name'],
                              ),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}