import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense_model.dart';

class LocalStorageService {
  static const String _expensesKey = 'expenses';

  Future<void> saveExpenses(List<ExpenseModel> expenses) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> encodedExpenses = expenses
        .map(
          (ExpenseModel expense) => jsonEncode(<String, dynamic>{
            'id': expense.id,
            'title': expense.title,
            'amount': expense.amount,
            'category': expense.category,
            'date': expense.date.toIso8601String(),
          }),
        )
        .toList();

    await prefs.setStringList(_expensesKey, encodedExpenses);
  }

  Future<List<ExpenseModel>> getExpenses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> storedExpenses =
        prefs.getStringList(_expensesKey) ?? <String>[];

    return storedExpenses.map((String expenseJson) {
      final Map<String, dynamic> expenseMap =
          jsonDecode(expenseJson) as Map<String, dynamic>;
      return ExpenseModel.fromMap(expenseMap);
    }).toList();
  }

  Future<void> deleteExpense(String id) async {
    final List<ExpenseModel> expenses = await getExpenses();
    final List<ExpenseModel> updatedExpenses = expenses
        .where((ExpenseModel expense) => expense.id != id)
        .toList();

    await saveExpenses(updatedExpenses);
  }

  Future<void> updateExpense(ExpenseModel updatedExpense) async {
    final List<ExpenseModel> expenses = await getExpenses();
    final int index = expenses.indexWhere(
      (ExpenseModel expense) => expense.id == updatedExpense.id,
    );

    if (index == -1) {
      return;
    }

    expenses[index] = updatedExpense;
    await saveExpenses(expenses);
  }
}
