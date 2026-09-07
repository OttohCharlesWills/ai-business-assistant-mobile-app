import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../services/auth_service.dart';
import '../screens/admin/category/category_screen.dart';
import '../screens/admin/shop/shop_screen.dart';
import '../screens/admin/product/product_screen.dart';
import '../screens/admin/sales/sales_screen.dart';
import '../screens/admin/register/register_staff_screen.dart';
import '../screens/admin/roles/manage_roles_screen.dart';
import '../screens/admin/invoice/invoice_screen.dart';
import '../screens/admin/invoice/create_invoice_screen.dart';
import '../screens/admin/invoice/receivables_screen.dart';
import '../screens/admin/customer/customer_screen.dart';
import '../screens/admin/notification/notification_screen.dart';
import '../screens/admin/profile/profile_screen.dart';
import '../screens/admin/reports/profit_report_screen.dart';
import '../screens/admin/reports/production_report_screen.dart';
import '../screens/admin/reports/sales_report_screen.dart';
import '../screens/admin/reports/stock_report_screen.dart';
import '../screens/admin/production/production_screen.dart';
import '../screens/admin/production/production_create_screen.dart';
import '../screens/admin/productionEntry/production_entry_list_screen.dart';
import '../screens/admin/prouctionType/production_type_screen.dart';
import '../screens/login_screen.dart';

class SideNav extends StatefulWidget {
  const SideNav({super.key});

  @override
  State<SideNav> createState() => _SideNavState();
}

class _SideNavState extends State<SideNav> {
  bool _usersExpanded = false;
  bool _invoiceExpanded = false;
  bool _reportsExpanded = false;
  bool _productionExpanded = false;

  @override
  void initState() {
    super.initState();
    // Fetch unread count when sidebar opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Drawer(
      backgroundColor: const Color(0xFF0C1F3F),
      child: SafeArea(
        child: Column(
          children: [

            // HEADER
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F5DA8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Stock X",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Business Assistant",
                    style: TextStyle(
                      color: Color(0xFF8FAADC),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF2F5DA8), thickness: 0.5),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [

                  _NavItem(
                    icon: Icons.dashboard_rounded,
                    label: "Dashboard",
                    onTap: () => Navigator.pop(context),
                  ),

                  _NavItem(
                    icon: Icons.shopping_bag_rounded,
                    label: "Products",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ProductScreen()));
                    },
                  ),

                  _NavItem(
                    icon: Icons.category_rounded,
                    label: "Categories",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CategoryScreen()));
                    },
                  ),

                  _NavItem(
                    icon: Icons.receipt_long_rounded,
                    label: "Sales",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AdminSalesScreen()));
                    },
                  ),

                  _NavItem(
                    icon: Icons.store_rounded,
                    label: "My Shops",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ShopScreen()));
                    },
                  ),

                  _NavItem(
                    icon: Icons.people_outline,
                    label: "Customers",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const CustomerScreen()));
                    },
                  ),

                  // INVOICE EXPANDABLE
                  _ExpandableNavItem(
                    icon: Icons.receipt_rounded,
                    label: "Invoices",
                    isExpanded: _invoiceExpanded,
                    onTap: () => setState(() => _invoiceExpanded = !_invoiceExpanded),
                    children: [
                      _SubNavItem(
                        icon: Icons.list_alt_rounded,
                        label: "All Invoices",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const InvoiceScreen()));
                        },
                      ),
                      _SubNavItem(
                        icon: Icons.add_circle_outline_rounded,
                        label: "Create Invoice",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()));
                        },
                      ),
                      _SubNavItem(
                        icon: Icons.account_balance_wallet_rounded,
                        label: "Receivables",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ReceivablesScreen()));
                        },
                      ),
                    ],
                  ),

                  // PRODUCTION & MANUFACTURING EXPANDABLE
                  _ExpandableNavItem(
                    icon: Icons.precision_manufacturing_rounded,
                    label: "Production & Manufacturing",
                    isExpanded: _productionExpanded,
                    onTap: () => setState(() => _productionExpanded = !_productionExpanded),
                    children: [
                      _SubNavItem(
                        icon: Icons.list_alt_rounded,
                        label: "Production Batches",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ProductionScreen()));
                        },
                      ),
                      _SubNavItem(
                        icon: Icons.add_circle_outline_rounded,
                        label: "New Production",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ProductionCreateScreen()));
                        },
                      ),
                      _SubNavItem(
                        icon: Icons.playlist_add_check_rounded,
                        label: "Production Entries",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ProductionEntryListScreen()));
                        },
                      ),
                      _SubNavItem(
                        icon: Icons.category_outlined,
                        label: "Production Types",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ProductionTypeScreen()));
                        },
                      ),
                    ],
                  ),

                  // REPORTS EXPANDABLE
                  _ExpandableNavItem(
                    icon: Icons.analytics_rounded,
                    label: "Reports",
                    isExpanded: _reportsExpanded,
                    onTap: () {
                      setState(() => _reportsExpanded = !_reportsExpanded);
                    },
                    children: [
                      _SubNavItem(
                        icon: Icons.attach_money_rounded,
                        label: "Sales Report",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SalesReportScreen(),
                            ),
                          );
                        },
                      ),

                      _SubNavItem(
                        icon: Icons.account_balance_wallet_rounded,
                        label: "Profit Report",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfitReportScreen(),
                            ),
                          );
                        },
                      ),

                      _SubNavItem(
                        icon: Icons.precision_manufacturing_rounded,
                        label: "Production Report",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProductionReportScreen(),
                            ),
                          );
                        },
                      ),

                      _SubNavItem(
                        icon: Icons.inventory_2_rounded,
                        label: "Stock Report",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StockReportScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  _NavItem(
                    icon: Icons.bar_chart_rounded,
                    label: "Analytics",
                    onTap: () => Navigator.pop(context),
                  ),

                  _NavItem(
                    icon: Icons.smart_toy_rounded,
                    label: "AI Assistant",
                    onTap: () => Navigator.pop(context),
                  ),

                  // NOTIFICATIONS WITH BADGE
                  _NavItemWithBadge(
                    icon: Icons.notifications_rounded,
                    label: "Notifications",
                    badgeCount: unreadCount,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationScreen()),
                      ).then((_) {
                        // Refresh count after coming back from notification screen
                        context
                            .read<NotificationProvider>()
                            .fetchUnreadCount();
                      });
                    },
                  ),

                  // USERS EXPANDABLE
                  _ExpandableNavItem(
                    icon: Icons.people_rounded,
                    label: "Users",
                    isExpanded: _usersExpanded,
                    onTap: () => setState(() => _usersExpanded = !_usersExpanded),
                    children: [
                      _SubNavItem(
                        icon: Icons.manage_accounts_rounded,
                        label: "Manage Users",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ManageRolesScreen()));
                        },
                      ),
                      _SubNavItem(
                        icon: Icons.person_add_rounded,
                        label: "Register Staff",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const RegisterStaffScreen()));
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF2F5DA8), thickness: 0.5),
                  const SizedBox(height: 8),

                  _NavItem(
                    icon: Icons.settings_rounded,
                    label: "Settings",
                    onTap: () => Navigator.pop(context),
                  ),

                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    label: "Profile",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),

                  _NavItem(
                    icon: Icons.logout_rounded,
                    label: "Logout",
                    isLogout: true,
                    onTap: () async {
                      await AuthService.logout();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── NAV ITEM WITH BADGE ──────────────────────────────────────────────────────
class _NavItemWithBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItemWithBadge({
    required this.icon,
    required this.label,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: const Color(0xFF8FAADC), size: 22),
          if (badgeCount > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

// ─── REGULAR NAV ITEM ─────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLogout;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Icon(
        icon,
        color: isLogout ? Colors.redAccent : const Color(0xFF8FAADC),
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isLogout ? Colors.redAccent : Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

// ─── EXPANDABLE NAV ITEM ──────────────────────────────────────────────────────
class _ExpandableNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isExpanded;
  final VoidCallback onTap;
  final List<Widget> children;

  const _ExpandableNavItem({
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.onTap,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
          leading: Icon(icon, color: const Color(0xFF8FAADC), size: 22),
          title: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF8FAADC),
              size: 20,
            ),
          ),
          onTap: onTap,
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(left: 24, bottom: 4),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: const Color(0xFF2F5DA8).withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ),
            child: Column(children: children),
          ),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

// ─── SUB NAV ITEM ─────────────────────────────────────────────────────────────
class _SubNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SubNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 20, right: 24),
      leading: Icon(icon, color: const Color(0xFF8FAADC), size: 18),
      title: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF8FAADC),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: onTap,
    );
  }
}