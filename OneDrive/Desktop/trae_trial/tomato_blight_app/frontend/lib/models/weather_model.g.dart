// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeatherData _$WeatherDataFromJson(Map<String, dynamic> json) => WeatherData(
  temperature: (json['temperature'] as num).toDouble(),
  feelsLike: (json['feelsLike'] as num).toDouble(),
  humidity: (json['humidity'] as num).toInt(),
  pressure: (json['pressure'] as num).toDouble(),
  windSpeed: (json['windSpeed'] as num).toDouble(),
  windDirection: (json['windDirection'] as num).toInt(),
  cloudiness: (json['cloudiness'] as num).toInt(),
  uvIndex: (json['uvIndex'] as num?)?.toDouble(),
  visibility: (json['visibility'] as num?)?.toDouble(),
  description: json['description'] as String,
  icon: json['icon'] as String,
  dateTime: DateTime.parse(json['dateTime'] as String),
  location: json['location'] as String?,
  additionalData: json['additionalData'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$WeatherDataToJson(WeatherData instance) =>
    <String, dynamic>{
      'temperature': instance.temperature,
      'feelsLike': instance.feelsLike,
      'humidity': instance.humidity,
      'pressure': instance.pressure,
      'windSpeed': instance.windSpeed,
      'windDirection': instance.windDirection,
      'cloudiness': instance.cloudiness,
      'uvIndex': instance.uvIndex,
      'visibility': instance.visibility,
      'description': instance.description,
      'icon': instance.icon,
      'dateTime': instance.dateTime.toIso8601String(),
      'location': instance.location,
      'additionalData': instance.additionalData,
    };

WeatherForecast _$WeatherForecastFromJson(Map<String, dynamic> json) =>
    WeatherForecast(
      dailyForecast:
          (json['dailyForecast'] as List<dynamic>)
              .map((e) => WeatherData.fromJson(e as Map<String, dynamic>))
              .toList(),
      hourlyForecast:
          (json['hourlyForecast'] as List<dynamic>)
              .map((e) => WeatherData.fromJson(e as Map<String, dynamic>))
              .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      location: json['location'] as String,
    );

Map<String, dynamic> _$WeatherForecastToJson(WeatherForecast instance) =>
    <String, dynamic>{
      'dailyForecast': instance.dailyForecast,
      'hourlyForecast': instance.hourlyForecast,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'location': instance.location,
    };
