import 'package:flutter/services.dart';

/// The network states defined by the shared M2 data contract.
enum NetworkCondition { stable, highLatency, intermittent, offline }

extension NetworkConditionValue on NetworkCondition {
  String get value => switch (this) {
    NetworkCondition.stable => 'stable',
    NetworkCondition.highLatency => 'high_latency',
    NetworkCondition.intermittent => 'intermittent',
    NetworkCondition.offline => 'offline',
  };

  static NetworkCondition parse(String value) => switch (value) {
    'stable' => NetworkCondition.stable,
    'high_latency' => NetworkCondition.highLatency,
    'intermittent' => NetworkCondition.intermittent,
    'offline' => NetworkCondition.offline,
    _ => throw FormatException('Unknown network condition: $value'),
  };
}

class DeviceState {
  const DeviceState({
    required this.timestamp,
    required this.batteryLevelPercent,
    required this.batteryCurrentMa,
    required this.temperatureCelsius,
    required this.availableRamMb,
    required this.peakMemoryMb,
    required this.networkCondition,
    required this.contextSizeTokens,
    required this.remainingBudgetUsd,
  });

  final int timestamp;
  final int batteryLevelPercent;
  final double batteryCurrentMa;
  final double temperatureCelsius;
  final double availableRamMb;
  final double peakMemoryMb;
  final String networkCondition;
  final int contextSizeTokens;
  final double remainingBudgetUsd;

  factory DeviceState.fromMap(Map<Object?, Object?> map) {
    int integer(String key) =>
        (map[key] as num?)?.toInt() ??
        (throw FormatException('Missing integer telemetry field: $key'));
    double number(String key) =>
        (map[key] as num?)?.toDouble() ??
        (throw FormatException('Missing numeric telemetry field: $key'));
    String text(String key) =>
        map[key] as String? ??
        (throw FormatException('Missing string telemetry field: $key'));

    final network = text('network_condition');
    NetworkConditionValue.parse(network);
    return DeviceState(
      timestamp: integer('timestamp'),
      batteryLevelPercent: integer('battery_level_percent'),
      batteryCurrentMa: number('battery_current_ma'),
      temperatureCelsius: number('temperature_celsius'),
      availableRamMb: number('available_ram_mb'),
      peakMemoryMb: number('peak_memory_mb'),
      networkCondition: network,
      contextSizeTokens: integer('context_size_tokens'),
      remainingBudgetUsd: number('remaining_budget_usd'),
    );
  }
}

/// Samples Android telemetry through the native AURAF telemetry channel.
class DeviceStateCollector {
  DeviceStateCollector({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const String _channelName = 'com.auraf.runtime/telemetry';
  final MethodChannel _channel;

  Future<DeviceState> sample({
    required int contextSizeTokens,
    required double remainingBudgetUsd,
  }) async {
    if (contextSizeTokens < 0) {
      throw ArgumentError.value(
        contextSizeTokens,
        'contextSizeTokens',
        'must be non-negative',
      );
    }
    if (remainingBudgetUsd < 0) {
      throw ArgumentError.value(
        remainingBudgetUsd,
        'remainingBudgetUsd',
        'must be non-negative',
      );
    }

    final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
      'sampleDeviceState',
      <String, Object>{
        'context_size_tokens': contextSizeTokens,
        'remaining_budget_usd': remainingBudgetUsd,
      },
    );
    if (raw == null) {
      throw StateError('Telemetry platform returned no device state');
    }
    return DeviceState.fromMap(raw);
  }
}
