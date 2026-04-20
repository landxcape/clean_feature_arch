/// The Absolute Rule Architecture toolkit for Flutter.
///
/// This package provides a command-line interface for scaffolding features
/// and a custom analyzer plugin for enforcing architectural boundaries.
library;

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/lints/rules/avoid_illegal_layer_imports.dart';
import 'src/lints/rules/enforce_feature_isolation.dart';
import 'src/lints/rules/enforce_model_folder_structure.dart';
import 'src/lints/rules/prefer_sealed_freezed_models.dart';

/// The entry point for the Absolute Rule analyzer plugin.
final plugin = _AbsoluteRulePlugin();

/// The internal implementation of the Absolute Rule analyzer plugin.
class _AbsoluteRulePlugin extends Plugin {
  @override
  String get name => 'clean_feature_arch';

  @override
  void register(PluginRegistry registry) {
    registry.registerLintRule(AvoidIllegalLayerImports());
    registry.registerLintRule(EnforceFeatureIsolation());
    registry.registerLintRule(EnforceModelFolderStructure());
    registry.registerLintRule(PreferSealedFreezedModels());
  }
}
