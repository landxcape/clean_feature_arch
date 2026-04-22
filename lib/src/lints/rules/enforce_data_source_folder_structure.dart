import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Enforces that data sources are organized into appropriate subdirectories.
class EnforceDataSourceFolderStructure extends AnalysisRule {
  EnforceDataSourceFolderStructure()
      : super(
          name: 'absolute_rule_enforce_data_source_folder_structure',
          description:
              'Data sources must be organized into local_data_sources/ or remote_data_sources/ subdirectories.',
        );

  static const _code = LintCode(
    'absolute_rule_enforce_data_source_folder_structure',
    'Data sources must be organized into local_data_sources/ or remote_data_sources/ subdirectories.',
    correctionMessage: 'Move the data source file into the appropriate subdirectory.',
  );

  @override
  DiagnosticCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final path = context.currentUnit?.file.path;
    if (path == null || !path.contains('/data/data_sources/')) return;

    // Check if the file is directly under data_sources/
    final containsValidSubdir = path.contains('/data_sources/local_data_sources/') ||
        path.contains('/data_sources/remote_data_sources/');

    if (!containsValidSubdir) {
      registry.addCompilationUnit(this, _Visitor(this));
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final EnforceDataSourceFolderStructure rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    rule.reportAtNode(node);
  }
}
