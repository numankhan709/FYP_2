// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScanResult _$ScanResultFromJson(Map<String, dynamic> json) => ScanResult(
  id: json['id'] as String,
  imagePath: json['imagePath'] as String,
  scanDate: DateTime.parse(json['scanDate'] as String),
  detections:
      (json['detections'] as List<dynamic>)
          .map((e) => DetectionResult.fromJson(e as Map<String, dynamic>))
          .toList(),
  confidence: (json['confidence'] as num).toDouble(),
  notes: json['notes'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ScanResultToJson(ScanResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'imagePath': instance.imagePath,
      'scanDate': instance.scanDate.toIso8601String(),
      'detections': instance.detections,
      'confidence': instance.confidence,
      'notes': instance.notes,
      'metadata': instance.metadata,
    };

DetectionResult _$DetectionResultFromJson(Map<String, dynamic> json) =>
    DetectionResult(
      diseaseId: json['diseaseId'] as String,
      diseaseName: json['diseaseName'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      boundingBoxes:
          (json['boundingBoxes'] as List<dynamic>?)
              ?.map((e) => BoundingBox.fromJson(e as Map<String, dynamic>))
              .toList(),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$DetectionResultToJson(DetectionResult instance) =>
    <String, dynamic>{
      'diseaseId': instance.diseaseId,
      'diseaseName': instance.diseaseName,
      'confidence': instance.confidence,
      'boundingBoxes': instance.boundingBoxes,
      'additionalData': instance.additionalData,
    };

BoundingBox _$BoundingBoxFromJson(Map<String, dynamic> json) => BoundingBox(
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
  width: (json['width'] as num).toDouble(),
  height: (json['height'] as num).toDouble(),
  confidence: (json['confidence'] as num).toDouble(),
);

Map<String, dynamic> _$BoundingBoxToJson(BoundingBox instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'width': instance.width,
      'height': instance.height,
      'confidence': instance.confidence,
    };
