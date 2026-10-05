
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/admin_expense_service.dart';
import 'create_admin_expense_screen.dart';

class AdminExpensesScreen extends StatefulWidget {
  const AdminExpensesScreen({super.key});

  @override
  State<AdminExpensesScreen> createState() =>
      _AdminExpensesScreenState();
}

class _AdminExpensesScreenState extends State<AdminExpensesScreen> {
  bool _isLoading = true;
  bool _isDeleting = false;

  String? _error;

  List<dynamic> _expenses = [];

  int _currentPage = 1;
  int _lastPage = 1;

  final NumberFormat _currencyFormat = NumberFormat(
    '#,##0.00',
    'en_NG',
  );

  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  // ============================================================
  // LOAD EXPENSES
  // ============================================================

  Future<void> _loadExpenses({int page = 1}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await AdminExpenseService.getExpenses(
        page: page,
      );

      final expensesResponse = result['expenses'];

      List<dynamic> expenses = [];

      int currentPage = page;
      int lastPage = page;

      if (expensesResponse is Map) {
        expenses = expensesResponse['data'] ?? [];

        currentPage =
            expensesResponse['current_page'] ?? page;

        lastPage =
            expensesResponse['last_page'] ?? page;
      } else if (expensesResponse is List) {
        expenses = expensesResponse;
      }

      if (!mounted) return;

      setState(() {
        _expenses = expenses;
        _currentPage = currentPage;
        _lastPage = lastPage;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  // ============================================================
  // DELETE EXPENSE
  // ============================================================

  Future<void> _deleteExpense(dynamic expense) async {
    final id = int.tryParse(
      expense['id'].toString(),
    );

    if (id == null) return;

    final title =
        expense['title']?.toString() ?? 'this expense';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: Text(
            'Are you sure you want to delete "$title"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final result =
          await AdminExpenseService.deleteExpense(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                'Expense deleted successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await _loadExpenses(
        page: _currentPage,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // ============================================================
  // FORMAT AMOUNT
  // ============================================================

  String _formatAmount(dynamic amount) {
    final value = double.tryParse(
          amount?.toString() ?? '0',
        ) ??
        0;

    return '₦${_currencyFormat.format(value)}';
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(dynamic date) {
    if (date == null) return '—';

    try {
      final parsedDate = DateTime.parse(
        date.toString(),
      );

      return _dateFormat.format(parsedDate);
    } catch (_) {
      return date.toString();
    }
  }

  // ============================================================
  // GET USER NAME
  // ============================================================

  String _getAddedBy(dynamic expense) {
    if (expense['user'] is Map) {
      return expense['user']['name']?.toString() ??
          'Unknown User';
    }

    if (expense['added_by'] != null) {
      return 'User #${expense['added_by']}';
    }

    return 'Unknown User';
  }

  // ============================================================
  // ADD EXPENSE
  // ============================================================

  Future<void> _openCreateExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminExpenseCreateScreen(),
      ),
    );

    if (result == true) {
      await _loadExpenses(
        page: _currentPage,
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0C1F3F),
        title: const Row(
          children: [
            Icon(
              Icons.attach_money,
              size: 25,
            ),
            SizedBox(width: 8),
            Text(
              'Expenses',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      body: _buildBody(),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _openCreateExpense,
        backgroundColor: const Color(0xFF2F5DA8),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.red,
              ),

              const SizedBox(height: 12),

              Text(
                _error!,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: () => _loadExpenses(
                  page: _currentPage,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_expenses.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadExpenses(
          page: _currentPage,
        ),
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 150),

            Icon(
              Icons.receipt_long_outlined,
              size: 70,
              color: Colors.grey,
            ),

            SizedBox(height: 15),

            Center(
              child: Text(
                'No expenses found.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadExpenses(
        page: _currentPage,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ),
        children: [
          _buildSummaryCard(),

          const SizedBox(height: 16),

          ..._expenses.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final expense = entry.value;

              return _buildExpenseCard(
                expense,
                index,
              );
            },
          ),

          if (_lastPage > 1) ...[
            const SizedBox(height: 10),
            _buildPagination(),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _buildSummaryCard() {
    double total = 0;

    for (final expense in _expenses) {
      total +=
          double.tryParse(
                expense['amount']?.toString() ?? '0',
              ) ??
              0;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1F3F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expenses on this page',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '₦${_currencyFormat.format(total)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EXPENSE CARD
  // ============================================================

  Widget _buildExpenseCard(
    dynamic expense,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F5DA8)
                        .withOpacity(.1),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFF2F5DA8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense['title']
                                ?.toString() ??
                            'Untitled Expense',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        _formatDate(
                          expense['date'],
                        ),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  _formatAmount(
                    expense['amount'],
                  ),
                  style: const TextStyle(
                    color: Color(0xFF2F5DA8),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            _buildInfoRow(
              Icons.person_outline,
              'Added By',
              _getAddedBy(expense),
            ),

            const SizedBox(height: 8),

            _buildInfoRow(
              Icons.description_outlined,
              'Description',
              expense['description']
                          ?.toString()
                          .trim()
                          .isNotEmpty ==
                      true
                  ? expense['description'].toString()
                  : '—',
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _isDeleting
                    ? null
                    : () => _deleteExpense(
                          expense,
                        ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(
                    color: Colors.red,
                  ),
                ),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                ),
                label: const Text('Delete'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade600,
        ),

        const SizedBox(width: 8),

        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),

        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 1
              ? () => _loadExpenses(
                    page: _currentPage - 1,
                  )
              : null,
          icon: const Icon(
            Icons.chevron_left,
          ),
        ),

        Text(
          'Page $_currentPage of $_lastPage',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        IconButton(
          onPressed: _currentPage < _lastPage
              ? () => _loadExpenses(
                    page: _currentPage + 1,
                  )
              : null,
          icon: const Icon(
            Icons.chevron_right,
          ),
        ),
      ],
    );
  }
}

