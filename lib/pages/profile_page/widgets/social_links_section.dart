import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialLinksSection extends StatelessWidget {
  const SocialLinksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _socialButton(
          icon: FontAwesomeIcons.instagram,
          label: 'Instagram',
          onTap: () {},
        ),
        const SizedBox(height: 16),
        _socialButton(
          icon: FontAwesomeIcons.twitch,
          label: 'Twitch',
          onTap: () {},
        ),
        const SizedBox(height: 16),
        _socialButton(
          icon: FontAwesomeIcons.globe,
          label: 'Website',
          onTap: () {},
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _socialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            FaIcon(icon, size: 22),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
} 