/// The Absolute Rule Architecture toolkit for Flutter.
///
/// This package provides a command-line interface for scaffolding features
/// and a custom analyzer plugin for enforcing architectural boundaries.
library clean_feature_arch;

import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/lints/rules/avoid_illegal_layer_imports.dart';
import 'src/lints/rules/enforce_feature_isolation.dart';
import 'src/lints/rules/prefer_sealed_freezed_models.dart';
import 'src/lints/rules/enforce_model_folder_structure.dart';

/// The entry point for the Absolute Rule analyzer plugin.
///
/// This function is used by the `custom_lint` server to instantiate
/// the plugin and register its associated lint rules.
PluginBase createPlugin() => _AbsoluteRulePlugin();

/// The internal implementation of the Absolute Rule analyzer plugin.
class _AbsoluteRulePlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    return [
      const AvoidIllegalLayerImports(),
      const EnforceFeatureIsolation(),
      const PreferSealedFreezedModels(),
      const EnforceModelFolderStructure(),
    ];
  }
}
