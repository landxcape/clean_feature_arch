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
    // TODO: Add properties
  }) = _${pascal}Entity;
}
''';
  }

  static String repository(String featureName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;
    
    return '''
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_error.dart';
import '../entities/${snake}_entity.dart';

/// Repository interface for $pascal.
abstract interface class ${pascal}Repository {
  Future<Either<AppError, ${pascal}Entity>> get$pascal(String id);
}
''';
  }

  static String usecase(String featureName) {
    final pascal = featureName.pascalCase;
    final camel = featureName.camelCase;
    final snake = featureName.snakeCase;
    
    return '''
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_error.dart';
import '../entities/${snake}_entity.dart';
import '../repositories/${snake}_repository.dart';

/// Use case for fetching a $pascal.
class Get${pascal}UseCase {
  const Get${pascal}UseCase(this._${camel}Repository);
  
  final ${pascal}Repository _${camel}Repository;

  Future<Either<AppError, ${pascal}Entity>> call(String id) {
    return _${camel}Repository.get$pascal(id);
  }
}
''';
  }
}
