import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  Budget({
    required this.id,
    required this.category,
    required this.limit,
    required this.month,
  });

  final String id;
  final String category;
  final double limit;
  final DateTime month;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'category': category,
      'limit': limit,
      'month': Timestamp.fromDate(month),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    final dynamic rawMonth = map['month'];

    return Budget(
      id: map['id'] as String,
      category: map['category'] as String,
      limit: (map['limit'] as num).toDouble(),
      month: rawMonth is Timestamp
          ? rawMonth.toDate()
          : DateTime.parse(rawMonth as String),
    );
  }
}
