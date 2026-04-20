import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Lints Freezed classes that are not declared as sealed.
class PreferSealedFreezedModels extends DartLintRule {
  const PreferSealedFreezedModels() : super(code: _code);

  static const _code = LintCode(
    name: 'absolute_rule_prefer_sealed_freezed_models',
    problemMessage: 'Freezed models must be declared as a sealed class.',
    correctionMessage: 'Add the "sealed" keyword before "class".',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final isFreezed = node.metadata.any((annotation) =>
          annotation.name.name == 'freezed' ||
          annotation.name.name == 'Freezed');

      if (isFreezed) {
        final isSealed = node.sealedKeyword != null;
        if (!isSealed) {
          reporter.atToken(node.classKeyword, _code);
        }
      }
    });
  }
}
