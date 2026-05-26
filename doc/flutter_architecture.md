# Flutter Production Architecture
### Feature-First Clean Architecture

---

## The Stack

| Concern | Library |
|---|---|
| DI | get_it |
| Navigation | GoRouter |
| Networking | Dio + Retrofit |
| Local DB | Drift (relational/SQL) |
| Local Settings | Shared Preferences |
| Secure Storage | Flutter Secure Storage (Credentials only) |
| Serialization | Freezed + json_serializable |
| FP Error Handling | fpdart (Either/Option) |

> State management is a separate decision documented in `state_management/`. Select one tool per project at initialization.

---

## Local Storage Strategy

The architecture follows a modular storage pattern to ensure data integrity and minimize dependency bloat.

### 1. Storage Engines
*   **Secure Storage (`core/`)**: Initialized by default. Reserved strictly for credentials and sensitive data.
*   **Local Settings (`core/`)**: Used for simple key-value configuration (e.g., `theme_mode`).
*   **App Database (`core/`)**: A central SQLite engine (Drift) that manages feature-specific tables.

### 2. Feature Implementation
When a feature requires persistence, its **Local Data Source** is injected with the specific engine required.
*   **Initialization**: Using the `feature` command with the `--storage` flag automatically configures the engine and generates the necessary `Table` classes.
*   **Injection**: The `storage feature` command allows for adding storage to an existing feature.

---

## Core Resource Ecosystem

The `init` command generates a centralized resource ecosystem in `core/` to prevent logic duplication and ensure type safety.

### 1. Asset Management (`core/constants/`)
*   **`app_constants.dart`**: Global metadata (App name, version, design dimensions).
*   **`asset_constants.dart`**: Type-safe paths for `assets/` (Images, Icons, Fonts, Animations).

### 2. Localization (`core/localization/`)
*   **Engine**: Powered by `easy_localization`.
*   **`app_strings.dart`**: Centralized getters that fetch translations in real-time.
*   **Samples**: Provides `en-US.json` and `ne-NP.json` templates in `assets/translations/`.

### 3. BuildContext Extensions (`core/extensions/`)
*   **`context_extensions.dart`**: Utility hooks for `theme`, `mediaQuery`, responsive scaling, and localization shortcuts.

### 4. Responsive Utilities (`core/utils/`)
*   **`responsive_utils.dart`**: Sizing logic to ensure UI consistency across multiple device dimensions.

---

## Part 1 — Folder Structure

```
lib/
├── core/
│   ├── config/
│   │   ├── app_runner.dart              # declarative initialization
│   │   ├── app_config.dart              # static configuration
│   │   └── app_flavor.dart              # type-safe flavor enums
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── asset_constants.dart
│   │   └── route_constants.dart
│   ├── di/
│   │   ├── injection_container.dart     # get_it root registration
│   │   └── modules/
│   │       └── core_module.dart         # combined network and storage registration
│   ├── error/
│   │   ├── app_error.dart               # sealed class AppError
│   │   └── error_handler.dart           # exception → AppError mapping
│   ├── extensions/
│   │   ├── context_extensions.dart
│   │   └── string_extensions.dart
│   ├── localization/
│   │   ├── app_locales.dart             # supported locales configuration
│   │   └── app_strings.dart             # type-safe localization keys/getters
│   ├── network/
│   │   ├── api_client.dart              # Dio client factory
│   │   ├── base_response.dart           # standard response model wrapper
│   │   ├── network_info.dart            # abstract network checker
│   │   ├── network_info_impl.dart       # implementation of network checker
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart    # attaches secure token
│   │       └── logging_interceptor.dart # pretty logs HTTP calls
│   ├── router/
│   │   └── app_router.dart              # GoRouter configuration
│   ├── storage/
│   │   ├── secure_storage.dart          # abstract secure credentials interface
│   │   ├── secure_storage_impl.dart     # implementation using flutter_secure_storage
│   │   ├── app_database.dart            # central SQLite engine (if Drift is enabled)
│   │   └── local_settings.dart          # key-value settings (if SharedPreferences is enabled)
│   ├── theme/
│   │   ├── app_theme.dart               # ThemeData configurations
│   │   ├── app_colors.dart              # central color palette
│   │   ├── app_spacing.dart             # margins, paddings, and border radius
│   │   └── app_text_theme.dart          # typography configurations
│   ├── types/
│   │   └── typedefs.dart                # Result<T> and VoidResult definition
│   └── utils/
│       ├── logger.dart                  # central logger wrapper
│       ├── permission_service.dart      # system permissions handler
│       ├── responsive_utils.dart        # screen sizing utilities
│       └── validator_utils.dart         # regex validator utilities
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
│       │   │   ├── local/
│       │   │   │   └── [feature]_local_model.dart
│       │   │   ├── requests/
│       │   │   │   └── [feature]_request_model.dart
│       │   │   └── responses/
│       │   │       └── [feature]_response_model.dart
│       │   └── repositories/
│       │       └── [feature]_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── [feature]_entity.dart
│       │   ├── repositories/
│       │   │   └── [feature]_repository.dart    # abstract interface
│       │   └── usecases/
│       │       └── get_[feature]_usecase.dart
│       ├── presentation/
│       │   ├── [bloc|providers|state]/         # state manager (e.g. bloc, providers, or state)
│       │   │   ├── [feature]_bloc.dart
│       │   │   ├── [feature]_event.dart
│       │   │   └── [feature]_state.dart
│       │   └── screens/                         # smart widgets containing own state and callbacks
│       │       └── [feature]_screen.dart
│       └── di/
│           └── [feature]_di.dart                # feature dependency injection registry
│
├── shared/
│   └── widgets/
│       ├── buttons/
│       │   └── primary_button.dart              # shared custom primary button
│       └── layout/
│           └── app_scaffold.dart                # shared layout scaffold
│
├── app.dart                             # MaterialApp root widget configuration
└── main.dart                            # App startup point with AppRunner
```

---

## The Absolute Rules

| # | Rule |
|---|---|
| 1 | **Maintain state manager consistency within a project.** |
| 2 | **Use get_it for dependency injection across all layers.** |
| 3 | **UI layers must not interact with data models directly.** |
| 4 | **Repositories must return `Result<T>` to ensure functional error handling.** |
| 5 | **State management layers should delegate business logic to UseCases.** |
| 6 | **The domain layer must remain independent of Flutter dependencies.** |
| 7 | **Enforce feature-based directory organization.** |
| 8 | **Utilize Freezed for models, entities, and state objects.** |
| 9 | **Implement strongly-typed error handling throughout the application.** |
| 10 | **The repository implementation serves as the boundary for model-entity translation.** |
| 11 | **UseCases are required for all domain operations.** |
