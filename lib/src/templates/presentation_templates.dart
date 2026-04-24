import 'package:recase/recase.dart';

class PresentationTemplates {
  static String screen(String featureName, {String? stateManager, String stateFolderName = 'state'}) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;

    String imports = '';
    String body = 'const Center(child: Text(\'$pascal Screen\'))';

    if (stateManager == 'bloc') {
      imports = "import 'package:flutter_bloc/flutter_bloc.dart';\nimport '../$stateFolderName/${snake}_bloc.dart';\nimport '../$stateFolderName/${snake}_state.dart';";
      body = '''BlocBuilder<${pascal}Bloc, ${pascal}State>(
        builder: (context, state) {
          return const Center(child: Text('$pascal Screen with BLoC'));
        },
      )''';
    } else if (stateManager == 'riverpod') {
      imports = "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../$stateFolderName/${snake}_provider.dart';";
      body = 'const Center(child: Text(\'$pascal Screen with Riverpod\'))';
    } else {
      imports = "import '../$stateFolderName/${snake}_state.dart';";
    }

    return '''
import 'package:flutter/material.dart';
$imports

class ${pascal}Screen extends StatelessWidget {
  const ${pascal}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$pascal')),
      body: $body,
    );
  }
}
''';
  }

  static String bloc(String featureName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;
    return '''
import 'package:flutter_bloc/flutter_bloc.dart';
import '${snake}_event.dart';
import '${snake}_state.dart';
import '../../domain/usecases/get_${snake}_usecase.dart';

class ${pascal}Bloc extends Bloc<${pascal}Event, ${pascal}State> {
  final Get${pascal}UseCase _get${pascal}UseCase;

  ${pascal}Bloc(this._get${pascal}UseCase) : super(const ${pascal}State.initial()) {
    on<${pascal}Started>((event, emit) {
      // TODO: Implement event handler
    });
  }
}
''';
  }

  static String blocEvent(String featureName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;
    return '''
import 'package:freezed_annotation/freezed_annotation.dart';

part '${snake}_event.freezed.dart';

@freezed
class ${pascal}Event with _\$${pascal}Event {
  const factory ${pascal}Event.started() = ${pascal}Started;
}
''';
  }

  static String blocState(String featureName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;
    return '''
import 'package:freezed_annotation/freezed_annotation.dart';

part '${snake}_state.freezed.dart';

@freezed
class ${pascal}State with _\$${pascal}State {
  const factory ${pascal}State.initial() = ${pascal}Initial;
  const factory ${pascal}State.loading() = ${pascal}Loading;
  const factory ${pascal}State.success() = ${pascal}Success;
  const factory ${pascal}State.error(String message) = ${pascal}Error;
}
''';
  }

  static String riverpod(String featureName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;
    return '''
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/usecases/get_${snake}_usecase.dart';
import '../../../../core/di/injection_container.dart';

part '${snake}_provider.g.dart';

@riverpod
class ${pascal}Notifier extends _\$${pascal}Notifier {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  Future<void> fetchData() async {
    state = const AsyncValue.loading();
    final useCase = sl<Get${pascal}UseCase>();
    // TODO: Implement logic
  }
}
''';
  }

  static String genericState(String featureName) {
    final pascal = featureName.pascalCase;
    return '''
/// State management for $pascal.
class ${pascal}State {
  const ${pascal}State();
}
''';
  }
}
