import 'package:flutter/material.dart';

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
  // Estilo del logo oficial: cabeza blanca, cara oscura, ojos felices
  // y sonrisa con brillo menta, audífonos y antenas laterales.
  static const _face = Color(0xFF1D3A4A);
  static const _faceDeep = Color(0xFF17283A);
  static const _glow = Color(0xFFCFF7EF);
  static const _shell = Color(0xFFF6F8F8);
  static const _shellEdge = Color(0xFFD9E2E4);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h * 0.52);

    // Sombra en el piso
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w / 2, h * 0.95), width: w * 0.46, height: h * 0.05),
      Paint()..color = const Color(0x1A18202B),
    );

    final shell = Paint()..color = _shell;
    final edge = Paint()
      ..color = _shellEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012;

    // Antenas curvas (salen de los audífonos hacia arriba)
    final antenna = Paint()
      ..color = _shell
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;
    for (final dx in [-1.0, 1.0]) {
      final path = Path()
        ..moveTo(c.dx + dx * w * 0.40, c.dy - h * 0.06)
        ..quadraticBezierTo(c.dx + dx * w * 0.36, c.dy - h * 0.28,
            c.dx + dx * w * 0.42, c.dy - h * 0.38);
      canvas.drawPath(path, antenna);
    }

    // Audífonos
    for (final dx in [-1.0, 1.0]) {
      final r = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(c.dx + dx * w * 0.37, c.dy + h * 0.03),
            width: w * 0.14,
            height: h * 0.26),
        Radius.circular(w * 0.07),
      );
      canvas.drawRRect(r, shell);
      canvas.drawRRect(r, edge);
    }

    // Cabeza blanca
    final headR = w * 0.33;
    canvas.drawCircle(c.translate(0, h * 0.015), headR,
        Paint()..color = const Color(0x22000000));
    canvas.drawCircle(c, headR, shell);
    canvas.drawCircle(c, headR, edge);

    // Cara oscura con degradado
    final faceR = w * 0.245;
    final faceRect = Rect.fromCircle(center: c, radius: faceR);
    canvas.drawCircle(
      c,
      faceR,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          radius: 1.0,
          colors: [_face, _faceDeep],
        ).createShader(faceRect),
    );

    // Brillo superior del visor
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(c.dx, c.dy - faceR * 0.55),
          width: faceR * 1.1,
          height: faceR * 0.35),
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );

    // Ojos felices (arcos) y sonrisa con brillo
    final glowBlur = Paint()
      ..color = _glow.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.02);
    final line = Paint()
      ..color = _glow
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
      ..strokeCap = StrokeCap.round;

    for (final dx in [-1.0, 1.0]) {
      final eye = Rect.fromCenter(
          center: Offset(c.dx + dx * faceR * 0.42, c.dy - faceR * 0.12),
          width: faceR * 0.42,
          height: faceR * 0.36);
      canvas.drawArc(eye, 3.4, 2.62, false, glowBlur);
      canvas.drawArc(eye, 3.4, 2.62, false, line);
    }
    final smile = Rect.fromCenter(
        center: Offset(c.dx, c.dy + faceR * 0.22),
        width: faceR * 0.5,
        height: faceR * 0.36);
    canvas.drawArc(smile, 0.35, 2.44, false, glowBlur);
    canvas.drawArc(smile, 0.35, 2.44, false, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
