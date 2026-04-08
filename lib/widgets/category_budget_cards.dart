import 'package:flutter/material.dart';

import '../core/constants/util/expense_utils.dart';

class CategoryBudgetCards extends StatelessWidget {
  const CategoryBudgetCards({
    super.key,
    required this.budgets,
  });

  final List<BudgetSummary> budgets;

  String _formatCurrency(double amount) {
    final bool isNegative = amount < 0;
    final String fixed = amount.abs().toStringAsFixed(2);
    return '${isNegative ? '-' : ''}₹$fixed';
  }

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) {
      return const Center(
        child: Text(
          'No budget data available',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: budgets.map((BudgetSummary budget) {
        final bool isOverBudget = budget.isOverBudget;
        final Color accentColor = isOverBudget
            ? Colors.redAccent
            : colorScheme.primary;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isOverBudget
                    ? Colors.redAccent.withValues(alpha: 0.35)
                    : colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        budget.category,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isOverBudget)
                      Text(
                        'Over Budget',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.redAccent,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${_formatCurrency(budget.spent)} / ${_formatCurrency(budget.limit)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Remaining: ${_formatCurrency(budget.remaining)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isOverBudget
                        ? Colors.redAccent
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: budget.limit <= 0
                        ? 0
                        : (budget.spent / budget.limit).clamp(0, 1).toDouble(),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
