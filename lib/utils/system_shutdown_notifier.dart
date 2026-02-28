import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:umivpn/utils/darwin_host_api.g.dart';
import 'package:umivpn/main.dart';
import 'package:umivpn/utils/logger.dart';

/// Service to handle system shutdown notifications on macOS
class SystemShutdownNotifier extends DarwinFlutterApi {
  static SystemShutdownNotifier? _instance;
  static SystemShutdownNotifier get instance => _instance ??= SystemShutdownNotifier._();
  
  SystemShutdownNotifier._();
  
  final List<VoidCallback> _shutdownCallbacks = [];
  final List<VoidCallback> _restartCallbacks = [];
  final List<VoidCallback> _sleepCallbacks = [];
  
  bool _isInitialized = false;
  
  /// Initialize the shutdown notifier (call this once in main.dart)
  Future<void> initialize() async {
    if (!Platform.isMacOS || _isInitialized) return;
    
    try {
      // Set up the Flutter API to receive callbacks from native side
      DarwinFlutterApi.setUp(this);
      
      // Set up native side to listen for system notifications
      await darwinHostApi?.setupShutdownNotification();
      
      _isInitialized = true;
      logger.i('System shutdown notifier initialized');
    } catch (e) {
      logger.e('Failed to initialize system shutdown notifier: $e');
    }
  }
  
  /// Register a callback to be called when system is about to shutdown
  void onShutdown(VoidCallback callback) {
    _shutdownCallbacks.add(callback);
  }
  
  /// Register a callback to be called when system is about to restart
  void onRestart(VoidCallback callback) {
    _restartCallbacks.add(callback);
  }
  
  /// Register a callback to be called when system is about to sleep
  void onSleep(VoidCallback callback) {
    _sleepCallbacks.add(callback);
  }
  
  /// Remove a shutdown callback
  void removeShutdownCallback(VoidCallback callback) {
    _shutdownCallbacks.remove(callback);
  }
  
  /// Remove a restart callback
  void removeRestartCallback(VoidCallback callback) {
    _restartCallbacks.remove(callback);
  }
  
  /// Remove a sleep callback
  void removeSleepCallback(VoidCallback callback) {
    _sleepCallbacks.remove(callback);
  }
  
  /// Clear all callbacks
  void clearAllCallbacks() {
    _shutdownCallbacks.clear();
    _restartCallbacks.clear();
    _sleepCallbacks.clear();
  }
  
  // Implementation of DarwinFlutterApi methods
  @override
  void onSystemWillShutdown() {
    logger.i('System will shutdown - notifying ${_shutdownCallbacks.length} callbacks');
    
    for (final callback in _shutdownCallbacks) {
      try {
        callback();
      } catch (e) {
        logger.e('Error in shutdown callback: $e');
      }
    }
  }
  
  @override
  void onSystemWillRestart() {
    logger.i('System will restart - notifying ${_restartCallbacks.length} callbacks');
    
    for (final callback in _restartCallbacks) {
      try {
        callback();
      } catch (e) {
        logger.e('Error in restart callback: $e');
      }
    }
  }
  
  @override
  void onSystemWillSleep() {
    logger.i('System will sleep - notifying ${_sleepCallbacks.length} callbacks');
    
    for (final callback in _sleepCallbacks) {
      try {
        callback();
      } catch (e) {
        logger.e('Error in sleep callback: $e');
      }
    }
  }
}
