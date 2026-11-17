import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Cabecera con degradado corporativo y curvatura inferior de 28 px.
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 24),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: SrRobotColors.brandGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: padding.copyWith(top: padding.top + top),
      child: child,
    );
  }
}
