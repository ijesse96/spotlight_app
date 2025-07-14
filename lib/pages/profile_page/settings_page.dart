import 'package:flutter/material.dart';
import '../wallet_page/transactions_page.dart'; // Added import
import './widgets/settings_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFB74D),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        children: [
          const Text("Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SettingsTile(icon: Icons.person, title: "Edit Profile", onTap: () {}),
          SettingsTile(icon: Icons.email, title: "Change Email", onTap: () {}),
          SettingsTile(icon: Icons.lock, title: "Change Password", onTap: () {}),

          const SizedBox(height: 24),
          const Text("Wallet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SettingsTile(
            icon: Icons.receipt_long,
            title: "Transaction History",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransactionsPage()),
              );
            },
          ),
          SettingsTile(icon: Icons.credit_card, title: "Linked Payment Methods", onTap: () {}),

          const SizedBox(height: 24),
          const Text("App Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SettingsTile(icon: Icons.notifications, title: "Push Notifications", onTap: () {}),
          SettingsTile(icon: Icons.language, title: "Language", onTap: () {}),
          SettingsTile(icon: Icons.info_outline, title: "App Version: 1.0.0", onTap: () {}),

          const SizedBox(height: 24),
          SettingsTile(
            icon: Icons.logout,
            title: "Log Out",
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirm Logout"),
                  content: const Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Logged out")),
                        );
                      },
                      child: const Text("Log Out"),
                    ),
                  ],
                ),
              );
            },
            iconColor: Colors.red,
            textColor: Colors.red,
          ),
        ],
      ),
    );
  }
}
