import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/financial_event.dart';
import '../../../core/providers/detail_stats_provider.dart';
import '../../../core/providers/home_stats_provider.dart';
import '../../../core/providers/repository_provider.dart';
import '../../../core/providers/timeline_provider.dart';
import '../../../core/theme/app_theme.dart';

class ReflectionPicker extends ConsumerWidget {
  const ReflectionPicker({super.key, required this.event});

  final FinancialEvent event;

  static Color _colorFor(ReflectionState state) => switch (state) {
        ReflectionState.worthIt => AppColors.semanticSaved,
        ReflectionState.mehh => AppColors.goldPrimary,
        ReflectionState.notWorthIt => AppColors.semanticExpense,
      };

  Future<void> _pick(WidgetRef ref, ReflectionState picked) async {
    final updated = event.copyWith(
      reflection: picked,
      // Only set reflectedAt on first reflection
      reflectedAt: event.reflectedAt ?? DateTime.now().toUtc(),
      editedAt: DateTime.now().toUtc(),
    );
    final repo = ref.read(eventRepositoryProvider);
    await repo.update(updated);
    ref.invalidate(homeStatsProvider);
    ref.invalidate(timelineProvider);
    ref.invalidate(detailStatsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: ReflectionState.values.map((state) {
        final isActive = event.reflection == state;
        final color = _colorFor(state);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => _pick(ref, state),
              child: AnimatedContainer(
                duration: AppMotion.cardFloat,
                curve: AppMotion.cardFloatCurve,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp2),
                decoration: BoxDecoration(
                  color: isActive
                      ? color.withValues(alpha: 0.18)
                      : AppColors.surfaceL2,
                  borderRadius: AppRadius.chip,
                  border: Border.all(
                    color: isActive
                        ? color.withValues(alpha: 0.5)
                        : AppColors.surfaceBorder,
                  ),
                ),
                child: Text(
                  state.displayName,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: isActive ? color : AppColors.textSecondary,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
