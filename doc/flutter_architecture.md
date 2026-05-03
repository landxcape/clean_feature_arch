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

## Folder Structure

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
└── presentation/
    ├── [bloc|providers|state]/         # Dynamic based on state manager
    ├── screens/                         # smart widgets — own state, callbacks
    └── widgets/                         # dumb widgets — pure UI
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
## Part 1 — Folder Structure

```
lib/
...
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
