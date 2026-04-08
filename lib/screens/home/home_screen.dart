import 'dart:async';

import 'package:flutter/material.dart';

import '../../main.dart';
import '../../core/constants/util/expense_utils.dart';
import '../../models/budget_model.dart';
import '../../models/expense_model.dart';
import '../../services/export_service.dart';
import '../../services/firestore_service.dart';
import '../../services/local_storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final LocalStorageService _localStorageService = LocalStorageService();
  final ExportService _exportService = ExportService();

  late final Stream<List<ExpenseModel>> _expensesStream;
  StreamSubscription<List<ExpenseModel>>? _expensesCacheSubscription;
  List<ExpenseModel> _latestExpenses = <ExpenseModel>[];
  double _budget = 0.0;
  bool _isBudgetLoading = true;
  late String _selectedMonthKey;

  @override
  void initState() {
    super.initState();
    _selectedMonthKey = _formatMonthYear(DateTime.now());
    _expensesStream = _firestoreService.expensesStream();
    _expensesCacheSubscription = _expensesStream.listen((
      List<ExpenseModel> expenses,
    ) {
      _latestExpenses = expenses;
      unawaited(_localStorageService.saveExpenses(expenses));
    });
    _loadBudgetForSelectedMonth();
  }

  @override
  void dispose() {
    _expensesCacheSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadBudgetForSelectedMonth() async {
    try {
      final double budget = await _firestoreService.getBudgetLimitForMonth(
        _parseMonthKey(_selectedMonthKey),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _budget = budget;
        _isBudgetLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isBudgetLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load expenses')));
    }
  }

  Future<void> _openAddExpenseScreen() async {
    await Navigator.pushNamed(context, '/add-expense');
  }

  Future<void> _openExpenseDetails(ExpenseModel expense) async {
    await Navigator.pushNamed(context, '/add-expense', arguments: expense);
  }

  Future<void> _showBudgetDialog() async {
    final TextEditingController budgetController = TextEditingController();
    final List<String> monthOptions = _buildBudgetMonthOptions();
    String selectedMonthKey = _selectedMonthKey;

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Set Monthly Budget'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: budgetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Budget Amount',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedMonthKey,
                    decoration: const InputDecoration(
                      labelText: 'Budget Month',
                      border: OutlineInputBorder(),
                    ),
                    items: monthOptions.map((String monthKey) {
                      return DropdownMenuItem<String>(
                        value: monthKey,
                        child: Text(monthKey),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        selectedMonthKey = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave != true) {
      budgetController.dispose();
      return;
    }

    final double? budget = double.tryParse(budgetController.text.trim());
    budgetController.dispose();

    if (budget == null || budget <= 0) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid budget amount')),
      );
      return;
    }

    final Budget budgetEntry = Budget(
      id: '${selectedMonthKey}_${DateTime.now().millisecondsSinceEpoch}',
      category: 'Monthly',
      limit: budget,
      month: _parseMonthKey(selectedMonthKey),
    );

    await _firestoreService.saveBudget(budgetEntry);

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedMonthKey = selectedMonthKey;
    });
    await _loadBudgetForSelectedMonth();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Budget saved for $selectedMonthKey')),
    );
  }

  Future<void> _deleteExpense(String id) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: const Text('Are you sure you want to delete this expense?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _firestoreService.deleteExpense(id);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete expense')));
    }
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day/$month/$year';
  }

  List<ExpenseModel> _filterCurrentMonthExpenses(List<ExpenseModel> expenses) {
    final DateTime selectedMonth = _parseMonthKey(_selectedMonthKey);

    return expenses.where((ExpenseModel expense) {
      return expense.date.month == selectedMonth.month &&
          expense.date.year == selectedMonth.year;
    }).toList();
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

  DateTime _parseMonthKey(String monthKey) {
    const Map<String, int> monthNumbers = <String, int>{
      'January': 1,
      'February': 2,
      'March': 3,
      'April': 4,
      'May': 5,
      'June': 6,
      'July': 7,
      'August': 8,
      'September': 9,
      'October': 10,
      'November': 11,
      'December': 12,
    };

    final List<String> parts = monthKey.split(' ');
    final int month = monthNumbers[parts.first] ?? DateTime.now().month;
    final int year = int.tryParse(parts.last) ?? DateTime.now().year;

    return DateTime(year, month);
  }

  List<String> _buildBudgetMonthOptions() {
    final DateTime now = DateTime.now();

    return List<String>.generate(24, (int index) {
      final DateTime optionDate = DateTime(now.year, now.month - 6 + index);
      return _formatMonthYear(optionDate);
    });
  }

  double _totalExpensesFor(List<ExpenseModel> expenses) {
    return _filterCurrentMonthExpenses(
      expenses,
    ).fold(0, (double sum, ExpenseModel expense) => sum + expense.amount);
  }

  double _remainingBudgetFor(List<ExpenseModel> expenses) {
    return _budget - _totalExpensesFor(expenses);
  }

  double _budgetUsagePercentageFor(List<ExpenseModel> expenses) {
    if (_budget <= 0) {
      return 0;
    }

    return (_totalExpensesFor(expenses) / _budget) * 100;
  }

  String? _budgetStatusTextFor(List<ExpenseModel> expenses) {
    if (_budget <= 0) {
      return null;
    }

    if (_budgetUsagePercentageFor(expenses) >= 100) {
      return 'Budget exceeded';
    }

    if (_budgetUsagePercentageFor(expenses) >= 80) {
      return '80% of budget used';
    }

    return null;
  }

  Color? _budgetStatusColorFor(List<ExpenseModel> expenses) {
    if (_budget <= 0) {
      return null;
    }

    if (_budgetUsagePercentageFor(expenses) >= 100) {
      return Colors.redAccent;
    }

    if (_budgetUsagePercentageFor(expenses) >= 80) {
      return Colors.orange;
    }

    return Colors.green;
  }

  Future<void> _onMonthChanged(String monthKey) async {
    if (monthKey == _selectedMonthKey) {
      return;
    }

    final double budget = await _firestoreService.getBudgetLimitForMonth(
      _parseMonthKey(monthKey),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedMonthKey = monthKey;
      _budget = budget;
    });
  }

  Future<void> _exportCsv(List<ExpenseModel> expenses) async {
    try {
      final String filePath = await _exportService.exportExpensesToCsv(
        _filterCurrentMonthExpenses(expenses),
      );
      await _exportService.shareExportedFile(filePath);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File saved')));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to export CSV')));
    }
  }

  Future<void> _exportPdf(List<ExpenseModel> expenses) async {
    try {
      final String filePath = await _exportService.exportExpensesToPdf(
        _filterCurrentMonthExpenses(expenses),
      );
      await _exportService.shareExportedFile(filePath);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File saved')));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to export PDF')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> monthOptions = _buildBudgetMonthOptions();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
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
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/analytics'),
            icon: const Icon(Icons.bar_chart_outlined),
          ),
        ],
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: _expensesStream,
        builder: (BuildContext context, AsyncSnapshot<List<ExpenseModel>> snapshot) {
          final List<ExpenseModel> expenses = snapshot.data ?? _latestExpenses;
          final Map<String, List<ExpenseModel>> groupedExpenses =
              groupExpensesByMonth(expenses);
          final Color? budgetStatusColor = _budgetStatusColorFor(expenses);
          final String? budgetStatusText = _budgetStatusTextFor(expenses);

          if (_isBudgetLoading && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Failed to load expenses',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    Card(
                      margin: EdgeInsets.zero,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Month',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedMonthKey,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              items: monthOptions.map((String monthKey) {
                                return DropdownMenuItem<String>(
                                  value: monthKey,
                                  child: Text(monthKey),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                if (value == null) {
                                  return;
                                }

                                _onMonthChanged(value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Budget Overview',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _budget <= 0
                                ? const Text(
                                    'No budget set',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : Text(
                                    'Budget ($_selectedMonthKey): ₹${_budget.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: budgetStatusColor,
                                    ),
                                  ),
                            const SizedBox(height: 8),
                            Text(
                              'Remaining: ₹${_remainingBudgetFor(expenses).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: budgetStatusColor,
                              ),
                            ),
                            if (budgetStatusText != null) ...[
                              const SizedBox(height: 10),
                              Text(
                                budgetStatusText,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: budgetStatusColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showBudgetDialog,
                        child: const Text('Set Monthly Budget'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _exportCsv(expenses),
                            child: const Text('Export CSV'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _exportPdf(expenses),
                            child: const Text('Export PDF'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: expenses.isEmpty
                    ? const Center(
                        child: Text(
                          'No expenses yet',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: groupedExpenses.length,
                        itemBuilder: (BuildContext context, int index) {
                          final MapEntry<String, List<ExpenseModel>> section =
                              groupedExpenses.entries.elementAt(index);
                          final String month = section.key;
                          final List<ExpenseModel> expenses = section.value;
                          final double monthTotal = expenses.fold(
                            0,
                            (double sum, ExpenseModel expense) =>
                                sum + expense.amount,
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    bottom: 10,
                                  ),
                                  child: Text(
                                    month,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    bottom: 10,
                                  ),
                                  child: Text(
                                    'Total: ₹${monthTotal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                ...expenses.map((ExpenseModel expense) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Card(
                                      margin: EdgeInsets.zero,
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () =>
                                            _openExpenseDetails(expense),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      expense.title,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      '${expense.category} • ${_formatDate(expense.date)}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '₹${expense.amount.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  IconButton(
                                                    onPressed: () =>
                                                        _deleteExpense(
                                                          expense.id,
                                                        ),
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.redAccent,
                                                    ),
                                                    tooltip: 'Delete expense',
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpenseScreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}
