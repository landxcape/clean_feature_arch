import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../generator.dart';

class CICommand extends Command<int> {
  CICommand(this._logger);

  @override
  String get name => 'ci';

  @override
  String get description => 'Scaffold CI/CD configurations for various platforms.';

  final Logger _logger;

  @override
  Future<int> run() async {
    final choice = _logger.chooseOne(
      'Select CI/CD Platform:',
      choices: ['GitHub Actions', 'GitLab CI'],
      defaultValue: 'GitHub Actions',
    );

    final generator = FeatureGenerator(_logger);
    final platform = choice.toLowerCase().replaceAll(' ', '_');

    try {
      await generator.addCI(platform);
      _logger.success('Successfully scaffolded $choice configuration.');
      return ExitCode.success.code;
    } catch (e) {
      _logger.err('Failed to scaffold CI: $e');
      return ExitCode.software.code;
    }
  }
}
