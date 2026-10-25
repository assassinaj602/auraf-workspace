import 'package:meta/meta.dart';

/// Represents a single benchmark trial execution record.
///
/// Encapsulates performance, energy, thermal, cost, and quality telemetry.
/// Maps 1:1 to the local SQLite table `benchmark_records` and the CSV export
/// defined in `docs/SHARED_DATA_CONTRACT.md`.
@immutable
class BenchmarkRecord {
  /// Strict CSV header line matching Section 5 of docs/SHARED_DATA_CONTRACT.md.
  static const String csvHeader =
      'run_id,timestamp,device_model,network_condition,context_budget,'
      'placement,ttft_ms,total_latency_ms,tokens_per_sec,energy_mah,'
      'peak_memory_mb,temp_celsius,cost_usd,quality_score,constraint_violated';

  /// Unique identifier (UUID v4) for the benchmark execution.
  final String runId;

  /// Timestamp in milliseconds since Unix epoch when test commenced.
  final int timestamp;

  /// Hardware and OS descriptor of the test device (e.g. `Pixel_7_Android_14`).
  final String deviceModel;

  /// Network condition during test execution (`stable`, `high_latency`, etc.).
  final String networkCondition;

  /// Evaluated prompt context budget in tokens (e.g. 512, 2048, 8192).
  final int contextBudget;

  /// Target placement (`cloud` or `device`).
  final String placement;

  /// Time To First Token in milliseconds (ms).
  final double ttftMs;

  /// Total end-to-end turnaround time in milliseconds (ms).
  final double totalLatencyMs;

  /// Decoding throughput in output tokens per second.
  final double tokensPerSec;

  /// Incremental energy consumed by device during execution in milliampere-hours (mAh).
  final double energyMah;

  /// Peak resident memory allocated by the application in megabytes (MB).
  final double peakMemoryMb;

  /// Peak device thermal sensor reading during the run in degrees Celsius (°C).
  final double tempCelsius;

  /// Monetary cost of the API call in US Dollars ($ USD, 0.0 for on-device).
  final double costUsd;

  /// Normalized task accuracy or semantic fidelity score (0.0 to 1.0).
  final double qualityScore;

  /// 1 if SLA latency, thermal limit, or budget was violated; 0 otherwise.
  final bool constraintViolated;

  const BenchmarkRecord({
    required this.runId,
    required this.timestamp,
    required this.deviceModel,
    required this.networkCondition,
    required this.contextBudget,
    required this.placement,
    required this.ttftMs,
    required this.totalLatencyMs,
    required this.tokensPerSec,
    required this.energyMah,
    required this.peakMemoryMb,
    required this.tempCelsius,
    required this.costUsd,
    required this.qualityScore,
    required this.constraintViolated,
  });

  /// Deserializes a map from SQLite row query.
  factory BenchmarkRecord.fromMap(Map<String, dynamic> map) {
    return BenchmarkRecord(
      runId: map['run_id'] as String,
      timestamp: (map['timestamp'] as num).toInt(),
      deviceModel: map['device_model'] as String,
      networkCondition: map['network_condition'] as String,
      contextBudget: (map['context_budget'] as num).toInt(),
      placement: map['placement'] as String,
      ttftMs: (map['ttft_ms'] as num).toDouble(),
      totalLatencyMs: (map['total_latency_ms'] as num).toDouble(),
      tokensPerSec: (map['tokens_per_sec'] as num).toDouble(),
      energyMah: (map['energy_mah'] as num).toDouble(),
      peakMemoryMb: (map['peak_memory_mb'] as num).toDouble(),
      tempCelsius: (map['temp_celsius'] as num).toDouble(),
      costUsd: (map['cost_usd'] as num).toDouble(),
      qualityScore: (map['quality_score'] as num).toDouble(),
      constraintViolated: ((map['constraint_violated'] as num).toInt() == 1),
    );
  }

  /// Serializes to a map matching the SQLite columns exactly.
  Map<String, dynamic> toMap() {
    return {
      'run_id': runId,
      'timestamp': timestamp,
      'device_model': deviceModel,
      'network_condition': networkCondition,
      'context_budget': contextBudget,
      'placement': placement,
      'ttft_ms': ttftMs,
      'total_latency_ms': totalLatencyMs,
      'tokens_per_sec': tokensPerSec,
      'energy_mah': energyMah,
      'peak_memory_mb': peakMemoryMb,
      'temp_celsius': tempCelsius,
      'cost_usd': costUsd,
      'quality_score': qualityScore,
      'constraint_violated': constraintViolated ? 1 : 0,
    };
  }

  /// Converts this record into a single CSV row string matching [csvHeader].
  String toCsvRow() {
    return '$runId,'
        '$timestamp,'
        '$deviceModel,'
        '$networkCondition,'
        '$contextBudget,'
        '$placement,'
        '${ttftMs.toStringAsFixed(2)},'
        '${totalLatencyMs.toStringAsFixed(2)},'
        '${tokensPerSec.toStringAsFixed(2)},'
        '${energyMah.toStringAsFixed(3)},'
        '${peakMemoryMb.toStringAsFixed(2)},'
        '${tempCelsius.toStringAsFixed(1)},'
        '${costUsd.toStringAsFixed(6)},'
        '${qualityScore.toStringAsFixed(2)},'
        '${constraintViolated ? 1 : 0}';
  }

  /// Parses a comma-separated CSV line into a [BenchmarkRecord].
  factory BenchmarkRecord.fromCsvRow(String line) {
    final parts = line.split(',');
    if (parts.length != 15) {
      throw FormatException(
        'Expected 15 CSV columns for BenchmarkRecord, got ${parts.length}: "$line"',
      );
    }
    return BenchmarkRecord(
      runId: parts[0].trim(),
      timestamp: int.parse(parts[1].trim()),
      deviceModel: parts[2].trim(),
      networkCondition: parts[3].trim(),
      contextBudget: int.parse(parts[4].trim()),
      placement: parts[5].trim(),
      ttftMs: double.parse(parts[6].trim()),
      totalLatencyMs: double.parse(parts[7].trim()),
      tokensPerSec: double.parse(parts[8].trim()),
      energyMah: double.parse(parts[9].trim()),
      peakMemoryMb: double.parse(parts[10].trim()),
      tempCelsius: double.parse(parts[11].trim()),
      costUsd: double.parse(parts[12].trim()),
      qualityScore: double.parse(parts[13].trim()),
      constraintViolated: int.parse(parts[14].trim()) == 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BenchmarkRecord &&
          runtimeType == other.runtimeType &&
          runId == other.runId &&
          timestamp == other.timestamp &&
          deviceModel == other.deviceModel &&
          networkCondition == other.networkCondition &&
          contextBudget == other.contextBudget &&
          placement == other.placement &&
          ttftMs == other.ttftMs &&
          totalLatencyMs == other.totalLatencyMs &&
          tokensPerSec == other.tokensPerSec &&
          energyMah == other.energyMah &&
          peakMemoryMb == other.peakMemoryMb &&
          tempCelsius == other.tempCelsius &&
          costUsd == other.costUsd &&
          qualityScore == other.qualityScore &&
          constraintViolated == other.constraintViolated;

  @override
  int get hashCode =>
      runId.hashCode ^
      timestamp.hashCode ^
      deviceModel.hashCode ^
      networkCondition.hashCode ^
      contextBudget.hashCode ^
      placement.hashCode ^
      ttftMs.hashCode ^
      totalLatencyMs.hashCode ^
      tokensPerSec.hashCode ^
      energyMah.hashCode ^
      peakMemoryMb.hashCode ^
      tempCelsius.hashCode ^
      costUsd.hashCode ^
      qualityScore.hashCode ^
      constraintViolated.hashCode;

  @override
  String toString() {
    return 'BenchmarkRecord('
        'runId: $runId, '
        'placement: $placement, '
        'latency: ${totalLatencyMs}ms, '
        'energy: ${energyMah}mAh, '
        'cost: \$$costUsd, '
        'quality: $qualityScore'
        ')';
  }
}

