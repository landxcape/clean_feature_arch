import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Enforces that models are organized into appropriate subdirectories.
class EnforceModelFolderStructure extends AnalysisRule {
  EnforceModelFolderStructure()
      : super(
          name: 'absolute_rule_enforce_model_folder_structure',
          description:
              'Models must be organized into requests/, responses/, or local/ subdirectories.',
        );

  static const _code = LintCode(
    'absolute_rule_enforce_model_folder_structure',
    'Models must be organized into requests/, responses/, or local/ subdirectories.',
    correctionMessage: 'Move the model file into the appropriate subdirectory.',
  );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final path = context.currentUnit?.file.path;
    if (path == null || !path.contains('/data/models/')) return;

    // Check if the file is directly under models/
    final containsValidSubdir = path.contains('/models/requests/') ||
        path.contains('/models/responses/') ||
        path.contains('/models/local/');

    if (!containsValidSubdir) {
      registry.addCompilationUnit(this, _Visitor(this));
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final EnforceModelFolderStructure rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    rule.reportAtNode(node);
  }
}
