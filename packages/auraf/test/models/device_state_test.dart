import 'package:auraf/auraf.dart';
import 'package:test/test.dart';

void main() {
  group('DeviceState Model Tests', () {
    test('serializes to and from map cleanly matching contract', () {
      final original = DeviceState(
        timestamp: 1730000000000,
        batteryLevelPercent: 78,
        batteryCurrentMa: -420.5,
        temperatureCelsius: 34.2,
        availableRamMb: 1950.0,
        peakMemoryMb: 410.0,
        networkCondition: NetworkCondition.highLatency,
        contextSizeTokens: 2048,
        remainingBudgetUsd: 4.85,
      );

      final map = original.toMap();

      expect(map['timestamp'], equals(1730000000000));
      expect(map['battery_level_percent'], equals(78));
      expect(map['battery_current_ma'], equals(-420.5));
      expect(map['temperature_celsius'], equals(34.2));
      expect(map['available_ram_mb'], equals(1950.0));
      expect(map['peak_memory_mb'], equals(410.0));
      expect(map['network_condition'], equals('high_latency'));
      expect(map['context_size_tokens'], equals(2048));
      expect(map['remaining_budget_usd'], equals(4.85));

      final restored = DeviceState.fromMap(map);
      expect(restored, equals(original));
    });

    test('NetworkCondition parsing handles wire names and defaults', () {
      expect(NetworkCondition.fromString('stable'), equals(NetworkCondition.stable));
      expect(NetworkCondition.fromString('high_latency'), equals(NetworkCondition.highLatency));
      expect(NetworkCondition.fromString('intermittent'), equals(NetworkCondition.intermittent));
      expect(NetworkCondition.fromString('offline'), equals(NetworkCondition.offline));
      expect(NetworkCondition.fromString('unknown'), equals(NetworkCondition.stable));
    });

    test('baseline factory provides valid operational defaults', () {
      final baseline = DeviceState.baseline();
      expect(baseline.batteryLevelPercent, equals(85));
      expect(baseline.networkCondition, equals(NetworkCondition.stable));
      expect(baseline.remainingBudgetUsd, equals(10.0));
    });
  });
}
