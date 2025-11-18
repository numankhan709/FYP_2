import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scan_result_model.dart';
import '../models/disease_model.dart';
import '../utils/helpers.dart';

class PDFService {
  static Future<String> generateScanReport(ScanResult scanResult) async {
    final pdf = pw.Document();
    
    // Add content to PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Text(
                'Tomato Disease Scan Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red800,
                ),
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Scan Information
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Scan Information',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  _buildInfoRow('Scan ID:', scanResult.id),
                  _buildInfoRow('Date:', DateTimeHelper.formatDate(scanResult.scanDate)),
                  _buildInfoRow('Time:', DateTimeHelper.formatTime(scanResult.scanDate)),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Primary Detection
            if (scanResult.primaryDetection != null) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.red300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Primary Detection',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red800,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    _buildInfoRow('Disease:', scanResult.primaryDetection!.diseaseName),
                    _buildInfoRow('Confidence:', '${(scanResult.primaryDetection!.confidence * 100).toStringAsFixed(1)}%'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
            ],
            
            // Additional Detections
            if (scanResult.detections.length > 1) ...[
              pw.Text(
                'Additional Detections',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange800,
                ),
              ),
              pw.SizedBox(height: 10),
              ...scanResult.detections.skip(1).map((detection) => 
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.orange300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Disease:', detection.diseaseName),
                      _buildInfoRow('Confidence:', '${(detection.confidence * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
            ],
            
            // Treatment Recommendations
            if (scanResult.primaryDetection != null) ...[
              () {
                final disease = DiseaseDatabase.getById(scanResult.primaryDetection!.diseaseId);
                if (disease != null && disease.treatments.isNotEmpty) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Treatment Recommendations',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.blue300),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: disease.treatments.map((treatment) => 
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 8),
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                  pw.Expanded(child: pw.Text(treatment)),
                                ],
                              ),
                            ),
                          ).toList(),
                        ),
                      ),
                      pw.SizedBox(height: 20),
                    ],
                  );
                }
                return pw.SizedBox.shrink();
              }(),
            ],
            
            // Prevention Tips
            if (scanResult.primaryDetection != null) ...[
              () {
                final disease = DiseaseDatabase.getById(scanResult.primaryDetection!.diseaseId);
                if (disease != null && disease.prevention.isNotEmpty) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Prevention Tips',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.green300),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: disease.prevention.map((tip) => 
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 8),
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                                  pw.Expanded(child: pw.Text(tip)),
                                ],
                              ),
                            ),
                          ).toList(),
                        ),
                      ),
                      pw.SizedBox(height: 20),
                    ],
                  );
                }
                return pw.SizedBox.shrink();
              }(),
            ],
            
            // Footer
            pw.SizedBox(height: 40),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Generated by Tomato Care App',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              'Report generated on ${DateTimeHelper.formatDateTime(DateTime.now())}',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ];
        },
      ),
    );
    
    // Save PDF to device
    final pdfBytes = await pdf.save();
    final fileName = 'scan_report_${scanResult.id}_${DateTimeHelper.formatDateForFilename(scanResult.scanDate)}.pdf';
    
    return await savePDF(pdfBytes, fileName);
  }
  
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }
  
  static Future<void> sharePDF(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)], text: 'Tomato Disease Scan Report');
    } catch (e) {
      throw Exception('Failed to share PDF: $e');
    }
  }
  
  static Future<void> printPDF(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
    } catch (e) {
      throw Exception('Failed to print PDF: $e');
    }
  }
  
  static Future<List<String>> getDownloadedReports() async {
    try {
      final output = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${output.path}/TomatoCare/Reports');
      
      if (!await reportsDir.exists()) {
        return [];
      }
      
      final files = await reportsDir.list().toList();
      return files
          .where((file) => file is File && file.path.endsWith('.pdf'))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  static Future<void> deleteReport(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  /// Save PDF to device storage
  static Future<String> savePDF(Uint8List pdfBytes, String filename) async {
    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${baseDir.path}/TomatoCare/Reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }
      final file = File('${reportsDir.path}/$filename');
      await file.writeAsBytes(pdfBytes);
      return file.path;
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }
}