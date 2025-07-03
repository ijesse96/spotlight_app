import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
        title: const Text("Transaction History"),
        backgroundColor: const Color(0xFFFFB74D),
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const Divider(height: 20),
        itemBuilder: (context, index) {
          final tx = transactions[index];
          final formattedDate = DateFormat("MMM d, yyyy • h:mm a").format(tx["timestamp"]);
          final isPositive = tx["amount"] >= 0;
          final amountDisplay = tx["type"] == "Deposit"
              ? "+${tx["amount"]} coins"
              : "\$${tx["amount"].abs().toStringAsFixed(2)}";

          return ListTile(
            leading: Icon(
              tx["type"] == "Gift"
                  ? Icons.card_giftcard
                  : tx["type"] == "Withdraw"
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
              color: tx["type"] == "Withdraw" ? Colors.red : Colors.green,
            ),
            title: Text(amountDisplay, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${tx["type"]} • $formattedDate"),
          );
        },
      ),
    );
  }
}
