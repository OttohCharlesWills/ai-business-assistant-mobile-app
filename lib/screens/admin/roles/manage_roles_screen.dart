import 'package:flutter/material.dart';
import '../../../services/role_service.dart';

class ManageRolesScreen extends StatefulWidget {
  const ManageRolesScreen({super.key});

  @override
  State<ManageRolesScreen> createState() => _ManageRolesScreenState();
}

class _ManageRolesScreenState extends State<ManageRolesScreen> {

  static const bgColor = Color(0xFF0C1F3F);
  static const cardColor = Color(0xFF0F2847);
  static const accentBlue = Color(0xFF2F5DA8);
  static const softBlue = Color(0xFF8FAADC);

  List users = [];
  List shops = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() => loading = true);
    final result = await RoleService.getUsers();
    setState(() {
      users = result['users'];
      shops = result['shops'];
      loading = false;
    });
  }

  Future<void> confirmDelete(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: cardColor,
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
                    color: Colors.redAccent),
              ),
              const SizedBox(height: 16),
              const Text(
                "Delete User",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                "Are you sure you want to delete \"$name\"? This cannot be undone.",
                style: const TextStyle(
                    color: softBlue, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: accentBlue.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel",
                          style: TextStyle(color: softBlue)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Delete",
                          style: TextStyle(color: Colors.white)),
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
      final res = await RoleService.deleteUser(id);
      if (!mounted) return;
      if (res['status'] == true) {
        fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User deleted"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _openUserOptions(Map user) {
    String currentRole = user['role'];
    int? currentShopId = user['shop_id'];

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: softBlue.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // USER INFO
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: accentBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: softBlue, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'] ?? '',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user['email'] ?? '',
                          style: const TextStyle(
                              color: softBlue, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // CHANGE ROLE
              const Text(
                "Change Role",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currentRole,
                    dropdownColor: bgColor,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(
                        value: 'cashier',
                        child: Text("Cashier",
                            style: TextStyle(color: Colors.white)),
                      ),
                      DropdownMenuItem(
                        value: 'manager',
                        child: Text("Manager",
                            style: TextStyle(color: Colors.white)),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text("Admin",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                    onChanged: (val) =>
                        setSheetState(() => currentRole = val!),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ASSIGN SHOP
              const Text(
                "Assign Shop",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: currentShopId,
                    dropdownColor: bgColor,
                    isExpanded: true,
                    hint: const Text("Select Shop",
                        style: TextStyle(color: softBlue)),
                    items: shops.map<DropdownMenuItem<int>>((shop) {
                      return DropdownMenuItem<int>(
                        value: shop['id'],
                        child: Text(shop['name'],
                            style:
                                const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setSheetState(() => currentShopId = val),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // UPDATE BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    // UPDATE ROLE
                    await RoleService.updateRole(
                      userId: user['id'],
                      role: currentRole,
                    );

                    // UPDATE SHOP IF SELECTED
                    if (currentShopId != null) {
                      await RoleService.updateShop(
                        userId: user['id'],
                        shopId: currentShopId!,
                      );
                    }

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    fetchUsers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("User updated successfully"),
                        backgroundColor: accentBlue,
                      ),
                    );
                  },
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // DELETE BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    confirmDelete(user['id'], user['name']);
                  },
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent),
                  label: const Text("Delete User",
                      style: TextStyle(color: Colors.redAccent)),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
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
          "Manage Users",
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: fetchUsers,
          ),
        ],
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: accentBlue))
          : users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: accentBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people_outline_rounded,
                            size: 48, color: softBlue),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "No staff yet",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Register staff to manage roles",
                        style:
                            TextStyle(color: softBlue, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchUsers,
                  color: accentBlue,
                  backgroundColor: cardColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final role = user['role'] ?? 'cashier';
                      final shopName =
                          user['shop']?['name'] ?? 'Not assigned';

                      return GestureDetector(
                        onTap: () => _openUserOptions(user),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: accentBlue.withOpacity(0.2),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                    Icons.person_rounded,
                                    color: softBlue),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['name'] ?? '',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user['email'] ?? '',
                                      style: const TextStyle(
                                          color: softBlue,
                                          fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                            Icons.store_rounded,
                                            size: 12,
                                            color: softBlue),
                                        const SizedBox(width: 4),
                                        Text(
                                          shopName,
                                          style: const TextStyle(
                                              color: softBlue,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: role == 'manager'
                                      ? Colors.orange.withOpacity(0.2)
                                      : accentBlue.withOpacity(0.2),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Text(
                                  role[0].toUpperCase() +
                                      role.substring(1),
                                  style: TextStyle(
                                    color: role == 'manager'
                                        ? Colors.orange
                                        : softBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right_rounded,
                                  color: softBlue, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}