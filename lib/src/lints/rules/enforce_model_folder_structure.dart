import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Lints models that are placed directly in data/models/ instead of subdirectories.
class EnforceModelFolderStructure extends DartLintRule {
  const EnforceModelFolderStructure() : super(code: _code);

  static const _code = LintCode(
    name: 'absolute_rule_enforce_model_folder_structure',
    problemMessage:
        'Models must be organized into requests/, responses/, or local/ subdirectories.',
    correctionMessage: 'Move the model file into the appropriate subdirectory.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    final path = resolver.path;
    if (!path.contains('/data/models/')) return;

    // Check if the file is directly under models/
    // A correct path should be models/requests/file.dart, models/responses/file.dart, or models/local/file.dart
    final containsValidSubdir = path.contains('/models/requests/') ||
        path.contains('/models/responses/') ||
        path.contains('/models/local/');

    if (!containsValidSubdir) {
      context.registry.addCompilationUnit((node) {
        reporter.atNode(node, _code);
      });
    }
  }
}
