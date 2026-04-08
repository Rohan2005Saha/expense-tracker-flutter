import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/budget_model.dart';
import '../../models/expense_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_button.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.expense});

  final ExpenseModel? expense;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  final List<String> _categories = const [
    'Food',
    'Travel',
    'Shopping',
    'Other',
  ];

  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  ExpenseModel? _editingExpense;
  bool _hasLoadedExpense = false;
  bool _isLoading = false;

  bool get _isEditing => _editingExpense != null;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_refreshFormState);
    _amountController.addListener(_refreshFormState);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_hasLoadedExpense) {
      return;
    }

    final Object? arguments = ModalRoute.of(context)?.settings.arguments;
    final ExpenseModel? expense =
        widget.expense ?? (arguments as ExpenseModel?);

    if (expense != null) {
      _editingExpense = expense;
      _titleController.text = expense.title;
      _amountController.text = expense.amount.toStringAsFixed(2);
      _selectedCategory = expense.category;
      _selectedDate = expense.date;
    }

    _hasLoadedExpense = true;
  }

  @override
  void dispose() {
    _titleController.removeListener(_refreshFormState);
    _amountController.removeListener(_refreshFormState);
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _refreshFormState() {
    setState(() {});
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day/$month/$year';
  }

  bool get _isFormReady {
    return _titleController.text.trim().isNotEmpty &&
        _amountController.text.trim().isNotEmpty &&
        !_isLoading;
  }

  Future<void> _submitExpense() async {
    if (_isLoading) {
      return;
    }

    final String title = _titleController.text.trim();
    final double? amount = double.tryParse(_amountController.text.trim());

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than 0'),
        ),
      );
      return;
    }

    final ExpenseModel expense = ExpenseModel(
      id:
          _editingExpense?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
    );

    try {
      setState(() {
        _isLoading = true;
      });

      if (_isEditing) {
        await _firestoreService.updateExpense(expense);
      } else {
        await _firestoreService.addExpense(expense);
      }

      if (!mounted) {
        return;
      }

      if (!_isEditing) {
        final Budget? categoryBudget = await _firestoreService
            .getBudgetForCategoryAndMonth(expense.category, expense.date);
        final double categorySpending = await _firestoreService
            .getCategorySpendingForMonth(expense.category, expense.date);

        if (!mounted) {
          return;
        }

        if (categoryBudget != null && categorySpending > categoryBudget.limit) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You are over budget in ${expense.category}'),
            ),
          );
        }
      }

      Navigator.pop(context, true);
    } on StateError catch (error, stackTrace) {
      debugPrint('Failed to save expense: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } catch (error, stackTrace) {
      debugPrint('Failed to save expense: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
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
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
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
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Date: ${_formatDate(_selectedDate)}',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: _isLoading
                    ? (_isEditing ? 'Updating...' : 'Adding...')
                    : (_isEditing ? 'Update Expense' : 'Add Expense'),
                onPressed: _isFormReady ? _submitExpense : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
