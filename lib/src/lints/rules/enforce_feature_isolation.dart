import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import '../absolute_rule_linter.dart';

/// Lints a feature attempting to import internals (data/presentation) of another feature.
class EnforceFeatureIsolation extends DartLintRule {
  const EnforceFeatureIsolation() : super(code: _code);

  static const _code = LintCode(
    name: 'absolute_rule_enforce_feature_isolation',
    problemMessage: 'Features can only depend on the Domain layer of other features.',
    correctionMessage: 'Import from domain/ or move shared logic to core/ or shared/.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final currentPath = resolver.path;
    final currentFeature = AbsoluteRuleUtils.getFeatureName(currentPath);
    if (currentFeature == null) return;

    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue;
      if (uri == null) return;

      // Only check inter-feature imports
      if (uri.contains('/features/') && !uri.contains('/$currentFeature/')) {
        // Flag if importing data or presentation of another feature
        if (uri.contains('/data/') || uri.contains('/presentation/')) {
          reporter.reportErrorForNode(_code, node);
        }
      }
    });
  }
}
