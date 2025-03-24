// lib/models/transaction_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final DateTime date;
  final String type;
  final double amount;
  final double gst;
  final double pst;
  final double total;
  final double balance;
  final String remark;

  TransactionModel({
    required this.id,
    required this.date,
    required this.type,
    required this.amount,
    required this.gst,
    required this.pst,
    required this.total,
    required this.balance,
    required this.remark,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return TransactionModel(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      type: data['type'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      gst: (data['gst'] ?? 0).toDouble(),
      pst: (data['pst'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      balance: (data['balance'] ?? 0).toDouble(),
      remark: data['remark'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'type': type,
      'amount': amount,
      'gst': gst,
      'pst': pst,
      'total': total,
      'balance': balance,
      'remark': remark,
    };
  }

  // Sample transactions for demonstration
  static List<TransactionModel> getSampleTransactions() {
    return [
      TransactionModel(
        id: '1',
        date: DateTime(2025, 3, 10, 14, 7, 44),
        type: 'Transfer In',
        amount: 1500.00,
        gst: 0.00,
        pst: 0.00,
        total: 1500.00,
        balance: 8641.10,
        remark: 'E-transfer',
      ),
      TransactionModel(
        id: '2',
        date: DateTime(2025, 2, 27, 14, 14, 30),
        type: 'Ground School',
        amount: -1200.00,
        gst: 0.00,
        pst: 0.00,
        total: -1200.00,
        balance: 7141.10,
        remark: 'CPL & Multi ground school balance',
      ),
      TransactionModel(
        id: '3',
        date: DateTime(2025, 2, 27, 14, 9, 59),
        type: 'Refund to Account',
        amount: 6775.00,
        gst: 0.00,
        pst: 0.00,
        total: 6775.00,
        balance: 8341.10,
        remark: 'change contract, refund to account',
      ),
      TransactionModel(
        id: '4',
        date: DateTime(2025, 2, 20, 17, 5, 43),
        type: 'Transfer In',
        amount: 2000.00,
        gst: 0.00,
        pst: 0.00,
        total: 2000.00,
        balance: 1566.10,
        remark: 'E-transfer',
      ),
      TransactionModel(
        id: '5',
        date: DateTime(2025, 2, 20, 11, 9, 5),
        type: 'Transfer In',
        amount: 3000.00,
        gst: 0.00,
        pst: 0.00,
        total: 3000.00,
        balance: -433.90,
        remark: 'E-transfer',
      ),
      TransactionModel(
        id: '6',
        date: DateTime(2025, 2, 14, 17, 47, 10),
        type: 'Ground School',
        amount: -6775.00,
        gst: 0.00,
        pst: 0.00,
        total: -6775.00,
        balance: -3433.90,
        remark: 'program changed, CPP ground school difference',
      ),
    ];
  }

  // Generate more sample transactions for infinite scrolling demo
  static List<TransactionModel> generateMoreTransactions(
    int startIndex,
    int count,
  ) {
    List<TransactionModel> transactions = [];

    for (int i = 0; i < count; i++) {
      final index = startIndex + i;
      final isDebit = index % 3 == 0;
      final amount =
          isDebit ? -(1000.0 + (index * 100)) : (1000.0 + (index * 50));
      final date = DateTime.now().subtract(Duration(days: index * 3 + 20));

      transactions.add(
        TransactionModel(
          id: 'gen-$index',
          date: date,
          type: isDebit ? 'Flight Lesson' : 'Transfer In',
          amount: amount,
          gst: 0.00,
          pst: 0.00,
          total: amount,
          balance: 8641.10 - (index * 200),
          remark: isDebit ? 'Flight training session' : 'E-transfer',
        ),
      );
    }

    return transactions;
  }
}
