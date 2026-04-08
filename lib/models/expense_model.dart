import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
    };
  }

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    final dynamic rawDate = map['date'];

    return ExpenseModel(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      date: rawDate is Timestamp
          ? rawDate.toDate()
          : DateTime.parse(rawDate as String),
    );
  }
}
