import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionTile({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat("MMM d, yyyy • h:mm a").format(transaction["timestamp"]);
    final isPositive = transaction["amount"] >= 0;
    final amountDisplay = transaction["type"] == "Deposit"
        ? "+${transaction["amount"]} coins"
        : "\$${transaction["amount"].abs().toStringAsFixed(2)}";

    return ListTile(
      leading: Icon(
        transaction["type"] == "Gift"
            ? Icons.card_giftcard
            : transaction["type"] == "Withdraw"
                ? Icons.arrow_upward
                : Icons.arrow_downward,
        color: transaction["type"] == "Withdraw" ? Colors.red : Colors.green,
      ),
      title: Text(amountDisplay, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("${transaction["type"]} • $formattedDate"),
    );
  }
} 