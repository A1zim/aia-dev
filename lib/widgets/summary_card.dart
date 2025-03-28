import 'package:flutter/material.dart';
import 'package:personal_finance/theme/styles.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final String currencySymbol;
  final Color color;
  final IconData icon;
  final Widget? trailing; // Add optional trailing widget

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.currencySymbol,
    required this.color,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded( // Use Expanded to push trailing to the right
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.subheading(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$amount $currencySymbol',
                    style: AppTextStyles.body(context).copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!, // Add trailing widget if provided
          ],
        ),
      ),
    );
  }
}