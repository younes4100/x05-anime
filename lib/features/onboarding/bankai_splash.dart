import 'package:flutter/material.dart';

import '../../core/brand/x05_brand.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

class BankaiSplash extends StatelessWidget {
  const BankaiSplash({super.key, required this.progress, this.size = 220});

  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final reveal = _seg(progress, 0.04, 0.68);
    final settle = _ease(_seg(progress, 0.0, 0.82));
    final caption = _ease(_seg(progress, 0.48, 0.92));
    final flare = 1 - (_seg(progress, 0.34, 0.82) * 2 - 1).abs();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.2 + settle * 0.8,
            child: Transform.scale(
              scale: 0.72 + settle * 0.28,
              child: Container(
                width: size * 0.86,
                height: size * 0.86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.2 + flare * 0.12),
                      AppColors.accent.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.48, 1],
                  ),
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: reveal,
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - settle)),
                  child: Transform.scale(
                    scale: 0.9 + settle * 0.1,
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (rect) => LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: const [
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                        ],
                        stops: [
                          0,
                          (reveal - 0.08).clamp(0.0, 1.0),
                          reveal.clamp(0.001, 1.0),
                        ],
                      ).createShader(rect),
                      child: X05Mark(
                        size: size * 0.92,
                        glow: true,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: size * 0.025),
              Opacity(
                opacity: caption,
                child: Column(
                  children: [
                    Text(
                      'ANIME',
                      style: AppText.overline.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: size * 0.055,
                        letterSpacing: size * 0.026,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: size * 0.045),
                    Container(
                      width: size * 0.34 * caption,
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0),
                            AppColors.accent,
                            AppColors.accent.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

double _ease(double t) {
  final inverse = 1 - t;
  return 1 - inverse * inverse * inverse;
}

double _seg(double t, double a, double b) =>
    ((t - a) / (b - a)).clamp(0.0, 1.0);
