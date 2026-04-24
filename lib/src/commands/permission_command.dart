import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import '../generator.dart';

class PermissionMetadata {
  const PermissionMetadata({
    required this.name,
    required this.android,
    required this.iosKey,
    required this.iosDesc,
  });

  final String name;
  final List<String> android;
  final String iosKey;
  final String iosDesc;
}

const cameraPermission = PermissionMetadata(
  name: 'camera',
  android: ['android.permission.CAMERA'],
  iosKey: 'NSCameraUsageDescription',
  iosDesc: 'This app needs camera access to take photos.',
);

const locationPermission = PermissionMetadata(
  name: 'location',
  android: [
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION'
  ],
  iosKey: 'NSLocationWhenInUseUsageDescription',
  iosDesc: 'This app needs location access to provide relevant data.',
);

const storagePermission = PermissionMetadata(
  name: 'storage',
  android: [
    'android.permission.READ_EXTERNAL_STORAGE',
    'android.permission.WRITE_EXTERNAL_STORAGE'
  ],
  iosKey: 'NSPhotoLibraryUsageDescription',
  iosDesc: 'This app needs photo library access to save and select photos.',
);

const microphonePermission = PermissionMetadata(
  name: 'microphone',
  android: ['android.permission.RECORD_AUDIO'],
  iosKey: 'NSMicrophoneUsageDescription',
  iosDesc: 'This app needs microphone access to record audio.',
);

const photosPermission = PermissionMetadata(
  name: 'photos',
  android: [], // Not needed for Android 13+ usually
  iosKey: 'NSPhotoLibraryUsageDescription',
  iosDesc: 'This app needs photo library access to save and select photos.',
);

const contactsPermission = PermissionMetadata(
  name: 'contacts',
  android: ['android.permission.READ_CONTACTS'],
  iosKey: 'NSContactsUsageDescription',
  iosDesc: 'This app needs contacts access to connect with friends.',
);

const bluetoothPermission = PermissionMetadata(
  name: 'bluetooth',
  android: ['android.permission.BLUETOOTH_CONNECT', 'android.permission.BLUETOOTH_SCAN'],
  iosKey: 'NSBluetoothAlwaysUsageDescription',
  iosDesc: 'This app needs bluetooth access to connect to devices.',
);

class PermissionCommand extends Command<int> {
  PermissionCommand(this._logger);

  @override
  String get name => 'permission';

  @override
  String get description => 'Add and configure system permissions across all platforms.';

  final Logger _logger;

  @override
  Future<int> run() async {
    final permissions = [
      cameraPermission,
      locationPermission,
      storagePermission,
      microphonePermission,
      photosPermission,
      contactsPermission,
      bluetoothPermission,
    ];

    PermissionMetadata? selected;

    if (argResults?.rest.isNotEmpty ?? false) {
      final name = argResults!.rest.first.toLowerCase();
      selected = permissions.firstWhere(
        (p) => p.name == name,
        orElse: () => throw UsageException('Permission "$name" not supported.', usage),
      );
    } else {
      final choice = _logger.chooseOne(
        'Select Permission to Configure:',
        choices: permissions.map((p) => p.name).toList(),
        defaultValue: permissions.first.name,
      );
      selected = permissions.firstWhere((p) => p.name == choice);
    }

    final generator = FeatureGenerator(_logger);
    await generator.addPermission(selected);

    _logger.success('Successfully configured ${selected.name} permission.');
    return ExitCode.success.code;
  }
}
