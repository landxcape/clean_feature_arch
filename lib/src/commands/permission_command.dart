import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../generator.dart';

class PermissionCommand extends Command<int> {
  PermissionCommand(this._logger);

  @override
  String get name => 'permission';

  @override
  String get description => 'Add and configure system permissions across all platforms.';

  final Logger _logger;

  final List<PermissionMetadata> _supportedPermissions = [
    PermissionMetadata(
      name: 'camera',
      android: ['android.permission.CAMERA'],
      iosKey: 'NSCameraUsageDescription',
      iosDesc: 'This app needs camera access to take photos.',
    ),
    PermissionMetadata(
      name: 'location',
      android: [
        'android.permission.ACCESS_FINE_LOCATION',
        'android.permission.ACCESS_COARSE_LOCATION'
      ],
      iosKey: 'NSLocationWhenInUseUsageDescription',
      iosDesc: 'This app needs location access to provide relevant data.',
    ),
    PermissionMetadata(
      name: 'microphone',
      android: ['android.permission.RECORD_AUDIO'],
      iosKey: 'NSMicrophoneUsageDescription',
      iosDesc: 'This app needs microphone access to record audio.',
    ),
    PermissionMetadata(
      name: 'photos',
      android: [
        'android.permission.READ_MEDIA_IMAGES',
        'android.permission.READ_MEDIA_VIDEO'
      ],
      iosKey: 'NSPhotoLibraryUsageDescription',
      iosDesc: 'This app needs photo library access to select photos.',
    ),
    PermissionMetadata(
      name: 'contacts',
      android: ['android.permission.READ_CONTACTS'],
      iosKey: 'NSContactsUsageDescription',
      iosDesc: 'This app needs contacts access to sync your friends.',
    ),
    PermissionMetadata(
      name: 'notifications',
      android: ['android.permission.POST_NOTIFICATIONS'],
      iosKey: '', // Not usually required for basic notifications
      iosDesc: '',
    ),
  ];

  @override
  Future<int> run() async {
    PermissionMetadata? permission;

    if (argResults?.rest.isNotEmpty ?? false) {
      final input = argResults!.rest.first.toLowerCase();
      permission = _supportedPermissions.firstWhere(
        (p) => p.name == input,
        orElse: () => throw UsageException('Unsupported permission: $input', usage),
      );
    } else {
      // Interactive Menu
      final choice = _logger.chooseOne(
        'Which permission would you like to add?',
        choices: _supportedPermissions.map((p) => p.name).toList(),
      );
      permission = _supportedPermissions.firstWhere((p) => p.name == choice);
    }

    final generator = FeatureGenerator(_logger);

    try {
      await generator.addPermission(permission);
      _logger.success('Successfully configured ${permission.name} permission.');
      return ExitCode.success.code;
    } catch (e) {
      _logger.err('Failed to add permission: $e');
      return ExitCode.software.code;
    }
  }
}

class PermissionMetadata {
  final String name;
  final List<String> android;
  final String iosKey;
  final String iosDesc;

  const PermissionMetadata({
    required this.name,
    required this.android,
    required this.iosKey,
    required this.iosDesc,
  });
}
