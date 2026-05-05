import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/enums.dart';
import '../../core/providers/detail_stats_provider.dart';
import '../../core/providers/filter_provider.dart';
import '../../core/providers/repository_provider.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/dual_pie_charts.dart';
import 'widgets/filter_bar.dart';
import 'widgets/transaction_list.dart';

class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({super.key, this.initialTypeFilter});

  /// One-time type filter applied on entry; cleared when screen is popped.
  final EventType? initialTypeFilter;

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    if (widget.initialTypeFilter != null) {
      // Apply one-time type filter after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(filterProvider.notifier)
            .setType(widget.initialTypeFilter);
      });
    }
  }

  @override
  void dispose() {
    // Clear the type filter when leaving (one-time only)
    if (widget.initialTypeFilter != null) {
      ref.read(filterProvider.notifier).clearType();
    }
    super.dispose();
  }

  String get _screenTitle {
    final filter = ref.read(filterProvider);
    if (filter.type == EventType.expense) return 'Expenses';
    if (filter.type == EventType.saved) return 'Saved';
    return 'All Transactions';
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(filterProvider);
    final statsAsync = ref.watch(detailStatsProvider);
    final now = DateTime.now();
    final isLastThreeDays =
        now.day >= (DateTime(now.year, now.month + 1, 0).day - 2);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundBot,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.surfaceL1,
        border: Border.all(color: AppColors.surfaceBorder, width: 0),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back,
              color: AppColors.goldPrimary),
        ),
        middle: Text(
          _screenTitle,
          style: AppTypography.headline,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.backgroundTop,
                  AppColors.backgroundMid,
                  AppColors.backgroundBot,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Month-end reflection banner ──────────────────────
                      _MonthEndBanner(
                        show: isLastThreeDays,
                        onTap: () {
                          // Filter to pending review
                          ref.read(filterProvider.notifier).setType(null);
                        },
                      ),

                      const SizedBox(height: AppSpacing.sp3),

                      // ── Filter bar ───────────────────────────────────────
                      const FilterBar(),

                      const SizedBox(height: AppSpacing.sp4),

                      // ── Aggregate totals ─────────────────────────────────
                      statsAsync.when(
                        data: (stats) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sp4),
                          child: Row(
                            children: [
                              _StatBadge(
                                label: 'Spent',
                                amount: _currencyFormat
                                    .format(stats.totalExpense),
                                color: AppColors.semanticExpense,
                              ),
                              Container(
                                width: 1,
                                height: 24,
                                color: AppColors.surfaceBorder,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sp4),
                              ),
                              _StatBadge(
                                label: 'Saved',
                                amount: _currencyFormat
                                    .format(stats.totalSaved),
                                color: AppColors.semanticSaved,
                              ),
                            ],
                          ),
                        ),
                        loading: () =>
                            const CupertinoActivityIndicator(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: AppSpacing.sp5),

                      // ── Dual pie charts ──────────────────────────────────
                      statsAsync.when(
                        data: (stats) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sp4),
                          child: DualPieCharts(
                            expenseByCategory: stats.expenseByCategory,
                            savedByCategory: stats.savedByCategory,
                          ),
                        ),
                        loading: () => const SizedBox(height: 160),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: AppSpacing.sp5),

                      // ── Section label ────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sp4),
                        child: Text(
                          'Transactions',
                          style: AppTypography.headline,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sp3),
                    ],
                  ),
                ),

                // ── Transaction list ───────────────────────────────────────
                const SliverToBoxAdapter(child: TransactionList()),

                const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.sp12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Month-end reflection banner ─────────────────────────────────────────────

class _MonthEndBanner extends ConsumerWidget {
  const _MonthEndBanner({required this.show, required this.onTap});

  final bool show;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!show) return const SizedBox.shrink();

    return FutureBuilder<int>(
      future: ref
          .read(eventRepositoryProvider)
          .getPendingReview()
          .then((list) => list.length),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        if (count == 0) return const SizedBox.shrink();

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(
                AppSpacing.sp4, AppSpacing.sp3, AppSpacing.sp4, 0),
            padding: const EdgeInsets.all(AppSpacing.sp3),
            decoration: BoxDecoration(
              color: AppColors.goldPrimary.withValues(alpha: 0.10),
              borderRadius: AppRadius.chip,
              border: Border.all(
                  color: AppColors.goldPrimary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.bell_fill,
                    size: 14, color: AppColors.goldPrimary),
                const SizedBox(width: AppSpacing.sp2),
                Expanded(
                  child: Text(
                    'You have $count expense${count == 1 ? '' : 's'} '
                    'without reflection — review them',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.goldHighlight),
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right,
                    size: 12, color: AppColors.goldPrimary),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Stat badge ──────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  const _StatBadge(
      {required this.label, required this.amount, required this.color});

  final String label;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: 2),
        Text(amount, style: AppTypography.headline.copyWith(color: color)),
      ],
    );
  }
}
