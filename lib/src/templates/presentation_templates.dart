import 'package:recase/recase.dart';

class PresentationTemplates {
  static String screen(String featureName, String projectName,
      {String? stateManager, String stateFolderName = 'state'}) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;

    String imports = '';
    String body = "const Center(child: Text('$pascal Screen'))";

    if (stateManager == 'bloc') {
      imports =
          "import 'package:flutter_bloc/flutter_bloc.dart';\nimport 'package:$projectName/features/$snake/presentation/$stateFolderName/${snake}_bloc.dart';";
      body = '''BlocBuilder<${pascal}Bloc, ${pascal}State>(
        builder: (context, state) => switch (state) {
          ${pascal}Initial() => const Center(
            child: Text('Initial'),
          ),
          ${pascal}Loading() => const Center(
            child: CircularProgressIndicator(),
          ),
          ${pascal}Success() => const Center(
            child: Text('Success'),
          ),
          ${pascal}Error(:final message) => Center(
            child: Text(message),
          ),
        },
      )''';
    } else if (stateManager == 'riverpod') {
      imports =
          "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:$projectName/features/$snake/presentation/$stateFolderName/${snake}_provider.dart';";
      body = '''Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(${snake.camelCase}NotifierProvider);
          return switch (state) {
            AsyncData() => const Center(
              child: Text('Success'),
            ),
            AsyncLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            AsyncError(:final error) => Center(
              child: Text(
                error.toString(),
              ),
            ),
            _ => const SizedBox.shrink(),
          };
        },
      )''';
    } else {
      imports =
          "import 'package:$projectName/features/$snake/presentation/$stateFolderName/${snake}_state.dart';";
    }

    return '''
import 'package:flutter/material.dart';
$imports
import 'package:$projectName/shared/widgets/layout/app_scaffold.dart';

class ${pascal}Screen extends StatelessWidget {
  const ${pascal}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '$pascal',
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
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:$projectName/features/$snake/domain/usecases/get_${snake}_usecase.dart';

part '${snake}_event.dart';
part '${snake}_state.dart';
part '${snake}_bloc.freezed.dart';

class ${pascal}Bloc extends Bloc<${pascal}Event, ${pascal}State> {
  ${pascal}Bloc(this._get${pascal}UseCase) : super(const ${pascal}Initial()) {
    on<${pascal}Started>((event, emit) {
      // TODO: Implement event handler
    });
  }

  // ignore: unused_field
  final Get${pascal}UseCase _get${pascal}UseCase;
}
''';
  }

  static String blocEvent(String featureName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;
    return '''
part of '${snake}_bloc.dart';

@freezed
sealed class ${pascal}Event with _\$${pascal}Event {
  const factory ${pascal}Event.started() = ${pascal}Started;
}
''';
  }

  static String blocState(String featureName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;
    return '''
part of '${snake}_bloc.dart';

@freezed
sealed class ${pascal}State with _\$${pascal}State {
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
import 'dart:async';
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
    // ignore: unused_local_variable
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
