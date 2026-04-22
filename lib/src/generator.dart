import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';
import 'templates/domain_templates.dart';
import 'templates/data_templates.dart';
import 'templates/presentation_templates.dart';
import 'templates/core_templates.dart';
import 'templates/test_templates.dart';
import 'commands/permission_command.dart';

/// Overwrite strategy for file conflicts.
enum OverwriteStrategy { ask, always, skipAll }

/// Generates architectural layers and core utilities.
class FeatureGenerator {
  /// Creates a [FeatureGenerator] with the provided [Logger].
  FeatureGenerator(this._logger);

  final Logger _logger;

  /// The current strategy for handling file conflicts.
  OverwriteStrategy _strategy = OverwriteStrategy.ask;

  /// Scaffolds a feature directory structure at [targetDirectory].
  ///
  /// Converts [name] to snake_case. Defaults to `lib/features/<name>`
  /// if [targetDirectory] is null.
  Future<void> generate(String name,
      {String? targetDirectory, String? stateManager, bool force = false}) async {
    final snakeCaseName = name.snakeCase;
    final baseDir = targetDirectory ?? p.join('lib', 'features', snakeCaseName);

    _strategy = force ? OverwriteStrategy.always : OverwriteStrategy.ask;

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
    _strategy = force ? OverwriteStrategy.always : OverwriteStrategy.ask;

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
      await _createFile('lib/core/error/app_error.dart', CoreTemplates.appError());
      await _createFile('lib/core/error/error_handler.dart', CoreTemplates.errorHandler());
      await _createFile('lib/core/di/injection_container.dart', CoreTemplates.injectionContainer(stateManager));
      await _createFile('lib/core/network/api_client.dart', CoreTemplates.apiClient());
      await _createFile('lib/core/network/network_info.dart', CoreTemplates.networkInfo());
      await _createFile('lib/core/network/network_info_impl.dart', CoreTemplates.networkInfoImpl());
      await _createFile('lib/core/network/interceptors/auth_interceptor.dart', CoreTemplates.authInterceptor());
      await _createFile('lib/core/network/interceptors/logging_interceptor.dart', CoreTemplates.loggingInterceptor());
      await _createFile('lib/core/storage/secure_storage.dart', CoreTemplates.secureStorage());
      await _createFile('lib/core/storage/secure_storage_impl.dart', CoreTemplates.secureStorageImpl());
      await _createFile('lib/core/config/app_config.dart', CoreTemplates.appConfig());
      await _createFile('lib/core/config/flavor_config.dart', CoreTemplates.flavorConfig());
      await _createFile('lib/core/router/app_router.dart', CoreTemplates.appRouter());
      await _createFile('lib/core/constants/route_constants.dart', CoreTemplates.routeConstants());
      await _createFile('lib/core/theme/app_theme.dart', CoreTemplates.appTheme());
      await _createFile('lib/core/theme/app_colors.dart', CoreTemplates.appColors());
      await _createFile('lib/core/theme/app_spacing.dart', CoreTemplates.appSpacing());
      await _createFile('lib/core/theme/app_text_theme.dart', CoreTemplates.appTextTheme());
      await _createFile('lib/core/extensions/context_extensions.dart', CoreTemplates.contextExtensions());
      await _createFile('lib/core/extensions/string_extensions.dart', CoreTemplates.stringExtensions());
      await _createFile('lib/core/utils/validator_utils.dart', CoreTemplates.validatorUtils());
      await _createFile('lib/core/utils/permission_service.dart', CoreTemplates.permissionService());
      await _createFile('lib/core/utils/logger.dart', CoreTemplates.logger());
      await _createFile('lib/core/types/typedefs.dart', CoreTemplates.typedefs());

      // 3. Generate Shared Files
      await _createFile('lib/shared/widgets/buttons/primary_button.dart', CoreTemplates.sharedButton());
      await _createFile('lib/shared/widgets/layout/app_scaffold.dart', CoreTemplates.appScaffold());

      // 4. Generate Root Files
      await _createFile('lib/main.dart', CoreTemplates.mainDart(stateManager));
      await _createFile('lib/app.dart', CoreTemplates.appDart());
      await _createFile('analysis_options.yaml', CoreTemplates.analysisOptions());
      await _createFile('build.yaml', CoreTemplates.buildYaml());

      // 5. Platform Patching
      await _patchAndroidManifest();
      await _patchInfoPlist();

      // 6. Inject Dependencies
      await _addDependencies(stateManager: stateManager);

      progress.complete('Project initialized successfully.');
    } catch (e) {
      progress.fail('Initialization failed: $e');
      rethrow;
    }
  }

  /// Scaffolds CI/CD configuration.
  Future<void> addCI(String platform) async {
    final progress = _logger.progress('Scaffolding $platform configuration');
    try {
      if (platform == 'github_actions') {
        await _createFile('.github/workflows/verify.yml', CoreTemplates.githubVerify());
      } else if (platform == 'gitlab_ci') {
        await _createFile('.gitlab-ci.yml', CoreTemplates.gitlabCI());
      }
      progress.complete();
    } catch (e) {
      progress.fail('CI scaffolding failed: $e');
    }
  }

  /// Scaffolds initial test infrastructure.
  Future<void> initTests() async {
    final progress = _logger.progress('Scaffolding test infrastructure');
    try {
      final projectName = _getProjectName();
      var testContent = CoreTemplates.apiClientTest();
      testContent = testContent.replaceFirst('your_project', projectName);

      await _createFile('test/core/network/api_client_test.dart', testContent);
      progress.complete();
    } catch (e) {
      progress.fail('Test scaffolding failed: $e');
    }
  }

  /// Scaffolds feature-specific unit and integration tests.
  Future<void> generateFeatureTests(String name, {bool force = false}) async {
    final snakeCaseName = name.snakeCase;
    _strategy = force ? OverwriteStrategy.always : OverwriteStrategy.ask;

    final progress = _logger.progress('Generating tests for $snakeCaseName');

    try {
      final projectName = _getProjectName();

      // 1. Detect State Manager
      final stateDir = 'lib/features/$snakeCaseName/presentation/state';
      String? stateManager;
      
      if (await File('$stateDir/${snakeCaseName}_bloc.dart').exists()) {
        stateManager = 'bloc';
      } else if (await File('$stateDir/${snakeCaseName}_provider.dart').exists()) {
        stateManager = 'riverpod';
      }

      // 2. Integration: Live API Test
      await _createFile(
        'test/integration/live_api/${snakeCaseName}_api_test.dart',
        TestTemplates.liveApiTest(snakeCaseName, projectName),
      );

      // 3. Unit: Repository Test
      await _createFile(
        'test/features/$snakeCaseName/data/repositories/${snakeCaseName}_repository_impl_test.dart',
        TestTemplates.repositoryTest(snakeCaseName, projectName),
      );

      // 4. Unit: UseCase Test
      await _createFile(
        'test/features/$snakeCaseName/domain/usecases/get_${snakeCaseName}_usecase_test.dart',
        TestTemplates.usecaseTest(snakeCaseName, projectName),
      );

      // 5. Unit: State Test
      if (stateManager == 'bloc') {
        await _createFile(
          'test/features/$snakeCaseName/presentation/state/${snakeCaseName}_bloc_test.dart',
          TestTemplates.blocTest(snakeCaseName, projectName),
        );
      } else if (stateManager == 'riverpod') {
        await _createFile(
          'test/features/$snakeCaseName/presentation/state/${snakeCaseName}_provider_test.dart',
          TestTemplates.riverpodTest(snakeCaseName, projectName),
        );
      }

      progress.complete('Tests generated for $snakeCaseName');
    } catch (e) {
      progress.fail('Test generation failed: $e');
    }
  }

  String _getProjectName() {
    final file = File('pubspec.yaml');
    if (!file.existsSync()) return 'your_project';
    final yaml = loadYaml(file.readAsStringSync()) as YamlMap;
    return yaml['name'] as String? ?? 'your_project';
  }

  /// Adds a system permission across Android, iOS, and the Dart service.
  Future<void> addPermission(PermissionMetadata permission) async {
    final progress = _logger.progress('Configuring ${permission.name} permission');

    try {
      // 1. Android Manifest
      await _updateAndroidManifest(permission.android);

      // 2. iOS Info.plist
      if (permission.iosKey.isNotEmpty) {
        await _updateInfoPlist(permission.iosKey, permission.iosDesc);
      }

      // 3. Dart PermissionService
      await _updatePermissionService(permission.name);

      progress.complete('${permission.name} permission configured.');
    } catch (e) {
      progress.fail('Failed to configure permission: $e');
      rethrow;
    }
  }

  Future<void> _updateAndroidManifest(List<String> permissions) async {
    final file = File('android/app/src/main/AndroidManifest.xml');
    if (!await file.exists()) return;

    var content = await file.readAsString();
    bool modified = false;

    for (final p in permissions) {
      if (!content.contains(p)) {
        final xml = '    <uses-permission android:name="$p" />';
        content = content.replaceFirst('<application', '$xml\n    <application');
        modified = true;
      }
    }

    if (modified) await file.writeAsString(content);
  }

  Future<void> _updateInfoPlist(String key, String desc) async {
    final file = File('ios/Runner/Info.plist');
    if (!await file.exists()) return;

    var content = await file.readAsString();
    if (!content.contains(key)) {
      final entry = '\n\t<key>$key</key>\n\t<string>$desc</string>';
      content = content.replaceFirst('<dict>', '<dict>$entry');
      await file.writeAsString(content);
    }
  }

  Future<void> _updatePermissionService(String name) async {
    final path = 'lib/core/utils/permission_service.dart';
    final file = File(path);
    if (!await file.exists()) return;

    var content = await file.readAsString();
    final pascal = name.pascalCase;

    // 1. Add to interface
    if (!content.contains('request$pascal()')) {
      final interfaceSearch = 'Future<void> openSettings();';
      content = content.replaceFirst(
        interfaceSearch,
        '$interfaceSearch\n  Future<bool> request$pascal();',
      );
    }

    // 2. Add to implementation
    if (!content.contains('request$pascal() async')) {
      final implSearch = 'await openAppSettings();\n  }';
      final implementation = '''
\n  @override
  Future<bool> request$pascal() async {
    final status = await Permission.$name.request();
    return status.isGranted;
  }''';
      
      content = content.replaceFirst(
        implSearch,
        '$implSearch$implementation',
      );
    }

    await file.writeAsString(content);
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
        'permission_handler',
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

  Future<void> _patchAndroidManifest() async {
    final manifestPath = 'android/app/src/main/AndroidManifest.xml';
    final file = File(manifestPath);

    if (!await file.exists()) return;

    final content = await file.readAsString();
    const permission = '    <uses-permission android:name="android.permission.INTERNET" />';

    if (!content.contains('android.permission.INTERNET')) {
      final updatedContent = content.replaceFirst(
        '<application',
        '$permission\n    <application',
      );
      await file.writeAsString(updatedContent);
      _logger.detail('Patched AndroidManifest.xml with Internet permission.');
    }
  }

  Future<void> _patchInfoPlist() async {
    final plistPath = 'ios/Runner/Info.plist';
    final file = File(plistPath);

    if (!await file.exists()) return;

    var content = await file.readAsString();
    bool modified = false;

    final Map<String, String> permissions = {
      'NSCameraUsageDescription': 'This app needs camera access to take photos.',
      'NSLocationWhenInUseUsageDescription': 'This app needs location access to provide relevant data.',
      'NSPhotoLibraryUsageDescription': 'This app needs photo library access to save and select photos.',
    };

    for (final entry in permissions.entries) {
      if (!content.contains(entry.key)) {
        content = content.replaceFirst(
          '<dict>',
          '<dict>\n\t<key>${entry.key}</key>\n\t<string>${entry.value}</string>',
        );
        modified = true;
      }
    }

    if (modified) {
      await file.writeAsString(content);
      _logger.detail('Patched Info.plist with permission descriptions.');
    }
  }

  Future<void> _createFile(String path, String content) async {
    final file = File(path);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    if (await file.exists()) {
      if (_strategy == OverwriteStrategy.skipAll) {
        _logger.detail('Skipped: $path (Strategy: Skip All)');
        return;
      }

      if (_strategy == OverwriteStrategy.ask) {
        final choice = _logger.chooseOne(
          'File $path already exists. Overwrite?',
          choices: ['Yes', 'No', 'Always', 'Skip All'],
          defaultValue: 'No',
        );

        switch (choice) {
          case 'Always':
            _strategy = OverwriteStrategy.always;
            break;
          case 'Skip All':
            _strategy = OverwriteStrategy.skipAll;
            _logger.detail('Skipping all remaining conflicts.');
            return;
          case 'No':
            _logger.warn('Skipped: $path');
            return;
          case 'Yes':
            // Continue to write
            break;
        }
      }
    }

    await file.writeAsString(content);
    _logger.detail('Created: $path');
  }
}
