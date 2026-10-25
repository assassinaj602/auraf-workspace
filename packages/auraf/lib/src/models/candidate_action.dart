import 'package:meta/meta.dart';

/// Execution target placement for an inference request.
enum ActionPlacement {
  /// Offload inference to remote cloud LLM endpoint.
  cloud('cloud'),

  /// Execute inference locally on device via edge runtime.
  device('device');

  final String wireName;
  const ActionPlacement(this.wireName);

  static ActionPlacement fromString(String value) {
    return ActionPlacement.values.firstWhere(
      (e) => e.wireName == value || e.name == value,
      orElse: () => ActionPlacement.cloud,
    );
  }
}

/// Represents an inference scheduling decision evaluated by the
/// Lyapunov optimizer or benchmark permutation harness.
///
/// Corresponds to the schema defined in `docs/SHARED_DATA_CONTRACT.md`.
@immutable
class CandidateAction {
  /// Target context length limit in tokens after token pruning.
  final int contextBudgetTokens;

  /// Target placement (`cloud` or `device`).
  final ActionPlacement placement;

  /// Model identifier (e.g. `gemini-1.5-flash`, `gemma-2-2b`).
  final String modelId;

  /// Weight quantization scheme (`none`, `int4`, `int8`, `fp16`).
  final String quantization;

  /// Number of CPU/NPU inference execution threads.
  final int threadCount;

  const CandidateAction({
    required this.contextBudgetTokens,
    required this.placement,
    required this.modelId,
    this.quantization = 'none',
    this.threadCount = 4,
  });

  /// Factory helper for creating a cloud action.
  factory CandidateAction.cloud({
    required int contextBudgetTokens,
    String modelId = 'gemini-1.5-flash',
  }) {
    return CandidateAction(
      contextBudgetTokens: contextBudgetTokens,
      placement: ActionPlacement.cloud,
      modelId: modelId,
      quantization: 'none',
      threadCount: 1,
    );
  }

  /// Factory helper for creating an on-device action.
  factory CandidateAction.device({
    required int contextBudgetTokens,
    String modelId = 'gemma-2-2b',
    String quantization = 'int4',
    int threadCount = 4,
  }) {
    return CandidateAction(
      contextBudgetTokens: contextBudgetTokens,
      placement: ActionPlacement.device,
      modelId: modelId,
      quantization: quantization,
      threadCount: threadCount,
    );
  }

  /// Deserializes from map.
  factory CandidateAction.fromMap(Map<String, dynamic> map) {
    return CandidateAction(
      contextBudgetTokens: (map['context_budget_tokens'] as num).toInt(),
      placement: ActionPlacement.fromString(map['placement'] as String),
      modelId: map['model_id'] as String,
      quantization: (map['quantization'] as String?) ?? 'none',
      threadCount: (map['thread_count'] as num?)?.toInt() ?? 4,
    );
  }

  /// Serializes to map.
  Map<String, dynamic> toMap() {
    return {
      'context_budget_tokens': contextBudgetTokens,
      'placement': placement.wireName,
      'model_id': modelId,
      'quantization': quantization,
      'thread_count': threadCount,
    };
  }

  /// Copies this instance with optional updated fields.
  CandidateAction copyWith({
    int? contextBudgetTokens,
    ActionPlacement? placement,
    String? modelId,
    String? quantization,
    int? threadCount,
  }) {
    return CandidateAction(
      contextBudgetTokens: contextBudgetTokens ?? this.contextBudgetTokens,
      placement: placement ?? this.placement,
      modelId: modelId ?? this.modelId,
      quantization: quantization ?? this.quantization,
      threadCount: threadCount ?? this.threadCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CandidateAction &&
          runtimeType == other.runtimeType &&
          contextBudgetTokens == other.contextBudgetTokens &&
          placement == other.placement &&
          modelId == other.modelId &&
          quantization == other.quantization &&
          threadCount == other.threadCount;

  @override
  int get hashCode =>
      contextBudgetTokens.hashCode ^
      placement.hashCode ^
      modelId.hashCode ^
      quantization.hashCode ^
      threadCount.hashCode;

  @override
  String toString() {
    return 'CandidateAction('
        'placement: ${placement.wireName}, '
        'model: $modelId, '
        'budget: ${contextBudgetTokens}t, '
        'quant: $quantization, '
        'threads: $threadCount'
        ')';
  }
}

