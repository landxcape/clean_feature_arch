import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:clean_feature_arch/src/commands/feature_command.dart';
import 'package:clean_feature_arch/src/commands/init_command.dart';

Future<void> main(List<String> arguments) async {
  final logger = Logger();

  final runner = CommandRunner<int>(
    'clean_feature_arch',
    'A development toolkit for enforcing the Absolute Rule Architecture in Flutter projects.',
  )
    ..addCommand(FeatureCommand(logger))
    ..addCommand(InitCommand(logger));

  try {
    final exitCode = await runner.run(arguments);
    exit(exitCode ?? 0);
  } on UsageException catch (e) {
    logger.err(e.message);
    logger.info(runner.usage);
    exit(ExitCode.usage.code);
  } catch (e) {
    logger.err(e.toString());
    exit(ExitCode.software.code);
  }
}
