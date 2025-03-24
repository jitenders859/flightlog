// lib/providers/wallet_provider.dart

import 'package:flutter/material.dart';
import 'package:navlog/models/transcation_wallet_model.dart';

import '../services/wallet_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletService _walletService = WalletService();

  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => _transactions;

  double _balance = 0.0;
  double get balance => _balance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  int _currentPage = 0;
  int get currentPage => _currentPage;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Filters
  DateTime? _fromDate;
  DateTime? get fromDate => _fromDate;

  DateTime? _toDate;
  DateTime? get toDate => _toDate;

  String? _selectedType;
  String? get selectedType => _selectedType;

  String? _remarkFilter;
  String? get remarkFilter => _remarkFilter;

  bool _isFiltering = false;
  bool get isFiltering => _isFiltering;

  // Initialize with student ID
  Future<void> initialize(String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Set the current balance
      await _loadUserBalance(studentId);

      // Load initial transactions
      await loadTransactions(studentId);
    } catch (e) {
      _errorMessage = 'Failed to load wallet data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user balance
  Future<void> _loadUserBalance(String userId) async {
    try {
      // For demo, use a fixed balance matching the screenshot
      _balance = 8641.10;

      // In production, uncomment this line:
      // _balance = await _walletService.getUserBalance(userId);
    } catch (e) {
      print('Error loading balance: $e');
      throw e;
    }
  }

  // Load transactions (initial or refresh)
  Future<void> loadTransactions(String userId, {bool refresh = false}) async {
    if (refresh) {
      _transactions = [];
      _currentPage = 0;
      _hasMore = true;
    }

    if (_isFiltering) {
      return await applyFilters(userId);
    }

    _isLoading = true;
    _errorMessage = null;

    if (!refresh) notifyListeners();

    try {
      _currentPage++;

      // Get transactions using the service
      List<TransactionModel> newTransactions = await _walletService
          .getSampleTransactions(page: _currentPage);

      if (newTransactions.isEmpty) {
        _hasMore = false;
      } else {
        _transactions.addAll(newTransactions);
      }
    } catch (e) {
      _errorMessage = 'Failed to load transactions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more transactions (pagination)
  Future<void> loadMoreTransactions(String userId) async {
    if (!_hasMore || _isLoadingMore || _isFiltering) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;

      // Get more transactions using the service
      List<TransactionModel> newTransactions = await _walletService
          .getSampleTransactions(page: _currentPage);

      if (newTransactions.isEmpty) {
        _hasMore = false;
      } else {
        _transactions.addAll(newTransactions);
      }
    } catch (e) {
      _errorMessage = 'Failed to load more transactions: $e';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Set date range filter
  void setDateRange(DateTime? from, DateTime? to) {
    _fromDate = from;
    _toDate = to;
    notifyListeners();
  }

  // Set type filter
  void setTypeFilter(String? type) {
    _selectedType = type;
    notifyListeners();
  }

  // Set remark filter
  void setRemarkFilter(String? remark) {
    _remarkFilter = remark;
    notifyListeners();
  }

  // Apply all filters
  Future<void> applyFilters(String userId) async {
    _isFiltering = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use the filter method from the service
      _transactions = await _walletService.filterSampleTransactions(
        fromDate: _fromDate,
        toDate: _toDate,
        type: _selectedType,
        remark: _remarkFilter,
      );

      // Since filtering returns all results, disable pagination
      _hasMore = false;
    } catch (e) {
      _errorMessage = 'Failed to filter transactions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear all filters
  Future<void> clearFilters(String userId) async {
    _fromDate = null;
    _toDate = null;
    _selectedType = null;
    _remarkFilter = null;
    _isFiltering = false;
    _hasMore = true;
    _transactions = [];
    _currentPage = 0;

    notifyListeners();

    // Reload transactions
    await loadTransactions(userId, refresh: true);
  }

  // Get available transaction types for filter dropdown
  List<String> getTransactionTypes() {
    // Extract unique types from transactions
    Set<String> types = _transactions.map((t) => t.type).toSet();
    return ['All', ...types];
  }
}
