# State Management — Riverpod

> This document extends `flutter_architecture.md` and `common.md`. Every rule in both applies here.

---

## Folder Structure

Rename `presentation/state/` to `presentation/providers/`:

```
presentation/
├── providers/
│   ├── auth_provider.dart
│   └── auth_provider.g.dart
├── screens/
└── widgets/
```

---

## Naming Conventions

| Layer | File Name Pattern | Class Name Pattern |
|---|---|---|
| Provider | `auth_provider.dart` | `AuthNotifier` |

---

## DI Strategy — Bridging get_it and Riverpod

get_it owns the dependency chain from data sources through usecases. Riverpod owns Notifier lifecycle. These two worlds connect through **bridge providers** — simple providers that expose get_it-managed UseCases to the Riverpod graph.

```dart
@riverpod
LoginUseCase loginUseCase(Ref ref) => sl<LoginUseCase>();
```

This achieves:
- **Explicit dependencies.** The Notifier declares what it needs via `ref.read` on a typed provider, not a raw service locator call.
- **Testability.** Override the bridge provider in tests — no get_it configuration needed.
- **Idiomatic Riverpod.** Dependencies flow through the provider graph, not through a global container.

Bridge providers live in the same file as the Notifier that consumes them.

---

## Template

### `[feature]_provider.dart`

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/error/app_error.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';

part 'auth_provider.g.dart';

// Bridge provider — exposes get_it UseCase to Riverpod graph
@riverpod
LoginUseCase loginUseCase(Ref ref) => sl<LoginUseCase>();

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<UserEntity?> build() => const AsyncData(null);

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    final loginUseCase = ref.read(loginUseCaseProvider);
    final result = await loginUseCase(email: email, password: password);
    state = result.fold(
      (error) => AsyncError(error, StackTrace.current),
      (user) => AsyncData(user),
    );
  }
}
```

> The `AsyncError` wraps the `AppError` directly — the typed error survives to the UI. See `common.md`.

---

## `app.dart` Bootstrap

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const ProviderScope(child: App()));
}
```

---

## `ref.watch` vs `ref.read` — The Precise Rule

- **`ref.watch` is for `build`.** Subscribes to the provider, rebuilds on state change.
- **`ref.read` is for callbacks.** One-shot read, no subscription.

```dart
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authNotifierProvider);  // reactive — correct in build

    return state.when(
      data: (user) => user != null
          ? const SizedBox.shrink()  // navigate in listener
          : LoginForm(
              isLoading: false,
              onSubmit: (email, password) => ref
                  .read(authNotifierProvider.notifier)
                  .login(email, password),  // one-shot — correct in callback
            ),
      loading: () => const LoadingIndicator(),
      error: (error, _) => ErrorDisplay(
        error: error as AppError,
        onRetry: () => ref.invalidate(authNotifierProvider),
      ),
    );
  }
}

// ❌ BANNED — ref.read during build
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.read(authNotifierProvider);  // non-reactive — violation
}

// ❌ BANNED — ref.watch inside a callback
onSubmit: (_) {
  final notifier = ref.watch(authNotifierProvider.notifier);  // leaked subscription — violation
}
```

---

## Hard Rules

| # | Rule |
|---|---|
| R1 | **Never register Notifiers in get_it.** Riverpod owns Notifier lifecycle. get_it stops at UseCases. Bridge providers connect the two. |
| R2 | **`ref.watch` is for `build` only.** `ref.read` is for callbacks only. Never invert them. |
| R3 | **Dumb widgets are always `StatelessWidget`.** Converting a widget in `widgets/` to `ConsumerWidget` is a violation. If `ref` is needed there, the logic belongs in the screen above it. |
| R4 | **Notifiers own no business logic.** They call UseCases via bridge providers. Logic inside a Notifier is a test liability. |
| R5 | **No `sl<>()` inside Notifier methods.** Dependencies are obtained via `ref.read` on bridge providers. Inline service locator calls are banned. |

---

## Testing

Override bridge providers in tests — no get_it configuration needed. This is the payoff of the bridge pattern.

### Dev Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
```

### Riverpod Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}

void main() {
  late MockLoginUseCase mockLoginUseCase;
  late ProviderContainer container;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    container = ProviderContainer(
      overrides: [
        loginUseCaseProvider.overrideWithValue(mockLoginUseCase),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('initial state is AsyncData(null)', () {
    final state = container.read(authNotifierProvider);
    expect(state, const AsyncData<UserEntity?>(null));
  });

  test('login success updates state to AsyncData with user', () async {
    when(() => mockLoginUseCase(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => const Right(
      UserEntity(id: '1', email: 'test@test.com', fullName: 'Test'),
    ));

    final notifier = container.read(authNotifierProvider.notifier);
    await notifier.login('test@test.com', 'pass');

    final state = container.read(authNotifierProvider);
    expect(state, isA<AsyncData<UserEntity?>>());
  });

  test('login failure updates state to AsyncError with typed AppError', () async {
    when(() => mockLoginUseCase(
      email: any(named: 'email'),
      password: any(named: 'password'),
    )).thenAnswer((_) async => const Left(UnauthorizedError()));

    final notifier = container.read(authNotifierProvider.notifier);
    await notifier.login('test@test.com', 'wrong');

    final state = container.read(authNotifierProvider);
    expect(state, isA<AsyncError<UserEntity?>>());
    expect(state.error, isA<UnauthorizedError>());
  });
}
```

> Mock UseCases via bridge provider overrides, not repositories. The Notifier doesn't know repositories exist. The bridge provider pattern makes this trivial — override the provider, inject the mock, test in isolation.
