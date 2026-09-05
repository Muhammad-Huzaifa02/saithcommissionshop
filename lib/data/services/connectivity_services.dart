import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription? _sub;

  ConnectivityService() { _init(); }

  Future<void> _init() async {
    // Check initial state
    final result = await Connectivity().checkConnectivity();
    _isOnline = result.isNotEmpty && !result.contains(ConnectivityResult.none);
    notifyListeners();

    // Listen for changes
    _sub = Connectivity().onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result.isNotEmpty && !result.contains(ConnectivityResult.none);
      if (wasOnline != _isOnline) notifyListeners();
    });
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}