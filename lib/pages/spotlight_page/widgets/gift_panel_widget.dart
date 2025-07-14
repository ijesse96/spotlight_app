import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import './gift_card.dart';

class GiftPanelWidget extends StatelessWidget {
  final int userCoinBalance;
  final Function(String giftName, int coinAmount) onGiftSelected;

  const GiftPanelWidget({
    super.key,
    required this.userCoinBalance,
    required this.onGiftSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Stack(
            children: [
              const Center(
                child: Text('Send a Gift', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Positioned(
                right: 0,
                child: Row(
                  children: [
                    const Icon(FontAwesomeIcons.coins, size: 16, color: Color(0xFFFFB74D)),
                    const SizedBox(width: 4),
                    Text(
                      '$userCoinBalance',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.7,
              children: [
                GiftCard(
                  icon: Icons.local_florist,
                  label: 'Rose',
                  coinValue: 50,
                  onTap: () => onGiftSelected('🌹', 50),
                ),
                GiftCard(
                  icon: Icons.whatshot,
                  label: 'Fire',
                  coinValue: 100,
                  onTap: () => onGiftSelected('🔥', 100),
                ),
                GiftCard(
                  icon: Icons.star,
                  label: 'Star',
                  coinValue: 200,
                  onTap: () => onGiftSelected('⭐', 200),
                ),
                GiftCard(
                  icon: Icons.emoji_events,
                  label: 'Crown',
                  coinValue: 250,
                  onTap: () => onGiftSelected('👑', 250),
                ),
                GiftCard(
                  icon: Icons.flash_on,
                  label: 'Zap',
                  coinValue: 300,
                  onTap: () => onGiftSelected('⚡', 300),
                ),
                GiftCard(
                  icon: Icons.favorite,
                  label: 'Heart',
                  coinValue: 400,
                  onTap: () => onGiftSelected('❤️', 400),
                ),
                GiftCard(
                  icon: Icons.rocket,
                  label: 'Rocket',
                  coinValue: 500,
                  onTap: () => onGiftSelected('🚀', 500),
                ),
                GiftCard(
                  icon: Icons.ac_unit,
                  label: 'Ice',
                  coinValue: 600,
                  onTap: () => onGiftSelected('❄️', 600),
                ),
                GiftCard(
                  icon: Icons.diamond,
                  label: 'Diamond',
                  coinValue: 750,
                  onTap: () => onGiftSelected('💎', 750),
                ),
                GiftCard(
                  icon: Icons.fort,
                  label: 'Castle',
                  coinValue: 1000,
                  onTap: () => onGiftSelected('🏰', 1000),
                ),
                GiftCard(
                  icon: Icons.language,
                  label: 'Planet',
                  coinValue: 1250,
                  onTap: () => onGiftSelected('🪐', 1250),
                ),
                GiftCard(
                  icon: Icons.pets,
                  label: 'Dragon',
                  coinValue: 2000,
                  onTap: () => onGiftSelected('🐉', 2000),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 