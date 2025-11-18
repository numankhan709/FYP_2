// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disease_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Disease _$DiseaseFromJson(Map<String, dynamic> json) => Disease(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  symptoms:
      (json['symptoms'] as List<dynamic>).map((e) => e as String).toList(),
  causes: (json['causes'] as List<dynamic>).map((e) => e as String).toList(),
  treatments:
      (json['treatments'] as List<dynamic>).map((e) => e as String).toList(),
  prevention:
      (json['prevention'] as List<dynamic>).map((e) => e as String).toList(),
  imageUrl: json['imageUrl'] as String,
  affectedParts:
      (json['affectedParts'] as List<dynamic>).map((e) => e as String).toList(),
  additionalInfo: json['additionalInfo'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$DiseaseToJson(Disease instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'symptoms': instance.symptoms,
  'causes': instance.causes,
  'treatments': instance.treatments,
  'prevention': instance.prevention,
  'imageUrl': instance.imageUrl,
  'affectedParts': instance.affectedParts,
  'additionalInfo': instance.additionalInfo,
};
