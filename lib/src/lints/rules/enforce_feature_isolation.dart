import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import '../absolute_rule_linter.dart';

/// Enforces that features only depend on the Domain layer of other features.
class EnforceFeatureIsolation extends AnalysisRule {
  EnforceFeatureIsolation()
      : super(
          name: 'absolute_rule_enforce_feature_isolation',
          description:
              'Features can only depend on the Domain layer of other features.',
        );

  static const _code = LintCode(
    'absolute_rule_enforce_feature_isolation',
    'Features can only depend on the Domain layer of other features.',
    correctionMessage:
        'Import from domain/ or move shared logic to core/ or shared/.',
  );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final currentPath = context.currentUnit?.file.path;
    if (currentPath == null) return;

    final currentFeature = AbsoluteRuleUtils.getFeatureName(currentPath);
    if (currentFeature == null) return;

    registry.addImportDirective(this, _Visitor(this, currentFeature));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final EnforceFeatureIsolation rule;
  final String currentFeature;

  _Visitor(this.rule, this.currentFeature);

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null) return;

    // Only check inter-feature imports
    if (uri.contains('/features/') && !uri.contains('/$currentFeature/')) {
      // Flag if importing data or presentation of another feature
      if (uri.contains('/data/') || uri.contains('/presentation/')) {
        rule.reportAtNode(node);
      }
    }
  }
}
