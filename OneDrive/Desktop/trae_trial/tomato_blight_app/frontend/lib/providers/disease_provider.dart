import 'package:flutter/material.dart';
import 'dart:io';
import '../services/disease_service.dart';
import '../models/disease_model.dart';
import '../models/scan_result_model.dart';

class DiseaseProvider with ChangeNotifier {
  final DiseaseService _diseaseService = DiseaseService();
  
  List<Disease> _diseases = [];
  List<ScanResult> _scanHistory = [];
  ScanResult? _currentScanResult;
  bool _isLoading = false;
  bool _isScanning = false;
  String? _errorMessage;

  List<Disease> get diseases => _diseases;
  List<ScanResult> get scanHistory => _scanHistory;
  ScanResult? get currentScanResult => _currentScanResult;
  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  String? get errorMessage => _errorMessage;

  DiseaseProvider() {
    _loadDiseases();
    _loadScanHistory();
  }

  Future<void> _loadDiseases() async {
    _setLoading(true);
    try {
      _diseases = await _diseaseService.getDiseases();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load disease information');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadScanHistory() async {
    try {
      _scanHistory = await _diseaseService.getScanHistory();
      notifyListeners();
    } catch (e) {
      // Silent fail for scan history
    }
  }
  
  // Public method to load diseases
  Future<void> loadDiseases() async {
    await _loadDiseases();
  }
  
  // Public method to load scan history
  Future<void> loadScanHistory() async {
    await _loadScanHistory();
  }

  Future<ScanResult?> scanImage(File imageFile, {String plantType = 'tomato'}) async {
    _setScanning(true);
    _clearError();
    
    try {
      final result = await _diseaseService.analyzeImage(imageFile, plantType: plantType);
      if (result != null) {
        _currentScanResult = result;
        _scanHistory.insert(0, result);
        await _diseaseService.saveScanResult(result);
        notifyListeners();
        return result;
      } else {
        _setError('Failed to analyze image');
        return null;
      }
    } catch (e) {
      _setError('Error analyzing image: ${e.toString()}');
      return null;
    } finally {
      _setScanning(false);
    }
  }

  Future<Map<String, dynamic>> getRiskAssessment({
    required String location,
    required Map<String, dynamic> weatherData,
    List<String>? previousDiseases,
  }) async {
    _setLoading(true);
    try {
      final assessment = await _diseaseService.getRiskAssessment(
        location: location,
        weatherData: weatherData,
        previousDiseases: previousDiseases,
      );
      return assessment;
    } catch (e) {
      _setError('Failed to get risk assessment');
      return {};
    } finally {
      _setLoading(false);
    }
  }

  Disease? getDiseaseById(String diseaseId) {
    try {
      return _diseases.firstWhere((disease) => disease.id == diseaseId);
    } catch (e) {
      return null;
    }
  }

  List<Disease> searchDiseases(String query) {
    if (query.isEmpty) return _diseases;
    
    return _diseases.where((disease) {
      return disease.name.toLowerCase().contains(query.toLowerCase()) ||
             disease.description.toLowerCase().contains(query.toLowerCase()) ||
             disease.symptoms.any((symptom) => 
                 symptom.toLowerCase().contains(query.toLowerCase()));
    }).toList();
  }

  void clearCurrentScan() {
    _currentScanResult = null;
    notifyListeners();
  }

  Future<void> deleteScanResult(String scanId) async {
    try {
      await _diseaseService.deleteScanResult(scanId);
      _scanHistory.removeWhere((scan) => scan.id == scanId);
      if (_currentScanResult?.id == scanId) {
        _currentScanResult = null;
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete scan result');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setScanning(bool scanning) {
    _isScanning = scanning;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get scan result by ID
  Future<ScanResult?> getScanResult(String scanId) async {
    try {
      return _scanHistory.firstWhere((scan) => scan.id == scanId);
    } catch (e) {
      return null;
    }
  }
  
  // Generate PDF report for scan result
  Future<String> generatePDFReport(ScanResult scanResult) async {
    try {
      return await _diseaseService.generatePDFReport(scanResult);
    } catch (e) {
      _setError('Failed to generate PDF report');
      rethrow;
    }
  }

  void refresh() {
    _loadDiseases();
    _loadScanHistory();
  }
}