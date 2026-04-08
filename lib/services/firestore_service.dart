import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/budget_model.dart';
import '../models/expense_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _firebaseAuth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  String get _currentUserId {
    final User? user = _firebaseAuth.currentUser;

    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _expensesCollection =>
      _firestore.collection('users').doc(_currentUserId).collection('expenses');

  CollectionReference<Map<String, dynamic>> get _budgetsCollection =>
      _firestore.collection('users').doc(_currentUserId).collection('budgets');

  Future<void> addExpense(ExpenseModel expense) async {
    await _expensesCollection.doc(expense.id).set(expense.toMap());
  }

  Stream<List<ExpenseModel>> expensesStream() {
    return _expensesCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs.map((
            QueryDocumentSnapshot<Map<String, dynamic>> doc,
          ) {
            final Map<String, dynamic> data = doc.data();
            data['id'] = data['id'] ?? doc.id;
            return ExpenseModel.fromMap(data);
          }).toList();
        });
  }

  Future<List<ExpenseModel>> getExpenses() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _expensesCollection.orderBy('date', descending: true).get();

    return snapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final Map<String, dynamic> data = doc.data();
      data['id'] = data['id'] ?? doc.id;
      return ExpenseModel.fromMap(data);
    }).toList();
  }

  Future<List<ExpenseModel>> getCurrentMonthExpenses() async {
    final DateTime now = DateTime.now();
    final DateTime monthStart = DateTime(now.year, now.month);
    final DateTime nextMonth = DateTime(now.year, now.month + 1);

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _expensesCollection
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
            )
            .where('date', isLessThan: Timestamp.fromDate(nextMonth))
            .orderBy('date', descending: true)
            .get();

    return snapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final Map<String, dynamic> data = doc.data();
      data['id'] = data['id'] ?? doc.id;
      return ExpenseModel.fromMap(data);
    }).toList();
  }

  Future<void> deleteExpense(String id) async {
    await _expensesCollection.doc(id).delete();
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await _expensesCollection.doc(expense.id).update(expense.toMap());
  }

  Future<void> saveBudget(Budget budget) async {
    await _budgetsCollection.doc(budget.id).set(budget.toMap());
  }

  Future<List<Budget>> getBudgets() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _budgetsCollection.orderBy('month', descending: true).get();

    return snapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final Map<String, dynamic> data = doc.data();
      data['id'] = data['id'] ?? doc.id;
      return Budget.fromMap(data);
    }).toList();
  }

  Future<double> getBudgetLimitForMonth(DateTime month) async {
    final List<Budget> budgets = await getBudgetsForMonth(month);

    double total = 0;

    for (final Budget budget in budgets) {
      total += budget.limit;
    }

    return total;
  }

  Future<List<Budget>> getBudgetsForMonth(DateTime month) async {
    final DateTime monthStart = DateTime(month.year, month.month);
    final DateTime nextMonth = DateTime(month.year, month.month + 1);

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _budgetsCollection
            .where(
              'month',
              isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
            )
            .where('month', isLessThan: Timestamp.fromDate(nextMonth))
            .orderBy('month', descending: true)
            .get();

    return snapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
      final Map<String, dynamic> data = doc.data();
      data['id'] = data['id'] ?? doc.id;
      return Budget.fromMap(data);
    }).toList();
  }

  Future<double> getCategorySpendingForMonth(
    String category,
    DateTime month,
  ) async {
    final DateTime monthStart = DateTime(month.year, month.month);
    final DateTime nextMonth = DateTime(month.year, month.month + 1);

    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _expensesCollection
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
            )
            .where('date', isLessThan: Timestamp.fromDate(nextMonth))
            .get();

    double total = 0;

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in snapshot.docs) {
      final Map<String, dynamic> data = doc.data();

      if (data['category'] == category) {
        total += (data['amount'] as num).toDouble();
      }
    }

    return total;
  }

  Future<Budget?> getBudgetForCategoryAndMonth(
    String category,
    DateTime month,
  ) async {
    final List<Budget> budgets = await getBudgetsForMonth(month);

    for (final Budget budget in budgets) {
      if (budget.category == category) {
        return budget;
      }
    }

    return null;
  }
}
