import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/financial_event.dart';
import '../../../core/providers/timeline_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'transaction_detail_card.dart';

class TransactionList extends ConsumerStatefulWidget {
  const TransactionList({super.key});

  @override
  ConsumerState<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends ConsumerState<TransactionList> {
  final _scrollCtrl = ScrollController();

  /// Set of event IDs currently expanded.
  final _expandedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(timelineProvider.notifier).loadMore();
    }
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(timelineProvider);

    return timelineAsync.when(
      data: (state) {
        if (state.events.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sp12),
            child: Center(
              child: Text(
                'No transactions found.\nTry adjusting the filters.',
                textAlign: TextAlign.center,
                style: AppTypography.body,
              ),
            ),
          );
        }

        return Column(
          children: [
            ...state.events.map((event) => _EventRow(
                  event: event,
                  isExpanded: _expandedIds.contains(event.id),
                  onTap: () => _toggleExpand(event.id),
                )),
            if (state.hasMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sp4),
                child: CupertinoActivityIndicator(),
              ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sp8),
        child: CupertinoActivityIndicator(),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ─── Event row ────────────────────────────────────────────────────────────────

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.isExpanded,
    required this.onTap,
  });

  final FinancialEvent event;
  final bool isExpanded;
  final VoidCallback onTap;

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
    final amount = _currencyFormat.format(event.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Row ─────────────────────────────────────────────────────────────
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp4,
              vertical: AppSpacing.sp3,
            ),
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
                // Note
                Expanded(
                  child: Text(
                    event.note ?? event.category.displayName,
                    style: AppTypography.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sp2),
                // Category chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sp2, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceL3,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    event.category.displayName,
                    style: AppTypography.label,
                  ),
                ),
                const SizedBox(width: AppSpacing.sp3),
                // Amount
                Text(
                  '$sign$amount',
                  style:
                      AppTypography.body.copyWith(color: amountColor),
                ),
                const SizedBox(width: AppSpacing.sp2),
                // Expand chevron
                Icon(
                  isExpanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),

        // ── Expanded detail ──────────────────────────────────────────────────
        AnimatedCrossFade(
          duration: AppMotion.cardFloat,
          firstCurve: AppMotion.cardFloatCurve,
          secondCurve: AppMotion.cardFloatCurve,
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: TransactionDetailCard(event: event),
        ),

        Container(height: 1, color: AppColors.surfaceBorder,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sp4)),
      ],
    );
  }
}
