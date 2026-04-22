import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../generator.dart';

class TestCommand extends Command<int> {
  TestCommand(this._logger) {
    argParser
      ..addFlag(
        'init',
        abbr: 'i',
        help: 'Scaffold initial test files and infrastructure.',
        negatable: false,
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Force overwrite existing files.',
        negatable: false,
      );
  }

  @override
  String get name => 'test';

  @override
  String get description => 'Scaffold and manage project tests.';

  final Logger _logger;

  @override
  Future<int> run() async {
    final isInit = argResults?['init'] as bool? ?? false;
    final force = argResults?['force'] as bool? ?? false;

    final generator = FeatureGenerator(_logger);

    if (isInit) {
      try {
        await generator.initTests();
        _logger.success('Initial test infrastructure scaffolded.');
        return ExitCode.success.code;
      } catch (e) {
        _logger.err('Failed to scaffold tests: $e');
        return ExitCode.software.code;
      }
    }

    if (argResults?.rest.isEmpty ?? true) {
      _logger.info('Usage:');
      _logger.info('  clean_feature_arch test --init (Scaffold infrastructure)');
      _logger.info('  clean_feature_arch test <feature_name> (Scaffold feature tests)');
      return ExitCode.usage.code;
    }

    final featureName = argResults!.rest.first;

    try {
      await generator.generateFeatureTests(featureName, force: force);
      _logger.success('Tests for $featureName scaffolded.');
      return ExitCode.success.code;
    } catch (e) {
      _logger.err('Failed to scaffold tests: $e');
      return ExitCode.software.code;
    }
  }
}
