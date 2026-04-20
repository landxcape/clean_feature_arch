import 'package:flutter/material.dart';

/// This is a basic Flutter application demonstrating the integration of
/// the `clean_feature_arch` analyzer plugin.
///
/// To see the linter in action:
/// 1. Run `dart pub get` in this example directory.
/// 2. Add `plugins: [custom_lint]` to your `analysis_options.yaml`.
/// 3. Create a feature folder in `lib/features/` and attempt to cross-import
///    internal layers (e.g., domain importing from data).
void main() {
  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text('Absolute Rule Architecture Example'),
      ),
    ),
  ));
}
