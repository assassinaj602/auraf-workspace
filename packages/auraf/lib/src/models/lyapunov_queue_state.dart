import 'dart:math' as math;
import 'package:meta/meta.dart';

/// Tracks the mathematical virtual deficit queues for Lyapunov optimization.
///
/// Under the Lyapunov Drift-plus-Penalty framework:
/// - [energyQueue] ($Q_e$): tracks cumulative energy deficit beyond target.
/// - [qualityQueue] ($Q_q$): tracks cumulative quality deficit below target.
///
/// Keeping these virtual queues stable (bounded) guarantees that the long-term
/// average energy and quality constraints are strictly satisfied.
@immutable
class LyapunovQueueState {
  /// Current virtual energy deficit backlog ($Q_e \ge 0$).
  final double energyQueue;

  /// Current virtual quality deficit backlog ($Q_q \ge 0$).
  final double qualityQueue;

  /// Per-request energy consumption constraint target ($E_{\text{target}}$ in mAh).
  final double targetEnergyMah;

  /// Per-request minimum output quality constraint target ($Q_{\text{target}} \in [0, 1]$).
  final double targetQualityScore;

  const LyapunovQueueState({
    required this.energyQueue,
    required this.qualityQueue,
    required this.targetEnergyMah,
    required this.targetQualityScore,
  });

  /// Initializes queues at baseline (empty deficit, $Q_e = 0, Q_q = 0$).
  factory LyapunovQueueState.initial({
    double targetEnergyMah = 1.0,
    double targetQualityScore = 0.80,
  }) {
    return LyapunovQueueState(
      energyQueue: 0.0,
      qualityQueue: 0.0,
      targetEnergyMah: targetEnergyMah,
      targetQualityScore: targetQualityScore,
    );
  }

  /// Calculates the quadratic Lyapunov function value:
  ///
  /// $$L(\mathbf{\Theta}(t)) = \frac{1}{2} \Big( Q_e(t)^2 + Q_q(t)^2 \Big)$$
  double get lyapunovValue =>
      0.5 * (math.pow(energyQueue, 2) + math.pow(qualityQueue, 2));

  /// Computes the queue state for the next time slot $(t+1)$ given the observed
  /// energy consumption and quality score from the current action.
  ///
  /// Mathematical update rules:
  /// $$Q_e(t+1) = \max \Big[ Q_e(t) + E(t) - E_{\text{target}}, \; 0 \Big]$$
  /// $$Q_q(t+1) = \max \Big[ Q_q(t) + Q_{\text{target}} - Q(t), \; 0 \Big]$$
  LyapunovQueueState update({
    required double energyMah,
    required double qualityScore,
  }) {
    final nextEnergyQueue = math.max(
      0.0,
      energyQueue + energyMah - targetEnergyMah,
    );

    final nextQualityQueue = math.max(
      0.0,
      qualityQueue + targetQualityScore - qualityScore,
    );

    return LyapunovQueueState(
      energyQueue: nextEnergyQueue,
      qualityQueue: nextQualityQueue,
      targetEnergyMah: targetEnergyMah,
      targetQualityScore: targetQualityScore,
    );
  }

  /// Deserializes from map.
  factory LyapunovQueueState.fromMap(Map<String, dynamic> map) {
    return LyapunovQueueState(
      energyQueue: (map['energy_queue'] as num).toDouble(),
      qualityQueue: (map['quality_queue'] as num).toDouble(),
      targetEnergyMah: (map['target_energy_mah'] as num).toDouble(),
      targetQualityScore: (map['target_quality_score'] as num).toDouble(),
    );
  }

  /// Serializes to map.
  Map<String, dynamic> toMap() {
    return {
      'energy_queue': energyQueue,
      'quality_queue': qualityQueue,
      'target_energy_mah': targetEnergyMah,
      'target_quality_score': targetQualityScore,
      'lyapunov_value': lyapunovValue,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyapunovQueueState &&
          runtimeType == other.runtimeType &&
          energyQueue == other.energyQueue &&
          qualityQueue == other.qualityQueue &&
          targetEnergyMah == other.targetEnergyMah &&
          targetQualityScore == other.targetQualityScore;

  @override
  int get hashCode =>
      energyQueue.hashCode ^
      qualityQueue.hashCode ^
      targetEnergyMah.hashCode ^
      targetQualityScore.hashCode;

  @override
  String toString() {
    return 'LyapunovQueueState('
        'Q_e: ${energyQueue.toStringAsFixed(3)}, '
        'Q_q: ${qualityQueue.toStringAsFixed(3)}, '
        'L(Θ): ${lyapunovValue.toStringAsFixed(3)}'
        ')';
  }
}
