import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../generator.dart';

class StorageCommand extends Command<int> {
  StorageCommand(this._logger) {
    addSubcommand(StorageInitCommand(_logger));
    addSubcommand(StorageFeatureCommand(_logger));
  }

  @override
  String get name => 'storage';

  @override
  String get description => 'Manage project-wide and feature-specific storage.';

  final Logger _logger;
}

class StorageInitCommand extends Command<int> {
  StorageInitCommand(this._logger) {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Force overwrite existing files.',
      negatable: false,
    );
  }

  @override
  String get name => 'init';

  @override
  String get description => 'Initialize a global storage engine (Drift or Shared Preferences).';

  @override
  String get invocation => 'clean_feature_arch storage init [engine]';

  final Logger _logger;

  @override
  Future<int> run() async {
    final force = argResults?['force'] as bool? ?? false;
    var engine = argResults?.rest.isNotEmpty ?? false ? argResults!.rest.first.toLowerCase() : null;

    if (engine == null) {
      final choices = ['Drift (SQL)', 'Shared Preferences'];
      final choice = _logger.chooseOne(
        'Select Global Storage Engine to Initialize:',
        choices: choices,
        defaultValue: 'Drift (SQL)',
      );
      engine = choice.toLowerCase().split(' ').first;
    }

    if (engine != 'drift' && engine != 'shared') {
      _logger.err('Invalid engine "$engine". Use "drift" or "shared".');
      return ExitCode.usage.code;
    }

    final generator = FeatureGenerator(_logger);

    try {
      await generator.initStorage(engine, force: force);
      _logger.success('Successfully initialized $engine engine.');
      return ExitCode.success.code;
    } catch (e) {
      _logger.err('Failed to initialize storage: $e');
      return ExitCode.software.code;
    }
  }
}

class StorageFeatureCommand extends Command<int> {
  StorageFeatureCommand(this._logger) {
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Force overwrite existing files.',
      negatable: false,
    );
  }

  @override
  String get name => 'feature';

  @override
  String get description => 'Surgically add a storage engine to an existing feature.';

  @override
  String get invocation => 'clean_feature_arch storage feature <name> [engine]';

  final Logger _logger;

  @override
  Future<int> run() async {
    if (argResults?.rest.isEmpty ?? true) {
      _logger.err('Please provide a feature name.');
      return ExitCode.usage.code;
    }

    final featureName = argResults!.rest.first;
    var type = argResults!.rest.length > 1 ? argResults!.rest[1].toLowerCase() : null;
    final force = argResults?['force'] as bool? ?? false;

    if (type == null) {
      final choices = ['Drift (SQL)', 'Shared Preferences'];
      final choice = _logger.chooseOne(
        'Which storage should the feature "$featureName" use?',
        choices: choices,
        defaultValue: 'Drift (SQL)',
      );
      type = choice.toLowerCase().split(' ').first;
    }

    if (type != 'drift' && type != 'shared') {
      _logger.err('Invalid storage type "$type". Use "drift" or "shared".');
      return ExitCode.usage.code;
    }

    final generator = FeatureGenerator(_logger);

    try {
      await generator.addStorageToFeature(featureName, type, force: force);
      _logger.success('Successfully added $type storage to $featureName.');
      return ExitCode.success.code;
    } catch (e) {
      _logger.err('Failed to add storage to feature: $e');
      return ExitCode.software.code;
    }
  }
}
