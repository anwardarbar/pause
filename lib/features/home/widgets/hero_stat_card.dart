import 'dart:ui';
import 'package:flutter/cupertino.dart';
import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';

class HeroStatCard extends StatelessWidget {
  const HeroStatCard({
    super.key,
    required this.label,
    required this.amount,
    required this.type,
    required this.onTap,
  });

  final String label;
  final String amount;
  final EventType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final amountColor = type == EventType.saved
        ? AppColors.semanticSaved
        : AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.glassBorder, width: 1),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.card,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sp5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: AppTypography.label,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    amount,
                    style: AppTypography.display.copyWith(color: amountColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
