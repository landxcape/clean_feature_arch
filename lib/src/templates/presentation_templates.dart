import 'package:recase/recase.dart';

class PresentationTemplates {
  
  static String screen(String featureName) {
    final pascal = featureName.pascalCase;
    
    return '''
import 'package:flutter/material.dart';

/// UI Screen for $pascal.
class ${pascal}Screen extends StatelessWidget {
  const ${pascal}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Connect state management here (BlocBuilder / Consumer)
    return Scaffold(
      appBar: AppBar(
        title: const Text('$pascal'),
      ),
      body: const Center(
        child: Text('$pascal Screen'),
      ),
    );
  }
}
''';
  }

  static String state(String featureName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;
    
    return '''
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/error/app_error.dart';
import '../../domain/entities/${snake}_entity.dart';

part '${snake}_state.freezed.dart';

/// State definition for $pascal.
@freezed
sealed class ${pascal}State with _\$${pascal}State {
  const factory ${pascal}State.initial() = _Initial;
  const factory ${pascal}State.loading() = _Loading;
  const factory ${pascal}State.success(${pascal}Entity data) = _Success;
  
  /// Failure state with AppError.
  const factory ${pascal}State.failure(AppError error) = _Failure;
}
''';
  }
}
