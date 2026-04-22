import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Enforces that Freezed models are declared as sealed.
class PreferSealedFreezedModels extends AnalysisRule {
  PreferSealedFreezedModels()
      : super(
          name: 'absolute_rule_prefer_sealed_freezed_models',
          description: 'Freezed models must be declared as a sealed class.',
        );

  static const _code = LintCode(
    'absolute_rule_prefer_sealed_freezed_models',
    'Freezed models must be declared as a sealed class.',
    correctionMessage: 'Add the "sealed" keyword before "class".',
  );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final PreferSealedFreezedModels rule;

  _Visitor(this.rule);

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final isFreezed = node.metadata.any((annotation) =>
        annotation.name.name == 'freezed' || annotation.name.name == 'Freezed');

    if (isFreezed) {
      final isSealed = node.sealedKeyword != null;
      if (!isSealed) {
        rule.reportAtToken(node.classKeyword);
      }
    }
  }
}
