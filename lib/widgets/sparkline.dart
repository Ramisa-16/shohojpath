import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

/// A minimal line chart over a fixed-height band — the therapist Progress
/// tab's reading-speed and accuracy trends. Real [values] in, straight line
/// out; no smoothing or interpolation, so a two-session reader gets an
/// honest two-point line rather than a chart implying a trend that isn't
/// there yet.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    required this.color,
    this.height = 90,
  });

  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            values.isEmpty ? context.t.noSessionsYet : context.t.needsTwoSessions,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _SparklinePainter(values: values, color: color)),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFEDF2F7)
      ..strokeWidth = 1.5;
    for (final frac in [0.0, 0.5, 1.0]) {
      final y = size.height * (1 - frac) * 0.87;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV).abs() < 1e-9 ? 1.0 : (maxV - minV);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : i * size.width / (values.length - 1);
      final y = size.height * 0.87 - ((values[i] - minV) / span) * size.height * 0.7;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
