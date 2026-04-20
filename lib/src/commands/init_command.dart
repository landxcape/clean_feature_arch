import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../generator.dart';

class InitCommand extends Command<int> {
  InitCommand(this._logger);

  @override
  String get name => 'init';

  @override
  String get description =>
      'Scaffold the Absolute Rule core architecture and folder structure.';

  final Logger _logger;

  @override
  Future<int> run() async {
    final generator = FeatureGenerator(_logger);

    try {
      await generator.initProject();
      _logger.info('Project initialized with core architectural layers.');
      return ExitCode.success.code;
    } catch (e) {
      _logger.err('Initialization failed: $e');
      return ExitCode.software.code;
    }
  }
}
