import 'package:flutter/material.dart';

class CoinOptionTile extends StatelessWidget {
  final int coins;
  final double price;
  final VoidCallback onTap;

  const CoinOptionTile({
    super.key,
    required this.coins,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.asset('assets/icons/spotlight_coin.png', width: 28),
      title: Text("$coins coins"),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          "\$${price.toStringAsFixed(2)}",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      onTap: onTap,
    );
  }
} 