import 'candidate_action.dart';
import 'device_state.dart';
import 'lyapunov_queue_state.dart';

/// Predicted metric profile for evaluating a [CandidateAction] in the Lyapunov formula.
class ActionEstimates {
  /// Estimated energy draw in mAh.
  final double estimatedEnergyMah;

  /// Estimated output quality score in [0.0, 1.0].
  final double estimatedQuality;

  /// Estimated monetary API cost in USD ($).
  final double estimatedCostUsd;

  /// Estimated turnaround latency in milliseconds (ms).
  final double estimatedLatencyMs;

  const ActionEstimates({
    required this.estimatedEnergyMah,
    required this.estimatedQuality,
    required this.estimatedCostUsd,
    required this.estimatedLatencyMs,
  });
}

/// Evaluation score for a single candidate action.
class ScoredAction {
  final CandidateAction action;
  final ActionEstimates estimates;
  final double lyapunovScore;

  const ScoredAction({
    required this.action,
    required this.estimates,
    required this.lyapunovScore,
  });
}

/// The optimization output containing the chosen action and candidate ranking.
class OptimizationResult {
  final CandidateAction selectedAction;
  final List<ScoredAction> evaluatedActions;
  final LyapunovQueueState queueState;
  final double vParam;
  final double alpha;

  const OptimizationResult({
    required this.selectedAction,
    required this.evaluatedActions,
    required this.queueState,
    required this.vParam,
    required this.alpha,
  });
}

/// Core Lyapunov Drift-plus-Penalty Stochastic Optimizer for AURAF.
///
/// Implements the decision rule formalized in `docs/MEASUREMENT_PROTOCOL_OUTLINE.md`:
///
/// $$a^*(t) = \arg\min_{a \in \mathcal{A}} \Bigg\{ Q_e(t) \cdot E(t, a) - Q_q(t) \cdot Q(t, a) + V \cdot \Big( \alpha \cdot \text{Cost}_{\text{api}}(a) + (1-\alpha) \cdot T_{\text{total}}(a) \Big) \Bigg\}$$
class LyapunovOptimizer {
  /// Control trade-off parameter $V > 0$.
  /// Higher values prioritize instant monetary cost and latency.
  /// Lower values prioritize strict adherence to battery and quality constraints.
  final double vParam;

  /// Relative balance between API cost and turnaround latency ($\alpha \in [0, 1]$).
  /// $\alpha = 0.5$ balances both equally.
  final double alpha;

  const LyapunovOptimizer({
    this.vParam = 10.0,
    this.alpha = 0.5,
  }) : assert(vParam > 0, 'V parameter must be strictly positive'),
       assert(alpha >= 0.0 && alpha <= 1.0, 'alpha must be in range [0, 1]');

  /// Computes the Lyapunov score for a candidate given current queue backlogs and estimates.
  double computeScore({
    required LyapunovQueueState queues,
    required ActionEstimates estimates,
  }) {
    // Normalization factors for dimension scaling:
    // Latency is normalized by 5000ms SLA baseline.
    // Cost is normalized by $0.05 baseline.
    final normalizedLatency = estimates.estimatedLatencyMs / 5000.0;
    final normalizedCost = estimates.estimatedCostUsd / 0.05;

    final penalty = (alpha * normalizedCost) + ((1.0 - alpha) * normalizedLatency);

    // Lyapunov Drift-plus-Penalty formula:
    // Q_e * E - Q_q * Q + V * Penalty
    return (queues.energyQueue * estimates.estimatedEnergyMah) -
        (queues.qualityQueue * estimates.estimatedQuality) +
        (vParam * penalty);
  }

  /// Evaluates all [candidates] against current [queues] and [deviceState]
  /// and selects the action that minimizes the drift-plus-penalty objective.
  OptimizationResult selectAction({
    required List<CandidateAction> candidates,
    required LyapunovQueueState queues,
    required DeviceState deviceState,
    Map<CandidateAction, ActionEstimates>? customEstimates,
  }) {
    if (candidates.isEmpty) {
      throw ArgumentError('Candidate actions list cannot be empty');
    }

    // If offline, only on-device candidates are eligible
    final eligibleCandidates = deviceState.networkCondition == NetworkCondition.offline
        ? candidates.where((c) => c.placement == ActionPlacement.device).toList()
        : candidates;

    final validCandidates = eligibleCandidates.isNotEmpty ? eligibleCandidates : candidates;

    final scored = <ScoredAction>[];

    for (final action in validCandidates) {
      final estimates = customEstimates?[action] ?? estimateProfile(action, deviceState);
      final score = computeScore(queues: queues, estimates: estimates);
      scored.add(ScoredAction(
        action: action,
        estimates: estimates,
        lyapunovScore: score,
      ));
    }

    // Sort ascending by score; lowest score is optimal
    scored.sort((a, b) => a.lyapunovScore.compareTo(b.lyapunovScore));

    return OptimizationResult(
      selectedAction: scored.first.action,
      evaluatedActions: scored,
      queueState: queues,
      vParam: vParam,
      alpha: alpha,
    );
  }

  /// Baseline profiling estimator for candidate actions when dynamic profiler is absent.
  ActionEstimates estimateProfile(CandidateAction action, DeviceState state) {
    if (action.placement == ActionPlacement.cloud) {
      // Cloud profile: High quality, low device battery consumption, but API cost and network latency
      final isHighLatency = state.networkCondition == NetworkCondition.highLatency;
      final isIntermittent = state.networkCondition == NetworkCondition.intermittent;

      double latency = 800.0 + (action.contextBudgetTokens * 0.15);
      if (isHighLatency) latency += 600.0;
      if (isIntermittent) latency += 1200.0;

      // API cost: ~$0.00015 per 1k input tokens (Gemini 1.5 Flash reference)
      final cost = (action.contextBudgetTokens / 1000.0) * 0.00015;
      const energy = 0.08; // Minimal device radio energy in mAh
      const quality = 0.95; // Uncompressed high capability model

      return ActionEstimates(
        estimatedEnergyMah: energy,
        estimatedQuality: quality,
        estimatedCostUsd: cost,
        estimatedLatencyMs: latency,
      );
    } else {
      // On-device profile: 0 cost, deterministic local latency, but higher battery drain
      final tokenFraction = action.contextBudgetTokens / 8192.0;
      final energy = 0.40 + (tokenFraction * 1.2); // mAh
      final latency = 400.0 + (action.contextBudgetTokens * 0.35); // ms
      final quality = 0.82; // SLM on-device accuracy baseline

      return ActionEstimates(
        estimatedEnergyMah: energy,
        estimatedQuality: quality,
        estimatedCostUsd: 0.0,
        estimatedLatencyMs: latency,
      );
    }
  }
}

