import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/models/enums.dart';
import '../../core/providers/home_stats_provider.dart';
import '../../core/providers/input_overlay_provider.dart';
import '../../core/providers/timeline_provider.dart';
import '../../core/theme/app_theme.dart';
import '../detail/detail_screen.dart';
import 'widgets/hero_stat_card.dart';
import 'widgets/mic_button.dart';
import 'widgets/recent_transaction_row.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Request mic permission after first frame — less jarring than on cold start
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestMicPermission());
  }

  Future<void> _requestMicPermission() async {
    final status = await Permission.microphone.status;
    if (status.isDenied) {
      final result = await Permission.microphone.request();
      if (result.isPermanentlyDenied && mounted) {
        _showPermissionDeniedDialog();
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Microphone Access'),
        content: const Text(
          'Pause needs microphone access to record your expenses by voice. '
          'Please enable it in Settings → Pause → Microphone.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Not Now'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Open Settings'),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, EventType? typeFilter) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => DetailScreen(initialTypeFilter: typeFilter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(homeSelectedMonthProvider);
    final statsAsync    = ref.watch(homeStatsProvider);
    final recentAsync   = ref.watch(recentEventsProvider);

    final now = DateTime.now();
    final isCurrentMonth = selectedMonth.year == now.year &&
        selectedMonth.month == now.month;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.backgroundBot,
      child: Stack(
        children: [
          // ── Background gradient ──────────────────────────────────────────
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

          // ── Scrollable content ───────────────────────────────────────────
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sp8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.sp6),

                        // ── Month header ──────────────────────────────────
                        _MonthHeader(
                          selectedMonth: selectedMonth,
                          isCurrentMonth: isCurrentMonth,
                          onPrevious: () => ref
                              .read(homeSelectedMonthProvider.notifier)
                              .state = DateTime(
                            selectedMonth.year,
                            selectedMonth.month - 1,
                          ),
                          onNext: isCurrentMonth
                              ? null
                              : () => ref
                                  .read(homeSelectedMonthProvider.notifier)
                                  .state = DateTime(
                                selectedMonth.year,
                                selectedMonth.month + 1,
                              ),
                        ),

                        const SizedBox(height: AppSpacing.sp5),

                        // ── Hero stat cards ───────────────────────────────
                        statsAsync.when(
                          data: (stats) => Row(
                            children: [
                              Expanded(
                                child: HeroStatCard(
                                  label: 'Spent this month',
                                  amount: _currencyFormat
                                      .format(stats.totalExpense),
                                  type: EventType.expense,
                                  onTap: () => _openDetail(
                                      context, EventType.expense),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sp3),
                              Expanded(
                                child: HeroStatCard(
                                  label: 'Saved this month',
                                  amount: _currencyFormat
                                      .format(stats.totalSaved),
                                  type: EventType.saved,
                                  onTap: () => _openDetail(
                                      context, EventType.saved),
                                ),
                              ),
                            ],
                          ),
                          loading: () => Row(
                            children: [
                              Expanded(
                                  child: _StatCardSkeleton()),
                              const SizedBox(width: AppSpacing.sp3),
                              Expanded(
                                  child: _StatCardSkeleton()),
                            ],
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                        const SizedBox(height: AppSpacing.sp6),

                        // ── Recent header ─────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent',
                                style: AppTypography.headline),
                            GestureDetector(
                              onTap: () => _openDetail(context, null),

                              child: Text(
                                'View all',
                                style: AppTypography.body.copyWith(
                                    color: AppColors.goldPrimary),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.sp3),

                        // ── Recent transactions ───────────────────────────
                        recentAsync.when(
                          data: (events) => events.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.sp6),
                                  child: Center(
                                    child: Text(
                                      'No transactions yet.\nTap the mic to add one.',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.body.copyWith(
                                          color: AppColors.textTertiary),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: events
                                      .map((e) =>
                                          RecentTransactionRow(event: e))
                                      .toList(),
                                ),
                          loading: () => const CupertinoActivityIndicator(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                        // Space so content doesn't hide behind mic button
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Floating bottom bar (mic + pencil) ───────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.only(bottom: AppSpacing.sp6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Pencil button
                    GestureDetector(
                      onTap: () => ref
                          .read(inputOverlayProvider.notifier)
                          .showText(),
                      child: Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.only(
                            right: AppSpacing.sp4, bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceL2,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.surfaceBorder),
                        ),
                        child: const Icon(
                          CupertinoIcons.pencil,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                    // Mic button
                    const MicButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

// ─── Month header ─────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.selectedMonth,
    required this.isCurrentMonth,
    required this.onPrevious,
    this.onNext,
  });

  final DateTime selectedMonth;
  final bool isCurrentMonth;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  static final _fmt = DateFormat('MMMM yyyy');

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onPrevious,
          child: const Icon(
            CupertinoIcons.chevron_left,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.sp3),
        Text(
          _fmt.format(selectedMonth),
          style: AppTypography.title,
        ),
        const SizedBox(width: AppSpacing.sp3),
        GestureDetector(
          onTap: onNext,
          child: Icon(
            CupertinoIcons.chevron_right,
            color: isCurrentMonth
                ? AppColors.textTertiary // dimmed — can't go to future
                : AppColors.textSecondary,
            size: 20,
          ),
        ),
      ],
    );
  }
}

// ─── Skeleton card for loading state ─────────────────────────────────────────

class _StatCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.glassBorder),
      ),
    );
  }
}
