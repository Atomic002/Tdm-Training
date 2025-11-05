import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class TargetWidget extends StatefulWidget {
  final VoidCallback onTap;
  final double size;

  const TargetWidget({super.key, required this.onTap, this.size = 60});

  @override
  State<TargetWidget> createState() => _TargetWidgetState();
}

class _TargetWidgetState extends State<TargetWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    _animationController.forward();
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159, // 360 degrees
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CustomPaint(painter: TargetPainter()),
              ),
            ),
          ),
        );
      },
    );
  }
}

class TargetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer red circle
    final outerPaint = Paint()
      ..color = AppColors.danger
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, outerPaint);

    // White ring
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.8, whitePaint);

    // Red ring
    final redPaint = Paint()
      ..color = AppColors.danger
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.6, redPaint);

    // White center ring
    final centerWhitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.4, centerWhitePaint);

    // Red center
    final centerRedPaint = Paint()
      ..color = AppColors.danger
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.2, centerRedPaint);

    // Crosshair
    final crosshairPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.3),
      Offset(center.dx, center.dy + radius * 0.3),
      crosshairPaint,
    );

    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - radius * 0.3, center.dy),
      Offset(center.dx + radius * 0.3, center.dy),
      crosshairPaint,
    );

    // Border
    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
