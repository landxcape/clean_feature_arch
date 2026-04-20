import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../generator.dart';

class FeatureCommand extends Command<int> {
  FeatureCommand(this._logger) {
    argParser.addOption(
      'dir',
      abbr: 'd',
      help: 'The target directory for the feature.',
    );
  }

  @override
  String get name => 'feature';

  @override
  String get description => 'Scaffold a new feature following Absolute Rule Architecture.';

  final Logger _logger;

  @override
  Future<int> run() async {
    if (argResults?.rest.isEmpty ?? true) {
      _logger.err('Please provide a feature name.');
      return ExitCode.usage.code;
    }

    final name = argResults!.rest.join('_');
    final targetDir = argResults?['dir'] as String?;

    final generator = FeatureGenerator(_logger);
    
    try {
      await generator.generate(name, targetDirectory: targetDir);
      _logger.info('Successfully generated feature: $name');
      _logger.info('Run `dart run build_runner build -d` to generate Freezed models.');
      return ExitCode.success.code;
    } catch (e) {
      _logger.err('Failed to generate feature: $e');
      return ExitCode.software.code;
    }
  }
}
