import 'package:auraf/auraf.dart';
import 'package:test/test.dart';

void main() {
  group('BenchmarkRecord Model Tests', () {
    final sample = BenchmarkRecord(
      runId: '550e8400-e29b-41d4-a716-446655440000',
      timestamp: 1730000000000,
      deviceModel: 'Pixel_7_Android_14',
      networkCondition: 'stable',
      contextBudget: 512,
      placement: 'device',
      ttftMs: 184.50,
      totalLatencyMs: 1420.25,
      tokensPerSec: 24.80,
      energyMah: 1.150,
      peakMemoryMb: 342.10,
      tempCelsius: 33.5,
      costUsd: 0.0,
      qualityScore: 0.88,
      constraintViolated: false,
    );

    test('serializes to SQLite map matching DDL columns', () {
      final map = sample.toMap();

      expect(map['run_id'], equals('550e8400-e29b-41d4-a716-446655440000'));
      expect(map['timestamp'], equals(1730000000000));
      expect(map['device_model'], equals('Pixel_7_Android_14'));
      expect(map['network_condition'], equals('stable'));
      expect(map['context_budget'], equals(512));
      expect(map['placement'], equals('device'));
      expect(map['ttft_ms'], equals(184.50));
      expect(map['total_latency_ms'], equals(1420.25));
      expect(map['tokens_per_sec'], equals(24.80));
      expect(map['energy_mah'], equals(1.150));
      expect(map['peak_memory_mb'], equals(342.10));
      expect(map['temp_celsius'], equals(33.5));
      expect(map['cost_usd'], equals(0.0));
      expect(map['quality_score'], equals(0.88));
      expect(map['constraint_violated'], equals(0));

      final restored = BenchmarkRecord.fromMap(map);
      expect(restored, equals(sample));
    });

    test('formats strict 15-column CSV row', () {
      final csv = sample.toCsvRow();
      final columns = csv.split(',');

      expect(columns.length, equals(15));
      expect(columns[0], equals('550e8400-e29b-41d4-a716-446655440000'));
      expect(columns[5], equals('device'));
      expect(columns[14], equals('0'));

      final restoredFromCsv = BenchmarkRecord.fromCsvRow(csv);
      expect(restoredFromCsv.runId, equals(sample.runId));
      expect(restoredFromCsv.totalLatencyMs, equals(sample.totalLatencyMs));
      expect(restoredFromCsv.constraintViolated, equals(sample.constraintViolated));
    });

    test('validates CSV header column count', () {
      final headers = BenchmarkRecord.csvHeader.split(',');
      expect(headers.length, equals(15));
      expect(headers[0], equals('run_id'));
      expect(headers[14], equals('constraint_violated'));
    });
  });
}
