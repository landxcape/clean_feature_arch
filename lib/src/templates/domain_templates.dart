import 'package:recase/recase.dart';

class DomainTemplates {
  static String entity(String featureName) {
    final snake = featureName.snakeCase;

    return '''
import 'package:freezed_annotation/freezed_annotation.dart';

part '${snake}_entity.freezed.dart';

/// Domain entity for ${featureName.pascalCase}.
@freezed
sealed class ${featureName.pascalCase}Entity with _\$${featureName.pascalCase}Entity {
  const factory ${featureName.pascalCase}Entity({
    required String id,
    // TODO: Add properties
  }) = _${featureName.pascalCase}Entity;
}
''';
  }

  static String repository(String featureName, String projectName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;

    return '''
import 'package:$projectName/core/types/typedefs.dart';
import 'package:$projectName/features/$snake/domain/entities/${snake}_entity.dart';

/// Repository interface for $pascal.
abstract interface class ${pascal}Repository {
  Future<Result<${pascal}Entity>> get$pascal(String id);
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

/// Use case for fetching a $pascal.
class Get${pascal}UseCase {
  const Get${pascal}UseCase(this._${camel}Repository);
  
  final ${pascal}Repository _${camel}Repository;

  Future<Result<${pascal}Entity>> call(String id) {
    return _${camel}Repository.get$pascal(id);
  }
}
''';
  }
}
