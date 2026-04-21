import 'package:recase/recase.dart';

class PresentationTemplates {
  static String screen(String featureName, {String? stateManager}) {
    final pascal = featureName.pascalCase;
    final camel = featureName.camelCase;

    String stateImports = '';
    String body = '';

    if (stateManager == 'bloc') {
      stateImports =
          "import 'package:flutter_bloc/flutter_bloc.dart';\nimport '../state/${featureName.snakeCase}_bloc.dart';";
      body = '''
      body: BlocBuilder<${pascal}Bloc, ${pascal}State>(
        builder: (context, state) {
          return state.when(
            initial: () => const Center(child: Text('Initial')),
            loading: () => const Center(child: CircularProgressIndicator()),
            success: (data) => Center(child: Text('Success: \${data.id}')),
            failure: (error) => Center(child: Text(error.message)),
          );
        },
      )''';
    } else if (stateManager == 'riverpod') {
      stateImports =
          "import 'package:flutter_riverpod/flutter_riverpod.dart';\nimport '../state/${featureName.snakeCase}_provider.dart';";
      body = '''
      body: Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(${camel}Provider);
          return state.when(
            data: (data) => Center(child: Text('Success: \${data.id}')),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text(error.toString())),
          );
        },
      )''';
    } else {
      body = "body: const Center(child: Text('$pascal Screen'))";
    }

    return '''
import 'package:flutter/material.dart';
$stateImports

/// UI Screen for $pascal.
class ${pascal}Screen extends StatelessWidget {
  const ${pascal}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$pascal'),
      ),
      $body,
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
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/error/app_error.dart';
import '../../domain/entities/${snake}_entity.dart';
import '../../domain/usecases/get_${snake}_usecase.dart';

part '${snake}_bloc.freezed.dart';
part '${snake}_event.dart';
part '${snake}_state.dart';

class ${pascal}Bloc extends Bloc<${pascal}Event, ${pascal}State> {
  final Get${pascal}UseCase _get${pascal}UseCase;

  ${pascal}Bloc(this._get${pascal}UseCase) : super(const ${pascal}State.initial()) {
    on<${pascal}Event>((event, emit) async {
      await event.when(
        started: (id) async {
          emit(const ${pascal}State.loading());
          final result = await _get${pascal}UseCase(id);
          result.fold(
            (error) => emit(${pascal}State.failure(error)),
            (data) => emit(${pascal}State.success(data)),
          );
        },
      );
    });
  }
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
  const factory ${pascal}Event.started(String id) = _Started;
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
  const factory ${pascal}State.initial() = _Initial;
  const factory ${pascal}State.loading() = _Loading;
  const factory ${pascal}State.success(${pascal}Entity data) = _Success;
  const factory ${pascal}State.failure(AppError error) = _Failure;
}
''';
  }

  static String riverpod(String featureName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;

    return '''
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/${snake}_entity.dart';
import '../../domain/usecases/get_${snake}_usecase.dart';
import '../../../../core/di/injection_container.dart';

part '${snake}_provider.g.dart';

@riverpod
class ${pascal} extends _\$${pascal} {
  @override
  FutureOr<${pascal}Entity> build() async {
    // Initial data fetch if needed
    throw UnimplementedError();
  }

  Future<void> get$pascal(String id) async {
    state = const AsyncValue.loading();
    final useCase = sl<Get${pascal}UseCase>();
    final result = await useCase(id);
    
    state = result.fold(
      (error) => AsyncValue.error(error.message, StackTrace.current),
      (data) => AsyncValue.data(data),
    );
  }
}
''';
  }

  static String genericState(String featureName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;

    return '''
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/error/app_error.dart';
import '../../domain/entities/${snake}_entity.dart';

part '${snake}_state.freezed.dart';

@freezed
sealed class ${pascal}State with _\$${pascal}State {
  const factory ${pascal}State.initial() = _Initial;
  const factory ${pascal}State.loading() = _Loading;
  const factory ${pascal}State.success(${pascal}Entity data) = _Success;
  const factory ${pascal}State.failure(AppError error) = _Failure;
}
''';
  }
}
