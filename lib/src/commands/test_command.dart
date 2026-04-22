import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../generator.dart';

class TestCommand extends Command<int> {
  TestCommand(this._logger) {
    argParser.addFlag(
      'init',
      abbr: 'i',
      help: 'Scaffold initial test files and infrastructure.',
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

    if (!isInit) {
      _logger.info('Usage: clean_feature_arch test --init to scaffold initial tests.');
      return ExitCode.usage.code;
    }

    final generator = FeatureGenerator(_logger);

    try {
      await generator.initTests();
      _logger.success('Initial test infrastructure scaffolded.');
      return ExitCode.success.code;
    } catch (e) {
      _logger.err('Failed to scaffold tests: $e');
      return ExitCode.software.code;
    }
  }
}
