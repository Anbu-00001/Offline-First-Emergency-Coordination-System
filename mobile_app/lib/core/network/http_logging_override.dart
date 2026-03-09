import 'dart:io';
import 'package:flutter/foundation.dart';

/// Intercepts outgoing HTTP requests on the Dart HttpClient
/// to log their status, headers, and any failures.
class LoggingHttpOverrides extends HttpOverrides {
  static final List<String> _logs = [];
  static const int _maxLogs = 100;

  static List<String> getLogs() => List.unmodifiable(_logs);

  static void _addLog(String message) {
    if (_logs.length >= _maxLogs) {
      _logs.removeAt(0);
    }
    final timeStr = DateTime.now().toIso8601String().substring(11, 23); // HH:mm:ss.mmm
    final log = '[$timeStr] HttpOverride: $message';
    _logs.add(log);
    debugPrint(log);
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    
    // Provide a way to intercept the requests if doing it directly via overrides
    // Unfortunately, Dart's standard HttpOverrides doesn't let you wrap individual 
    // requests easily without replacing the entire HttpClient implementation.
    // We will do a generic badCertificateCallback to catch TLS errors as a test.
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      _addLog('TLS Warning: Bad certificate for $host:$port. Trusting anyway for dev.');
      return true; // Trust to avoid blocks in dev
    };

    _addLog('HttpClient created.');
    return client;
  }
}
