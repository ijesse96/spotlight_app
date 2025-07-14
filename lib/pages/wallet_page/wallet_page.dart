import 'package:flutter/material.dart';
import './transactions_page.dart'; // Make sure the path matches your file structure
import './widgets/deposit_sheet.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  int coinBalance = 1000;
  double earnings = 12.50;

  void _showDepositMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DepositSheet(
        onCoinPurchase: (coins) {
          setState(() {
            coinBalance += coins;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("You bought $coins coins")),
          );
        },
      ),
    );
  }

  void _handleWithdraw() {
    TextEditingController controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              children: [
                const Text(
                  "Withdraw Funds",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Earnings: \$${earnings.toStringAsFixed(2)}",
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Amount in \$"),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel")),
                    ElevatedButton(
                      onPressed: () {
                        double amount = double.tryParse(controller.text) ?? 0;
                        if (amount <= earnings) {
                          setState(() {
                            earnings -= amount;
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Withdrew \$${amount.toStringAsFixed(2)}")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Not enough earnings")),
                          );
                        }
                      },
                      child: const Text("Withdraw"),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _walletButton(String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFFFFB74D),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Widget _metricCard(String value, String label) {
    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          width: 200,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewAllButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TransactionsPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFB74D),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          "View All Transactions",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB74D),
        title: const Text(
          "Wallet",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          _metricCard("\$${earnings.toStringAsFixed(2)}", "Earnings"),
          _walletButton("Withdraw", Icons.remove_circle, _handleWithdraw),
          const SizedBox(height: 20),
          _metricCard("$coinBalance", "Coin Balance"),
          _walletButton("Deposit", Icons.add_circle, _showDepositMenu),
          const SizedBox(height: 48),
          _viewAllButton(), // 🟧 View All Transactions Button
        ],
      ),
    );
  }
}
