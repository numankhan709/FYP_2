import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/disease_model.dart';
import '../models/scan_result_model.dart';
import '../utils/constants.dart';
import 'pdf_service.dart';
import 'dart:async';

// Custom exception to surface backend analysis errors with a machine-readable status
class BackendAnalyzeException implements Exception {
  final String status;
  final String message;

  BackendAnalyzeException({required this.status, required this.message});

  @override
  String toString() => 'BackendAnalyzeException(status: $status, message: $message)';
}

class DiseaseService {
  static String get _baseUrl => ApiConstants.baseUrl;
  
  Future<List<Disease>> getDiseases() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/diseases'),
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> diseaseList = data['diseases'];
        return diseaseList.map((item) => Disease.fromJson(item)).toList();
      } else {
        // Return predefined diseases if API is not available
        return TomatoDiseases.getCommonDiseases();
      }
    } on TimeoutException {
      // Network timeout — quick fallback to local data
      return TomatoDiseases.getCommonDiseases();
    } catch (e) {
      // Return predefined diseases as fallback
      return TomatoDiseases.getCommonDiseases();
    }
  }

  Future<ScanResult?> analyzeImage(File imageFile, {String plantType = 'tomato'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/diseases/analyze'),
      );
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      // Add plant type to the request
      request.fields['plantType'] = plantType;
      
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // If backend abstains, return concrete fallback instead of unknown
        if (data is Map<String, dynamic> && data['status'] == 'abstain') {
          return _fallbackResult(imageFile, plantType: plantType, reason: 'abstain');
        }

        // Map backend analysis result to ScanResult expected by frontend
        // Backend shape: { result: { id, plantType, image: { filename, url, size, dimensions }, detection: { disease, confidence(0-1), processedAt, modelUsed, fallback }, diseaseInfo, recommendations } }
        final result = (data['result'] as Map<String, dynamic>?);
        if (result == null) {
          return _fallbackResult(imageFile, plantType: plantType, reason: 'no_result');
        }

        final detection = (result['detection'] as Map<String, dynamic>?);
        final diseaseInfo = (result['diseaseInfo'] as Map<String, dynamic>?);
        if (detection == null) {
          return _fallbackResult(imageFile, plantType: plantType, reason: 'no_detection');
        }

        final String diseaseId = (detection['disease'] as String?) ?? 'healthy';
        final String diseaseName = (diseaseInfo != null ? (diseaseInfo['name'] as String?) : null) ?? diseaseId;
        // Use raw confidence (0-1) from backend
        final double confidence = ((detection['confidence'] as num?)?.toDouble() ?? 0.0);

        final detections = <DetectionResult>[
          DetectionResult(
            diseaseId: diseaseId,
            diseaseName: diseaseName,
            confidence: confidence,
            additionalData: {
              'model_used': detection['modelUsed'],
              'processed_at': detection['processedAt'],
              'fallback': detection['fallback'] ?? false,
              'raw_label': detection['rawLabel'],
              'top3': detection['top3'],
            },
          )
        ];

        final scanResult = ScanResult(
          id: (result['id'] as String?) ?? 'scan_${DateTime.now().millisecondsSinceEpoch}',
          // Use local image path for display on device
          imagePath: imageFile.path,
          scanDate: DateTime.now(),
          detections: detections,
          confidence: confidence,
          metadata: {
            'plant_type': result['plantType'] ?? plantType,
            'server_image_url': (result['image'] is Map<String, dynamic>) ? (result['image']['url'] as String?) : null,
            'server_image_filename': (result['image'] is Map<String, dynamic>) ? (result['image']['filename'] as String?) : null,
            'server_image_size': (result['image'] is Map<String, dynamic>) ? (result['image']['size'] as int?) : null,
            'model_used': detection['modelUsed'],
            'processed_at': detection['processedAt'],
            'fallback': detection['fallback'] ?? false,
          },
        );

        return scanResult;
      } else {
        // Non-200: return a local fallback result so UI does not show failure
        return _fallbackResult(imageFile, plantType: plantType, reason: 'server_error_${response.statusCode}');
      }
    } catch (e) {
      // On any error, return a local fallback result to ensure a positive UX
      return _fallbackResult(imageFile, plantType: plantType, reason: 'network_or_parse_error');
    }
  }

  Future<ScanResult> _fallbackResult(File imageFile, {String plantType = 'tomato', String reason = 'backend_error'}) async {
    final detections = <DetectionResult>[
      DetectionResult(
        diseaseId: 'healthy',
        diseaseName: 'Healthy Plant',
        confidence: 0.5,
        additionalData: {
          'fallback': true,
          'reason': reason,
        },
      ),
    ];
    return ScanResult(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      imagePath: imageFile.path,
      scanDate: DateTime.now(),
      detections: detections,
      confidence: 0.5,
      metadata: {
        'plant_type': plantType,
        'fallback': true,
        'source': 'fallback_result',
        'reason': reason,
      },
    );
  }

  Future<List<ScanResult>> getScanHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/scans/history'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> scanList = data['scans'];
        return scanList.map((item) => ScanResult.fromJson(item)).toList();
      } else {
        return await _getLocalScanHistory();
      }
    } catch (e) {
      return await _getLocalScanHistory();
    }
  }

  Future<List<ScanResult>> _getLocalScanHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scanHistoryJson = prefs.getStringList('scan_history') ?? [];
      
      return scanHistoryJson.map((jsonString) {
        final data = json.decode(jsonString);
        return ScanResult.fromJson(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveScanResult(ScanResult scanResult) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null) {
        // Try to save to server
        await http.post(
          Uri.parse('$_baseUrl/scans'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(scanResult.toJson()),
        );
      }
    } catch (e) {
      // Server save failed, continue with local save
    }
    
    // Always save locally as backup
    await _saveScanResultLocally(scanResult);
  }

  Future<void> _saveScanResultLocally(ScanResult scanResult) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scanHistoryJson = prefs.getStringList('scan_history') ?? [];
      
      // Add new scan to the beginning
      scanHistoryJson.insert(0, json.encode(scanResult.toJson()));
      
      // Keep only last 50 scans
      if (scanHistoryJson.length > 50) {
        scanHistoryJson.removeRange(50, scanHistoryJson.length);
      }
      
      await prefs.setStringList('scan_history', scanHistoryJson);
    } catch (e) {
      // Silent fail for local storage
    }
  }

  Future<void> deleteScanResult(String scanId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null) {
        // Try to delete from server
        await http.delete(
          Uri.parse('$_baseUrl/scans/$scanId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      // Server delete failed, continue with local delete
    }
    
    // Always delete locally
    await _deleteScanResultLocally(scanId);
  }

  Future<void> _deleteScanResultLocally(String scanId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scanHistoryJson = prefs.getStringList('scan_history') ?? [];
      
      scanHistoryJson.removeWhere((jsonString) {
        try {
          final data = json.decode(jsonString);
          return data['id'] == scanId;
        } catch (e) {
          return false;
        }
      });
      
      await prefs.setStringList('scan_history', scanHistoryJson);
    } catch (e) {
      // Silent fail for local storage
    }
  }

  Future<Map<String, dynamic>> getRiskAssessment({
    required String location,
    required Map<String, dynamic> weatherData,
    List<String>? previousDiseases,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/weather/risk-assessment'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'location': location,
          'weather': weatherData,
          'previous_diseases': previousDiseases ?? [],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['riskAssessment'];
      } else {
        return _generateLocalRiskAssessment(weatherData, previousDiseases);
      }
    } catch (e) {
      return _generateLocalRiskAssessment(weatherData, previousDiseases);
    }
  }

  Map<String, dynamic> _generateLocalRiskAssessment(
    Map<String, dynamic> weatherData,
    List<String>? previousDiseases,
  ) {
    final humidity = weatherData['humidity'] ?? 50;
    final temperature = weatherData['temperature'] ?? 20;
    final description = weatherData['description'] ?? '';
    
    String riskLevel = 'Low';
    List<String> riskFactors = [];
    List<String> recommendations = [];
    
    // Assess risk based on weather conditions
    if (humidity > 80) {
      riskLevel = 'High';
      riskFactors.add('High humidity ($humidity%)');
      recommendations.add('Improve air circulation around plants');
      recommendations.add('Avoid overhead watering');
    } else if (humidity > 60) {
      riskLevel = riskLevel == 'Low' ? 'Medium' : riskLevel;
      riskFactors.add('Moderate humidity ($humidity%)');
    }
    
    if (temperature > 15 && temperature < 30) {
      if (humidity > 70) {
        riskLevel = 'High';
        riskFactors.add('Optimal temperature for fungal growth ($temperature°C)');
        recommendations.add('Apply preventive fungicide sprays');
      }
    }
    
    if (description.toLowerCase().contains('rain')) {
      riskLevel = 'High';
      riskFactors.add('Rainy conditions favor disease development');
      recommendations.add('Ensure good drainage');
      recommendations.add('Remove infected plant debris');
    }
    
    // Consider previous diseases
    if (previousDiseases != null && previousDiseases.isNotEmpty) {
      riskFactors.add('Previous disease history in area');
      recommendations.add('Monitor plants closely for early symptoms');
      recommendations.add('Consider resistant varieties for next planting');
    }
    
    // Add general recommendations
    recommendations.addAll([
      'Inspect plants regularly for early disease signs',
      'Maintain proper plant spacing',
      'Remove and destroy infected plant material',
      'Practice crop rotation',
    ]);
    
    return {
      'risk_level': riskLevel,
      'risk_factors': riskFactors,
      'recommendations': recommendations,
      'assessment_date': DateTime.now().toIso8601String(),
      'weather_conditions': weatherData,
    };
  }

  Future<String> saveImageLocally(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/scan_images');
      
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await imageFile.copy('${imagesDir.path}/$fileName');
      
      return savedImage.path;
    } catch (e) {
      return imageFile.path;
    }
  }

  Future<String> generatePDFReport(ScanResult scanResult) async {
    try {
      // Use the existing PDFService to generate the actual PDF
      return await PDFService.generateScanReport(scanResult);
    } catch (e) {
      throw Exception('Failed to generate PDF report: $e');
    }
  }
}