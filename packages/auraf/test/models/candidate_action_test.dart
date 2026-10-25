import 'package:auraf/auraf.dart';
import 'package:test/test.dart';

void main() {
  group('CandidateAction Model Tests', () {
    test('creates and serializes cloud action correctly', () {
      final cloudAction = CandidateAction.cloud(
        contextBudgetTokens: 2048,
        modelId: 'gemini-1.5-flash',
      );

      expect(cloudAction.placement, equals(ActionPlacement.cloud));
      expect(cloudAction.contextBudgetTokens, equals(2048));
      expect(cloudAction.modelId, equals('gemini-1.5-flash'));

      final map = cloudAction.toMap();
      expect(map['placement'], equals('cloud'));
      expect(map['context_budget_tokens'], equals(2048));

      final restored = CandidateAction.fromMap(map);
      expect(restored, equals(cloudAction));
    });

    test('creates and serializes device action correctly', () {
      final deviceAction = CandidateAction.device(
        contextBudgetTokens: 512,
        modelId: 'gemma-2-2b',
        quantization: 'int4',
        threadCount: 4,
      );

      expect(deviceAction.placement, equals(ActionPlacement.device));
      expect(deviceAction.quantization, equals('int4'));
      expect(deviceAction.threadCount, equals(4));

      final map = deviceAction.toMap();
      expect(map['placement'], equals('device'));
      expect(map['quantization'], equals('int4'));

      final restored = CandidateAction.fromMap(map);
      expect(restored, equals(deviceAction));
    });
  });
}

