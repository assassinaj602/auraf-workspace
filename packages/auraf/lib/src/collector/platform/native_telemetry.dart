import 'package:flutter/services.dart';
import '../../models/device_state.dart';

/// Dart client for the Android Native Telemetry Platform Channel.
///
/// Dispatches calls to `com.auraf/telemetry` to read low-level hardware
/// sensors: battery current in mA, temperature in °C, and system RAM in MB.
///
/// Automatically provides simulated baseline telemetry when executed
/// in unit test runners or desktop platforms without native Android channel bindings.
class NativeTelemetry {
  static const MethodChannel _channel = MethodChannel('com.auraf/telemetry');

  // Singleton instance
  static final NativeTelemetry instance = NativeTelemetry._internal();
  NativeTelemetry._internal();

  /// Reads raw sensor telemetry map from the native Android OS.
  Future<Map<String, dynamic>> readRawSensors() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('readDeviceSensors');
      if (result != null) {
        return result;
      }
    } catch (_) {
      // Fallback for non-Android platforms, test environments, or channel errors
    }

    // Fallback baseline for non-Android environments or test suites
    return _simulatedRawSensors();
  }

  /// Convenience method that reads native sensors and parses directly into a [DeviceState] object.
  Future<DeviceState> readDeviceState({
    int contextSizeTokens = 512,
    double remainingBudgetUsd = 10.0,
  }) async {
    final raw = await readRawSensors();

    return DeviceState(
      timestamp: (raw['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      batteryLevelPercent: (raw['battery_level_percent'] as num?)?.toInt() ?? 80,
      batteryCurrentMa: (raw['battery_current_ma'] as num?)?.toDouble() ?? -350.0,
      temperatureCelsius: (raw['temperature_celsius'] as num?)?.toDouble() ?? 32.0,
      availableRamMb: (raw['available_ram_mb'] as num?)?.toDouble() ?? 2048.0,
      peakMemoryMb: (raw['peak_memory_mb'] as num?)?.toDouble() ?? 320.0,
      networkCondition: NetworkCondition.fromString(
        (raw['network_condition'] as String?) ?? 'stable',
      ),
      contextSizeTokens: contextSizeTokens,
      remainingBudgetUsd: remainingBudgetUsd,
    );
  }

  /// Queries the hardware model string from native Android Build API.
  Future<String> getDeviceModel() async {
    try {
      final model = await _channel.invokeMethod<String>('getDeviceModel');
      if (model != null && model.isNotEmpty) {
        return model;
      }
    } catch (_) {
      // Fallback
    }
    return 'Android_Simulated_Device';
  }

  Map<String, dynamic> _simulatedRawSensors() {
    return {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'battery_level_percent': 82,
      'battery_current_ma': -320.0,
      'temperature_celsius': 31.8,
      'available_ram_mb': 2150.0,
      'total_ram_mb': 8192.0,
      'peak_memory_mb': 285.4,
      'network_condition': 'stable',
      'device_model': 'Android_Simulated_Device',
    };
  }
}

