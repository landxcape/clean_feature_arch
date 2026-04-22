import 'package:recase/recase.dart';

class TestTemplates {
  // --- Integration (Live API) ---
  static String liveApiTest(String featureName, String projectName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;

    return '''
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:$projectName/core/network/api_client.dart';
import 'package:$projectName/features/$snake/data/models/responses/${snake}_response_model.dart';

void main() {
  late Dio dio;

  setUpAll(() {
    dio = ApiClient.create();
  });

  group('Live Fire: $pascal API Integration', () {
    test('Fetch and Parse $pascal', () async {
      const url = '/your-endpoint-here'; 
      
      late Response response;
      try {
        response = await dio.get(url);
      } on DioException catch (e) {
        fail('API Request Failed.\\nStatus: \${e.response?.statusCode}\\nBody: \${e.response?.data}');
      }

      expect(response.statusCode, 200);

      try {
        final data = response.data;
        final model = ${pascal}ResponseModel.fromJson(data);
        expect(model, isNotNull);
      } catch (e) {
        fail('Parse Failed!\\nError: \$e\\nJSON: \${response.data}');
      }
    });
  });
}
''';
  }

  // --- Unit Tests (Mocks) ---
  static String repositoryTest(String featureName, String projectName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;

    return '''
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:$projectName/features/$snake/data/repositories/${snake}_repository_impl.dart';
import 'package:$projectName/features/$snake/data/data_sources/remote_data_sources/${snake}_remote_data_source.dart';
import 'package:$projectName/features/$snake/data/models/requests/${snake}_request_model.dart';
import 'package:$projectName/features/$snake/data/models/responses/${snake}_response_model.dart';

class Mock${pascal}RemoteDataSource extends Mock implements ${pascal}RemoteDataSource {}
class Fake${pascal}RequestModel extends Fake implements ${pascal}RequestModel {}

void main() {
  late ${pascal}RepositoryImpl repository;
  late Mock${pascal}RemoteDataSource mockRemoteDataSource;

  setUpAll(() {
    registerFallbackValue(Fake${pascal}RequestModel());
  });

  setUp(() {
    mockRemoteDataSource = Mock${pascal}RemoteDataSource();
    repository = ${pascal}RepositoryImpl(mockRemoteDataSource);
  });

  group('$pascal Repository', () {
    const tId = 'test_id';
    const tResponseModel = ${pascal}ResponseModel(id: tId);

    test('should return Entity when call to remote data source is successful', () async {
      when(() => mockRemoteDataSource.get$pascal(any()))
          .thenAnswer((_) async => tResponseModel);

      final result = await repository.get$pascal(tId);

      expect(result.isRight(), true);
    });
  });
}
''';
  }

  static String usecaseTest(String featureName, String projectName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;

    return '''
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:$projectName/features/$snake/domain/usecases/get_${snake}_usecase.dart';
import 'package:$projectName/features/$snake/domain/repositories/${snake}_repository.dart';
import 'package:$projectName/features/$snake/domain/entities/${snake}_entity.dart';

class Mock${pascal}Repository extends Mock implements ${pascal}Repository {}

void main() {
  late Get${pascal}UseCase usecase;
  late Mock${pascal}Repository mockRepository;

  setUp(() {
    mockRepository = Mock${pascal}Repository();
    usecase = Get${pascal}UseCase(mockRepository);
  });

  group('Get $pascal UseCase', () {
    const tId = 'test_id';
    const tEntity = ${pascal}Entity(id: tId);

    test('should get entity from the repository', () async {
      when(() => mockRepository.get$pascal(any()))
          .thenAnswer((_) async => const Right(tEntity));

      final result = await usecase(tId);

      expect(result, const Right(tEntity));
    });
  });
}
''';
  }

  static String blocTest(String featureName, String projectName) {
    final pascal = featureName.pascalCase;
    final snake = featureName.snakeCase;

    return '''
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:$projectName/features/$snake/presentation/state/${snake}_bloc.dart';
import 'package:$projectName/features/$snake/domain/usecases/get_${snake}_usecase.dart';

class MockGet${pascal}UseCase extends Mock implements Get${pascal}UseCase {}

void main() {
  late ${pascal}Bloc bloc;
  late MockGet${pascal}UseCase mockGetUseCase;

  setUp(() {
    mockGetUseCase = MockGet${pascal}UseCase();
    bloc = ${pascal}Bloc(mockGetUseCase);
  });

  group('$pascal Bloc', () {
    test('initial state should be Initial', () {
      expect(bloc.state, const ${pascal}State.initial());
    });
  });
}
''';
  }

  static String riverpodTest(String featureName, String projectName) {
    final pascal = featureName.pascalCase;
    final camel = featureName.camelCase;
    final snake = featureName.snakeCase;

    return '''
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:$projectName/features/$snake/presentation/state/${snake}_provider.dart';
import 'package:$projectName/features/$snake/domain/usecases/get_${snake}_usecase.dart';
import 'package:$projectName/features/$snake/domain/entities/${snake}_entity.dart';
import 'package:$projectName/core/di/injection_container.dart';

class MockGet${pascal}UseCase extends Mock implements Get${pascal}UseCase {}

void main() {
  late MockGet${pascal}UseCase mockGetUseCase;

  setUp(() {
    mockGetUseCase = MockGet${pascal}UseCase();
    sl.allowReassignment = true;
    sl.registerLazySingleton<Get${pascal}UseCase>(() => mockGetUseCase);
  });

  group('$pascal Provider', () {
    test('fetches data successfully', () async {
      when(() => mockGetUseCase(any()))
          .thenAnswer((_) async => const Right(${pascal}Entity(id: '1')));
      
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(${camel}Provider.notifier).get$pascal('1');
      expect(container.read(${camel}Provider).hasValue, true);
    });
  });
}
''';
  }
}
