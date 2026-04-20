import 'package:recase/recase.dart';

class DataTemplates {
  
  static String requestModel(String featureName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;
    
    return '''
import 'package:freezed_annotation/freezed_annotation.dart';

part '${snake}_request_model.freezed.dart';
part '${snake}_request_model.g.dart';

/// Data model for $pascal requests.
@freezed
sealed class ${pascal}RequestModel with _\$${pascal}RequestModel {
  const factory ${pascal}RequestModel({
    required String id,
    // TODO: Add properties
  }) = _${pascal}RequestModel;

  factory ${pascal}RequestModel.fromJson(Map<String, dynamic> json) => 
      _\$${pascal}RequestModelFromJson(json);
}
''';
  }

  static String responseModel(String featureName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;
    
    return '''
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../domain/entities/${snake}_entity.dart';

part '${snake}_response_model.freezed.dart';
part '${snake}_response_model.g.dart';

/// Data model for $pascal responses.
@freezed
sealed class ${pascal}ResponseModel with _\$${pascal}ResponseModel {
  const ${pascal}ResponseModel._();

  const factory ${pascal}ResponseModel({
    required String id,
    // TODO: Add properties
  }) = _${pascal}ResponseModel;

  factory ${pascal}ResponseModel.fromJson(Map<String, dynamic> json) => 
      _\$${pascal}ResponseModelFromJson(json);

  /// Map to domain entity.
  ${pascal}Entity toEntity() {
    return ${pascal}Entity(
      id: id,
    );
  }
}
''';
  }

  static String localModel(String featureName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;
    
    return '''
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../domain/entities/${snake}_entity.dart';

part '${snake}_local_model.freezed.dart';
part '${snake}_local_model.g.dart';

/// Local storage model for $pascal.
@freezed
sealed class ${pascal}LocalModel with _\$${pascal}LocalModel {
  const ${pascal}LocalModel._();

  const factory ${pascal}LocalModel({
    required String id,
    // TODO: Add properties
  }) = _${pascal}LocalModel;

  factory ${pascal}LocalModel.fromJson(Map<String, dynamic> json) => 
      _\$${pascal}LocalModelFromJson(json);

  /// Map to domain entity
  ${pascal}Entity toEntity() {
    return ${pascal}Entity(
      id: id,
    );
  }

  /// Map from domain entity
  factory ${pascal}LocalModel.fromEntity(${pascal}Entity entity) {
    return ${pascal}LocalModel(
      id: entity.id,
    );
  }
}
''';
  }

  static String remoteDatasource(String featureName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;
    
    return '''
import '../models/requests/${snake}_request_model.dart';
import '../models/responses/${snake}_response_model.dart';

abstract interface class ${pascal}RemoteDataSource {
  Future<${pascal}ResponseModel> get$pascal(${pascal}RequestModel request);
}

class ${pascal}RemoteDataSourceImpl implements ${pascal}RemoteDataSource {
  // TODO: Add HTTP client (Dio) dependency
  
  @override
  Future<${pascal}ResponseModel> get$pascal(${pascal}RequestModel request) async {
    // TODO: Implement network call
    throw UnimplementedError();
  }
}
''';
  }

  static String repositoryImpl(String featureName) {
    final pascal = featureName.pascalCase;
    final camel = featureName.camelCase;
    final snake = featureName.snakeCase;
    
    return '''
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/error_handler.dart';
import '../../domain/entities/${snake}_entity.dart';
import '../../domain/repositories/${snake}_repository.dart';
import '../datasources/${snake}_remote_datasource.dart';
import '../models/requests/${snake}_request_model.dart';

/// Repository implementation for $pascal.
class ${pascal}RepositoryImpl implements ${pascal}Repository {
  const ${pascal}RepositoryImpl(this._${camel}RemoteDataSource);

  final ${pascal}RemoteDataSource _${camel}RemoteDataSource;

  @override
  Future<Either<AppError, ${pascal}Entity>> get$pascal(String id) async {
    return ErrorHandler.guard(() async {
      final request = ${pascal}RequestModel(id: id);
      final response = await _${camel}RemoteDataSource.get$pascal(request);
      return response.toEntity();
    });
  }
}
''';
  }
}
