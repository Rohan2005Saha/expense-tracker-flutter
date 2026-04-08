import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/expense_model.dart';
import '../../services/firestore_service.dart';
import '../../services/local_storage_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final LocalStorageService _localStorageService = LocalStorageService();
  final FirestoreService _firestoreService = FirestoreService();
  static const String _thisMonthFilter = 'This Month';
  static const String _lastMonthFilter = 'Last Month';
  static const String _selectMonthFilter = 'Select Month';

  final Map<String, Color> _categoryColors = <String, Color>{
    'Food': Colors.orange,
    'Travel': Colors.blue,
    'Shopping': Colors.pink,
    'Other': Colors.green,
  };

  List<ExpenseModel> _expenses = <ExpenseModel>[];
  double _budget = 0.0;
  bool _isLoading = true;
  String _selectedFilter = _thisMonthFilter;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _loadData();
  }

  Future<void> _loadData() async {
    final List<ExpenseModel> expenses = await _localStorageService
        .getExpenses();
    final double budget = await _firestoreService.getBudgetLimitForMonth(
      _selectedMonth,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _expenses = expenses;
      _budget = budget;
      _isLoading = false;
    });
  }

  List<ExpenseModel> _filterCurrentMonthExpenses(List<ExpenseModel> expenses) {
    return expenses.where((ExpenseModel expense) {
      return expense.date.month == _selectedMonth.month &&
          expense.date.year == _selectedMonth.year;
    }).toList();
  }

  List<ExpenseModel> get _currentMonthExpenses {
    return _filterCurrentMonthExpenses(_expenses);
  }

  double get _totalExpense {
    return _currentMonthExpenses.fold(
      0,
      (double sum, ExpenseModel expense) => sum + expense.amount,
    );
  }

  double get _remainingBudget {
    return _budget - _totalExpense;
  }

  Map<String, double> get _categoryTotals {
    final Map<String, double> totals = <String, double>{};

    for (final ExpenseModel expense in _currentMonthExpenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
    }

    return totals;
  }

  String _formatCurrency(double amount) {
    final bool isNegative = amount < 0;
    final String fixed = amount.abs().toStringAsFixed(2);
    final List<String> parts = fixed.split('.');
    final String whole = parts[0];
    final String decimal = parts[1];

    final String formattedWhole = whole.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (Match match) => ',',
    );

    return '${isNegative ? '-' : ''}₹$formattedWhole.$decimal';
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

  List<String> get _filterOptions => <String>[
    _thisMonthFilter,
    _lastMonthFilter,
    _selectMonthFilter,
  ];

  List<DateTime> get _monthOptions {
    final DateTime now = DateTime.now();

    return List<DateTime>.generate(12, (int index) {
      return DateTime(now.year, now.month - index);
    });
  }

  String get _activeMonthKey {
    return _formatMonthYear(_selectedMonth);
  }

  Future<void> _updateFilter(String filter, {DateTime? customMonth}) async {
    DateTime nextMonth = _selectedMonth;

    if (filter == _thisMonthFilter) {
      final DateTime now = DateTime.now();
      nextMonth = DateTime(now.year, now.month);
    } else if (filter == _lastMonthFilter) {
      final DateTime now = DateTime.now();
      nextMonth = DateTime(now.year, now.month - 1);
    } else if (customMonth != null) {
      nextMonth = DateTime(customMonth.year, customMonth.month);
    }

    final double budget = await _firestoreService.getBudgetLimitForMonth(
      nextMonth,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedFilter = filter;
      _selectedMonth = nextMonth;
      _budget = budget;
    });
  }

  List<PieChartSectionData> _buildPieSections(
    Map<String, double> categoryTotals,
  ) {
    return categoryTotals.entries.map((MapEntry<String, double> entry) {
      final double percentage = _totalExpense == 0
          ? 0
          : (entry.value / _totalExpense) * 100;

      return PieChartSectionData(
        color: _categoryColors[entry.key] ?? Colors.grey,
        value: entry.value,
        radius: 84,
        title: '${percentage.toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  MapEntry<String, double>? get _highestSpendingCategory {
    final Map<String, double> totals = _categoryTotals;

    if (totals.isEmpty) {
      return null;
    }

    return totals.entries.reduce((
      MapEntry<String, double> current,
      MapEntry<String, double> next,
    ) {
      return next.value > current.value ? next : current;
    });
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, double> categoryTotals = _categoryTotals;
    final MapEntry<String, double>? highestSpendingCategory =
        _highestSpendingCategory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : categoryTotals.isEmpty
          ? const Center(child: Text('No data to analyze'))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: _cardDecoration(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Month Filter',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedFilter,
                          decoration: const InputDecoration(
                            labelText: 'Filter',
                          ),
                          items: _filterOptions.map((String option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            if (value == null) {
                              return;
                            }

                            _updateFilter(value);
                          },
                        ),
                        if (_selectedFilter == _selectMonthFilter) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<DateTime>(
                            initialValue: _selectedMonth,
                            decoration: const InputDecoration(
                              labelText: 'Select Month',
                            ),
                            items: _monthOptions.map((DateTime month) {
                              return DropdownMenuItem<DateTime>(
                                value: month,
                                child: Text(_formatMonthYear(month)),
                              );
                            }).toList(),
                            onChanged: (DateTime? value) {
                              if (value == null) {
                                return;
                              }

                              _updateFilter(
                                _selectMonthFilter,
                                customMonth: value,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Expense ($_activeMonthKey)',
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _formatCurrency(_totalExpense),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Budget Overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryTile(
                                label: 'Budget ($_activeMonthKey)',
                                value: _formatCurrency(_budget),
                                valueColor: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryTile(
                                label: 'Remaining',
                                value: _formatCurrency(_remainingBudget),
                                valueColor: _remainingBudget < 0
                                    ? Colors.redAccent
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (highestSpendingCategory != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Insights',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'You spend most on ${highestSpendingCategory.key}.',
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try reducing ${highestSpendingCategory.key.toLowerCase()} expenses.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: _cardDecoration(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Spending Breakdown',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'A quick view of how your total spending is distributed across categories.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 240,
                          child: PieChart(
                            PieChartData(
                              centerSpaceRadius: 48,
                              sectionsSpace: 3,
                              sections: _buildPieSections(categoryTotals),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      'Category-wise Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...categoryTotals.entries.map((
                    MapEntry<String, double> entry,
                  ) {
                    final double percentage = _totalExpense == 0
                        ? 0
                        : (entry.value / _totalExpense) * 100;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: CircleAvatar(
                          radius: 8,
                          backgroundColor:
                              _categoryColors[entry.key] ?? Colors.grey,
                        ),
                        title: Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        trailing: Text(
                          _formatCurrency(entry.value),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
