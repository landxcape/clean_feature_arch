import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/lints/rules/avoid_illegal_layer_imports.dart';
import 'src/lints/rules/enforce_data_source_folder_structure.dart';
import 'src/lints/rules/enforce_feature_isolation.dart';
import 'src/lints/rules/enforce_model_folder_structure.dart';
import 'src/lints/rules/prefer_sealed_freezed_models.dart';

/// Entry point for the analyzer server plugin.
final plugin = AbsoluteRulePlugin();

/// Native analyzer plugin enforcing the Absolute Rule Architecture.
class AbsoluteRulePlugin extends Plugin {
  @override
  String get name => 'clean_feature_arch';

  @override
  void register(PluginRegistry registry) {
    registry.registerLintRule(AvoidIllegalLayerImports());
    registry.registerLintRule(EnforceFeatureIsolation());
    registry.registerLintRule(EnforceModelFolderStructure());
    registry.registerLintRule(PreferSealedFreezedModels());
    registry.registerLintRule(EnforceDataSourceFolderStructure());
  }
}
