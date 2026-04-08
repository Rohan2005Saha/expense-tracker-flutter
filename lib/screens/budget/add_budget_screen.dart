import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/budget_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_button.dart';

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({super.key});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final TextEditingController _amountController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  final List<String> _categories = const <String>[
    'Food',
    'Travel',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Other',
  ];

  String _selectedCategory = 'Food';
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isSaving = false;

  bool get _isFormReady => _amountController.text.trim().isNotEmpty && !_isSaving;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_refreshFormState);
  }

  @override
  void dispose() {
    _amountController.removeListener(_refreshFormState);
    _amountController.dispose();
    super.dispose();
  }

  void _refreshFormState() {
    setState(() {});
  }

  Future<void> _pickMonth() async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5, 12),
      helpText: 'Select Budget Month',
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedMonth = DateTime(pickedDate.year, pickedDate.month);
    });
  }

  String _formatMonthYear(DateTime date) {
    const List<String> months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _submitBudget() async {
    final double? limit = double.tryParse(_amountController.text.trim());

    if (limit == null || limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid budget amount greater than 0'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final Budget budget = Budget(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: _selectedCategory,
      limit: limit,
      month: _selectedMonth,
    );

    try {
      await _firestoreService.saveBudget(budget);

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } on StateError {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save budgets')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save budget')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Budget'),
        actions: [
          IconButton(
            onPressed: () => ExpenseTrackerApp.of(context).toggleThemeMode(),
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value == null || _isSaving) {
                    return;
                  }

                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Budget Amount',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _isSaving ? null : _pickMonth,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Month: ${_formatMonthYear(_selectedMonth)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: _isSaving ? 'Saving...' : 'Save Budget',
                onPressed: _isFormReady ? _submitBudget : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
