import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import 'alerts_bell_button.dart';
import 'app_sidebar.dart';

/// Scaffold base de la app: barra superior (navbar) + menú lateral.
///
/// Responsivo:
///  - Móvil  → AppBar con botón de menú y `Drawer` deslizable.
///  - Tablet → sidebar fijo a la izquierda + contenido a la derecha.
///
/// Las pantallas solo pasan `title` y `body`; la navegación la hereda.
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    final appBar = AppBar(
      title: Text(title),
      actions: [...?actions, const AlertsBellButton()],
    );

    // Tablet: sidebar fijo + contenido.
    if (context.isTablet) {
      return Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 260,
              child: Material(
                color: Colors.white,
                elevation: 1,
                child: AppSidebar(
                  currentRoute: currentRoute,
                  isPermanent: true,
                ),
              ),
            ),
            const VerticalDivider(width: 1, color: AppColors.border),
            Expanded(
              child: Scaffold(
                appBar: appBar,
                body: body,
                floatingActionButton: floatingActionButton,
              ),
            ),
          ],
        ),
      );
    }

    // Móvil: drawer deslizable.
    return Scaffold(
      appBar: appBar,
      drawer: Drawer(child: AppSidebar(currentRoute: currentRoute)),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}
