import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/lints/rules/avoid_illegal_layer_imports.dart';
import 'src/lints/rules/enforce_feature_isolation.dart';
import 'src/lints/rules/prefer_sealed_freezed_models.dart';
import 'src/lints/rules/enforce_model_folder_structure.dart';

/// The entry point for the Absolute Rule analyzer plugin.
PluginBase createPlugin() => _AbsoluteRulePlugin();

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
