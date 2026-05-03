import 'package:recase/recase.dart';

class DomainTemplates {
  static String entity(String featureName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;

    return '''
import 'package:freezed_annotation/freezed_annotation.dart';

part '${snake}_entity.freezed.dart';

/// Domain entity for $pascal.
@freezed
sealed class ${pascal}Entity with _\$${pascal}Entity {
  const factory ${pascal}Entity({
    required String id,
    // TODO: Define entity properties.
  }) = _${pascal}Entity;
}
''';
  }

  static String repository(String featureName, String projectName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;

    return '''
import 'package:$projectName/core/types/typedefs.dart';
import 'package:$projectName/features/$snake/domain/entities/${snake}_entity.dart';

abstract interface class ${pascal}Repository {
  Future<Result<${pascal}Entity>> get$pascal(
    String id,
  );
}
''';
  }

  static String usecase(String featureName, String projectName) {
    final pascal = featureName.pascalCase;
    final camel = featureName.camelCase;
    final snake = featureName.snakeCase;

    return '''
import 'package:$projectName/core/types/typedefs.dart';
import 'package:$projectName/features/$snake/domain/entities/${snake}_entity.dart';
import 'package:$projectName/features/$snake/domain/repositories/${snake}_repository.dart';

class Get${pascal}UseCase {
  const Get${pascal}UseCase(
    this._${camel}Repository,
  );
  
  final ${pascal}Repository _${camel}Repository;

  Future<Result<${pascal}Entity>> call(
    String id,
  ) {
    return _${camel}Repository.get$pascal(id);
  }
}
''';
  }
}
