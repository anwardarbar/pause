import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/models/enums.dart';
import '../../../core/theme/app_theme.dart';

/// Deterministic color per category (by enum index).
const _categoryColors = <Category, Color>{
  Category.food: Color(0xFFE6A838),
  Category.travel: Color(0xFF4A90D9),
  Category.shopping: Color(0xFF9B7FD4),
  Category.bills: Color(0xFFE07060),
  Category.entertainment: Color(0xFF3FB8A6),
  Category.misc: Color(0xFF6B7280),
};

class DualPieCharts extends StatelessWidget {
  const DualPieCharts({
    super.key,
    required this.expenseByCategory,
    required this.savedByCategory,
  });

  final Map<Category, double> expenseByCategory;
  final Map<Category, double> savedByCategory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PieSection(
            label: 'Spent',
            data: expenseByCategory,
          ),
        ),
        const SizedBox(width: AppSpacing.sp4),
        Expanded(
          child: _PieSection(
            label: 'Saved',
            data: savedByCategory,
          ),
        ),
      ],
    );
  }
}

class _PieSection extends StatelessWidget {
  const _PieSection({required this.label, required this.data});

  final String label;
  final Map<Category, double> data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: AppSpacing.sp2),
        SizedBox(
          height: 140,
          child: data.isEmpty ? const _EmptyPie() : _FilledPie(data: data),
        ),
        const SizedBox(height: AppSpacing.sp3),
        // Legend
        if (data.isNotEmpty)
          Wrap(
            spacing: AppSpacing.sp2,
            runSpacing: AppSpacing.sp1,
            children: data.keys
                .map((cat) => _LegendDot(category: cat))
                .toList(),
          ),
      ],
    );
  }
}

class _FilledPie extends StatelessWidget {
  const _FilledPie({required this.data});
  final Map<Category, double> data;

  @override
  Widget build(BuildContext context) {
    final sections = data.entries.map((e) {
      final color = _categoryColors[e.key] ?? AppColors.textTertiary;
      return PieChartSectionData(
        value: e.value,
        color: color,
        radius: 44,
        title: '',
        borderSide: const BorderSide(color: AppColors.backgroundMid, width: 2),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 28,
        sectionsSpace: 0,
      ),
    );
  }
}

class _EmptyPie extends StatelessWidget {
  const _EmptyPie();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedCirclePainter(),
      child: const Center(
        child: Text(
          'No data',
          style: AppTypography.caption,
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceL3
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    const dashCount = 20;
    const dashAngle = (2 * pi) / dashCount;
    const gapFraction = 0.4;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => false;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.category});
  final Category category;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColors[category] ?? AppColors.textTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(category.displayName, style: AppTypography.label),
      ],
    );
  }
}
