# Flutter Production Architecture
### The Absolute Rule — Feature-First Clean Architecture

---

## The Stack

| Concern | Library |
|---|---|
| DI | get_it |
| Navigation | GoRouter |
| Networking | Dio + Retrofit |
| Local DB | Drift (relational) / Hive (key-value only) |
| Serialization | Freezed + json_serializable |
| FP Error Handling | fpdart (Either/Option) |

> State management is a separate decision documented in `state_management/`. Pick one tool per project at kickoff. Never mix. Never revisit. Everything in this document applies regardless of which tool you choose.

---

## Part 1 — Folder Structure

```
lib/
├── core/
│   ├── config/
│   │   ├── app_config.dart              # env vars, base URLs, feature flags
│   │   └── flavor_config.dart           # dev/staging/prod flavors
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── asset_constants.dart
│   │   └── route_constants.dart
│   ├── di/
│   │   ├── injection_container.dart     # get_it root registration
│   │   └── modules/
│   │       ├── network_module.dart
│   │       ├── storage_module.dart
│   │       └── [feature]_module.dart    # one module per feature
│   ├── error/
│   │   ├── app_error.dart               # sealed class AppError
│   │   └── error_handler.dart           # exception → AppError mapping
│   ├── extensions/
│   │   ├── context_extensions.dart
│   │   ├── string_extensions.dart
│   │   └── datetime_extensions.dart
│   ├── network/
│   │   ├── api_client.dart              # Dio factory
│   │   ├── interceptors/
│   │   │   ├── auth_interceptor.dart
│   │   │   ├── logging_interceptor.dart
│   │   │   └── retry_interceptor.dart
│   │   └── network_info.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   └── router_guards.dart
│   ├── storage/
│   │   ├── secure_storage.dart
│   │   └── local_storage.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── app_spacing.dart
│   ├── types/
│   │   ├── typedefs.dart                # Result<T>, VoidResult
│   │   └── paginated.dart               # Paginated<T> wrapper
│   └── utils/
│       ├── date_utils.dart
│       ├── validator_utils.dart
│       └── logger.dart
│
├── features/
│   └── [feature_name]/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── [feature]_remote_datasource.dart
│       │   │   └── [feature]_local_datasource.dart
│       │   ├── models/
│       │   │   ├── requests/
│       │   │   │   └── [feature]_request_model.dart
│       │   │   ├── responses/
│       │   │   │   └── [feature]_response_model.dart
│       │   │   └── local/
│       │   │       └── [feature]_local_model.dart
│       │   └── repositories/
│       │       └── [feature]_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── [feature]_entity.dart
│       │   ├── repositories/
│       │   │   └── [feature]_repository.dart    # abstract interface
│       │   └── usecases/
│       │       ├── get_[thing]_usecase.dart
│       │       ├── create_[thing]_usecase.dart
│       │       └── delete_[thing]_usecase.dart
│       └── presentation/
│           ├── state/                           # tool-specific — see state_management/
│           ├── screens/                         # smart widgets — own state, callbacks
│           └── widgets/                         # dumb widgets — pure UI
│
├── shared/
│   ├── widgets/
│   │   ├── buttons/
│   │   │   ├── primary_button.dart
│   │   │   └── secondary_button.dart
│   │   ├── inputs/
│   │   │   └── app_text_field.dart
│   │   ├── overlays/
│   │   │   ├── app_dialog.dart
│   │   │   └── app_bottom_sheet.dart
│   │   ├── feedback/
│   │   │   ├── loading_indicator.dart
│   │   │   └── error_widget.dart
│   │   └── layout/
│   │       └── app_scaffold.dart
│   └── state/                                   # cross-feature shared state — see Part 7
│
└── app.dart
```

```
test/
├── core/
│   ├── network/
│   │   └── api_client_test.dart
│   └── error/
│       └── error_handler_test.dart
├── features/
│   └── [feature_name]/
│       ├── data/
│       │   └── repositories/
│       │       └── [feature]_repository_impl_test.dart
│       ├── domain/
│       │   └── usecases/
│       │       └── get_[thing]_usecase_test.dart
│       └── presentation/
│           └── state/
│               └── [feature]_state_test.dart
└── helpers/
    ├── mock_dependencies.dart
    └── test_factories.dart
```

---

## Part 2 — Naming Conventions

**Files:** `snake_case` — always, no exceptions.
**Classes:** `PascalCase` — always.

| Layer | File Name Pattern | Class Name Pattern |
|---|---|---|
| Entity | `user_entity.dart` | `UserEntity` |
| Request Model | `login_request_model.dart` | `LoginRequestModel` |
| Response Model | `login_response_model.dart` | `LoginResponseModel` |
| Local Model | `user_local_model.dart` | `UserLocalModel` |
| Repository (abstract) | `auth_repository.dart` | `AuthRepository` |
| Repository (impl) | `auth_repository_impl.dart` | `AuthRepositoryImpl` |
| Remote Datasource | `auth_remote_datasource.dart` | `AuthRemoteDataSource` |
| Local Datasource | `auth_local_datasource.dart` | `AuthLocalDataSource` |
| Use Case | `login_usecase.dart` | `LoginUseCase` |
| Screen | `login_screen.dart` | `LoginScreen` |
| Widget (shared) | `primary_button.dart` | `PrimaryButton` |
| DI Module | `auth_module.dart` | — (top-level functions only) |
| Router | `app_router.dart` | `AppRouter` |

> State-layer file and class naming is tool-specific. See `state_management/`.

---

## Part 3 — The Domain Contract

This is the philosophical foundation. Understand *why* each type exists and the rules are self-enforcing.

### The Three Model Types

**Entities** — Your domain truth. Belongs to no framework, no library, no API contract. If your backend is replaced entirely, your entity never changes. Everything in your UI and business logic reasons in terms of entities only.

**Request Models** — Your API is not your domain. When your backend renames `full_name` to `name`, you change one `@JsonKey` annotation. Your UseCase, entity, and UI see zero changes. Request models are the translation layer from domain → wire. They live exclusively in the data layer. The domain layer never sees them, never imports them, never knows they exist.

**Response Models** — Same reason, opposite direction. They absorb all JSON brittleness. The `.toEntity()` extension on the response model is the only permitted translation point. Never map directly from raw JSON to an entity.

There are three model types. Entity, Request Model, Response Model. Nothing else. No "request entities," no "domain models," no "transfer objects." Three types. Done.

### The Freezed Mandate

Every model, entity, event, and state class uses Freezed. Manual `copyWith` and equality implementations are banned — they are maintenance liabilities.

**Union types** (events, states, errors with multiple variants) use `sealed class`:

```dart
@freezed
sealed class AuthEvent with _$AuthEvent {
  const factory AuthEvent.loginRequested({
    required String email,
    required String password,
  }) = LoginRequested;

  const factory AuthEvent.logoutRequested() = LogoutRequested;
}
```

**Single-variant types** (entities, models) also use `sealed class`:

```dart
@freezed
sealed class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String email,
    required String fullName,
    DateTime? createdAt,
  }) = _UserEntity;
}
```

> One rule, no thinking. Every Freezed class is a `sealed class`. For union types it enables exhaustive pattern matching. For single-variant types it enforces type closure — no one extends your domain types outside the file. Both are correct constraints.

### UseCases

Mandatory. Every domain operation has a UseCase. No exceptions, no "it's too simple" opt-out. The effort to decide when a UseCase is "worth it" is not worth the effort of mandating one everywhere.

A UseCase is a plain class with a `call()` method. That's it.

> The only actual noise: abstract `BaseUseCase<Type, Params>` with a `call()` override. Zero value in Dart. No base class. Each UseCase is its own shape.

**Passthrough UseCase** — the minimum shape. Simple CRUD, single repo call:

```dart
class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AppError, UserEntity>> call({
    required String email,
    required String password,
  }) {
    return _repository.login(email: email, password: password);
  }
}
```

**Orchestration UseCase** — where UseCases earn their keep. Caching, analytics, multi-repo coordination, session handling — all belong here, not in the repository, not in the state layer:

```dart
class LoginUseCase {
  const LoginUseCase(this._authRepository, this._sessionStorage);

  final AuthRepository _authRepository;
  final SessionStorage _sessionStorage;

  Future<Either<AppError, UserEntity>> call({
    required String email,
    required String password,
  }) async {
    final result = await _authRepository.login(
      email: email,
      password: password,
    );

    // Cross-cutting: persist session on success
    await result.fold(
      (_) async {},
      (user) => _sessionStorage.saveSession(user),
    );

    return result;
  }
}
```

---

## Part 4 — Error Architecture

### `app_error.dart`

```dart
sealed class AppError {
  const AppError(this.message);
  final String message;
}

class NetworkError extends AppError {
  const NetworkError([super.message = 'Network error occurred.']);
}

class ServerError extends AppError {
  const ServerError({required this.statusCode, required String message})
      : super(message);
  final int statusCode;
}

class UnauthorizedError extends AppError {
  const UnauthorizedError([super.message = 'Session expired.']);
}

class NotFoundError extends AppError {
  const NotFoundError([super.message = 'Resource not found.']);
}

class CacheError extends AppError {
  const CacheError([super.message = 'Local storage error.']);
}

class UnknownError extends AppError {
  const UnknownError([super.message = 'An unexpected error occurred.']);
}
```

### `error_handler.dart`

This is the critical piece that catches raw exceptions from datasources and maps them to typed `AppError` subtypes. Every repository impl delegates to this.

```dart
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'app_error.dart';

class ErrorHandler {
  const ErrorHandler._();

  static Future<Either<AppError, T>> guard<T>(
    Future<T> Function() action,
  ) async {
    try {
      final result = await action();
      return Right(result);
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } on FormatException catch (e, stack) {
      logger.error('Format exception', error: e, stackTrace: stack);
      return Left(const UnknownError('Invalid response format.'));
    } catch (e, stack) {
      logger.error('Unhandled exception', error: e, stackTrace: stack);
      return Left(const UnknownError());
    }
  }

  static AppError _mapDioException(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        const NetworkError('Connection timed out.'),
      DioExceptionType.connectionError => const NetworkError(),
      _ => _mapStatusCode(e.response?.statusCode),
    };
  }

  static AppError _mapStatusCode(int? code) {
    return switch (code) {
      401 => const UnauthorizedError(),
      404 => const NotFoundError(),
      >= 500 => ServerError(statusCode: code!, message: 'Server error.'),
      _ => const UnknownError(),
    };
  }
}
```

### The Typed Error Survival Rule

Typed errors must survive from the datasource all the way to the UI. The chain is:

```
DioException → ErrorHandler.guard() → AppError → Repository Either → UseCase Either → State Layer → UI
```

At no point in this chain does `AppError` get collapsed to a `String`. The state layer carries `AppError`, not `error.message`. The UI decides how to present it — showing a retry button for `NetworkError`, a re-login prompt for `UnauthorizedError`, or a generic message for `UnknownError`.

Extracting `.message` from an `AppError` and discarding the type is a violation of this architecture.

---

## Part 4.5 — Shared Types

### `core/types/typedefs.dart`

Reduces verbosity across repositories, usecases, and state layers.

```dart
import 'package:fpdart/fpdart.dart';
import '../error/app_error.dart';

typedef Result<T> = Either<AppError, T>;
typedef VoidResult = Either<AppError, Unit>;
```

Usage — before and after:

```dart
// Before
Future<Either<AppError, UserEntity>> login(...);
Future<Either<AppError, Unit>> logout();

// After
Future<Result<UserEntity>> login(...);
Future<VoidResult> logout();
```

### `core/types/paginated.dart`

Shared pagination wrapper. Prevents every feature from reinventing list handling.

```dart
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.hasMore,
    this.nextPageToken,
  });

  final List<T> items;
  final bool hasMore;
  final String? nextPageToken;
}
```

> The pagination strategy (cursor, offset, keyset) is decided by your API — not this architecture. `Paginated<T>` is a generic wrapper. Adapt the fields to match your backend contract.

---

## Part 5 — Canonical File Templates

### `[feature]_entity.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';

@freezed
sealed class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String email,
    required String fullName,
    DateTime? createdAt,
  }) = _UserEntity;
}
```

### `[feature]_response_model.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user_entity.dart';

part 'user_response_model.freezed.dart';
part 'user_response_model.g.dart';

@freezed
sealed class UserResponseModel with _$UserResponseModel {
  const factory UserResponseModel({
    required String id,
    required String email,
    @JsonKey(name: 'full_name') required String fullName,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _UserResponseModel;

  factory UserResponseModel.fromJson(Map<String, dynamic> json) =>
      _$UserResponseModelFromJson(json);
}

extension UserResponseModelMapper on UserResponseModel {
  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        fullName: fullName,
        createdAt: createdAt,
      );
}
```

### `[feature]_request_model.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_request_model.freezed.dart';
part 'login_request_model.g.dart';

@freezed
sealed class LoginRequestModel with _$LoginRequestModel {
  const factory LoginRequestModel({
    required String email,
    required String password,
  }) = _LoginRequestModel;

  factory LoginRequestModel.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestModelFromJson(json);
}
```

### `[feature]_repository.dart` (abstract)

The abstract repository lives in the domain layer. It speaks exclusively in domain types — entities and primitives. It has no knowledge of request models, response models, JSON, or any external data format.

```dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_error.dart';
import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  Future<Either<AppError, UserEntity>> login({
    required String email,
    required String password,
  });
  Future<Either<AppError, Unit>> logout();
  Future<Either<AppError, UserEntity>> getCurrentUser();
}
```

### `[feature]_usecase.dart`

```dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_error.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AppError, UserEntity>> call({
    required String email,
    required String password,
  }) {
    return _repository.login(email: email, password: password);
  }
}
```

### `[feature]_repository_impl.dart`

The repository implementation lives in the data layer. It is the model↔entity translation boundary — the only place where Request Models are constructed from domain parameters and Response Models are mapped to Entities.

```dart
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/error_handler.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/requests/login_request_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<Either<AppError, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    return ErrorHandler.guard(() async {
      // Request Model is constructed here — the translation boundary
      final model = LoginRequestModel(email: email, password: password);
      final response = await _remoteDataSource.login(model);
      // Response Model is mapped to Entity here — the only exit point
      return response.toEntity();
    });
  }
}
```

---

## Part 6 — The Repository Contract

The repository implementation is the model↔entity translation boundary. This is an explicit architectural decision, not an accident of the template.

**What the repository impl does:**
- Constructs Request Models from domain parameters (named params or entities).
- Calls the datasource with the Request Model.
- Maps the Response Model to an Entity via `.toEntity()`.
- Wraps the entire operation in `ErrorHandler.guard()` to catch raw exceptions and return typed `Either<AppError, T>`.
- Data orchestration — source selection (remote vs local), cache fallback, response merging. The repository has access to both datasources and decides *where* data comes from.

**What the repository impl does NOT do:**
- Business logic. No analytics, no permission checks, no domain-conditional flows. That's the UseCase.
- Direct JSON manipulation. That's the datasource and serialization layer.
- Exposing models upstream. The return type is always an Entity or `Unit`.

The distinction: **data orchestration** (which source, caching, fallback) belongs in the repository. **Business orchestration** (multi-repo coordination, side effects, conditional domain flows) belongs in the UseCase.

---

## Part 7 — Dependency Injection

get_it is the DI container for every project. It owns the entire dependency chain from datasources through usecases. The state layer is the only exception — its DI strategy depends on the state tool. See `state_management/`.

### `injection_container.dart`

```dart
import 'package:get_it/get_it.dart';
import 'modules/network_module.dart';
import 'modules/auth_module.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  await registerNetworkModule(sl);
  await registerAuthModule(sl);
}
```

### `modules/[feature]_module.dart`

```dart
import 'package:get_it/get_it.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';

Future<void> registerAuthModule(GetIt sl) async {
  // Datasources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );

  // UseCases
  sl.registerLazySingleton(() => LoginUseCase(sl()));

  // State layer — see state_management/ for tool-specific registration
}
```

---

## Part 8 — Widget Rules

### Smart / Dumb Component Pattern

Every widget is either **Smart** or **Dumb**. Never both.

**Smart widget = Screen.** Lives in `screens/`. Owns the state subscription, owns all callbacks, orchestrates navigation and side effects. Delegates all UI rendering to dumb widgets. The screen's base class depends on the state tool — see `state_management/common.md`.

**Dumb widget = Widget.** Lives in `widgets/` or `shared/widgets/`. Receives everything via constructor — data and callbacks. Has zero knowledge of any state manager. Is always `StatelessWidget` unless managing purely local ephemeral UI state (animations, focus nodes, scroll controllers, form field state).

```dart
// Smart — Screen owns state and defines callbacks
class LoginScreen extends ... {
  // 1. Subscribe to state (tool-specific — see state_management/)
  // 2. Define callbacks — extract as named methods when the screen has multiple
  // 3. Pass data + callbacks down to dumb widgets

  @override
  Widget build(BuildContext context) {
    return LoginForm(
      isLoading: isLoading,
      onSubmit: _handleLogin,
    );
  }

  void _handleLogin(String email, String password) {
    // Dispatch to state manager — tool-specific
  }
}

// Dumb — LoginForm knows nothing about state management
class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.isLoading,
    required this.onSubmit,
  });

  final bool isLoading;
  final void Function(String email, String password) onSubmit;

  @override
  Widget build(BuildContext context) {
    // Pure UI — no state manager imports, no context.read, no ref
  }
}
```

### Widget Hard Rules

| # | Rule |
|---|---|
| W1 | **Screens are smart. Widgets are dumb.** Only screens touch the state manager. |
| W2 | **Callbacks are always defined in the screen and passed down.** Dumb widgets expose typed function parameters. They report that an interaction occurred — they never define what happens. When a screen has many callbacks, extract them as named methods on the screen class. |
| W3 | **Dumb widgets never import the state manager.** If a widget file has a state manager import (`flutter_bloc`, `riverpod`, etc.), it is a violation. |
| W4 | **Never pass a state object into a child widget.** No BLoC instance, no Notifier, no Ref. If a dumb widget needs state manager access, restructure so the screen handles it. |
| W5 | **`StatefulWidget` in `widgets/` is permitted only for local ephemeral UI state** — animations, focus nodes, scroll controllers, form field state. The moment it needs business state, it is no longer a dumb widget. |

---

## Part 9 — Multi-Feature Composition

### `shared/state/`

When two features need the same live domain data — session user, connectivity status, active subscription — a shared state container lives in `shared/state/`.

Rules:
- Shared state exposes **entities only**. No models, no raw data.
- Features depend on shared state. Features never depend on each other.
- Shared state containers are managed by the state tool. See `state_management/` for tool-specific patterns.

### `shared/widgets/`

Reusable UI components. Dumb widgets only. Zero state manager imports. Receive everything via constructor. The same rules from Widget Hard Rules apply — being in `shared/` does not grant special privileges.

### When to use `core/` vs `shared/`

- **`core/`** — infrastructure. Network clients, storage, error handling, DI, routing, theme. Things the app needs to *run*.
- **`shared/`** — reusable presentation-layer artifacts. Widgets and state that multiple features *consume*.

### The Cross-Feature Rule

Features never import from each other. Period.

Feature A needs data from Feature B? Options:
1. The data belongs in `shared/state/` — if it's live, reactive state.
2. The data belongs in `core/` — if it's infrastructure (e.g., session token, app config).
3. The dependency is a sign that A and B are the same feature — merge them.

There is no Option 4.

---

## Part 10 — Testing

Use `mocktail` for mocking. No code generation mocking frameworks.

### UseCase Test

Mock the repository, assert the Either result. The UseCase is tested in isolation — no datasources, no network, no state layer.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  test('returns UserEntity on successful login', () async {
    const user = UserEntity(id: '1', email: 'test@test.com', fullName: 'Test');
    when(() => mockRepository.login(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => const Right(user));

    final result = await useCase(email: 'test@test.com', password: 'pass');

    expect(result, const Right<AppError, UserEntity>(user));
    verify(() => mockRepository.login(
      email: 'test@test.com',
      password: 'pass',
    )).called(1);
  });

  test('returns AppError on failed login', () async {
    when(() => mockRepository.login(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => const Left(UnauthorizedError()));

    final result = await useCase(email: 'test@test.com', password: 'wrong');

    expect(result.isLeft(), true);
  });
}
```

### Repository Impl Test

Mock the datasource, verify the model→entity mapping and error handling.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(mockDataSource);
  });

  setUpAll(() {
    registerFallbackValue(
      const LoginRequestModel(email: '', password: ''),
    );
  });

  test('maps response model to entity on success', () async {
    const responseModel = UserResponseModel(
      id: '1',
      email: 'test@test.com',
      fullName: 'Test User',
    );
    when(() => mockDataSource.login(any()))
        .thenAnswer((_) async => responseModel);

    final result = await repository.login(
      email: 'test@test.com',
      password: 'pass',
    );

    result.fold(
      (_) => fail('Expected Right'),
      (entity) {
        expect(entity.id, '1');
        expect(entity.email, 'test@test.com');
        expect(entity.fullName, 'Test User');
      },
    );
  });

  test('returns NetworkError on connection timeout', () async {
    when(() => mockDataSource.login(any())).thenThrow(
      DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(),
      ),
    );

    final result = await repository.login(
      email: 'test@test.com',
      password: 'pass',
    );

    result.fold(
      (error) => expect(error, isA<NetworkError>()),
      (_) => fail('Expected Left'),
    );
  });
}
```

### ErrorHandler Test

Verify that raw exceptions are correctly mapped to typed `AppError` subtypes.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  test('returns Right on successful action', () async {
    final result = await ErrorHandler.guard(() async => 'success');

    expect(result, const Right<AppError, String>('success'));
  });

  test('maps connection timeout to NetworkError', () async {
    final result = await ErrorHandler.guard<String>(() async {
      throw DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(),
      );
    });

    result.fold(
      (error) => expect(error, isA<NetworkError>()),
      (_) => fail('Expected Left'),
    );
  });

  test('maps 401 to UnauthorizedError', () async {
    final result = await ErrorHandler.guard<String>(() async {
      throw DioException(
        type: DioExceptionType.badResponse,
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 401,
        ),
      );
    });

    result.fold(
      (error) => expect(error, isA<UnauthorizedError>()),
      (_) => fail('Expected Left'),
    );
  });

  test('maps unknown exceptions to UnknownError', () async {
    final result = await ErrorHandler.guard<String>(() async {
      throw Exception('something broke');
    });

    result.fold(
      (error) => expect(error, isA<UnknownError>()),
      (_) => fail('Expected Left'),
    );
  });
}
```

### Test Helpers

#### `test/helpers/mock_dependencies.dart`

```dart
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

// Add mocks as features grow — one per dependency you need to isolate.
```

#### `test/helpers/test_factories.dart`

```dart
// Factory methods for creating test entities with sensible defaults.
// Keeps test files clean and avoids repetitive constructors.

UserEntity createTestUser({
  String id = 'test-id',
  String email = 'test@test.com',
  String fullName = 'Test User',
  DateTime? createdAt,
}) {
  return UserEntity(
    id: id,
    email: email,
    fullName: fullName,
    createdAt: createdAt ?? DateTime(2024, 1, 1),
  );
}
```

> State-layer testing is tool-specific. See `state_management/bloc.md` or `state_management/riverpod.md`.

---

## The Absolute Rules

These apply to every project regardless of state manager, DI, or tool choice.

| # | Rule |
|---|---|
| 1 | **Pick one state manager per project. Never mix.** See `state_management/`. |
| 2 | **get_it owns all DI** from datasources through usecases. State layer DI is tool-specific. |
| 3 | **UI never touches a model.** Screens and widgets consume entities only. Importing a `ResponseModel` or `RequestModel` into a screen is a violation. |
| 4 | **Repositories return `Either<AppError, T>`.** No raw exceptions cross the repository boundary. Ever. |
| 5 | **The state layer owns no business logic.** It dispatches to UseCases. Logic in a BLoC or Notifier is a test liability. |
| 6 | **The domain layer has zero Flutter dependencies.** Pure Dart only — no state tool, no Dio, no Flutter SDK. |
| 7 | **One feature = one folder.** Features never import from each other. Cross-feature needs go through `shared/` or `core/`. |
| 8 | **Freezed for every model, entity, event, and state.** Manual `copyWith` and equality are banned. Every Freezed class uses `sealed class`. |
| 9 | **All errors are typed, end-to-end.** `catch (e)` returning a `String` is banned. Every error path uses typed `AppError` subtypes. The state layer carries `AppError`, not `String`. |
| 10 | **The repository implementation is the model↔entity translation boundary.** Request Models are constructed and Response Models are mapped to Entities here. Nowhere else. |
| 11 | **UseCases are mandatory.** Every domain operation has a UseCase. No exceptions. |

---

> This architecture scales from 1 feature to 100. Every new feature is a copy-paste of the feature folder skeleton with renamed files. The only decision external to this document is your state management tool — see `state_management/`. Everything else is settled.