import '../../../models/budget_model.dart';
import '../../../models/expense_model.dart';

class BudgetSummary {
  BudgetSummary({
    required this.category,
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.isOverBudget,
  });

  final String category;
  final double limit;
  final double spent;
  final double remaining;
  final bool isOverBudget;
}

Map<String, List<ExpenseModel>> groupExpensesByMonth(
  List<ExpenseModel> expenses,
) {
  const List<String> monthNames = <String>[
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

  final Map<String, List<ExpenseModel>> groupedExpenses =
      <String, List<ExpenseModel>>{};

  for (final ExpenseModel expense in expenses) {
    final String monthKey =
        '${monthNames[expense.date.month - 1]} ${expense.date.year}';

    groupedExpenses.putIfAbsent(monthKey, () => <ExpenseModel>[]);
    groupedExpenses[monthKey]!.add(expense);
  }

  return groupedExpenses;
}

Map<String, double> getCurrentMonthCategoryTotals(
  List<ExpenseModel> expenses,
) {
  final DateTime now = DateTime.now();
  final Map<String, double> categoryTotals = <String, double>{};

  for (final ExpenseModel expense in expenses) {
    final bool isCurrentMonth =
        expense.date.month == now.month && expense.date.year == now.year;

    if (!isCurrentMonth) {
      continue;
    }

    categoryTotals[expense.category] =
        (categoryTotals[expense.category] ?? 0) + expense.amount;
  }

  return categoryTotals;
}

List<BudgetSummary> getBudgetSummaries(
  List<Budget> budgets,
  Map<String, double> categorySpending,
) {
  return budgets.map((Budget budget) {
    final double spent = categorySpending[budget.category] ?? 0;
    final double remaining = budget.limit - spent;

    return BudgetSummary(
      category: budget.category,
      limit: budget.limit,
      spent: spent,
      remaining: remaining,
      isOverBudget: spent > budget.limit,
    );
  }).toList();
}
