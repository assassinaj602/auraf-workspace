import 'package:meta/meta.dart';

/// Network quality classification for the client device.
enum NetworkCondition {
  /// Low latency (<50ms RTT), high bandwidth, 0% packet loss (Wi-Fi / 5G).
  stable('stable'),

  /// Simulated high RTT (200ms - 500ms), 0% loss (cellular / satellite).
  highLatency('high_latency'),

  /// Fluctuating latency (100ms - 800ms) with 5% - 20% packet loss.
  intermittent('intermittent'),

  /// No connectivity (0 kbps).
  offline('offline');

  final String wireName;
  const NetworkCondition(this.wireName);

  static NetworkCondition fromString(String value) {
    return NetworkCondition.values.firstWhere(
      (e) => e.wireName == value || e.name == value,
      orElse: () => NetworkCondition.stable,
    );
  }
}

/// Represents the physical, computational, and environmental state
/// of the host device captured at inference scheduling time.
///
/// Corresponds to the schema defined in `docs/SHARED_DATA_CONTRACT.md`.
@immutable
class DeviceState {
  /// System timestamp when state was captured (epoch milliseconds).
  final int timestamp;

  /// Current battery level percentage (0 to 100).
  final int batteryLevelPercent;

  /// Instantaneous battery current draw in milliamperes (mA).
  /// Typically negative when discharging, positive when charging.
  final double batteryCurrentMa;

  /// Current battery or SoC thermal sensor reading in degrees Celsius (°C).
  final double temperatureCelsius;

  /// Total unreserved system memory available to the app in megabytes (MB).
  final double availableRamMb;

  /// Peak resident memory allocated by the application so far in megabytes (MB).
  final double peakMemoryMb;

  /// Current network connectivity state.
  final NetworkCondition networkCondition;

  /// Context length of the incoming prompt in tokens.
  final int contextSizeTokens;

  /// Remaining financial budget allocated for remote cloud API calls ($ USD).
  final double remainingBudgetUsd;

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

  /// Creates a [DeviceState] instance with default / placeholder baseline values.
  factory DeviceState.baseline({
    int? timestamp,
    int batteryLevelPercent = 85,
    double batteryCurrentMa = -350.0,
    double temperatureCelsius = 31.5,
    double availableRamMb = 2048.0,
    double peakMemoryMb = 350.0,
    NetworkCondition networkCondition = NetworkCondition.stable,
    int contextSizeTokens = 512,
    double remainingBudgetUsd = 10.0,
  }) {
    return DeviceState(
      timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      batteryLevelPercent: batteryLevelPercent,
      batteryCurrentMa: batteryCurrentMa,
      temperatureCelsius: temperatureCelsius,
      availableRamMb: availableRamMb,
      peakMemoryMb: peakMemoryMb,
      networkCondition: networkCondition,
      contextSizeTokens: contextSizeTokens,
      remainingBudgetUsd: remainingBudgetUsd,
    );
  }

  /// Deserializes a map using keys from `docs/SHARED_DATA_CONTRACT.md`.
  factory DeviceState.fromMap(Map<String, dynamic> map) {
    return DeviceState(
      timestamp: (map['timestamp'] as num).toInt(),
      batteryLevelPercent: (map['battery_level_percent'] as num).toInt(),
      batteryCurrentMa: (map['battery_current_ma'] as num).toDouble(),
      temperatureCelsius: (map['temperature_celsius'] as num).toDouble(),
      availableRamMb: (map['available_ram_mb'] as num).toDouble(),
      peakMemoryMb: (map['peak_memory_mb'] as num).toDouble(),
      networkCondition: NetworkCondition.fromString(map['network_condition'] as String),
      contextSizeTokens: (map['context_size_tokens'] as num).toInt(),
      remainingBudgetUsd: (map['remaining_budget_usd'] as num).toDouble(),
    );
  }

  /// Serializes into a map matching SQLite columns and JSON conventions.
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'battery_level_percent': batteryLevelPercent,
      'battery_current_ma': batteryCurrentMa,
      'temperature_celsius': temperatureCelsius,
      'available_ram_mb': availableRamMb,
      'peak_memory_mb': peakMemoryMb,
      'network_condition': networkCondition.wireName,
      'context_size_tokens': contextSizeTokens,
      'remaining_budget_usd': remainingBudgetUsd,
    };
  }

  /// Copies this instance with optional updated fields.
  DeviceState copyWith({
    int? timestamp,
    int? batteryLevelPercent,
    double? batteryCurrentMa,
    double? temperatureCelsius,
    double? availableRamMb,
    double? peakMemoryMb,
    NetworkCondition? networkCondition,
    int? contextSizeTokens,
    double? remainingBudgetUsd,
  }) {
    return DeviceState(
      timestamp: timestamp ?? this.timestamp,
      batteryLevelPercent: batteryLevelPercent ?? this.batteryLevelPercent,
      batteryCurrentMa: batteryCurrentMa ?? this.batteryCurrentMa,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      availableRamMb: availableRamMb ?? this.availableRamMb,
      peakMemoryMb: peakMemoryMb ?? this.peakMemoryMb,
      networkCondition: networkCondition ?? this.networkCondition,
      contextSizeTokens: contextSizeTokens ?? this.contextSizeTokens,
      remainingBudgetUsd: remainingBudgetUsd ?? this.remainingBudgetUsd,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceState &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          batteryLevelPercent == other.batteryLevelPercent &&
          batteryCurrentMa == other.batteryCurrentMa &&
          temperatureCelsius == other.temperatureCelsius &&
          availableRamMb == other.availableRamMb &&
          peakMemoryMb == other.peakMemoryMb &&
          networkCondition == other.networkCondition &&
          contextSizeTokens == other.contextSizeTokens &&
          remainingBudgetUsd == other.remainingBudgetUsd;

  @override
  int get hashCode =>
      timestamp.hashCode ^
      batteryLevelPercent.hashCode ^
      batteryCurrentMa.hashCode ^
      temperatureCelsius.hashCode ^
      availableRamMb.hashCode ^
      peakMemoryMb.hashCode ^
      networkCondition.hashCode ^
      contextSizeTokens.hashCode ^
      remainingBudgetUsd.hashCode;

  @override
  String toString() {
    return 'DeviceState('
        'time: $timestamp, '
        'batt: $batteryLevelPercent%, '
        'curr: ${batteryCurrentMa}mA, '
        'temp: $temperatureCelsius°C, '
        'ram: ${availableRamMb}MB, '
        'net: ${networkCondition.wireName}, '
        'tokens: $contextSizeTokens, '
        'budget: \$$remainingBudgetUsd'
        ')';
  }
}
