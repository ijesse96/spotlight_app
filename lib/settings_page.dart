import 'package:flutter/material.dart';
import 'transactions_page.dart'; // Added import

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFFFFB74D),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        children: [
          const Text("Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _settingsTile(icon: Icons.person, title: "Edit Profile", onTap: () {}),
          _settingsTile(icon: Icons.email, title: "Change Email", onTap: () {}),
          _settingsTile(icon: Icons.lock, title: "Change Password", onTap: () {}),

          const SizedBox(height: 24),
          const Text("Wallet", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _settingsTile(
            icon: Icons.receipt_long,
            title: "Transaction History",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TransactionsPage()),
              );
            },
          ),
          _settingsTile(icon: Icons.credit_card, title: "Linked Payment Methods", onTap: () {}),

          const SizedBox(height: 24),
          const Text("App Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _settingsTile(icon: Icons.notifications, title: "Push Notifications", onTap: () {}),
          _settingsTile(icon: Icons.language, title: "Language", onTap: () {}),
          _settingsTile(icon: Icons.info_outline, title: "App Version: 1.0.0", onTap: () {}),

          const SizedBox(height: 24),
          _settingsTile(
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

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.black,
    Color textColor = Colors.black,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
