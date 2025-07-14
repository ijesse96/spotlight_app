import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './widgets/transaction_tile.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> transactions = [
      {"type": "Gift", "amount": 5.00, "timestamp": DateTime.now().subtract(const Duration(minutes: 10))},
      {"type": "Withdraw", "amount": -2.00, "timestamp": DateTime.now().subtract(const Duration(hours: 1))},
      {"type": "Deposit", "amount": 500, "timestamp": DateTime.now().subtract(const Duration(days: 1))},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB74D),
        title: const Text(
          "Transaction History",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const Divider(height: 20),
        itemBuilder: (context, index) {
          final tx = transactions[index];
          return TransactionTile(transaction: tx);
        },
      ),
    );
  }
}
