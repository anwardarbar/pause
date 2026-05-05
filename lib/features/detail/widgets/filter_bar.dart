import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/enums.dart';
import '../../../core/providers/filter_provider.dart';
import '../../../core/theme/app_theme.dart';

class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  static final _monthFormat = DateFormat('MMM yyyy');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);
    final notifier = ref.read(filterProvider.notifier);

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.sp4),
        children: [
          // ── Date / Month chip ────────────────────────────────────────────
          _FilterChip(
            label: _monthFormat.format(filter.dateRange.from),
            isActive: true, // always shown, not clearable via chip
            onTap: () => _showMonthPicker(context, ref, filter),
          ),
          const SizedBox(width: AppSpacing.sp2),

          // ── Category chip ────────────────────────────────────────────────
          _FilterChip(
            label: filter.category?.displayName ?? 'Category',
            isActive: filter.category != null,
            onTap: filter.category != null
                ? notifier.clearCategory
                : () => _showCategoryPicker(context, ref),
          ),
          const SizedBox(width: AppSpacing.sp2),

          // ── Payment chip ─────────────────────────────────────────────────
          _FilterChip(
            label: filter.paymentMethod?.displayName ?? 'Payment',
            isActive: filter.paymentMethod != null,
            onTap: filter.paymentMethod != null
                ? notifier.clearPaymentMethod
                : () => _showPaymentPicker(context, ref),
          ),
          const SizedBox(width: AppSpacing.sp2),

          // ── Type chip ────────────────────────────────────────────────────
          _FilterChip(
            label: filter.type?.displayName ?? 'All types',
            isActive: filter.type != null,
            onTap: filter.type != null
                ? notifier.clearType
                : () => _showTypePicker(context, ref),
          ),
        ],
      ),
    );
  }

  void _showMonthPicker(
      BuildContext context, WidgetRef ref, FilterState filter) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Select month'),
        actions: List.generate(12, (i) {
          final now = DateTime.now();
          final month = DateTime(now.year, now.month - i);
          return CupertinoActionSheetAction(
            onPressed: () {
              final from = DateTime(month.year, month.month, 1);
              final to = DateTime(month.year, month.month + 1, 1)
                  .subtract(const Duration(milliseconds: 1));
              ref
                  .read(filterProvider.notifier)
                  .setDateRange(DateRange(from: from, to: to));
              Navigator.pop(context);
            },
            isDefaultAction: month.year == filter.dateRange.from.year &&
                month.month == filter.dateRange.from.month,
            child: Text(DateFormat('MMMM yyyy').format(month)),
          );
        }),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Filter by category'),
        actions: Category.values
            .map((c) => CupertinoActionSheetAction(
                  onPressed: () {
                    ref.read(filterProvider.notifier).setCategory(c);
                    Navigator.pop(context);
                  },
                  child: Text(c.displayName),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showPaymentPicker(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Filter by payment'),
        actions: PaymentMethod.values
            .map((p) => CupertinoActionSheetAction(
                  onPressed: () {
                    ref.read(filterProvider.notifier).setPaymentMethod(p);
                    Navigator.pop(context);
                  },
                  child: Text(p.displayName),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showTypePicker(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Filter by type'),
        actions: EventType.values
            .map((t) => CupertinoActionSheetAction(
                  onPressed: () {
                    ref.read(filterProvider.notifier).setType(t);
                    Navigator.pop(context);
                  },
                  child: Text(t.displayName),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

// ─── Chip widget ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.cardFloat,
        curve: AppMotion.cardFloatCurve,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp3, vertical: AppSpacing.sp1),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.goldPrimary.withValues(alpha: 0.12)
              : AppColors.surfaceL2,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: isActive ? AppColors.goldPrimary : AppColors.surfaceBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color:
                    isActive ? AppColors.goldPrimary : AppColors.textSecondary,
              ),
            ),
            if (isActive && label != DateFormat('MMM yyyy').format(DateTime.now())) ...[
              const SizedBox(width: AppSpacing.sp1),
              Icon(
                CupertinoIcons.xmark,
                size: 10,
                color: AppColors.goldPrimary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
