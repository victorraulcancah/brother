import 'package:flutter/material.dart';
import '../utils/responsive.dart';

/// Centra el contenido, lo limita a un ancho máximo y permite scroll.
///
/// Ideal para formularios (login, registro): en móviles usa todo el
/// ancho con menos padding; en pantallas grandes/tablet no se estira.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 440,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: context.isSmallPhone ? 16 : 24,
          vertical: 24,
        );

    return Center(
      child: SingleChildScrollView(
        padding: resolvedPadding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
