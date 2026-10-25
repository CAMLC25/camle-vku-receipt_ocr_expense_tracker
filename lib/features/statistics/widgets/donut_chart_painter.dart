import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

/// Interactive animated Donut Chart custom painter.
/// Draws segmented category arcs with center cutout and currency metrics natively.
class DonutChartPainter extends CustomPainter {
  final Map<String, int> categoryExpenses;
  final int totalExpense;
  final double animationProgress; // 0.0 to 1.0
  final bool isDark;

  DonutChartPainter({
    required this.categoryExpenses,
    required this.totalExpense,
    required this.animationProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2 - 8;
    final innerRadius = outerRadius * 0.68;
    final strokeWidth = outerRadius - innerRadius;
    final radius = innerRadius + strokeWidth / 2;

    final baseRect = Rect.fromCircle(center: center, radius: radius);

    // 1. Draw subtle background track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = isDark
          ? AppColors.surfaceDark.withAlpha(120)
          : const Color(0xFFF1F5F9);
    canvas.drawArc(baseRect, 0, 2 * math.pi, false, trackPaint);

    if (totalExpense <= 0 || categoryExpenses.isEmpty) {
      _drawCenterText(canvas, center, '0 ₫');
      return;
    }

    // 2. Draw animated category slices
    double startAngle = -math.pi / 2; // Start from top (12 o'clock)
    const gapAngle = 0.04; // Gap between arcs in radians

    for (final entry in categoryExpenses.entries) {
      final category = entry.key;
      final amount = entry.value;
      if (amount <= 0) continue;

      final sliceRatio = amount / totalExpense;
      final sweepAngle = sliceRatio * 2 * math.pi * animationProgress;

      if (sweepAngle > gapAngle) {
        final arcPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = AppColors.getCategoryColor(category);

        canvas.drawArc(
          baseRect,
          startAngle + gapAngle / 2,
          sweepAngle - gapAngle,
          false,
          arcPaint,
        );
      }

      startAngle += sweepAngle;
    }

    // 3. Draw center metric text
    _drawCenterText(
      canvas,
      center,
      CurrencyFormatter.formatVND((totalExpense * animationProgress).round()),
    );
  }

  void _drawCenterText(Canvas canvas, Offset center, String amountText) {
    // Label "Tổng chi"
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'Tổng chi tiêu',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    labelPainter.paint(
      canvas,
      Offset(center.dx - labelPainter.width / 2, center.dy - 18),
    );

    // Value text
    final valuePainter = TextPainter(
      text: TextSpan(
        text: amountText,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    valuePainter.paint(
      canvas,
      Offset(center.dx - valuePainter.width / 2, center.dy + 4),
    );
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.totalExpense != totalExpense ||
        oldDelegate.categoryExpenses != categoryExpenses ||
        oldDelegate.isDark != isDark;
  }
}

/// Widget providing AnimationController lifecycle for DonutChartPainter.
class DonutChartWidget extends StatefulWidget {
  final Map<String, int> categoryExpenses;
  final int totalExpense;
  final double size;

  const DonutChartWidget({
    super.key,
    required this.categoryExpenses,
    required this.totalExpense,
    this.size = 230,
  });

  @override
  State<DonutChartWidget> createState() => _DonutChartWidgetState();
}

class _DonutChartWidgetState extends State<DonutChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant DonutChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalExpense != widget.totalExpense ||
        oldWidget.categoryExpenses != widget.categoryExpenses) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: DonutChartPainter(
              categoryExpenses: widget.categoryExpenses,
              totalExpense: widget.totalExpense,
              animationProgress: _animation.value,
              isDark: isDark,
            ),
          );
        },
      ),
    );
  }
}
