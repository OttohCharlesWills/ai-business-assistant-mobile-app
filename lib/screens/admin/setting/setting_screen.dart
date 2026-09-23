import 'package:flutter/material.dart';

import '../../../services/product_permission_service.dart';

class SettingScreen extends StatefulWidget {
  final String baseUrl;
  final String token;

  const SettingScreen({
    super.key,
    required this.baseUrl,
    required this.token,
  });

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final ProductPermissionService _permissionService =
      ProductPermissionService();

  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _managers = [];
  List<dynamic> _permissions = [];
  List<dynamic> _shops = [];

  final Color primaryBlue = const Color(0xFF2F5DA8);
  final Color darkBlue = const Color(0xFF0C1F3F);
  final Color background = const Color(0xFFF6F8FC);

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _permissionService.getPermissions(
        baseUrl: widget.baseUrl,
        token: widget.token,
      );

      if (!mounted) return;

      setState(() {
        _managers = data['managers'] ?? [];
        _permissions = data['permissions'] ?? [];
        _shops = data['shops'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  bool _hasPermission(dynamic managerId) {
    final id = managerId is int
        ? managerId
        : int.tryParse(managerId.toString());

    return id != null && _permissions.contains(id);
  }

  Future<void> _togglePermission(
    dynamic manager,
    bool shouldGrant,
  ) async {
    final managerId = manager['id'] is int
        ? manager['id']
        : int.tryParse(manager['id'].toString());

    if (managerId == null) {
      _showMessage('Invalid manager ID.', isError: true);
      return;
    }

    try {
      if (shouldGrant) {
        await _permissionService.grantAccess(
          baseUrl: widget.baseUrl,
          token: widget.token,
          managerId: managerId,
        );
      } else {
        await _permissionService.revokeAccess(
          baseUrl: widget.baseUrl,
          token: widget.token,
          managerId: managerId,
        );
      }

      if (!mounted) return;

      _showMessage(
        shouldGrant
            ? 'Product access granted successfully.'
            : 'Product access revoked successfully.',
      );

      await _loadPermissions();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
  }

  String _managerName(dynamic manager) {
    final name = manager['name'];

    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString();
    }

    final firstName = manager['first_name']?.toString() ?? '';
    final lastName = manager['last_name']?.toString() ?? '';

    final fullName = '$firstName $lastName'.trim();

    return fullName.isNotEmpty ? fullName : 'Manager';
  }

  String _managerEmail(dynamic manager) {
    return manager['email']?.toString() ?? '';
  }

  String _shopName(dynamic manager) {
    final shop = manager['shop'];

    if (shop is Map<String, dynamic>) {
      return shop['name']?.toString() ?? '';
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Settings',
          style: TextStyle(
            color: darkBlue,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(
          color: darkBlue,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPermissions,
        color: primaryBlue,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 350,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.error_outline,
            size: 55,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 15),
          const Text(
            'Unable to load settings',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: _loadPermissions,
              child: const Text('Try Again'),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsHeader(),

        const SizedBox(height: 20),

        _buildPermissionSection(),

        const SizedBox(height: 20),

        _buildShopSection(),
      ],
    );
  }

  Widget _buildSettingsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Business Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Manage your business access and permissions.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  color: primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Product Access',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            Text(
              'Control which managers can access products and inventory.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 18),

            if (_managers.isEmpty)
              _buildEmptyManagers()
            else
              ..._managers.map(
                (manager) => _buildManagerTile(manager),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagerTile(dynamic manager) {
    final managerId = manager['id'];
    final hasAccess = _hasPermission(managerId);
    final name = _managerName(manager);
    final email = _managerEmail(manager);
    final shop = _shopName(manager);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: primaryBlue.withOpacity(0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'M',
              style: TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],

                if (shop.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.store_outlined,
                        size: 13,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          shop,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            children: [
              Switch(
                value: hasAccess,
                activeThumbColor: primaryBlue,
                onChanged: (value) {
                  _togglePermission(manager, value);
                },
              ),

              Text(
                hasAccess ? 'Enabled' : 'Disabled',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: hasAccess
                      ? Colors.green.shade700
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyManagers() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 25),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 45,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            'No managers found',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Managers will appear here when they are available.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.store_outlined,
              color: primaryBlue,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Shops',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_shops.length} shop${_shops.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
}