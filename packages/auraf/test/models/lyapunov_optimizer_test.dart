import 'package:auraf/auraf.dart';
import 'package:test/test.dart';

void main() {
  group('LyapunovOptimizer Decision Tests', () {
    const optimizer = LyapunovOptimizer(vParam: 10.0, alpha: 0.5);

    final cloudAction = CandidateAction.cloud(
      contextBudgetTokens: 2048,
      modelId: 'gemini-1.5-flash',
    );

    final deviceAction = CandidateAction.device(
      contextBudgetTokens: 2048,
      modelId: 'gemma-2-2b',
      quantization: 'int4',
    );

    final candidates = [cloudAction, deviceAction];

    test('forces on-device placement when network is offline', () {
      final offlineState = DeviceState.baseline(
        networkCondition: NetworkCondition.offline,
      );

      final queues = LyapunovQueueState.initial();

      final result = optimizer.selectAction(
        candidates: candidates,
        queues: queues,
        deviceState: offlineState,
      );

      expect(result.selectedAction.placement, equals(ActionPlacement.device));
    });

    test('shifts to cloud when device energy queue Qe is heavily backlogged', () {
      final stableState = DeviceState.baseline(
        networkCondition: NetworkCondition.stable,
      );

      // Huge energy deficit: device battery is in severe distress
      final criticalEnergyQueues = LyapunovQueueState(
        energyQueue: 50.0,
        qualityQueue: 0.0,
        targetEnergyMah: 1.0,
        targetQualityScore: 0.80,
      );

      final result = optimizer.selectAction(
        candidates: candidates,
        queues: criticalEnergyQueues,
        deviceState: stableState,
      );

      // The heavy local energy consumption gets penalized by Qe * E,
      // steering the optimizer to offload to cloud.
      expect(result.selectedAction.placement, equals(ActionPlacement.cloud));
    });

    test('evaluates mathematical ordering where lowest score wins', () {
      final state = DeviceState.baseline();
      final queues = LyapunovQueueState.initial();

      final result = optimizer.selectAction(
        candidates: candidates,
        queues: queues,
        deviceState: state,
      );

      final scores = result.evaluatedActions.map((e) => e.lyapunovScore).toList();
      for (int i = 0; i < scores.length - 1; i++) {
        expect(scores[i], lessThanOrEqualTo(scores[i + 1]));
      }

      expect(result.selectedAction, equals(result.evaluatedActions.first.action));
    });
  });
}

