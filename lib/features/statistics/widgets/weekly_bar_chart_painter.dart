import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Interactive animated 7-Day Weekly Bar Chart custom painter.
/// Draws vertical bars, rounded tops, baseline labels, and gridlines natively.
class WeeklyBarChartPainter extends CustomPainter {
  final Map<String, int> weeklyExpenses;
  final double animationProgress;
  final bool isDark;

  WeeklyBarChartPainter({
    required this.weeklyExpenses,
    required this.animationProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const bottomLabelHeight = 28.0;
    const topPadding = 24.0;
    final chartHeight = size.height - bottomLabelHeight - topPadding;

    if (weeklyExpenses.isEmpty) return;

    final entries = weeklyExpenses.entries.toList();
    final count = entries.length;

    // Find highest expense in the week
    int maxAmount = 0;
    for (final e in entries) {
      if (e.value > maxAmount) maxAmount = e.value;
    }
    // Baseline scale if all 0
    final scaleMax = maxAmount > 0 ? maxAmount : 100000;

    // 1. Draw subtle horizontal gridlines
    final gridPaint = Paint()
      ..color = isDark
          ? AppColors.outlineDark.withAlpha(80)
          : AppColors.outlineLight
      ..strokeWidth = 1.0;

    const gridLines = 3;
    for (int i = 0; i <= gridLines; i++) {
      final y = topPadding + (chartHeight / gridLines) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw bars
    final totalSpacing = size.width / (count * 2);
    final barWidth = totalSpacing * 1.2;

    for (int i = 0; i < count; i++) {
      final entry = entries[i];
      final dateStr = entry.key; // YYYY-MM-DD
      final amount = entry.value;

      final centerX = (size.width / count) * i + (size.width / count) / 2;
      final ratio = (amount / scaleMax).clamp(0.0, 1.0);
      final barHeight = chartHeight * ratio * animationProgress;

      final barLeft = centerX - barWidth / 2;
      final barTop = topPadding + chartHeight - barHeight;
      final barRect = Rect.fromLTWH(barLeft, barTop, barWidth, barHeight);

      final isHighest = amount > 0 && amount == maxAmount;

      // Bar Paint: highlighted if highest day
      final barPaint = Paint()
        ..color = amount == 0
            ? (isDark ? Colors.white10 : Colors.black12)
            : (isHighest
                  ? AppColors.primaryLight
                  : (isDark
                        ? AppColors.secondary
                        : AppColors.secondary.withAlpha(200)))
        ..style = PaintingStyle.fill;

      if (barHeight > 0) {
        final rrect = RRect.fromRectAndCorners(
          barRect,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        );
        canvas.drawRRect(rrect, barPaint);
      } else {
        // Subtle base dot for 0 amount
        canvas.drawCircle(
          Offset(centerX, topPadding + chartHeight),
          2.5,
          barPaint,
        );
      }

      // 3. Draw amount label above bar if amount > 0
      if (amount > 0 && animationProgress > 0.6) {
        final compactText = _formatCompact(amount);
        final amountPainter = TextPainter(
          text: TextSpan(
            text: compactText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isHighest
                  ? AppColors.primaryLight
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        amountPainter.paint(
          canvas,
          Offset(
            centerX - amountPainter.width / 2,
            math.max(4.0, barTop - amountPainter.height - 3),
          ),
        );
      }

      // 4. Draw Date / Day label below baseline
      final dayLabel = _formatDayLabel(dateStr);
      final labelPainter = TextPainter(
        text: TextSpan(
          text: dayLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isHighest ? FontWeight.bold : FontWeight.w500,
            color: isHighest
                ? (isDark ? Colors.white : AppColors.primary)
                : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(centerX - labelPainter.width / 2, topPadding + chartHeight + 6),
      );
    }
  }

  String _formatDayLabel(String isoDate) {
    // Convert YYYY-MM-DD to DD/MM
    try {
      final parts = isoDate.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}';
      }
    } catch (_) {}
    return isoDate;
  }

  String _formatCompact(int amount) {
    if (amount >= 1000000) {
      final m = (amount / 1000000).toStringAsFixed(1);
      return '${m.replaceAll('.0', '')}M';
    } else if (amount >= 1000) {
      final k = (amount / 1000).round();
      return '${k}k';
    }
    return '$amount';
  }

  @override
  bool shouldRepaint(covariant WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.weeklyExpenses != weeklyExpenses ||
        oldDelegate.isDark != isDark;
  }
}

/// Widget providing AnimationController for WeeklyBarChartPainter.
class WeeklyBarChartWidget extends StatefulWidget {
  final Map<String, int> weeklyExpenses;
  final double height;

  const WeeklyBarChartWidget({
    super.key,
    required this.weeklyExpenses,
    this.height = 220,
  });

  @override
  State<WeeklyBarChartWidget> createState() => _WeeklyBarChartWidgetState();
}

class _WeeklyBarChartWidgetState extends State<WeeklyBarChartWidget>
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
  void didUpdateWidget(covariant WeeklyBarChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weeklyExpenses != widget.weeklyExpenses) {
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

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: WeeklyBarChartPainter(
            weeklyExpenses: widget.weeklyExpenses,
            animationProgress: _animation.value,
            isDark: isDark,
          ),
        );
      },
    );
  }
}
