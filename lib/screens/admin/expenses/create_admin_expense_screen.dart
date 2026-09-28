import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/admin_expense_service.dart';

class AdminExpenseCreateScreen extends StatefulWidget {
  const AdminExpenseCreateScreen({super.key});

  @override
  State<AdminExpenseCreateScreen> createState() =>
      _AdminExpenseCreateScreenState();
}

class _AdminExpenseCreateScreenState
    extends State<AdminExpenseCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController =
      TextEditingController();

  final TextEditingController _amountController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  List<dynamic> _shops = [];

  dynamic _selectedShop;

  DateTime _selectedDate = DateTime.now();

  bool _loadingShops = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD SHOPS
  // ============================================================

  Future<void> _loadShops() async {
    try {
      final shops = await AdminExpenseService.getShops();

      if (!mounted) return;

      setState(() {
        _shops = shops;
        _loadingShops = false;

        if (_shops.isNotEmpty) {
          _selectedShop = _shops.first;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingShops = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });
  }

  // ============================================================
  // SAVE EXPENSE
  // ============================================================

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedShop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a shop'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final int? shopId = int.tryParse(
      _selectedShop['id'].toString(),
    );

    if (shopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid shop selected'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final double? amount = double.tryParse(
      _amountController.text
          .trim()
          .replaceAll(',', ''),
    );

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final result =
          await AdminExpenseService.createExpense(
        shopId: shopId,
        title: _titleController.text.trim(),
        amount: amount,
        date: DateFormat('yyyy-MM-dd').format(
          _selectedDate,
        ),
        description:
            _descriptionController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                'Expense added successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Tell the expense list that an expense
      // was successfully created.
      Navigator.pop(context, true);
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
          _saving = false;
        });
      }
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
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0C1F3F),
        elevation: 0,
        title: const Text(
          'Add Expense',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: _loadingShops
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeader(),

                  const SizedBox(height: 24),

                  _buildShopDropdown(),

                  const SizedBox(height: 16),

                  _buildTitleField(),

                  const SizedBox(height: 16),

                  _buildAmountField(),

                  const SizedBox(height: 16),

                  _buildDateField(),

                  const SizedBox(height: 16),

                  _buildDescriptionField(),

                  const SizedBox(height: 30),

                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1F3F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: Colors.white,
            size: 36,
          ),

          SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Record an Expense',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Add a new business expense',
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

  // ============================================================
  // SHOP
  // ============================================================

  Widget _buildShopDropdown() {
    return DropdownButtonFormField<dynamic>(
      value: _selectedShop,

      decoration: _inputDecoration(
        label: 'Shop',
        icon: Icons.store_outlined,
      ),

      items: _shops.map((shop) {
        return DropdownMenuItem<dynamic>(
          value: shop,
          child: Text(
            shop['name']?.toString() ??
                'Unnamed Shop',
          ),
        );
      }).toList(),

      onChanged: (value) {
        setState(() {
          _selectedShop = value;
        });
      },

      validator: (value) {
        if (value == null) {
          return 'Please select a shop';
        }

        return null;
      },
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,

      textInputAction: TextInputAction.next,

      decoration: _inputDecoration(
        label: 'Expense Title',
        hint: 'e.g. Shop rent',
        icon: Icons.title,
      ),

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Enter expense title';
        }

        return null;
      },
    );
  }

  // ============================================================
  // AMOUNT
  // ============================================================

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,

      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),

      decoration: _inputDecoration(
        label: 'Amount',
        hint: '0.00',
        icon: Icons.payments_outlined,
      ),

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Enter amount';
        }

        final amount = double.tryParse(
          value.replaceAll(',', '').trim(),
        );

        if (amount == null || amount <= 0) {
          return 'Enter a valid amount';
        }

        return null;
      },
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,

      borderRadius: BorderRadius.circular(12),

      child: InputDecorator(
        decoration: _inputDecoration(
          label: 'Date',
          icon: Icons.calendar_today_outlined,
        ),

        child: Text(
          DateFormat(
            'MMM dd, yyyy',
          ).format(_selectedDate),

          style: const TextStyle(
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,

      maxLines: 4,

      decoration: _inputDecoration(
        label: 'Description',
        hint: 'Optional expense description',
        icon: Icons.description_outlined,
      ),
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _buildSaveButton() {
    return SizedBox(
      height: 54,

      child: ElevatedButton(
        onPressed: _saving
            ? null
            : _saveExpense,

        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF2F5DA8),

          foregroundColor: Colors.white,

          disabledBackgroundColor:
              const Color(0xFF2F5DA8)
                  .withOpacity(.6),

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),

        child: _saving
            ? const SizedBox(
                width: 23,
                height: 23,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Save Expense',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,

      prefixIcon: Icon(
        icon,
        color: const Color(0xFF2F5DA8),
      ),

      filled: true,
      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF2F5DA8),
          width: 2,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
    );
  }
}