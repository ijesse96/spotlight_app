import 'package:flutter/material.dart';
import './coin_option_tile.dart';

class DepositSheet extends StatelessWidget {
  final Function(int coins) onCoinPurchase;

  const DepositSheet({
    super.key,
    required this.onCoinPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Buy Coins",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          CoinOptionTile(
            coins: 70,
            price: 1.00,
            onTap: () {
              Navigator.pop(context);
              onCoinPurchase(70);
            },
          ),
          CoinOptionTile(
            coins: 350,
            price: 5.00,
            onTap: () {
              Navigator.pop(context);
              onCoinPurchase(350);
            },
          ),
          CoinOptionTile(
            coins: 700,
            price: 10.00,
            onTap: () {
              Navigator.pop(context);
              onCoinPurchase(700);
            },
          ),
          CoinOptionTile(
            coins: 1400,
            price: 20.00,
            onTap: () {
              Navigator.pop(context);
              onCoinPurchase(1400);
            },
          ),
          CoinOptionTile(
            coins: 3500,
            price: 50.00,
            onTap: () {
              Navigator.pop(context);
              onCoinPurchase(3500);
            },
          ),
          CoinOptionTile(
            coins: 7000,
            price: 100.00,
            onTap: () {
              Navigator.pop(context);
              onCoinPurchase(7000);
            },
          ),
        ],
      ),
    );
  }
} 