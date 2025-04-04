import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService { // checks internet connectivity
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isConnected = true;

  void initialize(BuildContext context) {
    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      bool newConnectionStatus = results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi);

      if (_isConnected != newConnectionStatus) {
        _isConnected = newConnectionStatus;
        _showConnectivityDialog(context, _isConnected);
      }
    });
  }

  void _showConnectivityDialog(BuildContext context, bool isConnected) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (context) => AlertDialog(
        title: Text("Connectivity Status"),
        content: Text(
          isConnected ? "You are now online" : "No internet connection. Using cached data if available.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Dismiss only when OK is clicked
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void dispose() {
    _subscription?.cancel();
  }
}
class GlobalNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    Future.microtask(() => ConnectivityService().initialize(route.navigator!.context));
  }
}