import 'dart:convert';
import 'package:meta/meta.dart';

/// Represents a standardized benchmark prompt workload item.
///
/// Encapsulates prompt text, target token length tier (512, 2048, 8192),
/// dataset split partition, and task metadata.
@immutable
class BenchmarkPrompt {
  /// Unique identifier (e.g. `prof_05k_01`).
  final String id;

  /// Partition split: `'profiling'`, `'validation'`, or `'test'`.
  final String split;

  /// Target token length tier (512, 2048, or 8192 tokens).
  final int targetTokens;

  /// Benchmark category (e.g. `'code_optimization'`, `'mathematical_reasoning'`).
  final String category;

  /// Brief human-readable description of the prompt task.
  final String description;

  /// The raw prompt text payload dispatched to inference engines.
  final String prompt;

  /// Expected completion token count for throughput benchmarking.
  final int expectedResponseTokens;

  const BenchmarkPrompt({
    required this.id,
    required this.split,
    required this.targetTokens,
    required this.category,
    required this.description,
    required this.prompt,
    required this.expectedResponseTokens,
  });

  /// Deserializes a map from JSON asset.
  factory BenchmarkPrompt.fromMap(Map<String, dynamic> map) {
    return BenchmarkPrompt(
      id: map['id'] as String,
      split: map['split'] as String,
      targetTokens: (map['target_tokens'] as num).toInt(),
      category: map['category'] as String,
      description: map['description'] as String,
      prompt: map['prompt'] as String,
      expectedResponseTokens: (map['expected_response_tokens'] as num).toInt(),
    );
  }

  /// Serializes into a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'split': split,
      'target_tokens': targetTokens,
      'category': category,
      'description': description,
      'prompt': prompt,
      'expected_response_tokens': expectedResponseTokens,
    };
  }

  /// Parses a complete JSON string into a list of [BenchmarkPrompt] items.
  static List<BenchmarkPrompt> parseList(String jsonString) {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! List) {
      throw const FormatException('Expected JSON array of benchmark prompts');
    }
    return decoded
        .map((dynamic item) => BenchmarkPrompt.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// Filters prompts matching a specific split (`profiling`, `validation`, `test`).
  static List<BenchmarkPrompt> filterBySplit(List<BenchmarkPrompt> prompts, String split) {
    return prompts.where((p) => p.split.toLowerCase() == split.toLowerCase()).toList();
  }

  /// Filters prompts matching a target token budget (e.g. 512, 2048, 8192).
  static List<BenchmarkPrompt> filterByTokens(List<BenchmarkPrompt> prompts, int targetTokens) {
    return prompts.where((p) => p.targetTokens == targetTokens).toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BenchmarkPrompt &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          split == other.split &&
          targetTokens == other.targetTokens;

  @override
  int get hashCode => id.hashCode ^ split.hashCode ^ targetTokens.hashCode;

  @override
  String toString() => 'BenchmarkPrompt($id, split: $split, ${targetTokens}t, cat: $category)';
}

