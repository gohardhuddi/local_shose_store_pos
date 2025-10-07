<!--
  Project-specific Copilot instructions for local_shoes_store_pos
  Keep this concise (~20-50 lines). Update when project structure or key files change.
-->
# Copilot / AI developer instructions — local_shoes_store_pos

Short, actionable guidance to help AI assistants be productive in this Flutter offline-first POS.

- Big picture
  - Mobile Flutter app (lib/) using BLoC for state. Entry: `lib/main.dart`.
  - Offline-first storage via an abstract `StockDb` (`lib/services/storage/stock_db.dart`) with two concrete backends:
    - `StockDbFloor` (mobile) implemented in `lib/services/storage/stock_db_floor.dart` (Floor DB + DAOs under `lib/services/storage/mobile/`).
    - `StockDbWeb` for web builds (`lib/services/storage/stock_db_web.dart`).
  - Repositories mediate between UI/blocs and services: `lib/repository/*`.
  - Services split by responsibility: `services/stock/*`, `services/sales/*`, `services/networking/network_service.dart`.

- Important architectural patterns
  - BLoC pattern for UI state: controllers live in `lib/controller/*`. Examples: `AddStockBloc` (`lib/controller/add_stock_bloc/add_stock_bloc.dart`) and `SalesBloc`.
  - Single global `stockDb` instance created by `StockDbFactory.create()` in `main.dart` (global in `lib/main.dart`). Many services import `main.dart` to reference `stockDb` — treat `stockDb` as the canonical DB handle.
  - Repositories provide business mapping (e.g., `AddStockRepository.mapUnsyncedToBackend`) and decide when to call local vs remote services.
  - Idempotency is important for movements: movement operations expect a `movementId` UUID; storage layer enforces idempotency (`StockDbFloor.addInventoryMovement`).

- Developer workflows (how to build, run, test locally)
  - Standard Flutter commands apply. Typical development flow:
    - Install packages: `flutter pub get`
    - Run on mobile: `flutter run -d <device>` or use Android Studio/VSCode run configs
    - Run web: `flutter run -d chrome` (uses `StockDbWeb` backend)
  - Code generation: the project uses Floor + `build_runner` for DAOs. Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate.

- Project-specific conventions
  - Use repository -> service -> storage layering. Prefer editing repository methods when adding business mapping rather than sprinkling logic in UI.
  - Parsing helpers live in `StockServiceLocal` (e.g., `_parseInt`, `_parseDouble`) — services validate and normalize inputs before calling `stockDb`.
  - Network checks: `ConnectivityBloc` periodically checks internet and backend health via `NetworkService.isBackendHealthy()`; avoid assuming backend availability.
  - Strings/IDs: many DB methods accept stringified UUIDs. Prefer passing UUIDs as strings (see `stock_db_floor.dart` usage of `Uuid().v4()`).

- Integration points & external dependencies
  - Network: `dio` (configured via `getIt<Dio>()` from `lib/helper/global.dart`). Check `Global.baseUrl` in `lib/helper/global.dart` when constructing remote endpoints.
  - Local DB: Floor (mobile) and a web alternative (sembast/sembast_web are in `pubspec.yaml`); storage API surface is defined in `lib/services/storage/stock_db.dart`.
  - Background sync: repository methods expose `getUnSyncPayload()` and `syncProductsToBackend()` used by UI or manual sync flows.

- When editing code, prefer these files as examples
  - Add/update stock flows: `lib/controller/add_stock_bloc/*`, `lib/repository/add_stock_repository.dart`, `lib/services/stock/add_stock_service_local.dart` and `lib/services/storage/stock_db_floor.dart`.
  - Sales: `lib/controller/sales_bloc/*`, `lib/repository/sales_repository.dart`, `lib/services/storage/stock_db_floor.dart` (sales stored via `addSale`).

- Quick gotchas for AI code edits
  - `stockDb` is a late final created in `main.dart` — tests or small scripts may need a mocked or test `StockDb` instance; avoid importing `main.dart` in non-Flutter test helpers.
  - Movement actions are normalized in `StockDbFloor._normalizeActionEnumStyle` — send action strings matching allowed values (e.g., `purchase_in`, `sale_out`) or `StockMovementType.*` style.
  - Network health check uses a hard-coded URL in `NetworkService.isBackendHealthy()` — update when backend URL changes (see `Global.baseUrl`).

If any section is unclear or you want more examples (tests, DI setup in `lib/helper/global.dart`, or codegen details), tell me which area to expand and I will iterate.
