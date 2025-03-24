// lib/screens/student/wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:navlog/models/transcation_wallet_model.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../providers/wallet_provider.dart';
import '../../../services/auth_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({Key? key}) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _remarkController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  final DateFormat _inputDateFormat = DateFormat('dd/MM/yyyy');

  String _studentId = '';

  bool showFilterMenu = false;

  @override
  void initState() {
    super.initState();

    // Set up scroll listener for infinite scrolling
    _scrollController.addListener(_scrollListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final walletProvider = Provider.of<WalletProvider>(
        context,
        listen: false,
      );

      if (authService.currentUser != null) {
        setState(() {
          _studentId = authService.currentUser!.id;
        });

        walletProvider.initialize(_studentId);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // We're approaching the end of the list, load more
      final walletProvider = Provider.of<WalletProvider>(
        context,
        listen: false,
      );
      if (!walletProvider.isLoadingMore && walletProvider.hasMore) {
        walletProvider.loadMoreTransactions(_studentId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);

    return Scaffold(
      // appBar: AppBar(title: const Text('Wallet')),
      body:
          walletProvider.isLoading && walletProvider.transactions.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () async {
                  await walletProvider.loadTransactions(
                    _studentId,
                    refresh: true,
                  );
                },
                child: Column(
                  children: [
                    _buildAccountHeader(walletProvider),
                    if (showFilterMenu) ...{
                      _buildFilterSection(walletProvider),
                    },
                    _buildTransactionsList(walletProvider),
                  ],
                ),
              ),
    );
  }

  Widget _buildAccountHeader(WalletProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ronit Tiwari(22121601) Account Detail',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              // IconButton(
              //   icon: const Icon(Icons.close, color: Colors.red),
              //   onPressed: () {
              //     Navigator.pop(context);
              //   },
              // ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Balance:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                '\$ ${provider.balance.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  showFilterMenu = !showFilterMenu;
                  setState(() {});
                },
                icon: const Icon(Icons.filter_alt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(WalletProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: const Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDateInput(
                  label: 'from',
                  value:
                      provider.fromDate != null
                          ? _inputDateFormat.format(provider.fromDate!)
                          : 'dd/mm/yyyy',
                  onTap: () => _selectDate(context, isStartDate: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateInput(
                  label: 'to',
                  value:
                      provider.toDate != null
                          ? _inputDateFormat.format(provider.toDate!)
                          : 'dd/mm/yyyy',
                  onTap: () => _selectDate(context, isStartDate: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTypeDropdown(provider)),
              const SizedBox(width: 16),
              Expanded(child: _buildRemarkInput(provider)),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (provider.fromDate != null ||
                  provider.toDate != null ||
                  provider.selectedType != null &&
                      provider.selectedType != 'All' ||
                  provider.remarkFilter != null &&
                      provider.remarkFilter!.isNotEmpty) {
                provider.applyFilters(_studentId);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(100, 36),
            ),
            child: const Text('Filter'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInput({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text(label, style: const TextStyle(color: Colors.grey)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(value, style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeDropdown(WalletProvider provider) {
    // Get unique transaction types
    List<String> types = provider.getTransactionTypes();

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text('type'),
          value: provider.selectedType,
          items:
              types.map((type) {
                return DropdownMenuItem<String>(
                  value: type == 'All' ? null : type,
                  child: Text(type),
                );
              }).toList(),
          onChanged: (value) {
            provider.setTypeFilter(value);
          },
        ),
      ),
    );
  }

  Widget _buildRemarkInput(WalletProvider provider) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: _remarkController,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'remark',
        ),
        onChanged: (value) {
          provider.setRemarkFilter(value.isNotEmpty ? value : null);
        },
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context, {
    required bool isStartDate,
  }) async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      if (isStartDate) {
        walletProvider.setDateRange(picked, walletProvider.toDate);
      } else {
        walletProvider.setDateRange(walletProvider.fromDate, picked);
      }
    }
  }

  Widget _buildTransactionsList(WalletProvider provider) {
    final transactions = provider.transactions;

    if (transactions.isEmpty) {
      return Expanded(
        child: Center(
          child:
              provider.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('No transactions found'),
        ),
      );
    }

    return Expanded(
      child: Column(
        children: [
          // Table header
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                _buildTableHeaderCell('Date', flex: 3),
                _buildTableHeaderCell('Type', flex: 2),
                _buildTableHeaderCell(
                  'Amount',
                  flex: 2,
                  alignment: Alignment.centerRight,
                ),
                _buildTableHeaderCell(
                  'GST',
                  flex: 1,
                  alignment: Alignment.centerRight,
                ),
                _buildTableHeaderCell(
                  'PST',
                  flex: 1,
                  alignment: Alignment.centerRight,
                ),
                _buildTableHeaderCell(
                  'Total',
                  flex: 2,
                  alignment: Alignment.centerRight,
                ),
                _buildTableHeaderCell(
                  'Balance',
                  flex: 2,
                  alignment: Alignment.centerRight,
                ),
                _buildTableHeaderCell('Remark', flex: 3),
              ],
            ),
          ),

          // Transactions list
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  itemCount:
                      transactions.length + 1, // +1 for loading indicator
                  itemBuilder: (context, index) {
                    if (index == transactions.length) {
                      // This is the last item, show loading indicator if needed
                      return provider.isLoadingMore
                          ? Container(
                            padding: const EdgeInsets.all(16),
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator(),
                          )
                          : provider.hasMore
                          ? Container(
                            padding: const EdgeInsets.all(16),
                            alignment: Alignment.center,
                            child: const Text('Scroll to load more'),
                          )
                          : Container(
                            padding: const EdgeInsets.all(16),
                            alignment: Alignment.center,
                            child:
                                provider.isFiltering
                                    ? ElevatedButton(
                                      onPressed: () {
                                        provider.clearFilters(_studentId);
                                        _remarkController.clear();
                                      },
                                      child: const Text('Clear Filters'),
                                    )
                                    : const Text('End of transactions'),
                          );
                    }

                    // Regular transaction item
                    return _buildTransactionItem(transactions[index], index);
                  },
                ),

                // Show loading overlay when filtering
                if (provider.isLoading && provider.transactions.isNotEmpty)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(
    String text, {
    int flex = 1,
    Alignment alignment = Alignment.centerLeft,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction, int index) {
    // Format date
    final formattedDate = _dateFormat.format(transaction.date);

    // Format amount with colors
    final isNegative = transaction.amount < 0;
    final amountColor = isNegative ? Colors.red : Colors.black;
    final amountText =
        '${isNegative ? '' : ''}${transaction.amount.toStringAsFixed(2)}';
    final totalText =
        '${isNegative ? '' : ''}${transaction.total.toStringAsFixed(2)}';

    // Format balance with colors
    final isNegativeBalance = transaction.balance < 0;
    final balanceColor = isNegativeBalance ? Colors.red : Colors.black;
    final balanceText = '${transaction.balance.toStringAsFixed(2)}';

    return Container(
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey[50],
        border: const Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Date
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(formattedDate),
            ),
          ),

          // Type
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(transaction.type),
            ),
          ),

          // Amount
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                amountText,
                style: TextStyle(color: amountColor),
                textAlign: TextAlign.right,
              ),
            ),
          ),

          // GST
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                transaction.gst.toStringAsFixed(2),
                textAlign: TextAlign.right,
              ),
            ),
          ),

          // PST
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                transaction.pst.toStringAsFixed(2),
                textAlign: TextAlign.right,
              ),
            ),
          ),

          // Total
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                totalText,
                style: TextStyle(color: amountColor),
                textAlign: TextAlign.right,
              ),
            ),
          ),

          // Balance
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                balanceText,
                style: TextStyle(color: balanceColor),
                textAlign: TextAlign.right,
              ),
            ),
          ),

          // Remark
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(transaction.remark),
            ),
          ),
        ],
      ),
    );
  }
}
