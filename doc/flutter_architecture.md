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
│       │   ├── data_sources/
│       │   │   ├── local_data_sources/
│       │   │   │   └── [feature]_local_data_source.dart
│       │   │   └── remote_data_sources/
│       │   │       └── [feature]_remote_data_source.dart
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
| Remote Data Source | `auth_remote_data_source.dart` | `AuthRemoteDataSource` |
| Local Data Source | `auth_local_data_source.dart` | `AuthLocalDataSource` |
| Use Case | `login_usecase.dart` | `LoginUseCase` |
| Screen | `login_screen.dart` | `LoginScreen` |
| Widget (shared) | `primary_button.dart` | `PrimaryButton` |
| DI Module | `auth_module.dart` | — (top-level functions only) |
| Router | `app_router.dart` | `AppRouter` |

---

## Part 6 — The Repository Contract

The repository implementation is the model↔entity translation boundary.

**What the repository impl does:**
- Constructs Request Models from domain parameters.
- Calls the data source with the Request Model.
- Maps the Response Model to an Entity via `.toEntity()`.
- Wraps the operation in `ErrorHandler.guard()`.
- Data orchestration — source selection (remote vs local), cache fallback.

**What the repository impl does NOT do:**
- Business logic. That's the UseCase.
- Direct JSON manipulation.
- Exposing models upstream.

---

## The Absolute Rules

| # | Rule |
|---|---|
| 1 | **Pick one state manager per project. Never mix.** |
| 2 | **get_it owns all DI** from data sources through usecases. |
| 3 | **UI never touches a model.** |
| 4 | **Repositories return `Result<T>`.** No raw exceptions cross the repository boundary. |
| 5 | **The state layer owns no business logic.** It dispatches to UseCases. |
| 6 | **The domain layer has zero Flutter dependencies.** Pure Dart only. |
| 7 | **One feature = one folder.** |
| 8 | **Freezed for every model, entity, event, and state.** |
| 9 | **All errors are typed, end-to-end.** |
| 10 | **The repository implementation is the model↔entity translation boundary.** |
| 11 | **UseCases are mandatory.** |
