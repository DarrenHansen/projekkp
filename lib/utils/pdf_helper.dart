import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../models/item.dart';
import '../models/business_profile.dart';
import 'helpers.dart';

/// PDF Helper - Generate invoice PDF profesional
class PdfHelper {
  static Future<void> generateAndPreviewInvoice({
    required Invoice invoice,
    required List<Item> items,
    BusinessProfile? businessProfile,
  }) async {
    final pdf = await _buildInvoicePdf(invoice, items, businessProfile);
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static Future<String> generateAndSaveInvoice({
    required Invoice invoice,
    required List<Item> items,
    BusinessProfile? businessProfile,
  }) async {
    final pdf = await _buildInvoicePdf(invoice, items, businessProfile);
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        '${invoice.invoiceNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static Future<pw.Document> _buildInvoicePdf(
    Invoice invoice,
    List<Item> items,
    BusinessProfile? businessProfile,
  ) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.nunitoRegular(),
        bold: await PdfGoogleFonts.nunitoBold(),
        italic: await PdfGoogleFonts.nunitoItalic(),
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // ===== HEADER with Business Profile =====
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (businessProfile != null &&
                      businessProfile.businessName.isNotEmpty) ...[
                    pw.Text(
                      businessProfile.businessName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ] else ...[
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 4),
                  pw.Text(
                    invoice.invoiceNumber,
                    style: const pw.TextStyle(
                        fontSize: 14, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _buildStatusBadge(invoice.status),
                  pw.SizedBox(height: 8),
                  pw.Text('Tanggal: ${Helpers.formatDateFull(invoice.date)}',
                      style: const pw.TextStyle(fontSize: 11)),
                  pw.Text(
                      'Jatuh Tempo: ${Helpers.formatDateFull(invoice.dueDate)}',
                      style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),

          // Business Profile Info
          if (businessProfile != null && !businessProfile.isEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (businessProfile.businessAddress.isNotEmpty)
                    pw.Text('Alamat: ${businessProfile.businessAddress}',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                  if (businessProfile.businessPhone.isNotEmpty)
                    pw.Text('Telp: ${businessProfile.businessPhone}',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                  if (businessProfile.businessEmail.isNotEmpty)
                    pw.Text('Email: ${businessProfile.businessEmail}',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                  if (businessProfile.bankName.isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Text('Bank: ${businessProfile.bankName}',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                    pw.Text(
                        'Rekening: ${businessProfile.bankAccount} a/n ${businessProfile.bankHolder}',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                  ],
                ],
              ),
            ),
          ],

          pw.SizedBox(height: 20),

          // ===== INFO CUSTOMER =====
          _buildSectionTitle('INFO PELANGGAN'),
          pw.SizedBox(height: 8),
          _buildInfoRow('Nama', invoice.customerName),
          if (invoice.customerAddress.isNotEmpty)
            _buildInfoRow('Alamat', invoice.customerAddress),
          if (invoice.customerEmail.isNotEmpty)
            _buildInfoRow('Email', invoice.customerEmail),
          if (invoice.customerPhone.isNotEmpty)
            _buildInfoRow('Telepon', invoice.customerPhone),

          pw.SizedBox(height: 24),

          // ===== TABEL ITEMS =====
          _buildSectionTitle('RINCIAN ITEM'),
          pw.SizedBox(height: 8),
          _buildItemsTable(items),

          pw.SizedBox(height: 24),

          // ===== TOTAL SUMMARY =====
          _buildSummary(invoice, items),

          if (invoice.notes.isNotEmpty) ...[
            pw.SizedBox(height: 30),
            _buildSectionTitle('CATATAN'),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(invoice.notes,
                  style: const pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey700)),
            ),
          ],

          if (businessProfile != null && businessProfile.notes.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(businessProfile.notes,
                  style: const pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey700)),
            ),
          ],

          // ===== FOOTER =====
          pw.Spacer(),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Terima kasih atas kepercayaan Anda.',
              style: pw.TextStyle(
                  fontSize: 11,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey500),
            ),
          ),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildStatusBadge(dynamic status) {
    String label;
    PdfColor color;

    switch (status.toString()) {
      case 'InvoiceStatus.paid':
      case 'paid':
        label = 'LUNAS';
        color = PdfColors.green;
        break;
      case 'InvoiceStatus.overdue':
      case 'overdue':
        label = 'JATUH TEMPO';
        color = PdfColors.red;
        break;
      default:
        label = 'BELUM BAYAR';
        color = PdfColors.orange;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: pw.BoxDecoration(
          color: color, borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Text(label,
          style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white)),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(title,
        style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700));
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
              width: 80,
              child: pw.Text(label,
                  style: const pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey500))),
          pw.SizedBox(
              width: 16,
              child: pw.Text(':',
                  style: const pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey500))),
          pw.Expanded(
              child: pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold))),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(List<Item> items) {
    return pw.TableHelper.fromTextArray(
      headers: ['No', 'Produk', 'Harga', 'Qty', 'Total'],
      data: items.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final item = entry.value;
        return [
          index.toString(),
          item.productName,
          Helpers.formatCurrency(item.price),
          item.qty.toString(),
          Helpers.formatCurrency(item.total),
        ];
      }).toList(),
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.blue800,
        borderRadius: pw.BorderRadius.only(
          topLeft: pw.Radius.circular(6),
          topRight: pw.Radius.circular(6),
        ),
      ),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      rowDecoration: pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5)),
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(40),
        4: const pw.FlexColumnWidth(2),
      },
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildSummary(Invoice invoice, List<Item> items) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final taxAmount = subtotal * (invoice.tax / 100);
    final grandTotal = subtotal + taxAmount - invoice.discount;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        children: [
          _buildSummaryRow('Subtotal', Helpers.formatCurrency(subtotal)),
          if (invoice.tax > 0)
            _buildSummaryRow('Pajak (${invoice.tax.toStringAsFixed(0)}%)',
                Helpers.formatCurrency(taxAmount)),
          if (invoice.discount > 0)
            _buildSummaryRow(
                'Diskon', '- ${Helpers.formatCurrency(invoice.discount)}',
                textColor: PdfColors.red),
          pw.Divider(color: PdfColors.grey300),
          _buildSummaryRow('GRAND TOTAL', Helpers.formatCurrency(grandTotal),
              isBold: true, fontSize: 14),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, double fontSize = 11, PdfColor? textColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: fontSize,
                  fontWeight:
                      isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: fontSize,
                  fontWeight:
                      isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: textColor)),
        ],
      ),
    );
  }
}
