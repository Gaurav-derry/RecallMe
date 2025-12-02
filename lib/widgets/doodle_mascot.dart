import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';

/// Cute doodle-style mascot for RecallMe
/// A friendly memory companion with soft rounded shapes
class DoodleMascot extends StatefulWidget {
  final double size;
  final bool animate;
  final bool showSparkles;

  const DoodleMascot({
    super.key,
    this.size = 120,
    this.animate = true,
    this.showSparkles = true,
  });

  @override
  State<DoodleMascot> createState() => _DoodleMascotState();
}

class _DoodleMascotState extends State<DoodleMascot> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _blinkController;
  bool _isBlinking = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    if (widget.animate) {
      _bounceController.repeat(reverse: true);
      _startBlinking();
    }
  }

  void _startBlinking() async {
    while (mounted && widget.animate) {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() => _isBlinking = true);
        await Future.delayed(const Duration(milliseconds: 150));
        if (mounted) setState(() => _isBlinking = false);
      }
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 1.4,
      height: widget.size * 1.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sparkles around mascot
          if (widget.showSparkles) ...[
            _buildSparkle(widget.size * 0.6, -widget.size * 0.5, 0),
            _buildSparkle(-widget.size * 0.5, -widget.size * 0.3, 200),
            _buildSparkle(widget.size * 0.55, widget.size * 0.35, 400),
            _buildSparkle(-widget.size * 0.45, widget.size * 0.4, 600),
          ],

          // Main mascot body with bounce animation
          AnimatedBuilder(
            animation: _bounceController,
            builder: (context, child) {
              final bounce = widget.animate 
                  ? Tween<double>(begin: 0, end: 6).animate(
                      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut)
                    ).value 
                  : 0.0;
              
              return Transform.translate(
                offset: Offset(0, -bounce),
                child: child,
              );
            },
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _DoodleMascotPainter(isBlinking: _isBlinking),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSparkle(double x, double y, int delayMs) {
    return Positioned(
      left: widget.size * 0.7 + x,
      top: widget.size * 0.7 + y,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: AppColors.doodleSparkle,
          shape: BoxShape.circle,
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(delay: delayMs.ms, duration: 600.ms)
          .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.2, 1.2), duration: 800.ms)
          .then()
          .fadeOut(duration: 400.ms),
    );
  }
}

class _DoodleMascotPainter extends CustomPainter {
  final bool isBlinking;

  _DoodleMascotPainter({this.isBlinking = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Body fill - soft cream
    final bodyPaint = Paint()
      ..color = AppColors.doodleBody
      ..style = PaintingStyle.fill;

    // Outline - warm brown with hand-drawn wobble effect
    final outlinePaint = Paint()
      ..color = AppColors.doodleOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Draw body (slightly wobbly circle for hand-drawn look)
    final bodyPath = Path();
    for (int i = 0; i <= 360; i += 5) {
      final angle = i * 3.14159 / 180;
      // Add slight wobble for hand-drawn effect
      final wobble = (i % 20 == 0) ? 2.0 : (i % 10 == 0) ? -1.5 : 0.0;
      final r = radius * 0.85 + wobble;
      final x = center.dx + r * _cos(angle);
      final y = center.dy + r * _sin(angle);
      if (i == 0) {
        bodyPath.moveTo(x, y);
      } else {
        bodyPath.lineTo(x, y);
      }
    }
    bodyPath.close();

    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(bodyPath, outlinePaint);

    // Draw ears (two small bumps on top)
    _drawEar(canvas, center, radius, -0.4, bodyPaint, outlinePaint);
    _drawEar(canvas, center, radius, 0.4, bodyPaint, outlinePaint);

    // Draw eyes
    final eyePaint = Paint()
      ..color = AppColors.doodleOutline
      ..style = PaintingStyle.fill;

    final eyeY = center.dy - radius * 0.1;
    final eyeSpacing = radius * 0.3;

    if (isBlinking) {
      // Closed eyes (cute lines)
      final closedEyePaint = Paint()
        ..color = AppColors.doodleOutline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCenter(center: Offset(center.dx - eyeSpacing, eyeY), width: 20, height: 10),
        0, 3.14159, false, closedEyePaint,
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(center.dx + eyeSpacing, eyeY), width: 20, height: 10),
        0, 3.14159, false, closedEyePaint,
      );
    } else {
      // Open eyes
      canvas.drawCircle(Offset(center.dx - eyeSpacing, eyeY), 8, eyePaint);
      canvas.drawCircle(Offset(center.dx + eyeSpacing, eyeY), 8, eyePaint);

      // Eye highlights
      final highlightPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(center.dx - eyeSpacing + 2, eyeY - 3), 3, highlightPaint);
      canvas.drawCircle(Offset(center.dx + eyeSpacing + 2, eyeY - 3), 3, highlightPaint);
    }

    // Draw blush
    final blushPaint = Paint()
      ..color = AppColors.doodleBlush.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx - radius * 0.5, center.dy + radius * 0.15), width: 18, height: 10),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx + radius * 0.5, center.dy + radius * 0.15), width: 18, height: 10),
      blushPaint,
    );

    // Draw smile
    final smilePaint = Paint()
      ..color = AppColors.doodleOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final smilePath = Path();
    smilePath.moveTo(center.dx - radius * 0.2, center.dy + radius * 0.25);
    smilePath.quadraticBezierTo(
      center.dx, center.dy + radius * 0.45,
      center.dx + radius * 0.2, center.dy + radius * 0.25,
    );
    canvas.drawPath(smilePath, smilePaint);

    // Draw small heart on chest
    _drawHeart(canvas, Offset(center.dx, center.dy + radius * 0.5), 12);
  }

  void _drawEar(Canvas canvas, Offset center, double radius, double angleOffset, Paint fillPaint, Paint strokePaint) {
    final earCenter = Offset(
      center.dx + radius * 0.5 * angleOffset.sign,
      center.dy - radius * 0.7,
    );
    final earPath = Path();
    earPath.addOval(Rect.fromCenter(center: earCenter, width: 25, height: 30));
    canvas.drawPath(earPath, fillPaint);
    canvas.drawPath(earPath, strokePaint);
  }

  void _drawHeart(Canvas canvas, Offset center, double size) {
    final heartPaint = Paint()
      ..color = AppColors.accentCoral
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(
      center.dx - size, center.dy - size * 0.3,
      center.dx - size * 0.5, center.dy - size,
      center.dx, center.dy - size * 0.4,
    );
    path.cubicTo(
      center.dx + size * 0.5, center.dy - size,
      center.dx + size, center.dy - size * 0.3,
      center.dx, center.dy + size * 0.3,
    );
    canvas.drawPath(path, heartPaint);
  }

  double _cos(double angle) => angle >= 0 ? (1 - (angle * angle) / 2 + (angle * angle * angle * angle) / 24) : _cos(-angle);
  double _sin(double angle) => angle - (angle * angle * angle) / 6 + (angle * angle * angle * angle * angle) / 120;

  @override
  bool shouldRepaint(covariant _DoodleMascotPainter oldDelegate) {
    return oldDelegate.isBlinking != isBlinking;
  }
}

/// Simple doodle logo without animation (for static use)
class DoodleLogo extends StatelessWidget {
  final double size;

  const DoodleLogo({super.key, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.creamGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryOrange.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _SimpleDoodlePainter(),
      ),
    );
  }
}

class _SimpleDoodlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw a simple friendly face
    final facePaint = Paint()
      ..color = AppColors.doodleOutline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Eyes
    canvas.drawCircle(Offset(center.dx - size.width * 0.15, center.dy - size.height * 0.05), 5, 
      Paint()..color = AppColors.doodleOutline..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(center.dx + size.width * 0.15, center.dy - size.height * 0.05), 5, 
      Paint()..color = AppColors.doodleOutline..style = PaintingStyle.fill);

    // Smile
    final smilePath = Path();
    smilePath.moveTo(center.dx - size.width * 0.15, center.dy + size.height * 0.1);
    smilePath.quadraticBezierTo(
      center.dx, center.dy + size.height * 0.25,
      center.dx + size.width * 0.15, center.dy + size.height * 0.1,
    );
    canvas.drawPath(smilePath, facePaint);

    // Blush
    final blushPaint = Paint()
      ..color = AppColors.doodleBlush.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx - size.width * 0.25, center.dy + size.height * 0.05), 8, blushPaint);
    canvas.drawCircle(Offset(center.dx + size.width * 0.25, center.dy + size.height * 0.05), 8, blushPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


