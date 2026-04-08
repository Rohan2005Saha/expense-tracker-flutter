import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/expense_model.dart';

class ExportService {
  Future<pw.Font> _loadPdfFont() async {
    try {
      final ByteData notoSansFontData = await rootBundle.load(
        'assets/fonts/NotoSans-Regular.ttf',
      );
      return pw.Font.ttf(notoSansFontData);
    } catch (_) {
      final ByteData fallbackFontData = await rootBundle.load(
        'assets/fonts/ArialUnicode.ttf',
      );
      return pw.Font.ttf(fallbackFontData);
    }
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatCurrency(double amount) {
    return '₹ ${amount.toStringAsFixed(2)}';
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

  Future<String> exportExpensesToCsv(List<ExpenseModel> expenses) async {
    final List<List<dynamic>> rows = <List<dynamic>>[
      <String>['Id', 'Title', 'Amount', 'Category', 'Date'],
      ...expenses.map((ExpenseModel expense) {
        return <dynamic>[
          expense.id,
          expense.title,
          expense.amount.toStringAsFixed(2),
          expense.category,
          expense.date.toIso8601String(),
        ];
      }),
    ];

    final String csvData = const ListToCsvConverter().convert(rows);
    final Directory directory = await getApplicationDocumentsDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final File file = File('${directory.path}/expenses_$timestamp.csv');

    await file.writeAsString(csvData);

    return file.path;
  }

  Future<String> exportExpensesToPdf(List<ExpenseModel> expenses) async {
    final pw.Document document = pw.Document();
    final pw.Font font = await _loadPdfFont();
    final DateTime reportMonth = expenses.isNotEmpty
        ? expenses.first.date
        : DateTime.now();
    final double totalSpending = expenses.fold(
      0,
      (double sum, ExpenseModel expense) => sum + expense.amount,
    );

    document.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: font,
          bold: font,
          italic: font,
          boldItalic: font,
        ),
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Center(
              child: pw.Text(
                'Monthly Expense Report (${_formatMonthYear(reportMonth)})',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              'Total Spending: ${_formatCurrency(totalSpending)}',
              style: pw.TextStyle(
                font: font,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.TableHelper.fromTextArray(
                headers: const <String>[
                  'Date',
                  'Title',
                  'Category',
                  'Amount',
                ],
                headerStyle: pw.TextStyle(
                  font: font,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
                cellStyle: pw.TextStyle(
                  font: font,
                  fontSize: 11,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellAlignments: <int, pw.Alignment>{
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                },
                headerAlignments: <int, pw.Alignment>{
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                },
                data: expenses.map((ExpenseModel expense) {
                  return <String>[
                    _formatDate(expense.date),
                    expense.title,
                    expense.category,
                    _formatCurrency(expense.amount),
                  ];
                }).toList(),
              ),
            ),
          ];
        },
      ),
    );

    final Directory directory = await getApplicationDocumentsDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final File file = File('${directory.path}/expenses_$timestamp.pdf');

    await file.writeAsBytes(await document.save());

    return file.path;
  }

  Future<void> shareExportedFile(String filePath) async {
    await Share.shareXFiles(<XFile>[XFile(filePath)]);
  }
}
