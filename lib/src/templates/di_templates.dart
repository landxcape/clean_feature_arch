import 'package:recase/recase.dart';

class DiTemplates {
  static String featureDi(String snake, String projectName,
      {String? stateManager, String? storageType}) {
    final pascal = snake.pascalCase;

    String stateImport = '';
    String stateRegistration = '';
    final stateFolderName = stateManager == 'bloc'
        ? 'bloc'
        : (stateManager == 'riverpod' ? 'providers' : 'state');

    if (stateManager == 'bloc') {
      stateImport =
          "import 'package:$projectName/features/$snake/presentation/$stateFolderName/${snake}_bloc.dart';\n";
      stateRegistration = '''

    sl.registerFactory(
      () => ${pascal}Bloc(
        sl(),
      ),
    );''';
    }

    return '''
import 'package:get_it/get_it.dart';
import 'package:$projectName/features/$snake/data/data_sources/local_data_sources/${snake}_local_data_source.dart';
import 'package:$projectName/features/$snake/data/data_sources/remote_data_sources/${snake}_remote_data_source.dart';
import 'package:$projectName/features/$snake/data/repositories/${snake}_repository_impl.dart';
import 'package:$projectName/features/$snake/domain/repositories/${snake}_repository.dart';
import 'package:$projectName/features/$snake/domain/usecases/get_${snake}_usecase.dart';
$stateImport
class ${pascal}DI {
  static void init(GetIt sl) {
    // --- Data Sources ---
    sl.registerLazySingleton<${pascal}RemoteDataSource>(
      () => ${pascal}RemoteDataSourceImpl(
        sl(),
      ),
    );
    sl.registerLazySingleton<${pascal}LocalDataSource>(
      () => ${pascal}LocalDataSourceImpl(
        ${storageType != null ? 'sl(),' : ''}
      ),
    );

    // --- Repositories ---
    sl.registerLazySingleton<${pascal}Repository>(
      () => ${pascal}RepositoryImpl(
        sl(),
        sl(),
      ),
    );

    // --- Use Cases ---
    sl.registerLazySingleton<Get${pascal}UseCase>(
      () => Get${pascal}UseCase(
        sl(),
      ),
    );

    // --- Blocs / Providers ---$stateRegistration
  }
}
''';
  }
}
