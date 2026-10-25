import 'package:auraf/auraf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeTelemetry Platform Channel Client Tests', () {
    test('readDeviceState returns valid DeviceState with fallback sensors', () async {
      final telemetry = NativeTelemetry.instance;
      final state = await telemetry.readDeviceState(
        contextSizeTokens: 2048,
        remainingBudgetUsd: 7.50,
      );

      expect(state.contextSizeTokens, equals(2048));
      expect(state.remainingBudgetUsd, equals(7.50));
      expect(state.batteryLevelPercent, greaterThan(0));
      expect(state.temperatureCelsius, greaterThan(0.0));
      expect(state.availableRamMb, greaterThan(0.0));
    });

    test('getDeviceModel returns non-empty model identifier', () async {
      final telemetry = NativeTelemetry.instance;
      final model = await telemetry.getDeviceModel();

      expect(model, isNotEmpty);
    });
  });
}

