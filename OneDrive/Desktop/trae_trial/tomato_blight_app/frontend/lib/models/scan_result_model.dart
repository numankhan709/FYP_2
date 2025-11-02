import 'package:json_annotation/json_annotation.dart';

part 'scan_result_model.g.dart';

@JsonSerializable()
class ScanResult {
  final String id;
  final String imagePath;
  final DateTime scanDate;
  final List<DetectionResult> detections;
  final double confidence;
  final String? notes;
  final Map<String, dynamic>? metadata;

  ScanResult({
    required this.id,
    required this.imagePath,
    required this.scanDate,
    required this.detections,
    required this.confidence,
    this.notes,
    this.metadata,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) => _$ScanResultFromJson(json);
  Map<String, dynamic> toJson() => _$ScanResultToJson(this);

  ScanResult copyWith({
    String? id,
    String? imagePath,
    DateTime? scanDate,
    List<DetectionResult>? detections,
    double? confidence,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return ScanResult(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      scanDate: scanDate ?? this.scanDate,
      detections: detections ?? this.detections,
      confidence: confidence ?? this.confidence,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get hasDisease => detections.any((d) => d.diseaseId != 'healthy');
  
  DetectionResult? get primaryDetection {
    if (detections.isEmpty) return null;
    return detections.reduce((a, b) => a.confidence > b.confidence ? a : b);
  }

  String get status {
    if (!hasDisease) return 'Healthy';
    final primary = primaryDetection;
    if (primary == null) return 'Unknown';
    if (primary.confidence > 0.8) return 'Disease Detected';
    if (primary.confidence > 0.6) return 'Possible Disease';
    return 'Uncertain';
  }

  @override
  String toString() {
    return 'ScanResult{id: $id, scanDate: $scanDate, confidence: $confidence}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScanResult && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@JsonSerializable()
class DetectionResult {
  final String diseaseId;
  final String diseaseName;
  final double confidence;
  final List<BoundingBox>? boundingBoxes;
  final Map<String, dynamic>? additionalData;

  DetectionResult({
    required this.diseaseId,
    required this.diseaseName,
    required this.confidence,
    this.boundingBoxes,
    this.additionalData,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) => _$DetectionResultFromJson(json);
  Map<String, dynamic> toJson() => _$DetectionResultToJson(this);

  DetectionResult copyWith({
    String? diseaseId,
    String? diseaseName,
    double? confidence,
    List<BoundingBox>? boundingBoxes,
    Map<String, dynamic>? additionalData,
  }) {
    return DetectionResult(
      diseaseId: diseaseId ?? this.diseaseId,
      diseaseName: diseaseName ?? this.diseaseName,
      confidence: confidence ?? this.confidence,
      boundingBoxes: boundingBoxes ?? this.boundingBoxes,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(1)}%';
  
  String get confidenceLevel {
    if (confidence >= 0.9) return 'Very High';
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.6) return 'Medium';
    if (confidence >= 0.4) return 'Low';
    return 'Very Low';
  }

  @override
  String toString() {
    return 'DetectionResult{diseaseId: $diseaseId, confidence: $confidence}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetectionResult && 
           other.diseaseId == diseaseId && 
           other.confidence == confidence;
  }

  @override
  int get hashCode => diseaseId.hashCode ^ confidence.hashCode;
}

@JsonSerializable()
class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;
  final double confidence;

  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.confidence,
  });

  factory BoundingBox.fromJson(Map<String, dynamic> json) => _$BoundingBoxFromJson(json);
  Map<String, dynamic> toJson() => _$BoundingBoxToJson(this);

  BoundingBox copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? confidence,
  }) {
    return BoundingBox(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  String toString() {
    return 'BoundingBox{x: $x, y: $y, width: $width, height: $height, confidence: $confidence}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BoundingBox &&
           other.x == x &&
           other.y == y &&
           other.width == width &&
           other.height == height &&
           other.confidence == confidence;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ width.hashCode ^ height.hashCode ^ confidence.hashCode;
}