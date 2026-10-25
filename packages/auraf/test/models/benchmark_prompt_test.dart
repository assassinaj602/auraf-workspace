import 'dart:io';
import 'package:auraf/auraf.dart';
import 'package:test/test.dart';

void main() {
  group('BenchmarkPrompt Tests', () {
    test('parses prompts.json asset file correctly', () {
      final file = File('assets/prompts.json');
      expect(file.existsSync(), isTrue, reason: 'assets/prompts.json should exist');

      final jsonContent = file.readAsStringSync();
      final prompts = BenchmarkPrompt.parseList(jsonContent);

      expect(prompts.length, equals(9));

      // Test split filtering
      final profiling = BenchmarkPrompt.filterBySplit(prompts, 'profiling');
      final validation = BenchmarkPrompt.filterBySplit(prompts, 'validation');
      final testSplits = BenchmarkPrompt.filterBySplit(prompts, 'test');

      expect(profiling.isNotEmpty, isTrue);
      expect(validation.isNotEmpty, isTrue);
      expect(testSplits.isNotEmpty, isTrue);

      // Test token filtering
      final p05k = BenchmarkPrompt.filterByTokens(prompts, 512);
      final p2k = BenchmarkPrompt.filterByTokens(prompts, 2048);
      final p8k = BenchmarkPrompt.filterByTokens(prompts, 8192);

      expect(p05k.isNotEmpty, isTrue);
      expect(p2k.isNotEmpty, isTrue);
      expect(p8k.isNotEmpty, isTrue);

      // Verify fields
      final first = prompts.first;
      expect(first.id, equals('prof_05k_01'));
      expect(first.targetTokens, equals(512));
      expect(first.prompt, contains('Flutter'));
    });

    test('serializes to and from map', () {
      const prompt = BenchmarkPrompt(
        id: 'test_custom',
        split: 'test',
        targetTokens: 2048,
        category: 'unit_test',
        description: 'Test description',
        prompt: 'Test prompt text',
        expectedResponseTokens: 100,
      );

      final map = prompt.toMap();
      final restored = BenchmarkPrompt.fromMap(map);
      expect(restored, equals(prompt));
    });
  });
}

