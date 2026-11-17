import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Mascota "Sr Robot": cabeza blanca redonda, visor oscuro, ojos blancos
/// y sonrisa. Flota suavemente si [animated] es true.
class RobotAvatar extends StatefulWidget {
  const RobotAvatar({super.key, this.size = 120, this.animated = true});

  final double size;
  final bool animated;

  @override
  State<RobotAvatar> createState() => _RobotAvatarState();
}

class _RobotAvatarState extends State<RobotAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animated) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(painter: _RobotPainter()),
    );
    if (!widget.animated) return painter;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -widget.size * 0.04 * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
      child: painter,
    );
  }
}

class _RobotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h * 0.5);

    // Sombra en el piso
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w / 2, h * 0.95), width: w * 0.5, height: h * 0.06),
      Paint()..color = const Color(0x1A18202B),
    );

    // Antena
    final antenna = Paint()
      ..color = SrRobotColors.textInk
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w / 2, h * 0.16), Offset(w / 2, h * 0.07), antenna);
    canvas.drawCircle(Offset(w / 2, h * 0.06), w * 0.04,
        Paint()..color = SrRobotColors.primaryTeal);

    // Orejas
    final ear = Paint()..color = SrRobotColors.primaryTeal;
    for (final dx in [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(c.dx + dx * w * 0.40, c.dy),
              width: w * 0.07,
              height: h * 0.2),
          Radius.circular(w * 0.03),
        ),
        ear,
      );
    }

    // Cabeza
    final head = Rect.fromCenter(center: c, width: w * 0.76, height: h * 0.7);
    canvas.drawOval(
      head.shift(Offset(0, h * 0.015)),
      Paint()..color = const Color(0x14000000),
    );
    canvas.drawOval(head, Paint()..color = Colors.white);
    canvas.drawOval(
      head,
      Paint()
        ..color = SrRobotColors.lineBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.012,
    );

    // Visor oscuro
    final visor = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(c.dx, c.dy - h * 0.02),
          width: w * 0.58,
          height: h * 0.36),
      Radius.circular(w * 0.18),
    );
    canvas.drawRRect(visor, Paint()..color = SrRobotColors.textInk);

    // Brillo del visor
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(visor.left + w * 0.06, visor.top + h * 0.035,
            w * 0.14, h * 0.035),
        Radius.circular(w * 0.02),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    // Ojos
    final eye = Paint()..color = Colors.white;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(c.dx - w * 0.11, c.dy - h * 0.04),
            width: w * 0.08,
            height: h * 0.11),
        eye);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(c.dx + w * 0.11, c.dy - h * 0.04),
            width: w * 0.08,
            height: h * 0.11),
        eye);

    // Sonrisa
    final smile = Paint()
      ..color = SrRobotColors.lime
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(c.dx, c.dy + h * 0.04),
          width: w * 0.18,
          height: h * 0.1),
      0.2,
      2.74,
      false,
      smile,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
