import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import '../absolute_rule_linter.dart';

/// Enforces that the Domain layer does not import from Data or Presentation layers.
class AvoidIllegalLayerImports extends AnalysisRule {
  AvoidIllegalLayerImports()
      : super(
          name: 'absolute_rule_avoid_illegal_layer_imports',
          description:
              'Domain layer cannot import from Data or Presentation layers.',
        );

  static const _code = LintCode(
    'absolute_rule_avoid_illegal_layer_imports',
    'Domain layer cannot import from Data or Presentation layers.',
    correctionMessage:
        'Move the logic to the Domain layer or refactor dependencies.',
  );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final path = context.currentUnit?.file.path;
    if (path == null || !AbsoluteRuleUtils.isDomain(path)) return;

    registry.addImportDirective(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AvoidIllegalLayerImports rule;

  _Visitor(this.rule);

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null) return;

    // Check if importing data or presentation
    if (uri.contains('/data/') || uri.contains('/presentation/')) {
      rule.reportAtNode(node);
    }
  }
}
