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
    // TODO: Define model properties.
  }) = _${pascal}RequestModel;

  factory ${pascal}RequestModel.fromJson(Map<String, dynamic> json) => 
      _\$${pascal}RequestModelFromJson(json);
}
''';
  }

  static String responseModel(String featureName, String projectName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;

    return '''
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:$projectName/features/$snake/domain/entities/${snake}_entity.dart';

part '${snake}_response_model.freezed.dart';
part '${snake}_response_model.g.dart';

/// Data model for $pascal responses.
@freezed
sealed class ${pascal}ResponseModel with _\$${pascal}ResponseModel {
  const ${pascal}ResponseModel._();

  const factory ${pascal}ResponseModel({
    required String id,
    // TODO: Define model properties.
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

  static String localModel(String featureName, String projectName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;

    return '''
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:$projectName/features/$snake/domain/entities/${snake}_entity.dart';

part '${snake}_local_model.freezed.dart';
part '${snake}_local_model.g.dart';

/// Local storage model for $pascal.
@freezed
sealed class ${pascal}LocalModel with _\$${pascal}LocalModel {
  const ${pascal}LocalModel._();

  const factory ${pascal}LocalModel({
    required String id,
    // TODO: Define model properties.
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

  static String remoteDataSource(String featureName, String projectName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;

    return '''
import 'package:$projectName/features/$snake/data/models/requests/${snake}_request_model.dart';
import 'package:$projectName/features/$snake/data/models/responses/${snake}_response_model.dart';

abstract interface class ${pascal}RemoteDataSource {
  Future<${pascal}ResponseModel> get$pascal(${pascal}RequestModel request);
}

class ${pascal}RemoteDataSourceImpl implements ${pascal}RemoteDataSource {
  // TODO: Add HTTP client (Dio) dependency via DI.
  
  @override
  Future<${pascal}ResponseModel> get$pascal(${pascal}RequestModel request) async {
    // TODO: Implement the network request.
    throw UnimplementedError();
  }
}
''';
  }

  static String localDataSource(String featureName, String projectName, {String? storageType}) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;

    String imports = '';
    String tableDef = '';
    String fields = '';
    String params = '';

    if (storageType == 'drift') {
      imports = "\nimport 'package:drift/drift.dart';\nimport 'package:$projectName/core/storage/app_database.dart';";
      tableDef = '''

/// Local database table for $pascal.
class ${pascal}Table extends Table {
  IntColumn get id => integer().autoIncrement()();
}
''';
      fields = "\n  final AppDatabase _db;";
      params = "this._db";
    } else if (storageType == 'shared') {
      imports = "\nimport 'package:$projectName/core/storage/local_settings.dart';";
      fields = "\n  final LocalSettings _localSettings;";
      params = "this._localSettings";
    }

    return '''
import 'package:$projectName/features/$snake/data/models/local/${snake}_local_model.dart';$imports
$tableDef
abstract interface class ${pascal}LocalDataSource {
  Future<void> save$pascal(${pascal}LocalModel model);
  Future<${pascal}LocalModel?> get$pascal(String id);
}

class ${pascal}LocalDataSourceImpl implements ${pascal}LocalDataSource {$fields
  const ${pascal}LocalDataSourceImpl($params);

  @override
  Future<void> save$pascal(${pascal}LocalModel model) async {
    // TODO: Implement local storage.
    throw UnimplementedError();
  }

  @override
  Future<${pascal}LocalModel?> get$pascal(String id) async {
    // TODO: Implement local storage.
    throw UnimplementedError();
  }
}
''';
  }

  static String repositoryImpl(String featureName, String projectName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;

    return '''
import 'package:$projectName/core/error/error_handler.dart';
import 'package:$projectName/core/types/typedefs.dart';
import 'package:$projectName/features/$snake/domain/entities/${snake}_entity.dart';
import 'package:$projectName/features/$snake/domain/repositories/${snake}_repository.dart';
import 'package:$projectName/features/$snake/data/data_sources/remote_data_sources/${snake}_remote_data_source.dart';
import 'package:$projectName/features/$snake/data/data_sources/local_data_sources/${snake}_local_data_source.dart';
import 'package:$projectName/features/$snake/data/models/requests/${snake}_request_model.dart';

/// Repository implementation for $pascal.
class ${pascal}RepositoryImpl implements ${pascal}Repository {
  const ${pascal}RepositoryImpl(this._remoteDataSource, this._localDataSource);

  final ${pascal}RemoteDataSource _remoteDataSource;
  final ${pascal}LocalDataSource _localDataSource;

  @override
  Future<Result<${pascal}Entity>> get$pascal(String id) async {
    return ErrorHandler.guard(() async {
      final request = ${pascal}RequestModel(id: id);
      final response = await _remoteDataSource.get$pascal(request);
      return response.toEntity();
    });
  }
}
''';
  }
}
