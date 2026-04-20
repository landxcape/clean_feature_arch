# State Management — BLoC

> This document extends `flutter_architecture.md` and `common.md`. Every rule in both applies here.

---

## Folder Structure

Rename `presentation/state/` to `presentation/bloc/`:

```
presentation/
├── bloc/
│   ├── auth_bloc.dart
│   ├── auth_event.dart
│   └── auth_state.dart
├── screens/
└── widgets/
```

---

## Naming Conventions

| Layer | File Name Pattern | Class Name Pattern |
|---|---|---|
| BLoC | `auth_bloc.dart` | `AuthBloc` |
| Event | `auth_event.dart` | `AuthEvent`, `LoginRequested` |
| State | `auth_state.dart` | `AuthState`, `AuthAuthenticated` |

---

## Templates

### `[feature]_event.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_event.freezed.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  const factory AuthEvent.loginRequested({
    required String email,
    required String password,
  }) = LoginRequested;

  const factory AuthEvent.logoutRequested() = LogoutRequested;
}
```

### `[feature]_state.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../core/error/app_error.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated(UserEntity user) = AuthAuthenticated;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.failure(AppError error) = AuthFailure;
}
```

> `AppError error` — not `String message`. The typed error survives to the UI. See `common.md`.

### `[feature]_bloc.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._loginUseCase) : super(const AuthState.initial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  final LoginUseCase _loginUseCase;

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _loginUseCase(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (error) => emit(AuthState.failure(error)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.unauthenticated());
  }
}
```

---

## DI Registration

BLoC is registered as `Factory` in get_it — always. Never `LazySingleton`. A singleton BLoC shared across screens corrupts state.

```dart
sl.registerFactory(() => AuthBloc(sl()));
```

---

## BLoC as MVVM — The Contract

BLoC is used strictly as a ViewModel. The widget is a pure View — renders state, emits events, contains zero business logic.

**BLoC is always provided at the route level:**

```dart
GoRoute(
  path: '/login',
  builder: (context, state) => BlocProvider(
    create: (_) => sl<AuthBloc>(),
    child: const LoginScreen(),
  ),
)
```

**Screen is a pure reaction surface — events up, state down:**

```dart
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: _handleStateChange,
      builder: (context, state) {
        return LoginForm(
          isLoading: state is AuthLoading,
          onSubmit: (email, password) => context.read<AuthBloc>().add(
            AuthEvent.loginRequested(email: email, password: password),
          ),
        );
      },
    );
  }

  void _handleStateChange(BuildContext context, AuthState state) {
    switch (state) {
      case AuthAuthenticated():
        context.go('/home');
      case AuthFailure(:final error):
        showErrorSnackbar(context, error.message);
      default:
        break;
    }
  }
}
```

> Callbacks are extracted as named methods when the screen has more than one or two. The `builder` stays clean — data and callbacks go down, events go up.

---

## Hard Rules

| # | Rule |
|---|---|
| B1 | **BLoC is always registered as `Factory` in get_it.** Never `LazySingleton`. |
| B2 | **BLoC is always provided at the route level** via `BlocProvider(create: (_) => sl<AuthBloc>())`. Never inside the widget's `build` method. |
| B3 | **`context.read` is banned during `build`.** Permitted only inside callbacks (`onPressed`, `onSubmit`, `onTap`). State during build is always read via `BlocBuilder` or `BlocConsumer`. |
| B4 | **BLoCs own no business logic.** They dispatch to UseCases. Logic inside a BLoC is a test liability. |
| B5 | **Events and states are always Freezed sealed classes.** No raw subclassing. |

---

## Testing

Use `bloc_test` for state transition verification. Mock UseCases, not repositories.

### Dev Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.0.0
  mocktail: ^1.0.0
```

### BLoC Test Template

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

void main() {
  late AuthBloc bloc;
  late MockLoginUseCase mockLoginUseCase;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    bloc = AuthBloc(mockLoginUseCase);
  });

  tearDown(() => bloc.close());

  test('initial state is AuthInitial', () {
    expect(bloc.state, const AuthState.initial());
  });

  blocTest<AuthBloc, AuthState>(
    'emits [loading, authenticated] on successful login',
    build: () {
      when(() => mockLoginUseCase(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => const Right(
        UserEntity(id: '1', email: 'test@test.com', fullName: 'Test'),
      ));
      return bloc;
    },
    act: (bloc) => bloc.add(
      const AuthEvent.loginRequested(
        email: 'test@test.com',
        password: 'pass',
      ),
    ),
    expect: () => [
      const AuthState.loading(),
      isA<AuthAuthenticated>(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [loading, failure] on failed login',
    build: () {
      when(() => mockLoginUseCase(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async => const Left(UnauthorizedError()));
      return bloc;
    },
    act: (bloc) => bloc.add(
      const AuthEvent.loginRequested(
        email: 'test@test.com',
        password: 'wrong',
      ),
    ),
    expect: () => [
      const AuthState.loading(),
      isA<AuthFailure>(),
    ],
  );
}
```

> Mock UseCases, not repositories. The BLoC doesn't know repositories exist.
