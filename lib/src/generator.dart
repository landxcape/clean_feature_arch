import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';
import 'package:mason_logger/mason_logger.dart';
import 'templates/domain_templates.dart';
import 'templates/data_templates.dart';
import 'templates/presentation_templates.dart';
import 'templates/core_templates.dart';

/// A generator responsible for scaffolding architectural layers and core utilities.
class FeatureGenerator {
  /// Creates a new [FeatureGenerator] instance with the provided [Logger].
  FeatureGenerator(this._logger);

  final Logger _logger;

  /// Scaffolds a new feature directory structure at the specified [targetDirectory].
  ///
  /// The [name] parameter is converted to snake_case to match Dart file conventions.
  /// If [targetDirectory] is null, the feature is generated in `lib/features/<name>`.
  Future<void> generate(String name,
      {String? targetDirectory, String? stateManager}) async {
    final snakeCaseName = name.snakeCase;
    final baseDir = targetDirectory ?? p.join('lib', 'features', snakeCaseName);

    _logger.info('Generating feature: ${lightCyan.wrap(snakeCaseName)}...');

    final progress = _logger.progress('Generating layers');

    try {
      // 1. Domain Layer
      await _createFile(
        p.join(baseDir, 'domain', 'entities', '${snakeCaseName}_entity.dart'),
        DomainTemplates.entity(snakeCaseName),
      );
      await _createFile(
        p.join(baseDir, 'domain', 'repositories',
            '${snakeCaseName}_repository.dart'),
        DomainTemplates.repository(snakeCaseName),
      );
      await _createFile(
        p.join(
            baseDir, 'domain', 'usecases', 'get_${snakeCaseName}_usecase.dart'),
        DomainTemplates.usecase(snakeCaseName),
      );

      // 2. Data Layer
      await _createFile(
        p.join(baseDir, 'data', 'models', 'requests',
            '${snakeCaseName}_request_model.dart'),
        DataTemplates.requestModel(snakeCaseName),
      );
      await _createFile(
        p.join(baseDir, 'data', 'models', 'responses',
            '${snakeCaseName}_response_model.dart'),
        DataTemplates.responseModel(snakeCaseName),
      );
      await _createFile(
        p.join(baseDir, 'data', 'models', 'local',
            '${snakeCaseName}_local_model.dart'),
        DataTemplates.localModel(snakeCaseName),
      );

      // Data Sources
      await _createFile(
        p.join(baseDir, 'data', 'data_sources', 'remote_data_sources',
            '${snakeCaseName}_remote_data_source.dart'),
        DataTemplates.remoteDataSource(snakeCaseName),
      );
      await _createFile(
        p.join(baseDir, 'data', 'data_sources', 'local_data_sources',
            '${snakeCaseName}_local_data_source.dart'),
        DataTemplates.localDataSource(snakeCaseName),
      );

      await _createFile(
        p.join(baseDir, 'data', 'repositories',
            '${snakeCaseName}_repository_impl.dart'),
        DataTemplates.repositoryImpl(snakeCaseName),
      );

      // 3. Presentation Layer
      await _createFile(
        p.join(
            baseDir, 'presentation', 'screens', '${snakeCaseName}_screen.dart'),
        PresentationTemplates.screen(snakeCaseName, stateManager: stateManager),
      );

      // Create state folder explicitly
      final stateDir = p.join(baseDir, 'presentation', 'state');
      await Directory(stateDir).create(recursive: true);

      switch (stateManager) {
        case 'bloc':
          await _createFile(
            p.join(stateDir, '${snakeCaseName}_bloc.dart'),
            PresentationTemplates.bloc(snakeCaseName),
          );
          await _createFile(
            p.join(stateDir, '${snakeCaseName}_event.dart'),
            PresentationTemplates.blocEvent(snakeCaseName),
          );
          await _createFile(
            p.join(stateDir, '${snakeCaseName}_state.dart'),
            PresentationTemplates.blocState(snakeCaseName),
          );
          break;
        case 'riverpod':
          await _createFile(
            p.join(stateDir, '${snakeCaseName}_provider.dart'),
            PresentationTemplates.riverpod(snakeCaseName),
          );
          break;
        default:
          // Just an empty state folder (already created above)
          break;
      }

      progress.complete('Feature generated at $baseDir');
    } catch (e) {
      progress.fail('Generation failed: $e');
      rethrow;
    }
  }

  /// Bootstraps a new project with the Absolute Rule core architecture.
  ///
  /// This method creates the standard folder hierarchy in `lib/core` and `lib/shared`,
  /// generates essential utility classes (e.g., ErrorHandler, ApiClient),
  /// and updates the project's dependencies via `flutter pub add`.
  Future<void> initProject({String? stateManager}) async {
    _logger.info('Initializing core architecture...');
    final progress = _logger.progress('Generating core structure');

    try {
      // 1. Create Folder Hierarchy
      final dirs = [
        'lib/core/config',
        'lib/core/constants',
        'lib/core/di/modules',
        'lib/core/error',
        'lib/core/extensions',
        'lib/core/network/interceptors',
        'lib/core/router',
        'lib/core/storage',
        'lib/core/theme',
        'lib/core/types',
        'lib/core/utils',
        'lib/features',
        'lib/shared/widgets/buttons',
        'lib/shared/widgets/inputs',
        'lib/shared/widgets/overlays',
        'lib/shared/widgets/feedback',
        'lib/shared/widgets/layout',
        'lib/shared/state',
      ];

      for (final dir in dirs) {
        final directory = Directory(dir);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
          _logger.detail('Created: $dir');
        }
      }

      // 2. Generate Core Files
      await _createFile(
          'lib/core/error/app_error.dart', CoreTemplates.appError(),
          overwrite: true);
      await _createFile(
          'lib/core/error/error_handler.dart', CoreTemplates.errorHandler(),
          overwrite: true);
      await _createFile('lib/core/di/injection_container.dart',
          CoreTemplates.injectionContainer(stateManager),
          overwrite: true);
      await _createFile(
          'lib/core/network/api_client.dart', CoreTemplates.apiClient(),
          overwrite: true);
      await _createFile(
          'lib/core/types/typedefs.dart', CoreTemplates.typedefs(),
          overwrite: true);
      await _createFile('lib/core/utils/logger.dart', CoreTemplates.logger(),
          overwrite: true);

      // 3. Generate Root Files
      await _createFile('lib/main.dart', CoreTemplates.mainDart(stateManager),
          overwrite: true);
      await _createFile('lib/app.dart', CoreTemplates.appDart(),
          overwrite: true);
      await _createFile(
          'analysis_options.yaml', CoreTemplates.analysisOptions(),
          overwrite: true);
      await _createFile('build.yaml', CoreTemplates.buildYaml(), overwrite: true);

      // 4. Inject Dependencies
      await _addDependencies(stateManager: stateManager);

      progress.complete('Project initialized successfully.');
    } catch (e) {
      progress.fail('Initialization failed: $e');
      rethrow;
    }
  }

  Future<void> _addDependencies({String? stateManager}) async {
    final progress = _logger.progress('Injecting dependencies');

    try {
      final deps = [
        'get_it',
        'go_router',
        'dio',
        'fpdart',
        'freezed_annotation',
        'json_annotation',
        'retrofit',
      ];

      if (stateManager == 'bloc') {
        deps.add('flutter_bloc');
      } else if (stateManager == 'riverpod') {
        deps.add('flutter_riverpod');
        deps.add('riverpod_annotation');
      }

      final devDeps = [
        'freezed',
        'json_serializable',
        'build_runner',
        'retrofit_generator',
        'mocktail',
        'clean_feature_arch',
      ];

      if (stateManager == 'riverpod') {
        devDeps.add('riverpod_generator');
      }

      _logger.detail('Running: flutter pub add ${deps.join(' ')}');
      final depResult = await Process.run('flutter', ['pub', 'add', ...deps]);
      if (depResult.exitCode != 0) {
        _logger.warn(
            'Note: flutter pub add failed. Addition may be required manually.');
      }

      _logger.detail('Running: flutter pub add -d ${devDeps.join(' ')}');
      final devDepResult =
          await Process.run('flutter', ['pub', 'add', '-d', ...devDeps]);
      if (devDepResult.exitCode != 0) {
        _logger.warn(
            'Note: flutter pub add -d failed. Addition may be required manually.');
      }

      progress.complete('Dependencies injected.');
    } catch (e) {
      progress.fail('Dependency injection failed: $e');
    }
  }

  Future<void> _createFile(String path, String content,
      {bool overwrite = false}) async {
    final file = File(path);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    if (await file.exists() && !overwrite) {
      _logger.warn('Skipped: $path (Exists)');
      return;
    }

    await file.writeAsString(content);
    _logger.detail('Created: $path');
  }
}
