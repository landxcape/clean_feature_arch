import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import '../absolute_rule_linter.dart';

/// Lints Domain layer attempting to import Data or Presentation layers.
class AvoidIllegalLayerImports extends DartLintRule {
  const AvoidIllegalLayerImports() : super(code: _code);

  static const _code = LintCode(
    name: 'absolute_rule_avoid_illegal_layer_imports',
    problemMessage:
        'Domain layer cannot import from Data or Presentation layers.',
    correctionMessage:
        'Move the logic to the Domain layer or refactor dependencies.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    final path = resolver.path;
    if (!AbsoluteRuleUtils.isDomain(path)) return;

    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue;
      if (uri == null) return;

      // Check if importing data or presentation
      if (uri.contains('/data/') || uri.contains('/presentation/')) {
        reporter.atNode(node, _code);
      }
    });
  }
}
