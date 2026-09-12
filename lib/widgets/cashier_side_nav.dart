import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/offline_pos_service.dart';
import '../screens/login_screen.dart';
import '../screens/cashier/customer/cashier_customer_screen.dart';
import '../screens/cashier/expense/cashier_expense_screen.dart';
import '../screens/cashier/invoice/cashier_invoice_create_screen.dart';
import '../screens/cashier/invoice/cashier_invoice_list_screen.dart';
import '../screens/cashier/invoice/cashier_invoice_receivables_screen.dart';
import '../screens/cashier/offline/offline_sales_screen.dart';
import '../screens/cashier/sales/cashier_sales_screen.dart';

class CashierSideNav extends StatefulWidget {
  const CashierSideNav({super.key});

  @override
  State<CashierSideNav> createState() => _CashierSideNavState();
}

class _CashierSideNavState extends State<CashierSideNav> {
  bool _invoiceExpanded = false;
  int _pendingOfflineSyncCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingSyncCount();
  }

  // Shows how many offline sales are still waiting to sync, right on the
  // nav item — so a cashier can see at a glance that there's unsynced
  // work before even opening the offline sales screen.
  Future<void> _loadPendingSyncCount() async {
    final count = await OfflinePosService.getPendingSyncCount();
    if (!mounted) return;
    setState(() => _pendingOfflineSyncCount = count);
  }

  @override
  Widget build(BuildContext context) {
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
                    "Cashier",
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
                    icon: Icons.people_outline,
                    label: "Customers",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CashierCustomerScreen()),
                      );
                    },
                  ),

                  // OFFLINE SALES
                  _NavItem(
                    icon: Icons.wifi_off_rounded,
                    label: "Offline Sales",
                    badgeCount: _pendingOfflineSyncCount,
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const OfflineSalesScreen()),
                      );
                      // Refresh the badge in case sales were synced or
                      // queued while that screen was open.
                      _loadPendingSyncCount();
                    },
                  ),

                  // INVOICE EXPANDABLE
                  _ExpandableNavItem(
                    icon: Icons.receipt_rounded,
                    label: "Invoices",
                    isExpanded: _invoiceExpanded,
                    onTap: () =>
                        setState(() => _invoiceExpanded = !_invoiceExpanded),
                    children: [
                      _SubNavItem(
                        icon: Icons.list_alt_rounded,
                        label: "All Invoices",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const CashierInvoiceListScreen()),
                          );
                        },
                      ),
                      _SubNavItem(
                        icon: Icons.add_circle_outline_rounded,
                        label: "Create Invoice",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const CashierInvoiceCreateScreen()),
                          );
                        },
                      ),
                      _SubNavItem(
                        icon: Icons.account_balance_wallet_rounded,
                        label: "Receivables",
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const CashierInvoiceReceivablesScreen()),
                          );
                        },
                      ),
                    ],
                  ),

                  _NavItem(
                    icon: Icons.money_off_rounded,
                    label: "Expenses",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CashierExpenseScreen()),
                      );
                    },
                  ),

                  _NavItem(
                    icon: Icons.shopping_cart_rounded,
                    label: "Sales",
                    onTap: () {
                      Navigator.pop(context); // close the drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CashierSalesScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF2F5DA8), thickness: 0.5),
                  const SizedBox(height: 8),

                  _NavItem(
                    icon: Icons.logout_rounded,
                    label: "Logout",
                    isLogout: true,
                    onTap: () async {
                      await AuthService.logout();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
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

// ─── NAV ITEM ─────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLogout;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLogout = false,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
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
      trailing: badgeCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$badgeCount",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
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
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
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