import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/enums.dart';
import '../../core/models/parse_result.dart';
import '../../core/providers/input_overlay_provider.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/editable_field_row.dart';
import 'widgets/swipe_card.dart';

class ConfirmationCard extends ConsumerStatefulWidget {
  const ConfirmationCard({super.key, required this.result});

  final ParseResult result;

  @override
  ConsumerState<ConfirmationCard> createState() => _ConfirmationCardState();
}

class _ConfirmationCardState extends ConsumerState<ConfirmationCard> {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  bool _anyFieldEditing = false;

  ParseResult get _edited =>
      ref.read(inputOverlayProvider).editedResult ?? widget.result;

  void _applyEdit(ParseResult updated) =>
      ref.read(inputOverlayProvider.notifier).applyEdit(updated);

  // ─── Confirm / Discard ────────────────────────────────────────────────────

  Future<void> _confirm() async {
    await ref.read(inputOverlayProvider.notifier).confirmAndSave(
          const Uuid().v4(),
          DateTime.now().toUtc(),
        );
  }

  void _discard() => ref.read(inputOverlayProvider.notifier).discard();

  // ─── Pickers ──────────────────────────────────────────────────────────────

  void _showCategoryPicker(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Category'),
        actions: Category.values
            .map((c) => CupertinoActionSheetAction(
                  onPressed: () {
                    _applyEdit(_edited.copyWith(category: c));
                    Navigator.pop(context);
                  },
                  isDefaultAction: c == _edited.category,
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

  void _showPaymentPicker(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Payment Method'),
        actions: [
          ...PaymentMethod.values.map((p) => CupertinoActionSheetAction(
                onPressed: () {
                  _applyEdit(_edited.copyWith(paymentMethod: p));
                  Navigator.pop(context);
                },
                isDefaultAction: p == _edited.paymentMethod,
                child: Text(p.displayName),
              )),
          CupertinoActionSheetAction(
            onPressed: () {
              _applyEdit(_edited.copyWith(paymentMethod: null));
              Navigator.pop(context);
            },
            child: const Text('Not specified'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final overlayState = ref.watch(inputOverlayProvider);
    final edited = overlayState.editedResult ?? widget.result;
    final isManual = edited.source == ParseSource.manual;
    final showWarning =
        !edited.isHighConfidence || edited.source != ParseSource.ai;

    return SwipeCard(
      swipeEnabled: !_anyFieldEditing,
      onConfirm: _confirm,
      onDiscard: _discard,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceL1,
          borderRadius: AppRadius.sheet,
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        padding: const EdgeInsets.all(AppSpacing.sp5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Swipe hint ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('← back',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.semanticExpense)),
                Text('confirm →',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.semanticSaved)),
              ],
            ),
            const SizedBox(height: AppSpacing.sp4),

            // ── Type badge ──────────────────────────────────────────────────
            GestureDetector(
              onTap: () {
                final toggled = edited.type == EventType.expense
                    ? EventType.saved
                    : EventType.expense;
                _applyEdit(edited.copyWith(type: toggled));
              },
              child: _TypeBadge(type: edited.type),
            ),
            const SizedBox(height: AppSpacing.sp3),

            // ── Amount ──────────────────────────────────────────────────────
            EditableFieldRow(
              label: 'Amount',
              value: edited.amount != null
                  ? _currencyFormat.format(edited.amount)
                  : '',
              placeholder: 'Enter amount',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autoFocus: isManual && edited.amount == null,
              onChanged: (v) {
                final cleaned = v.replaceAll(RegExp(r'[^\d.]'), '');
                final parsed = double.tryParse(cleaned);
                _applyEdit(edited.copyWith(amount: parsed));
              },
              onDone: () => setState(() => _anyFieldEditing = false),
            ),

            const _Divider(),

            // ── Note ────────────────────────────────────────────────────────
            EditableFieldRow(
              label: 'Note',
              value: edited.note ?? '',
              placeholder: 'Add a note',
              onChanged: (v) => _applyEdit(edited.copyWith(note: v)),
              onDone: () => setState(() => _anyFieldEditing = false),
            ),

            const _Divider(),

            // ── Category + Payment chips ─────────────────────────────────
            const SizedBox(height: AppSpacing.sp2),
            Row(
              children: [
                _Chip(
                  label: edited.category.displayName,
                  onTap: () => _showCategoryPicker(context),
                ),
                const SizedBox(width: AppSpacing.sp2),
                _Chip(
                  label: edited.paymentMethod?.displayName ?? 'Payment',
                  onTap: () => _showPaymentPicker(context),
                  muted: edited.paymentMethod == null,
                ),
              ],
            ),

            // ── Warning strip ────────────────────────────────────────────
            if (showWarning && overlayState.rawText != null) ...[
              const SizedBox(height: AppSpacing.sp4),
              _WarningStrip(rawInput: overlayState.rawText!),
            ],

            // ── Manual prompt ─────────────────────────────────────────────
            if (isManual) ...[
              const SizedBox(height: AppSpacing.sp4),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sp3),
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withValues(alpha: 0.08),
                  borderRadius: AppRadius.chip,
                  border: Border.all(
                      color: AppColors.goldPrimary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.info_circle,
                        size: 14, color: AppColors.goldPrimary),
                    const SizedBox(width: AppSpacing.sp2),
                    Expanded(
                      child: Text(
                        'Please fill in the amount, type and category.',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.goldPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.sp2),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final EventType type;

  @override
  Widget build(BuildContext context) {
    final isExpense = type == EventType.expense;
    final color =
        isExpense ? AppColors.semanticExpense : AppColors.semanticSaved;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp3, vertical: AppSpacing.sp1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pill,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            type.displayName.toUpperCase(),
            style: AppTypography.label.copyWith(color: color),
          ),
          const SizedBox(width: AppSpacing.sp1),
          Icon(CupertinoIcons.chevron_up_chevron_down,
              size: 10, color: color),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.onTap,
    this.muted = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp3, vertical: AppSpacing.sp1),
        decoration: BoxDecoration(
          color: AppColors.surfaceL2,
          borderRadius: AppRadius.pill,
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: muted ? AppColors.textTertiary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _WarningStrip extends StatelessWidget {
  const _WarningStrip({required this.rawInput});
  final String rawInput;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sp3),
      decoration: BoxDecoration(
        color: AppColors.goldPrimary.withValues(alpha: 0.06),
        borderRadius: AppRadius.chip,
        border:
            Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.exclamationmark_triangle,
              size: 14, color: AppColors.goldPrimary),
          const SizedBox(width: AppSpacing.sp2),
          Expanded(
            child: Text(
              'AI wasn\'t fully certain · "$rawInput"',
              style: AppTypography.caption
                  .copyWith(color: AppColors.goldHighlight),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: AppColors.surfaceBorder,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sp1),
    );
  }
}
