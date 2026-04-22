import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';
import 'package:mason_logger/mason_logger.dart';
import 'templates/domain_templates.dart';
import 'templates/data_templates.dart';
import 'templates/presentation_templates.dart';
import 'templates/core_templates.dart';

/// Generates architectural layers and core utilities.
class FeatureGenerator {
  /// Creates a [FeatureGenerator] with the provided [Logger].
  FeatureGenerator(this._logger);

  final Logger _logger;

  /// Scaffolds a feature directory structure at [targetDirectory].
  ///
  /// Converts [name] to snake_case. Defaults to `lib/features/<name>`
  /// if [targetDirectory] is null.
  Future<void> generate(String name,
      {String? targetDirectory, String? stateManager, bool force = false}) async {
    final snakeCaseName = name.snakeCase;
    final baseDir = targetDirectory ?? p.join('lib', 'features', snakeCaseName);

    _logger.info('Generating feature: ${lightCyan.wrap(snakeCaseName)}...');

    final progress = _logger.progress('Generating layers');

    try {
      // 1. Domain Layer
      await _createFile(
        p.join(baseDir, 'domain', 'entities', '${snakeCaseName}_entity.dart'),
        DomainTemplates.entity(snakeCaseName),
        overwrite: force,
      );
      await _createFile(
        p.join(baseDir, 'domain', 'repositories',
            '${snakeCaseName}_repository.dart'),
        DomainTemplates.repository(snakeCaseName),
        overwrite: force,
      );
      await _createFile(
        p.join(
            baseDir, 'domain', 'usecases', 'get_${snakeCaseName}_usecase.dart'),
        DomainTemplates.usecase(snakeCaseName),
        overwrite: force,
      );

      // 2. Data Layer
      await _createFile(
        p.join(baseDir, 'data', 'models', 'requests',
            '${snakeCaseName}_request_model.dart'),
        DataTemplates.requestModel(snakeCaseName),
        overwrite: force,
      );
      await _createFile(
        p.join(baseDir, 'data', 'models', 'responses',
            '${snakeCaseName}_response_model.dart'),
        DataTemplates.responseModel(snakeCaseName),
        overwrite: force,
      );
      await _createFile(
        p.join(baseDir, 'data', 'models', 'local',
            '${snakeCaseName}_local_model.dart'),
        DataTemplates.localModel(snakeCaseName),
        overwrite: force,
      );

      // Data Sources
      await _createFile(
        p.join(baseDir, 'data', 'data_sources', 'remote_data_sources',
            '${snakeCaseName}_remote_data_source.dart'),
        DataTemplates.remoteDataSource(snakeCaseName),
        overwrite: force,
      );
      await _createFile(
        p.join(baseDir, 'data', 'data_sources', 'local_data_sources',
            '${snakeCaseName}_local_data_source.dart'),
        DataTemplates.localDataSource(snakeCaseName),
        overwrite: force,
      );
      await _createFile(
        p.join(baseDir, 'data', 'repositories',
            '${snakeCaseName}_repository_impl.dart'),
        DataTemplates.repositoryImpl(snakeCaseName),
        overwrite: force,
      );

      // 3. Presentation Layer
      await _createFile(
        p.join(
            baseDir, 'presentation', 'screens', '${snakeCaseName}_screen.dart'),
        PresentationTemplates.screen(snakeCaseName, stateManager: stateManager),
        overwrite: force,
      );

      // Create state folder explicitly
      final stateDir = p.join(baseDir, 'presentation', 'state');
      await Directory(stateDir).create(recursive: true);

      switch (stateManager) {
        case 'bloc':
          await _createFile(
            p.join(stateDir, '${snakeCaseName}_bloc.dart'),
            PresentationTemplates.bloc(snakeCaseName),
            overwrite: force,
          );
          await _createFile(
            p.join(stateDir, '${snakeCaseName}_event.dart'),
            PresentationTemplates.blocEvent(snakeCaseName),
            overwrite: force,
          );
          await _createFile(
            p.join(stateDir, '${snakeCaseName}_state.dart'),
            PresentationTemplates.blocState(snakeCaseName),
            overwrite: force,
          );
          break;
        case 'riverpod':
          await _createFile(
            p.join(stateDir, '${snakeCaseName}_provider.dart'),
            PresentationTemplates.riverpod(snakeCaseName),
            overwrite: force,
          );
          break;
        default:
          // Just an empty state folder
          break;
      }

      progress.complete('Feature generated at $baseDir');
    } catch (e) {
      progress.fail('Generation failed: $e');
      rethrow;
    }
  }

  /// Initializes the project structure and core utilities.
  ///
  /// Creates the folder hierarchy, generates infrastructure classes,
  /// and updates project dependencies.
  Future<void> initProject({String? stateManager, bool force = false}) async {
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
          overwrite: force);
      await _createFile(
          'lib/core/error/error_handler.dart', CoreTemplates.errorHandler(),
          overwrite: force);
      await _createFile('lib/core/di/injection_container.dart',
          CoreTemplates.injectionContainer(stateManager),
          overwrite: force);
      await _createFile(
          'lib/core/network/api_client.dart', CoreTemplates.apiClient(),
          overwrite: force);
      await _createFile(
          'lib/core/types/typedefs.dart', CoreTemplates.typedefs(),
          overwrite: force);
      await _createFile('lib/core/utils/logger.dart', CoreTemplates.logger(),
          overwrite: force);

      // New Infrastructure Files
      await _createFile('lib/core/config/app_config.dart', CoreTemplates.appConfig(), overwrite: force);
      await _createFile('lib/core/config/flavor_config.dart', CoreTemplates.flavorConfig(), overwrite: force);
      await _createFile('lib/core/router/app_router.dart', CoreTemplates.appRouter(), overwrite: force);
      await _createFile('lib/core/theme/app_theme.dart', CoreTemplates.appTheme(), overwrite: force);
      await _createFile('lib/core/theme/app_colors.dart', CoreTemplates.appColors(), overwrite: force);
      await _createFile('lib/core/network/network_info.dart', CoreTemplates.networkInfo(), overwrite: force);
      await _createFile('lib/core/storage/secure_storage.dart', CoreTemplates.secureStorage(), overwrite: force);
      
      // 3. Generate Shared Files
      await _createFile('lib/shared/widgets/buttons/primary_button.dart', CoreTemplates.sharedButton(), overwrite: force);

      // 4. Generate Root Files
      await _createFile('lib/main.dart', CoreTemplates.mainDart(stateManager),
          overwrite: force);
      await _createFile('lib/app.dart', CoreTemplates.appDart(),
          overwrite: force);
      await _createFile(
          'analysis_options.yaml', CoreTemplates.analysisOptions(),
          overwrite: force);
      await _createFile('build.yaml', CoreTemplates.buildYaml(), overwrite: force);

      // 5. Inject Dependencies
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
        'flutter_secure_storage',
        'internet_connection_checker_plus',
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
      if (depResult.exitCode != 0) {
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
