import 'package:clean_feature_arch/src/templates/core_templates.dart';
import 'package:test/test.dart';

void main() {
  group('CoreTemplates', () {
    test('analysisOptions does not contain deprecated analyzer: plugins block', () {
      final content = CoreTemplates.analysisOptions();

      expect(content.contains('analyzer:\n  plugins:'), isFalse);
      expect(content.contains('- clean_feature_arch'), isFalse);
      expect(content.contains('strict-casts: true'), isTrue);
      expect(content.contains('strict-inference: true'), isTrue);
      expect(content.contains('strict-raw-types: true'), isTrue);
    });
  });
}
