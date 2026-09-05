import 'dart:async';
import 'package:flutter/material.dart';
import 'package:saithcommissionshop/data/services/weather_service.dart';

enum WeatherState { idle, loading, loaded, error }

class WeatherProvider extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────
  WeatherData?    _data;
  WeatherState    _state          = WeatherState.idle;
  LocationStatus  _locationStatus = LocationStatus.unknown;
  String?         _errorMessage;
  DateTime?       _lastFetch;
  Timer?          _autoRefreshTimer;

  // ── Getters ───────────────────────────────────────────────
  WeatherData?   get data           => _data;
  WeatherState   get state          => _state;
  LocationStatus get locationStatus => _locationStatus;
  String?        get errorMessage   => _errorMessage;
  bool           get isLoading      => _state == WeatherState.loading;
  bool           get hasData        => _data != null;
  bool           get locationBlocked =>
      _locationStatus == LocationStatus.permissionForever;
  bool           get gpsOff        =>
      _locationStatus == LocationStatus.serviceDisabled;

  String? get locationWarning {
    if (_data == null) return null;
    if (!_data!.isFallback) return null;
    return _errorMessage;
  }

  WeatherProvider() {
    // Initial fetch
    fetch();

    // Start auto-refresh every 15 minutes
    _autoRefreshTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => fetch(forceRefresh: true),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  // ── Fetch ─────────────────────────────────────────────────
  Future<void> fetch({bool forceRefresh = false}) async {
    // Skip if cache is still fresh (< 10 min) and not forced
    if (!forceRefresh && hasData && _lastFetch != null) {
      final age = DateTime.now().difference(_lastFetch!).inMinutes;
      if (age < 10) return;
    }

    _state = WeatherState.loading;
    notifyListeners();

    try {
      final result = await WeatherService.fetchWeather()
          .timeout(const Duration(seconds: 20));

      _locationStatus = result.locationStatus;
      _errorMessage   = result.errorMessage;

      if (result.data != null) {
        _data      = result.data;
        _state     = WeatherState.loaded;
        _lastFetch = DateTime.now();
      } else {
        _state = WeatherState.error;
      }
    } catch (e) {
      debugPrint('WeatherProvider fetch error: $e');
      _state = WeatherState.error;
      _errorMessage = 'Connection timeout. Try again.';
    }

    notifyListeners();
  }

  void refresh() => fetch(forceRefresh: true);

  Future<void> openLocationSettings() =>
      WeatherService.openLocationSettings();

  Future<void> openAppSettings() =>
      WeatherService.openAppSettings();
}
