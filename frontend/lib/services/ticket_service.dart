import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_service.dart';

class TicketService {
  // Generar ticket en formato PDF
  static Future<Uint8List> generarTicketPDF(Map<String, dynamic> venta, Map<String, dynamic> configuracion) async {
    final pdf = pw.Document();
    final formatoMoneda = NumberFormat.currency(locale: 'es_PY', symbol: 'Gs ', decimalDigits: 0);
    
    // Obtener fecha formateada
    final fecha = venta['fecha'] != null 
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(venta['fecha']))
        : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Logo (si está configurado para mostrarlo)
                if (configuracion['mostrar_logo'] == true)
                  pw.Container(
                    height: 60,
                    width: 60,
                    margin: const pw.EdgeInsets.only(bottom: 10),
                    child: pw.Placeholder(),
                  ),
                
                // Nombre del negocio
                pw.Text(
                  configuracion['nombre_negocio'] ?? 'Mi Negocio',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
                
                // Dirección
                if (configuracion['direccion'] != null && configuracion['direccion'].isNotEmpty)
                  pw.Text(
                    configuracion['direccion'],
                    style: const pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                
                // Teléfono
                if (configuracion['telefono'] != null && configuracion['telefono'].isNotEmpty)
                  pw.Text(
                    'Tel: ${configuracion['telefono']}',
                    style: const pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                
                pw.SizedBox(height: 10),
                
                // Fecha
                if (configuracion['mostrar_fecha'] == true)
                  pw.Text(
                    'Fecha: $fecha',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                
                // Número de ticket
                if (configuracion['mostrar_numero_ticket'] == true && venta['id'] != null)
                  pw.Text(
                    'Ticket #: ${venta['id']}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                
                // Vendedor
                if (configuracion['mostrar_vendedor'] == true && venta['usuario_nombre'] != null)
                  pw.Text(
                    'Vendedor: ${venta['usuario_nombre']}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                
                // Cliente
                if (configuracion['mostrar_cliente'] == true && venta['cliente_nombre'] != null)
                  pw.Text(
                    'Cliente: ${venta['cliente_nombre']}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1),
                
                // Encabezado de la tabla
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text(
                        'Producto',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Text(
                        'Cant',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Precio',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'Subtotal',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
                
                pw.Divider(thickness: 1),
                
                // Detalles de la venta
                if (venta['items'] != null)
                  pw.Column(
                    children: List.generate(
                      venta['items'].length,
                      (index) {
                        final item = venta['items'][index];
                        return pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                flex: 4,
                                child: pw.Text(
                                  item['nombre'] ?? 'Producto',
                                  style: const pw.TextStyle(fontSize: 8),
                                ),
                              ),
                              pw.Expanded(
                                flex: 1,
                                child: pw.Text(
                                  '${item['cantidad']}',
                                  style: const pw.TextStyle(fontSize: 8),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text(
                                  formatoMoneda.format(item['precio_unitario']),
                                  style: const pw.TextStyle(fontSize: 8),
                                  textAlign: pw.TextAlign.right,
                                ),
                              ),
                              pw.Expanded(
                                flex: 2,
                                child: pw.Text(
                                  formatoMoneda.format(item['subtotal']),
                                  style: const pw.TextStyle(fontSize: 8),
                                  textAlign: pw.TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                
                pw.Divider(thickness: 1),
                
                // Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      'TOTAL:',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(
                      formatoMoneda.format(venta['total']),
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 10),
                
                // Mensaje personalizado
                if (configuracion['mensaje_personalizado'] != null && configuracion['mensaje_personalizado'].isNotEmpty)
                  pw.Text(
                    configuracion['mensaje_personalizado'],
                    style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                    textAlign: pw.TextAlign.center,
                  ),
                
                pw.SizedBox(height: 5),
                
                // Pie de página
                if (configuracion['pie_pagina'] != null && configuracion['pie_pagina'].isNotEmpty)
                  pw.Text(
                    configuracion['pie_pagina'],
                    style: const pw.TextStyle(fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
              ],
            ),
          );
        },
      ),
    );
    
    return pdf.save();
  }
  
  // Compartir ticket
  static Future<void> compartirTicket(Map<String, dynamic> venta) async {
    try {
      // Obtener la configuración del ticket
      final configuracion = await ApiService.obtenerConfiguracionTicket();
      
      // Generar el PDF del ticket
      final pdfBytes = await generarTicketPDF(venta, configuracion);
      
      // Guardar el PDF temporalmente
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/ticket_${venta['id']}.pdf');
      await file.writeAsBytes(pdfBytes);
      
      // Compartir el archivo
      await SharePlus.instance.share(
         ShareParams(
           files: [XFile(file.path)],
           text: 'Ticket de venta #${venta['id']}',
         ),
      );
    } catch (e) {
      print('Error al compartir ticket: $e');
      rethrow;
    }
  }
  
  // Vista previa del ticket
  static Future<void> mostrarVistaPrevia(BuildContext context, Map<String, dynamic> venta) async {
    try {
      // Obtener la configuración del ticket
      final configuracion = await ApiService.obtenerConfiguracionTicket();
      
      // Generar el PDF del ticket
      final pdfBytes = await generarTicketPDF(venta, configuracion);
      
      // Mostrar vista previa
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Ticket de venta #${venta['id']}',
      );
    } catch (e) {
      print('Error al mostrar vista previa: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar vista previa: $e')),
      );
    }
  }
}