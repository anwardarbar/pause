import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/financial_event.dart';
import '../../../core/theme/app_theme.dart';

class RecentTransactionRow extends StatelessWidget {
  const RecentTransactionRow({super.key, required this.event});

  final FinancialEvent event;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final isExpense = event.type == EventType.expense;
    final dotColor =
        isExpense ? AppColors.semanticExpense : AppColors.semanticSaved;
    final amountColor =
        isExpense ? AppColors.semanticExpense : AppColors.semanticSaved;
    final sign = isExpense ? '−' : '+';
    final formattedAmount = _currencyFormat.format(event.amount);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp2),
      child: Row(
        children: [
          // Type dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sp3),
          // Note + category
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.note ?? event.category.displayName,
                  style: AppTypography.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  event.category.displayName,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sp3),
          // Amount
          Text(
            '$sign$formattedAmount',
            style: AppTypography.body.copyWith(color: amountColor),
          ),
        ],
      ),
    );
  }
}
