import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../config/api_endpoints.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'app_segmented.dart';

/// Muestra el PDF de un documento en una hoja a pantalla casi completa,
/// reusando el mismo endpoint del backend (GET /pdf/{tipo}/{id}). El widget
/// `PdfPreview` de `printing` ya trae imprimir y compartir/guardar.
///
///   mostrarPdf(context, tipo: 'nota-venta', id: 12, nombre: 'NV01-00000012',
///       formatos: ['a4', 'ticket']);
Future<void> mostrarPdf(
  BuildContext context, {
  required String tipo,
  required int id,
  required String nombre,
  String titulo = 'Documento',
  List<String> formatos = const ['a4'],
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _PdfSheet(tipo: tipo, id: id, nombre: nombre, titulo: titulo, formatos: formatos),
  );
}

const _nombreFmt = {'a4': 'A4', 'ticket': 'Ticket'};

class _PdfSheet extends StatefulWidget {
  final String tipo;
  final int id;
  final String nombre;
  final String titulo;
  final List<String> formatos;

  const _PdfSheet({
    required this.tipo,
    required this.id,
    required this.nombre,
    required this.titulo,
    required this.formatos,
  });

  @override
  State<_PdfSheet> createState() => _PdfSheetState();
}

class _PdfSheetState extends State<_PdfSheet> {
  final ApiService _api = ApiService();
  int _formatoIndex = 0;

  String get _formato => widget.formatos[_formatoIndex];

  /// Trae los bytes del PDF para el formato actual (el `PdfPreview` lo llama).
  Future<Uint8List> _bytes() => _api.getBytes('${ApiEndpoints.pdf(widget.tipo, widget.id)}?formato=$_formato');

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.92,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.titulo,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textStrong),
                        ),
                        Text(widget.nombre, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            if (widget.formatos.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: AppSegmented(
                  items: [for (final f in widget.formatos) _nombreFmt[f] ?? f],
                  selected: _formatoIndex,
                  onChanged: (i) => setState(() => _formatoIndex = i),
                ),
              ),
            const Divider(height: 1),
            Expanded(
              child: PdfPreview(
                // Clave por formato: al cambiar A4/Ticket vuelve a pedir los bytes.
                key: ValueKey(_formato),
                build: (_) => _bytes(),
                // El preview rasteriza la página a bitmap: el ticket (80mm) es
                // muy angosto y a DPI bajo se ve borroso al estirarlo. Se sube
                // el DPI para que la imagen tenga más píxeles (el ticket más,
                // porque se amplía más). Imprimir/compartir usa el PDF vectorial.
                dpi: _formato == 'ticket' ? 260 : 160,
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                useActions: true,
                pdfFileName: '${widget.nombre}.pdf',
                loadingWidget: const Center(child: CircularProgressIndicator()),
                onError: (context, error) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No se pudo generar el PDF.\n$error', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
