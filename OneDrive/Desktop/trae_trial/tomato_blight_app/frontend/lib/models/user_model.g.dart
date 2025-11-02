// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['_id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt:
      json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
  profileImage: json['profileImage'] as String?,
  preferences: json['preferences'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  '_id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'profileImage': instance.profileImage,
  'preferences': instance.preferences,
};
