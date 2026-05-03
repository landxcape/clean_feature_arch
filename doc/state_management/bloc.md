# State Management — BLoC

This document specifies the implementation standards for BLoC within the architecture.

---

## Folder Structure

The presentation layer organizes state management within a dedicated `bloc/` directory:

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
| Event | `auth_event.dart` | `AuthEvent` |
| State | `auth_state.dart` | `AuthState` |

---

## Implementation Patterns

The architecture utilizes the `part` and `part of` directives to treat the BLoC triad as a single logical library.

### `auth_bloc.dart`

The main BLoC file serves as the library entry point, containing all imports and part declarations.

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/usecases/login_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';
part 'auth_bloc.freezed.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._loginUseCase) : super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  final LoginUseCase _loginUseCase;

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _loginUseCase(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (error) => emit(AuthFailure(error)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthUnauthenticated());
  }
}
```

### `auth_event.dart`

```dart
part of 'auth_bloc.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  const factory AuthEvent.loginRequested({
    required String email,
    required String password,
  }) = LoginRequested;

  const factory AuthEvent.logoutRequested() = LogoutRequested;
}
```

### `auth_state.dart`

```dart
part of 'auth_bloc.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated(UserEntity user) = AuthAuthenticated;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.failure(AppError error) = AuthFailure;
}
```

---

## Dependency Injection

BLoCs must be registered as a `Factory` within the service locator to ensure a fresh instance is provided when required.

```dart
sl.registerFactory(() => AuthBloc(sl()));
```

---

## UI Integration

The architecture mandates the use of native Dart 3.x `switch` expressions for rendering UI based on state.

```dart
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        }
      },
      builder: (context, state) {
        return switch (state) {
          AuthInitial() || AuthUnauthenticated() => const LoginForm(),
          AuthLoading() => const LoadingIndicator(),
          AuthAuthenticated() => const SizedBox.shrink(),
          AuthFailure(:final error) => ErrorDisplay(message: error.message),
        };
      },
    );
  }
}
```

---

## Architectural Rules

| # | Rule |
|---|---|
| 1 | **Register BLoCs as `Factory` instances.** Singletons are prohibited for feature-level state. |
| 2 | **Provide BLoCs at the route or feature-root level.** Avoid initialization within widget build methods. |
| 3 | **Utilize `part` and `part of` directives** to maintain the BLoC triad as a single library. |
| 4 | **Apply native `switch` expressions** for state-to-UI mapping. |
| 5 | **Encapsulate all events and states within Freezed sealed classes.** |
