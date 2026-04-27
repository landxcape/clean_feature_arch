import 'package:recase/recase.dart';

class PresentationTemplates {
  static String screen(String featureName, String projectName, {String? stateManager, String stateFolderName = 'state'}) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;

    String imports = '';
    String body = 'const Center(child: Text(\'$pascal Screen\'))';

    if (stateManager == 'bloc') {
      imports = "import 'package:flutter_bloc/flutter_bloc.dart';\nimport 'package:$projectName/features/$snake/presentation/$stateFolderName/${snake}_bloc.dart';\nimport 'package:$projectName/features/$snake/presentation/$stateFolderName/${snake}_state.dart';";
      body = '''BlocBuilder<${pascal}Bloc, ${pascal}State>(
        builder: (context, state) {
          return const Center(child: Text('$pascal Screen with BLoC'));
        },
      )''';
    } else if (stateManager == 'riverpod') {
      imports = "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:$projectName/features/$snake/presentation/$stateFolderName/${snake}_provider.dart';";
      body = 'const Center(child: Text(\'$pascal Screen with Riverpod\'))';
    } else {
      imports = "import 'package:$projectName/features/$snake/presentation/$stateFolderName/${snake}_state.dart';";
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

  static String bloc(String featureName, String projectName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;
    return '''
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:$projectName/features/$snake/presentation/bloc/${snake}_event.dart';
import 'package:$projectName/features/$snake/presentation/bloc/${snake}_state.dart';
import 'package:$projectName/features/$snake/domain/usecases/get_${snake}_usecase.dart';

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

  static String riverpod(String featureName, String projectName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;
    return '''
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:$projectName/features/$snake/domain/usecases/get_${snake}_usecase.dart';
import 'package:$projectName/core/di/injection_container.dart';

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
    final snake = featureName.snakeCase;
    return '''
import 'package:freezed_annotation/freezed_annotation.dart';

part '${snake}_state.freezed.dart';

@freezed
sealed class ${pascal}State with _\$${pascal}State {
  const factory ${pascal}State.initial() = _Initial;
  const factory ${pascal}State.loading() = _Loading;
  const factory ${pascal}State.success() = _Success;
  const factory ${pascal}State.error(String message) = _Error;
}
''';
  }
}
