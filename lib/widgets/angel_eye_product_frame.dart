import 'dart:math' as math;
import 'package:flutter/material.dart';

class AngelEyeProductFrame extends StatefulWidget {
  const AngelEyeProductFrame({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.framePadding = EdgeInsets.zero,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry framePadding;

  @override
  State<AngelEyeProductFrame> createState() => _AngelEyeProductFrameState();
}

class _AngelEyeProductFrameState extends State<AngelEyeProductFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5400),
  )..repeat();

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.framePadding,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: widget.child,
          ),
          IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _AngelFramePainter(_motion)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AngelFramePainter extends CustomPainter {
  _AngelFramePainter(this.motion) : super(repaint: motion);
  final Animation<double> motion;

  static const _pink = Color(0xFFFF3F9D);
  static const _hotPink = Color(0xFFFF78B9);
  static const _bone = Color(0xFFF0E4D9);
  static const _dark = Color(0xFF160D17);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final border = Paint()
      ..color = const Color(0xAA6D455B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(9),
      ).deflate(.5),
      border,
    );

    final scale = (size.width / 440).clamp(.24, .38).toDouble();
    canvas.save();
    canvas.translate(size.width / 2 - 220 * scale, 3);
    canvas.scale(scale);
    _drawWingedEye(canvas, motion.value);
    canvas.restore();
  }

  void _strokeRRect(Canvas canvas, Rect rect, double radius, Color color, double width) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  void _drawCorners(Canvas canvas) {
    final p = Paint()
      ..color = _pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final paths = <Path>[
      Path()..moveTo(20, 80)..lineTo(20, 23)..lineTo(78, 23),
      Path()..moveTo(420, 80)..lineTo(420, 23)..lineTo(362, 23),
      Path()..moveTo(20, 520)..lineTo(20, 577)..lineTo(78, 577),
      Path()..moveTo(420, 520)..lineTo(420, 577)..lineTo(362, 577),
    ];
    for (final path in paths) {
      canvas.drawPath(path, p);
    }
    for (final values in <List<double>>[
      [20, 56, 48, 28], [420, 56, 392, 28],
      [20, 544, 48, 572], [420, 544, 392, 572],
    ]) {
      canvas.drawLine(Offset(values[0], values[1]), Offset(values[2], values[3]), p);
    }
    final star = Paint()..color = _hotPink;
    for (final point in <Offset>[
      const Offset(20, 38), const Offset(420, 38),
      const Offset(20, 562), const Offset(420, 562),
    ]) {
      canvas.drawCircle(point, 2.5, star);
    }
  }

  void _drawWingedEye(Canvas canvas, double phase) {
    final blink = math.max(_blink(phase, .405), _blink(phase, .775));
    final eyeOpen = 1 - .96 * blink;
    final flutter = math.sin(phase * math.pi * 2) * .025;

    final aura = Paint()
      ..color = _pink.withValues(alpha: .18 + .18 * (1 + math.sin(phase * 2 * math.pi)) / 2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawArc(const Rect.fromLTRB(156, 12, 284, 116), math.pi, math.pi,
        false, aura);

    _drawWing(canvas, false, -flutter);
    _drawWing(canvas, true, flutter);

    final eye = Path()
      ..moveTo(166, 67)
      ..cubicTo(195, 39, 245, 39, 274, 67)
      ..cubicTo(245, 95, 195, 95, 166, 67)
      ..close();
    canvas.drawPath(eye, Paint()..color = _dark);
    canvas.drawPath(
      eye,
      Paint()
        ..color = _bone
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.save();
    canvas.clipPath(eye);
    canvas.save();
    canvas.translate(220, 67);
    canvas.scale(1, eyeOpen);
    canvas.translate(-220, -67);
    canvas.drawPath(eye, Paint()..color = const Color(0xFFF7E7E5));
    canvas.drawCircle(const Offset(220, 67), 17, Paint()..color = const Color(0xFFB51967));
    canvas.drawCircle(const Offset(220, 67), 11, Paint()..color = const Color(0xFFED398E));
    canvas.drawOval(Rect.fromCenter(center: const Offset(220, 67), width: 9, height: 22),
        Paint()..color = const Color(0xFF100A12));
    canvas.drawCircle(const Offset(214, 60), 4, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(226, 73), 2, Paint()..color = _hotPink);
    canvas.restore();
    canvas.restore();

    final lid = Paint()
      ..color = const Color(0xFF28111E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final upperLid = Path()
      ..moveTo(166, 67)
      ..cubicTo(195, 39, 245, 39, 274, 67);
    canvas.drawPath(upperLid, Paint()..color = const Color(0xFFFFF1E8)..style = PaintingStyle.stroke..strokeWidth = 3);
    if (blink > .05) {
      final closed = Path()
        ..moveTo(168, 67)
        ..quadraticBezierTo(220, 67 + 13 * blink, 272, 67);
      canvas.drawPath(closed, lid..color = lid.color.withValues(alpha: blink));
    }
    final lashes = Paint()..color = _bone..strokeWidth = 2;
    canvas.drawLine(const Offset(178, 48), const Offset(173, 41), lashes);
    canvas.drawLine(const Offset(190, 41), const Offset(188, 33), lashes);
    canvas.drawLine(const Offset(262, 48), const Offset(267, 41), lashes);
    canvas.drawLine(const Offset(250, 41), const Offset(252, 33), lashes);
    _drawDiamond(canvas, const Offset(220, 29), 6, _pink);
  }

  double _blink(double phase, double centre) {
    var distance = (phase - centre).abs();
    distance = math.min(distance, 1 - distance);
    final t = (1 - distance / .018).clamp(0.0, 1.0);
    return t * t * (3 - 2 * t);
  }

  void _drawWing(Canvas canvas, bool mirror, double angle) {
    canvas.save();
    canvas.translate(220, 67);
    canvas.scale(mirror ? -1 : 1, 1);
    canvas.rotate(angle);
    final outline = Path()
      ..moveTo(-20, 0)
      ..cubicTo(-48, -28, -94, -31, -143, -24)
      ..cubicTo(-121, -18, -106, -10, -96, -4)
      ..cubicTo(-123, -8, -145, -2, -158, 8)
      ..cubicTo(-119, 4, -101, 10, -87, 17)
      ..cubicTo(-108, 22, -121, 31, -130, 39)
      ..cubicTo(-87, 33, -54, 28, -25, 14)
      ..close();
    canvas.drawPath(outline, Paint()..color = const Color(0xFF1B111A));
    canvas.drawPath(outline, Paint()..color = _pink..style = PaintingStyle.stroke..strokeWidth = 2);

    final featherPaint = Paint()..color = _bone..style = PaintingStyle.fill;
    final featherEdge = Paint()..color = const Color(0xFF765667)..style = PaintingStyle.stroke..strokeWidth = 1;
    final feathers = <Path>[
      Path()..moveTo(-24, 1)..quadraticBezierTo(-66, -24, -132, -21)..quadraticBezierTo(-82, -11, -35, 8)..close(),
      Path()..moveTo(-25, 5)..quadraticBezierTo(-81, -8, -151, 7)..quadraticBezierTo(-89, 3, -31, 14)..close(),
      Path()..moveTo(-29, 10)..quadraticBezierTo(-83, 12, -128, 36)..quadraticBezierTo(-74, 22, -25, 17)..close(),
      Path()..moveTo(-35, 14)..quadraticBezierTo(-59, 23, -83, 43)..quadraticBezierTo(-47, 33, -23, 17)..close(),
    ];
    for (final feather in feathers) {
      canvas.drawPath(feather, featherPaint);
      canvas.drawPath(feather, featherEdge);
    }
    final vane = Paint()..color = _hotPink.withValues(alpha: .75)..strokeWidth = 1;
    canvas.drawLine(const Offset(-30, 5), const Offset(-137, 5), vane);
    canvas.drawLine(const Offset(-31, 12), const Offset(-111, 29), vane);
    canvas.restore();
  }

  void _drawDiamond(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius * .65, center.dy)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius * .65, center.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(path, Paint()..color = _bone..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  void _drawRose(Canvas canvas) {
    final stem = Paint()..color = _pink..strokeWidth = 1.6..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(196, 574), const Offset(244, 574), stem);
    final rose = Path()
      ..moveTo(220, 572)
      ..cubicTo(207, 567, 211, 559, 218, 564)
      ..cubicTo(220, 555, 229, 559, 224, 566)
      ..cubicTo(234, 560, 238, 569, 225, 573)
      ..close();
    canvas.drawPath(rose, Paint()..color = const Color(0xFF5A1932));
    canvas.drawPath(rose, Paint()..color = _pink..style = PaintingStyle.stroke..strokeWidth = 1.2);
    canvas.drawLine(const Offset(215, 573), const Offset(208, 568), Paint()..color = const Color(0xFF8D8A62)..strokeWidth = 1.5);
    canvas.drawLine(const Offset(228, 573), const Offset(235, 568), Paint()..color = const Color(0xFF8D8A62)..strokeWidth = 1.5);
  }

  void _drawRivet(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 4, Paint()..color = _pink);
    canvas.drawCircle(center, 2, Paint()..color = _bone);
  }

  @override
  bool shouldRepaint(covariant _AngelFramePainter oldDelegate) => false;
}
