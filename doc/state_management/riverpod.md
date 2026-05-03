# State Management — Riverpod

This document specifies the implementation standards for Riverpod within the architecture.

---

## Pattern Standards

The architecture utilizes the `riverpod_annotation` package to generate type-safe providers.

### Folder Structure

The presentation layer organizes state management within a dedicated `providers/` directory:

```
presentation/
├── providers/
│   └── auth_provider.dart
├── screens/
└── widgets/
```

---

## Implementation Patterns

### AuthProvider Implementation

The following example demonstrates a standard asynchronous notifier used for authentication.

```dart
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../../core/di/injection_container.dart';

part 'auth_provider.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<void> build() {
    // Initial state logic
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    
    final useCase = sl<LoginUseCase>();
    final result = await useCase(email: email, password: password);
    
    state = result.fold(
      (error) => AsyncValue.error(error, StackTrace.current),
      (user) => const AsyncValue.data(null),
    );
  }
}
```

---

## UI Integration

The architecture mandates the use of native Dart 3.x `switch` expressions when interacting with `AsyncValue` in the UI.

```dart
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authNotifierProvider);

    return Scaffold(
      body: switch (state) {
        AsyncData() => const SuccessWidget(),
        AsyncLoading() => const LoadingIndicator(),
        AsyncError(:final error) => ErrorDisplay(message: error.toString()),
        _ => const InitialForm(),
      },
    );
  }
}
```

---

## Architectural Rules

| # | Rule |
|---|---|
| 1 | **Use `riverpod_annotation`** for all provider definitions. |
| 2 | **Keep providers in the `presentation/providers/` directory** of their respective feature. |
| 3 | **Utilize native `switch` expressions** for handling `AsyncValue` states in the UI. |
| 4 | **Maintain business logic within UseCases**, keeping notifiers as thin orchestration layers. |
| 5 | **Avoid global providers for feature-specific state**; ensure providers are scoped to their features where appropriate. |
