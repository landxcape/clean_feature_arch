# State Management — Common Rules

> This document extends `flutter_architecture.md`. Every rule there applies upstream. This document defines the contract between the architecture and any state management tool.

---

## The One Decision

Pick one state manager per project. BLoC or Riverpod. This is decided at project kickoff and never revisited.

- **BLoC** → see `bloc.md`
- **Riverpod** → see `riverpod.md`

Never mix them in the same project.

---

## Folder Naming

In the architecture, the state folder is `presentation/state/`. Each state tool renames it:

| Tool | Folder Name |
|---|---|
| BLoC | `presentation/bloc/` |
| Riverpod | `presentation/providers/` |

---

## The State Layer Contract

### What it can import

- UseCases (from `domain/usecases/`)
- Entities (from `domain/entities/`)
- `AppError` (from `core/error/`)

### What it cannot import

- `ResponseModel`, `RequestModel`, `LocalModel` — these are data layer types. The state layer never sees them.
- Datasources — the state layer never touches raw data.
- Repositories directly — always go through UseCases.

### What it owns

- Translating UseCase results (`Either<AppError, T>`) into UI-consumable state.
- Emitting loading, success, and error states.

### What it does NOT own

- Business logic — dispatches to UseCases.
- Data mapping — that's the repository's job.
- Navigation decisions — the screen (smart widget) handles navigation in response to state changes.

---

## Typed Errors Survive

The state layer carries `AppError`, not `String`. Extracting `.message` from an `AppError` and discarding the type is a violation.

The implementation differs by tool, but the principle is the same:

```dart
// ✅ BLoC — AppError in state class
const factory AuthState.failure(AppError error) = AuthFailure;

// ✅ Riverpod — AppError as the error object in AsyncError
state = AsyncError(appError, StackTrace.current);  // appError IS the AppError

// ❌ Violation — type discarded (either tool)
emit(AuthState.failure(error.message));            // String, not AppError
state = AsyncError(error.message, StackTrace.current);  // String, not AppError
```

The UI decides how to present the error. It can switch on the `AppError` subtype to show different actions — a retry button for `NetworkError`, a re-login prompt for `UnauthorizedError`, a generic message for `UnknownError`.

---

## Screen Base Class

This is codified, not a suggestion.

| Tool | Screen extends | State access |
|---|---|---|
| BLoC | `StatelessWidget` | `BlocConsumer` / `BlocBuilder` |
| Riverpod | `ConsumerWidget` | `ref.watch` / `ref.read` |

---

## Testing

State layer tests verify:

1. Initial state is correct.
2. State transitions on success (UseCase returns `Right`).
3. State transitions on failure (UseCase returns `Left`).
4. Side effects are dispatched to the correct UseCase.

**Mock UseCases, not repositories.** The state layer doesn't know repositories exist.

Tool-specific test patterns are in `bloc.md` and `riverpod.md`.

---

## Shared State

When cross-feature state lives in `shared/state/` (see `flutter_architecture.md` Part 9), the state tool manages it:

| Tool | Pattern |
|---|---|
| BLoC | Shared BLoC provided via `MultiBlocProvider` at app level. Registered as `LazySingleton` (exception to Factory rule — shared state is intentionally long-lived). |
| Riverpod | App-scoped provider. Lives in `shared/state/`, auto-kept-alive or explicitly kept alive per use case. |

See tool-specific docs for concrete templates.
