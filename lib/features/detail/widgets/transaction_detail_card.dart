import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/financial_event.dart';
import '../../../core/theme/app_theme.dart';
import 'reflection_picker.dart';

class TransactionDetailCard extends StatelessWidget {
  const TransactionDetailCard({super.key, required this.event});

  final FinancialEvent event;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  static final _dateFormat = DateFormat('d MMM yyyy, h:mm a');

  @override
  Widget build(BuildContext context) {
    final isExpense = event.type == EventType.expense;
    final amountColor =
        isExpense ? AppColors.semanticExpense : AppColors.semanticSaved;

    return Container(
      margin: const EdgeInsets.only(
          left: AppSpacing.sp4,
          right: AppSpacing.sp4,
          bottom: AppSpacing.sp3),
      padding: const EdgeInsets.all(AppSpacing.sp4),
      decoration: BoxDecoration(
        color: AppColors.surfaceL2,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Amount + type ────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currencyFormat.format(event.amount),
                      style: AppTypography.title.copyWith(color: amountColor),
                    ),
                    Text(
                      event.type.displayName,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              _SourceBadge(source: event.source),
            ],
          ),

          const SizedBox(height: AppSpacing.sp4),

          // ── Fields grid ──────────────────────────────────────────────────
          _FieldRow(label: 'Category', value: event.category.displayName),
          if (event.paymentMethod != null)
            _FieldRow(
                label: 'Payment',
                value: event.paymentMethod!.displayName),
          if (event.note != null && event.note!.isNotEmpty)
            _FieldRow(label: 'Note', value: event.note!),
          _FieldRow(
              label: 'Date',
              value: _dateFormat.format(event.createdAt.toLocal())),
          if (event.editedAt != null)
            _FieldRow(
                label: 'Edited',
                value: _dateFormat.format(event.editedAt!.toLocal())),

          // ── Low confidence warning ───────────────────────────────────────
          if (event.rawInput != null) ...[
            const SizedBox(height: AppSpacing.sp3),
            _RawInputBadge(rawInput: event.rawInput!),
          ],

          // ── Reflection (expense only) ─────────────────────────────────
          if (isExpense) ...[
            const SizedBox(height: AppSpacing.sp4),
            Text(
              'How do you feel about this?',
              style:
                  AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sp2),
            ReflectionPicker(event: event),
          ],
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: AppTypography.caption),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.caption
                  .copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.source});
  final InputSource source;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp2, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceL3,
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            source == InputSource.voice
                ? CupertinoIcons.mic_fill
                : CupertinoIcons.pencil,
            size: 10,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 3),
          Text(source.displayName, style: AppTypography.label),
        ],
      ),
    );
  }
}

class _RawInputBadge extends StatelessWidget {
  const _RawInputBadge({required this.rawInput});
  final String rawInput;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp2),
      decoration: BoxDecoration(
        color: AppColors.goldPrimary.withValues(alpha: 0.06),
        borderRadius: AppRadius.chip,
        border:
            Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.exclamationmark_triangle,
              size: 12, color: AppColors.goldPrimary),
          const SizedBox(width: AppSpacing.sp2),
          Expanded(
            child: Text(
              'Low confidence · "$rawInput"',
              style: AppTypography.label
                  .copyWith(color: AppColors.goldHighlight),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
