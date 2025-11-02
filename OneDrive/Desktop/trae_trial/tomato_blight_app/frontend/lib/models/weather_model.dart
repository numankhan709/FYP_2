import 'package:json_annotation/json_annotation.dart';

part 'weather_model.g.dart';

@JsonSerializable()
class WeatherData {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double pressure;
  final double windSpeed;
  final int windDirection;
  final int cloudiness;
  final double? uvIndex;
  final double? visibility;
  final String description;
  final String icon;
  final DateTime dateTime;
  final String? location;
  final Map<String, dynamic>? additionalData;

  WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.windDirection,
    required this.cloudiness,
    this.uvIndex,
    this.visibility,
    required this.description,
    required this.icon,
    required this.dateTime,
    this.location,
    this.additionalData,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) => _$WeatherDataFromJson(json);
  Map<String, dynamic> toJson() => _$WeatherDataToJson(this);

  factory WeatherData.fromOpenWeatherMap(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;
    final wind = json['wind'] as Map<String, dynamic>? ?? {};
    final clouds = json['clouds'] as Map<String, dynamic>? ?? {};
    
    return WeatherData(
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      humidity: main['humidity'] as int,
      pressure: (main['pressure'] as num).toDouble(),
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0.0,
      windDirection: (wind['deg'] as num?)?.toInt() ?? 0,
      cloudiness: (clouds['all'] as num?)?.toInt() ?? 0,
      uvIndex: (json['uvi'] as num?)?.toDouble(),
      visibility: (json['visibility'] as num?)?.toDouble(),
      description: weather['description'] as String,
      icon: weather['icon'] as String,
      dateTime: DateTime.fromMillisecondsSinceEpoch(
        (json['dt'] as int) * 1000,
      ),
      location: json['name'] as String?,
      additionalData: json,
    );
  }

  WeatherData copyWith({
    double? temperature,
    double? feelsLike,
    int? humidity,
    double? pressure,
    double? windSpeed,
    int? windDirection,
    int? cloudiness,
    double? uvIndex,
    double? visibility,
    String? description,
    String? icon,
    DateTime? dateTime,
    String? location,
    Map<String, dynamic>? additionalData,
  }) {
    return WeatherData(
      temperature: temperature ?? this.temperature,
      feelsLike: feelsLike ?? this.feelsLike,
      humidity: humidity ?? this.humidity,
      pressure: pressure ?? this.pressure,
      windSpeed: windSpeed ?? this.windSpeed,
      windDirection: windDirection ?? this.windDirection,
      cloudiness: cloudiness ?? this.cloudiness,
      uvIndex: uvIndex ?? this.uvIndex,
      visibility: visibility ?? this.visibility,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  String get temperatureCelsius => '${temperature.toStringAsFixed(1)}°C';
  String get temperatureFahrenheit => '${(temperature * 9/5 + 32).toStringAsFixed(1)}°F';
  
  String get windSpeedKmh => '${(windSpeed * 3.6).toStringAsFixed(1)} km/h';
  String get windSpeedMph => '${(windSpeed * 2.237).toStringAsFixed(1)} mph';
  
  String get pressureHPa => '${pressure.toStringAsFixed(0)} hPa';
  String get pressureInHg => '${(pressure * 0.02953).toStringAsFixed(2)} inHg';
  
  String get visibilityKm => visibility != null ? '${(visibility! / 1000).toStringAsFixed(1)} km' : 'N/A';
  
  String get windDirectionCardinal {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
                      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((windDirection + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }
  
  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';
  
  bool get isRainy => description.toLowerCase().contains('rain');
  bool get isCloudy => cloudiness > 50;
  bool get isWindy => windSpeed > 5.0; // m/s
  bool get isHumid => humidity > 70;
  
  // Disease risk assessment helpers
  bool get favorableForFungalDiseases {
    return humidity > 70 && temperature > 15 && temperature < 30;
  }
  
  bool get favorableForBacterialDiseases {
    return humidity > 80 && temperature > 20 && temperature < 35;
  }
  
  String get diseaseRiskLevel {
    if (favorableForFungalDiseases || favorableForBacterialDiseases) {
      if (humidity > 90 && isRainy) return 'Very High';
      if (humidity > 80) return 'High';
      return 'Medium';
    }
    return 'Low';
  }

  @override
  String toString() {
    return 'WeatherData{temperature: $temperature, humidity: $humidity, description: $description}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherData &&
           other.temperature == temperature &&
           other.humidity == humidity &&
           other.dateTime == dateTime;
  }

  @override
  int get hashCode => temperature.hashCode ^ humidity.hashCode ^ dateTime.hashCode;
}

@JsonSerializable()
class WeatherForecast {
  final List<WeatherData> dailyForecast;
  final List<WeatherData> hourlyForecast;
  final DateTime lastUpdated;
  final String location;

  WeatherForecast({
    required this.dailyForecast,
    required this.hourlyForecast,
    required this.lastUpdated,
    required this.location,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) => _$WeatherForecastFromJson(json);
  Map<String, dynamic> toJson() => _$WeatherForecastToJson(this);

  WeatherForecast copyWith({
    List<WeatherData>? dailyForecast,
    List<WeatherData>? hourlyForecast,
    DateTime? lastUpdated,
    String? location,
  }) {
    return WeatherForecast(
      dailyForecast: dailyForecast ?? this.dailyForecast,
      hourlyForecast: hourlyForecast ?? this.hourlyForecast,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      location: location ?? this.location,
    );
  }

  List<WeatherData> getNext24Hours() {
    final now = DateTime.now();
    final next24Hours = now.add(const Duration(hours: 24));
    
    return hourlyForecast.where((weather) {
      return weather.dateTime.isAfter(now) && weather.dateTime.isBefore(next24Hours);
    }).toList();
  }

  List<WeatherData> getNext7Days() {
    return dailyForecast.take(7).toList();
  }

  @override
  String toString() {
    return 'WeatherForecast{location: $location, dailyCount: ${dailyForecast.length}, hourlyCount: ${hourlyForecast.length}}';
  }
}