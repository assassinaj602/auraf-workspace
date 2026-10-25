import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

const String benchmarkCsvHeader =
    'run_id,timestamp,device_model,network_condition,context_budget,placement,'
    'ttft_ms,total_latency_ms,tokens_per_sec,energy_mah,peak_memory_mb,'
    'temp_celsius,cost_usd,quality_score,constraint_violated';

class BenchmarkRecord {
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

  final String runId;
  final int timestamp;
  final String deviceModel;
  final String networkCondition;
  final int contextBudget;
  final String placement;
  final double ttftMs;
  final double totalLatencyMs;
  final double tokensPerSec;
  final double energyMah;
  final double peakMemoryMb;
  final double tempCelsius;
  final double costUsd;
  final double qualityScore;
  final bool constraintViolated;

  Map<String, Object> toMap() => <String, Object>{
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

  String toCsvRow() => toMap().values.map(_csvValue).join(',');

  static String _csvValue(Object? value) {
    final text = value.toString();
    if (text.contains(',') || text.contains('"') || text.contains('\n')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }
}

class TelemetryDatabase {
  TelemetryDatabase({String? databasePath}) : _databasePath = databasePath;

  static const String databaseName = 'auraf_telemetry.sqlite';
  final String? _databasePath;
  Database? _database;

  Future<Database> get database async {
    return _database ??= await _open();
  }

  Future<Database> _open() async {
    final location =
        _databasePath ?? path.join(await getDatabasesPath(), databaseName);
    return openDatabase(
      location,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE IF NOT EXISTS benchmark_records (
    run_id TEXT PRIMARY KEY,
    timestamp INTEGER NOT NULL,
    device_model TEXT NOT NULL,
    network_condition TEXT NOT NULL,
    context_budget INTEGER NOT NULL,
    placement TEXT NOT NULL,
    ttft_ms REAL NOT NULL,
    total_latency_ms REAL NOT NULL,
    tokens_per_sec REAL NOT NULL,
    energy_mah REAL NOT NULL,
    peak_memory_mb REAL NOT NULL,
    temp_celsius REAL NOT NULL,
    cost_usd REAL NOT NULL,
    quality_score REAL NOT NULL,
    constraint_violated INTEGER NOT NULL
);
''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_records_timestamp '
          'ON benchmark_records(timestamp)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_records_placement '
          'ON benchmark_records(placement)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_records_network '
          'ON benchmark_records(network_condition)',
        );
      },
    );
  }

  Future<void> insert(BenchmarkRecord record) async {
    final db = await database;
    await db.insert(
      'benchmark_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> count() async => (await database)
      .rawQuery('SELECT COUNT(*) AS count FROM benchmark_records')
      .then((rows) => Sqflite.firstIntValue(rows) ?? 0);

  Future<File> exportToCsv({
    String outputPath = 'results/m2_benchmark_results.csv',
  }) async {
    final rows = await (await database).query(
      'benchmark_records',
      orderBy: 'timestamp ASC, run_id ASC',
    );
    final file = File(outputPath);
    await file.parent.create(recursive: true);
    final contents = StringBuffer('$benchmarkCsvHeader\n');
    for (final row in rows) {
      contents.writeln(row.values.map(BenchmarkRecord._csvValue).join(','));
    }
    return file.writeAsString(contents.toString());
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    await db?.close();
  }
}
