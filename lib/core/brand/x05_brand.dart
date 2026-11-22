import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The X05 ANIME mark: a sharp geometric X whose crossing opens into a
/// play button. Drawn as geometry rather than shipped as a PNG so it stays
/// crisp at every size and every device pixel ratio.
///
/// Coordinates match `assets/brand/x05-mark.svg` in a {0, 0, 1024, 1024} box.
class X05Mark extends StatelessWidget {
  const X05Mark({super.key, this.size = 96, this.glow = false});

  final double size;

  /// Adds the soft bloom used by the splash. Leave it off for tiny chrome
  /// (the profile footer, list rows) where a blur would only cost frames.
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'X05 ANIME',
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: RepaintBoundary(
          child: CustomPaint(painter: _X05MarkPainter(glow: glow)),
        ),
      ),
    );
  }
}

class _X05MarkPainter extends CustomPainter {
  const _X05MarkPainter({required this.glow});

  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 1024;
    canvas.save();
    canvas.scale(scale);

    final bars = <Path>[
      Path()
        ..moveTo(232, 186)
        ..lineTo(404, 186)
        ..lineTo(792, 838)
        ..lineTo(620, 838)
        ..close(),
      Path()
        ..moveTo(620, 186)
        ..lineTo(792, 186)
        ..lineTo(404, 838)
        ..lineTo(232, 838)
        ..close(),
    ];
    const box = Rect.fromLTWH(0, 0, 1024, 1024);

    if (glow) {
      final bloom = Paint()
        ..color = const Color(0xFF1677FF).withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26);
      for (final bar in bars) {
        canvas.drawPath(bar, bloom);
      }
    }

    canvas.drawPath(
      bars[0],
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF2F8FF), Color(0xFFAFCDFF)],
          stops: [0, 0.52, 1],
        ).createShader(box),
    );
    canvas.drawPath(
      bars[1],
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF63B0FF), Color(0xFF1677FF), Color(0xFF083BB4)],
          stops: [0, 0.48, 1],
        ).createShader(box),
    );

    const discCenter = Offset(512, 512);
    const discRadius = 176.0;
    final disc = Rect.fromCircle(center: discCenter, radius: discRadius);
    canvas.drawCircle(
      discCenter,
      discRadius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF0C1D3B), Color(0xFF05080F)],
        ).createShader(disc),
    );
    canvas.drawCircle(
      discCenter,
      discRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF8FC4FF).withValues(alpha: 0.38),
    );

    final play = Path()
      ..moveTo(466, 430)
      ..lineTo(466, 594)
      ..lineTo(630, 512)
      ..close();
    canvas.drawPath(
      play,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFA9CEFF)],
        ).createShader(play.getBounds()),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _X05MarkPainter oldDelegate) =>
      oldDelegate.glow != glow;
}

/// The X05 ANIME wordmark. [stacked] is the hero lockup used by the splash;
/// the default inline lockup is what the Home header wears.
class X05Wordmark extends StatelessWidget {
  const X05Wordmark({super.key, this.height = 22, this.stacked = false});

  final double height;
  final bool stacked;

  Widget _x05(double fontSize) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFDCEBFF), Color(0xFF7DB6FF)],
        stops: [0, 0.55, 1],
      ).createShader(rect),
      child: Text(
        'X05',
        maxLines: 1,
        style: TextStyle(
          fontSize: fontSize,
          height: 1,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: -fontSize * 0.035,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _anime(double fontSize, double spacing) {
    return Text(
      'ANIME',
      maxLines: 1,
      style: TextStyle(
        fontSize: fontSize,
        height: 1,
        fontWeight: FontWeight.w700,
        letterSpacing: spacing,
        color: const Color(0xFFA9C7EE),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = stacked
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _x05(height * 0.55),
              SizedBox(height: height * 0.06),
              Container(
                width: height * 1.32,
                height: 2,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0x001677FF),
                      Color(0xFF1677FF),
                      Color(0x001677FF),
                    ],
                  ),
                ),
              ),
              SizedBox(height: height * 0.075),
              _anime(height * 0.12, height * 0.045),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _x05(height * 0.95),
              SizedBox(width: height * 0.2),
              Container(
                width: 1,
                height: height * 0.5,
                color: AppColors.hairline,
              ),
              SizedBox(width: height * 0.2),
              _anime(height * 0.26, height * 0.14),
            ],
          );

    // The wordmark is Latin in every locale. Keep its own direction so an
    // Arabic UI cannot mirror "X05" into "50X".
    return Directionality(
      textDirection: TextDirection.ltr,
      child: content,
    );
  }
}
