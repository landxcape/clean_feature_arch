import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../generator.dart';

class InitCommand extends Command<int> {
  InitCommand(this._logger) {
    argParser
      ..addOption(
        'state',
        abbr: 's',
        allowed: ['bloc', 'riverpod', 'none'],
        help: 'Pre-install state management dependencies.',
        defaultsTo: 'none',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Force overwrite existing files.',
        negatable: false,
      );
  }

  @override
  String get name => 'init';

  @override
  String get description =>
      'Scaffold the Absolute Rule core architecture (Networking, Theme, Router, Secure Storage).';

  final Logger _logger;

  @override
  Future<int> run() async {
    final stateManager = argResults?['state'] as String?;
    final force = argResults?['force'] as bool? ?? false;
    final generator = FeatureGenerator(_logger);

    try {
      await generator.initProject(stateManager: stateManager, force: force);
      _logger.info('Project initialized with core architectural layers.');
      return ExitCode.success.code;
    } catch (e) {
      _logger.err('Initialization failed: $e');
      return ExitCode.software.code;
    }
  }
}
