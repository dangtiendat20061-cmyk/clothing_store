import 'package:flutter/material.dart';
import '../theme.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;
  static const String angelPath =
      'asset/images/Ethereal_Silver-Haired_Angel_with_White_Wings.png';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;

        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.background),
            if (wide)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: constraints.maxWidth * .68,
                child: Opacity(
                  opacity: .78,
                  child: Image.asset(
                    angelPath,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerRight,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              )
            else
              Positioned.fill(
                child: Opacity(
                  opacity: .25,
                  child: Image.asset(
                    angelPath,
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: wide
                        ? [
                            AppColors.background,
                            AppColors.background.withOpacity(.96),
                            AppColors.background.withOpacity(.25),
                          ]
                        : [
                            AppColors.background.withOpacity(.72),
                            AppColors.background.withOpacity(.88),
                          ],
                    stops: wide ? const [0, .46, 1] : null,
                  ),
                ),
              ),
            ),
            Align(
              alignment: wide ? Alignment.centerLeft : Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: wide ? 500 : 560,
                ),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}
