import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

class DocsCommand extends Command<int> {
  DocsCommand(this._logger);

  @override
  String get name => 'docs';

  @override
  String get description => 'Access Absolute Rule documentation and references.';

  final Logger _logger;

  final Map<String, String> _links = {
    'Core Architecture':
        'https://github.com/landxcape/clean_feature_arch/blob/main/doc/flutter_architecture.md',
    'State Management: Common':
        'https://github.com/landxcape/clean_feature_arch/blob/main/doc/state_management/common.md',
    'State Management: BLoC':
        'https://github.com/landxcape/clean_feature_arch/blob/main/doc/state_management/bloc.md',
    'State Management: Riverpod':
        'https://github.com/landxcape/clean_feature_arch/blob/main/doc/state_management/riverpod.md',
  };

  @override
  Future<int> run() async {
    final topic = argResults?.rest.safeFirst?.toLowerCase();

    switch (topic) {
      case 'rules':
        await _printSection('## The Absolute Rules');
        return ExitCode.success.code;
      case 'skeleton':
        await _printSection('## Part 1 — Folder Structure');
        return ExitCode.success.code;
      case 'arch':
      case 'core':
        await _openLink(_links['Core Architecture']!);
        return ExitCode.success.code;
      case 'bloc':
        await _openLink(_links['State Management: BLoC']!);
        return ExitCode.success.code;
      case 'riverpod':
        await _openLink(_links['State Management: Riverpod']!);
        return ExitCode.success.code;
    }

    // Interactive Menu
    final choice = _logger.chooseOne(
      'What would you like to access?',
      choices: [
        'Terminal: 11 Absolute Rules',
        'Terminal: Project Skeleton',
        'Browser: Core Architecture Guide',
        'Browser: State Management (Common)',
        'Browser: State Management (BLoC)',
        'Browser: State Management (Riverpod)',
      ],
      defaultValue: 'Terminal: 11 Absolute Rules',
    );

    switch (choice) {
      case 'Terminal: 11 Absolute Rules':
        await _printSection('## The Absolute Rules');
        break;
      case 'Terminal: Project Skeleton':
        await _printSection('## Part 1 — Folder Structure');
        break;
      case 'Browser: Core Architecture Guide':
        await _openLink(_links['Core Architecture']!);
        break;
      case 'Browser: State Management (Common)':
        await _openLink(_links['State Management: Common']!);
        break;
      case 'Browser: State Management (BLoC)':
        await _openLink(_links['State Management: BLoC']!);
        break;
      case 'Browser: State Management (Riverpod)':
        await _openLink(_links['State Management: Riverpod']!);
        break;
    }

    return ExitCode.success.code;
  }

  /// Parses and prints a section from the local flutter_architecture.md file.
  Future<void> _printSection(String header) async {
    final progress = _logger.progress('Loading reference');
    try {
      // Find the package root
      final uri = Uri.parse('package:clean_feature_arch/clean_feature_arch.dart');
      final resolvedUri = await Isolate.resolvePackageUri(uri);
      
      if (resolvedUri == null) {
        progress.fail('Could not locate package path.');
        return;
      }

      // Move up from lib/clean_feature_arch.dart to the package root
      final packageRoot = File.fromUri(resolvedUri).parent.parent.path;
      final docFile = File(p.join(packageRoot, 'doc', 'flutter_architecture.md'));

      if (!await docFile.exists()) {
        progress.fail('Documentation file not found at ${docFile.path}');
        return;
      }

      final content = await docFile.readAsString();

      // Find the start of the section
      final startIndex = content.indexOf(header);
      if (startIndex == -1) {
        progress.fail('Section not found: $header');
        return;
      }

      // Find the end of the section (the next header or separator)
      int endIndex = content.indexOf('\n##', startIndex + header.length);
      if (endIndex == -1) {
        endIndex = content.indexOf('\n---', startIndex + header.length);
      }
      
      var section = endIndex == -1 
          ? content.substring(startIndex) 
          : content.substring(startIndex, endIndex);

      // Clean up the output
      section = section.replaceFirst(header, '').trim();
      
      progress.complete('Reference loaded.');
      _logger.info('\n${lightCyan.wrap('--- REFERENCE ---')}\n');
      _logger.info(section);
      _logger.info('\n${lightCyan.wrap('-----------------')}\n');
    } catch (e) {
      progress.fail('Error reading documentation: $e');
    }
  }

  Future<void> _openLink(String url) async {
    _logger.info('Opening: $url');
    String command = '';

    if (Platform.isMacOS) {
      command = 'open';
    } else if (Platform.isWindows) {
      command = 'start';
    } else {
      command = 'xdg-open';
    }

    try {
      await Process.run(command, [url]);
    } catch (e) {
      _logger.err('Could not open browser. Please visit the link manually.');
    }
  }
}

extension on List<String> {
  String? get safeFirst => isEmpty ? null : first;
}
