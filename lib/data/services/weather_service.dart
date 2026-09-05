// weather_service.dart  —  Saith Commission Shop

import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

// ── Enums ─────────────────────────────────────────────────────
enum LocationStatus {
  success,
  serviceDisabled,   // GPS turned off
  permissionDenied,  // user said no
  permissionForever, // permanently denied → must open Settings
  timeout,           // took too long
  unknown,
}

// ── Weather model ─────────────────────────────────────────────
class WeatherData {
  final double  tempC;
  final double  feelsLikeC;
  final int     humidity;
  final double  windKph;
  final double  uvIndex;
  final int     weatherCode;
  final String  description;
  final String  iconEmoji;
  final String  city;
  final bool    isRaining;
  final bool    isDaytime;
  final double  lat;
  final double  lon;
  final DateTime fetchedAt;
  final bool    isFallback; // true = GPS unavailable, using default city

  const WeatherData({
    required this.tempC,
    required this.feelsLikeC,
    required this.humidity,
    required this.windKph,
    required this.uvIndex,
    required this.weatherCode,
    required this.description,
    required this.iconEmoji,
    required this.city,
    required this.isRaining,
    required this.isDaytime,
    required this.lat,
    required this.lon,
    required this.fetchedAt,
    this.isFallback = false,
  });

  String get tempCStr      => '${tempC.round()}°C';
  String get feelsLikeStr  => '${feelsLikeC.round()}°C';
  String get humidityStr   => '$humidity%';
  String get windStr       => '${windKph.round()} km/h';
  String get uvStr         => uvIndex.toStringAsFixed(1);

  /// Minutes since last fetch
  int get minsAgo =>
      DateTime.now().difference(fetchedAt).inMinutes;

  String get lastUpdatedStr =>
      minsAgo == 0 ? 'Just now' : '${minsAgo}m ago';

  String get businessTip {
    if (isRaining)     return '🚚  Rain today — confirm deliveries before dispatch';
    if (tempC > 42)    return '🌡️  Extreme heat — keep warehouse cool & hydrated';
    if (tempC > 38)    return '🌡️  Heat wave — ensure warehouse ventilation';
    if (tempC < 4)     return '❄️  Near freezing — protect stock from moisture';
    if (humidity > 88) return '💧  Very high humidity — monitor rice storage bags';
    if (humidity > 78) return '💧  High humidity — check silo ventilation';
    if (windKph > 50)  return '💨  Strong winds — secure outdoor stock covers';
    if (uvIndex > 9)   return '☀️  Very high UV — staff outdoor work before noon';
    return '✅  Good conditions for deliveries and business today';
  }
}

// ── Result wrapper ────────────────────────────────────────────
class WeatherResult {
  final WeatherData?     data;
  final LocationStatus   locationStatus;
  final String?          errorMessage;

  const WeatherResult({
    this.data,
    required this.locationStatus,
    this.errorMessage,
  });

  bool get success => data != null && locationStatus == LocationStatus.success;
}

// ── Service ───────────────────────────────────────────────────
class WeatherService {
  WeatherService._();

  // Default coords (Lahore) — used only when GPS is unavailable
  static const double _defaultLat  = 31.5497;
  static const double _defaultLon  = 74.3436;
  static const String _defaultCity = 'Lahore';

  // ── 1. Request location permission + get GPS ──────────────
  static Future<({Position? pos, LocationStatus status})>
      _requestLocation() async {
    try {
      // Check if GPS is on
      if (!await Geolocator.isLocationServiceEnabled()) {
        // Even if disabled, try last known as it might be cached
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return (pos: last, status: LocationStatus.success);
        return (pos: null, status: LocationStatus.serviceDisabled);
      }

      // Check / request permission
      LocationPermission perm = await Geolocator.checkPermission();

      if (perm == LocationPermission.deniedForever) {
        return (pos: null, status: LocationStatus.permissionForever);
      }

      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          return (pos: null, status: LocationStatus.permissionDenied);
        }
        if (perm == LocationPermission.deniedForever) {
          return (pos: null, status: LocationStatus.permissionForever);
        }
      }

      // Permission granted — get position
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return (pos: pos, status: LocationStatus.success);
    } catch (e) {
      debugPrint('Location request failed: $e');
      // Final attempt at last known
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return (pos: last, status: LocationStatus.success);
      } catch (_) {}
      
      if (e is TimeoutException) return (pos: null, status: LocationStatus.timeout);
      return (pos: null, status: LocationStatus.unknown);
    }
  }

  // ── 2. Reverse geocode lat/lon → city name ─────────────────
  static Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lon&format=json&zoom=10&addressdetails=1',
      );
      final res = await http
          .get(uri, headers: {
            'Accept-Language': 'en-US,en',
            'User-Agent':      'SaithCommissionShop/1.0',
          })
          .timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final body    = json.decode(res.body) as Map<String, dynamic>;
        final address = body['address'] as Map<String, dynamic>? ?? {};
        return (address['city']       as String?)
            ?? (address['town']       as String?)
            ?? (address['village']    as String?)
            ?? (address['district']   as String?)
            ?? (address['county']     as String?)
            ?? (address['state']      as String?)
            ?? 'Your Location';
      }
    } catch (e) {
      debugPrint('Reverse geocode failed: $e');
    }
    return 'Your Location';
  }

  // ── 3. Fetch weather from Open-Meteo ─────────────────────
  static Future<WeatherData?> _fetchFromOpenMeteo(
      double lat, double lon, String city,
      {bool isFallback = false}) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat'
      '&longitude=$lon'
      '&current=temperature_2m'
      ',relative_humidity_2m'
      ',apparent_temperature'
      ',is_day'
      ',precipitation'
      ',weather_code'
      ',wind_speed_10m'
      ',uv_index'
      '&wind_speed_unit=kmh'
      '&timezone=auto'
      '&forecast_days=1',
    );

    final res = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 12));

    if (res.statusCode != 200) {
      debugPrint('Open-Meteo HTTP ${res.statusCode}: ${res.body}');
      return null;
    }

    final body = json.decode(res.body) as Map<String, dynamic>;
    final curr = body['current'] as Map<String, dynamic>;

    final code      = (curr['weather_code'] as num).toInt();
    final temp      = (curr['temperature_2m'] as num).toDouble();
    final feelsLike = (curr['apparent_temperature'] as num).toDouble();
    final humidity  = (curr['relative_humidity_2m'] as num).toInt();
    final wind      = (curr['wind_speed_10m'] as num).toDouble();
    final isDay     = (curr['is_day'] as num? ?? 1).toInt() == 1;
    final precip    = (curr['precipitation'] as num? ?? 0).toDouble();
    final uv        = (curr['uv_index'] as num? ?? 0).toDouble();
    final isRaining = precip > 0 || (code >= 51 && code <= 99);

    return WeatherData(
      tempC:       temp,
      feelsLikeC:  feelsLike,
      humidity:    humidity,
      windKph:     wind,
      uvIndex:     uv,
      weatherCode: code,
      description: _wmoDescription(code, isDay),
      iconEmoji:   _wmoEmoji(code, isDay),
      city:        city,
      isRaining:   isRaining,
      isDaytime:   isDay,
      lat:         lat,
      lon:         lon,
      fetchedAt:   DateTime.now(),
      isFallback:  isFallback,
    );
  }

  // ── Public entry point ────────────────────────────────────
  static Future<WeatherResult> fetchWeather() async {
    final (:pos, :status) = await _requestLocation();

    if (pos != null) {
      final results = await Future.wait([
        _reverseGeocode(pos.latitude, pos.longitude),
        Future.value(null), // placeholder
      ]);
      final city = results[0] as String;

      try {
        final data = await _fetchFromOpenMeteo(
            pos.latitude, pos.longitude, city);
        if (data != null) {
          return WeatherResult(data: data, locationStatus: status);
        }
      } catch (e) {
        debugPrint('Weather fetch failed: $e');
      }
    }

    // Fallback: use default city (Lahore) with real weather data
    try {
      final data = await _fetchFromOpenMeteo(
          _defaultLat, _defaultLon, _defaultCity,
          isFallback: true);
      if (data != null) {
        return WeatherResult(
          data:           data,
          locationStatus: status,
          errorMessage:   _locationErrorMsg(status),
        );
      }
    } catch (_) {}

    // Complete failure
    return WeatherResult(
      data:           null,
      locationStatus: status,
      errorMessage:   'Could not fetch weather. Check your internet connection.',
    );
  }

  // ── WMO code → description ────────────────────────────────
  static String _wmoDescription(int code, bool isDay) => switch (code) {
    0              => isDay ? 'Clear Sky'      : 'Clear Night',
    1              => isDay ? 'Mostly Clear'   : 'Mostly Clear',
    2              => 'Partly Cloudy',
    3              => 'Overcast',
    45 || 48       => 'Foggy',
    51 || 53 || 55 => 'Light Drizzle',
    56 || 57       => 'Freezing Drizzle',
    61 || 63       => 'Light Rain',
    65             => 'Heavy Rain',
    66 || 67       => 'Freezing Rain',
    71 || 73       => 'Light Snow',
    75             => 'Heavy Snow',
    77             => 'Snow Grains',
    80 || 81       => 'Rain Showers',
    82             => 'Heavy Showers',
    85 || 86       => 'Snow Showers',
    95             => 'Thunderstorm',
    96 || 99       => 'Thunderstorm with Hail',
    _              => code <= 49 ? 'Foggy' : 'Unknown',
  };

  // ── WMO code → emoji ──────────────────────────────────────
  static String _wmoEmoji(int code, bool isDay) => switch (code) {
    0              => isDay ? '☀️'  : '🌙',
    1              => isDay ? '🌤️' : '🌙',
    2              => '⛅',
    3              => '☁️',
    45 || 48       => '🌫️',
    51 || 53 || 55 => '🌦️',
    56 || 57       => '🌨️',
    61 || 63       => '🌧️',
    65             => '🌧️',
    66 || 67       => '🌨️',
    71 || 73       => '❄️',
    75 || 77       => '❄️',
    80 || 81 || 82 => '🌧️',
    85 || 86       => '❄️',
    95             => '⛈️',
    96 || 99       => '⛈️',
    _              => '🌡️',
  };

  // ── Location error messages ───────────────────────────────
  static String? _locationErrorMsg(LocationStatus status) =>
      switch (status) {
        LocationStatus.serviceDisabled  =>
            'GPS is off — showing weather for Lahore',
        LocationStatus.permissionDenied  =>
            'Location permission denied — showing weather for Lahore',
        LocationStatus.permissionForever =>
            'Location permission blocked — enable in Settings',
        LocationStatus.timeout           =>
            'Location timed out — showing weather for Lahore',
        _                                => null,
      };

  // ── Open device location settings (for permissionForever) ─
  static Future<void> openLocationSettings() =>
      Geolocator.openLocationSettings();

  static Future<void> openAppSettings() =>
      Geolocator.openAppSettings();
}
