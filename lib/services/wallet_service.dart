// lib/services/wallet_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:navlog/models/transcation_wallet_model.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'transactions';

  // Fetch user's current balance
  Future<double> getUserBalance(String userId) async {
    try {
      // Get the user document from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists && userDoc.data()!.containsKey('balance')) {
        return (userDoc.data()!['balance'] as num).toDouble();
      }

      // Return default balance if not found
      return 0.0;
    } catch (e) {
      print('Error fetching user balance: $e');
      throw e;
    }
  }

  // Fetch a paginated list of transactions for a user
  Future<List<TransactionModel>> getUserTransactions({
    required String userId,
    DateTime? startAfter,
    int limit = 10,
  }) async {
    try {
      // Start with a query for the user's transactions
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit);

      // Add pagination if startAfter is provided
      if (startAfter != null) {
        query = query.startAfter([Timestamp.fromDate(startAfter)]);
      }

      // Execute query
      final snapshot = await query.get();

      // Convert to models
      return snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching user transactions: $e');
      throw e;
    }
  }

  // For demo purposes: get transactions from sample data
  Future<List<TransactionModel>> getSampleTransactions({
    int page = 1,
    int perPage = 10,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (page == 1) {
      // Return the actual sample data for the first page
      return TransactionModel.getSampleTransactions();
    } else {
      // Generate additional mock data for subsequent pages
      int startIndex =
          (page - 2) * perPage +
          TransactionModel.getSampleTransactions().length;
      return TransactionModel.generateMoreTransactions(startIndex, perPage);
    }
  }

  // Add a new transaction
  Future<String> addTransaction(
    TransactionModel transaction,
    String userId,
  ) async {
    try {
      // Add userId to transaction data
      Map<String, dynamic> data = transaction.toFirestore();
      data['userId'] = userId;

      // Add to Firestore
      DocumentReference docRef = await _firestore
          .collection(_collection)
          .add(data);

      // Update user balance
      await _updateUserBalance(userId, transaction.total);

      return docRef.id;
    } catch (e) {
      print('Error adding transaction: $e');
      throw e;
    }
  }

  // Update user balance
  Future<void> _updateUserBalance(String userId, double amount) async {
    try {
      // Use a transaction to safely update balance
      await _firestore.runTransaction((transaction) async {
        // Get current user document
        DocumentSnapshot userDoc = await transaction.get(
          _firestore.collection('users').doc(userId),
        );

        if (userDoc.exists) {
          // Get current balance or default to 0
          double currentBalance = 0.0;
          if (userDoc.data() != null) {
            final userData = userDoc.data() as Map<String, dynamic>;
            if (userData.containsKey('balance')) {
              currentBalance = (userData['balance'] as num).toDouble();
            }
          }

          // Calculate new balance
          double newBalance = currentBalance + amount;

          // Update the balance
          transaction.update(_firestore.collection('users').doc(userId), {
            'balance': newBalance,
          });
        } else {
          // Create user document if it doesn't exist
          transaction.set(_firestore.collection('users').doc(userId), {
            'balance': amount,
          });
        }
      });
    } catch (e) {
      print('Error updating balance: $e');
      throw e;
    }
  }

  // Filter transactions by date range and type
  Future<List<TransactionModel>> filterTransactions({
    required String userId,
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? remark,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true);

      // Add date filters if provided
      if (fromDate != null) {
        query = query.where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate),
        );
      }

      if (toDate != null) {
        // Add 1 day to include the end date fully
        DateTime endDate = toDate.add(const Duration(days: 1));
        query = query.where('date', isLessThan: Timestamp.fromDate(endDate));
      }

      // Execute query
      final snapshot = await query.get();

      // Convert to models
      List<TransactionModel> transactions =
          snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .toList();

      // Filter by type and remark if provided
      // (These are client-side filters since Firestore can't do multiple field filters)
      if (type != null && type.isNotEmpty) {
        transactions = transactions.where((t) => t.type == type).toList();
      }

      if (remark != null && remark.isNotEmpty) {
        transactions =
            transactions
                .where(
                  (t) => t.remark.toLowerCase().contains(remark.toLowerCase()),
                )
                .toList();
      }

      return transactions;
    } catch (e) {
      print('Error filtering transactions: $e');
      throw e;
    }
  }

  // Demo version of filter for sample data
  Future<List<TransactionModel>> filterSampleTransactions({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? remark,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Get all sample transactions
    List<TransactionModel> transactions = [
      ...TransactionModel.getSampleTransactions(),
      ...TransactionModel.generateMoreTransactions(
        TransactionModel.getSampleTransactions().length,
        20,
      ),
    ];

    // Apply filters
    if (fromDate != null) {
      transactions =
          transactions
              .where(
                (t) =>
                    t.date.isAfter(fromDate) ||
                    t.date.isAtSameMomentAs(fromDate),
              )
              .toList();
    }

    if (toDate != null) {
      // Add 1 day to include the end date fully
      DateTime endDate = toDate.add(const Duration(days: 1));
      transactions =
          transactions.where((t) => t.date.isBefore(endDate)).toList();
    }

    if (type != null && type.isNotEmpty) {
      transactions = transactions.where((t) => t.type == type).toList();
    }

    if (remark != null && remark.isNotEmpty) {
      transactions =
          transactions
              .where(
                (t) => t.remark.toLowerCase().contains(remark.toLowerCase()),
              )
              .toList();
    }

    return transactions;
  }
}
