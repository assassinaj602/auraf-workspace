import 'package:auraf/auraf.dart';
import 'package:test/test.dart';

void main() {
  group('LyapunovQueueState Mathematical Tests', () {
    test('initial state begins at zero backlog', () {
      final initial = LyapunovQueueState.initial(
        targetEnergyMah: 1.0,
        targetQualityScore: 0.80,
      );

      expect(initial.energyQueue, equals(0.0));
      expect(initial.qualityQueue, equals(0.0));
      expect(initial.lyapunovValue, equals(0.0));
    });

    test('accumulates deficit when consumption exceeds target', () {
      final initial = LyapunovQueueState.initial(
        targetEnergyMah: 1.0,
        targetQualityScore: 0.80,
      );

      // Energy 1.5 mAh (0.5 deficit), Quality 0.70 (0.10 deficit)
      final step1 = initial.update(energyMah: 1.5, qualityScore: 0.70);

      expect(step1.energyQueue, closeTo(0.5, 1e-4));
      expect(step1.qualityQueue, closeTo(0.10, 1e-4));

      // L(Θ) = 0.5 * (0.5^2 + 0.1^2) = 0.5 * (0.25 + 0.01) = 0.13
      expect(step1.lyapunovValue, closeTo(0.13, 1e-4));
    });

    test('recovers and drains queue towards zero when consumption is low', () {
      final stateWithBacklog = LyapunovQueueState(
        energyQueue: 0.4,
        qualityQueue: 0.3,
        targetEnergyMah: 1.0,
        targetQualityScore: 0.80,
      );

      // Next run uses only 0.2 mAh (0.8 surplus) and gives high quality 0.95 (0.15 surplus)
      final drained = stateWithBacklog.update(energyMah: 0.2, qualityScore: 0.95);

      // max(0, 0.4 + 0.2 - 1.0) = max(0, -0.4) = 0.0
      expect(drained.energyQueue, equals(0.0));
      // max(0, 0.3 + 0.80 - 0.95) = max(0, 0.15) = 0.15
      expect(drained.qualityQueue, closeTo(0.15, 1e-4));
    });

    test('queues never become negative', () {
      final state = LyapunovQueueState.initial();
      final updated = state.update(energyMah: 0.01, qualityScore: 1.0);

      expect(updated.energyQueue, greaterThanOrEqualTo(0.0));
      expect(updated.qualityQueue, greaterThanOrEqualTo(0.0));
    });
  });
}
