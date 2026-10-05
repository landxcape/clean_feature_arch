import 'package:flutter/material.dart';

/// This is a basic Flutter application demonstrating the integration of
/// the `clean_feature_arch` analyzer plugin.
///
/// The plugin activates automatically via `dev_dependencies` in `pubspec.yaml`.
/// To see the architectural linter in action:
/// 1. Run `dart pub get` in this example directory.
/// 2. Create a feature folder in `lib/features/` and attempt to cross-import
///    internal layers (e.g., domain importing from data).
/// 3. Run `dart analyze` to observe architectural diagnostic reports.
void main() {
  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text('Absolute Rule Architecture Example'),
      ),
    ),
  ));
}
