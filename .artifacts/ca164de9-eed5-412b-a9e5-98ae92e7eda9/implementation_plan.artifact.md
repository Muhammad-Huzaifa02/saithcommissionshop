# Flutter Project Architecture Restructuring Plan

This plan aims to reorganize the `saithcommissionshop` project according to the "Clean, Scalable, Maintainable, Testable" architecture provided in the reference image. We will follow the folder structure while maintaining the current `Provider` state management.

## User Review Required

> [!IMPORTANT]
> This is a large-scale refactor involving moving almost all files in the `lib` directory. This will break all current imports, which will be fixed as part of the process.

## Proposed Changes

### 1. Core Layer
Responsible for application-wide configurations, themes, and shared utilities.

- `[NEW]` [lib/core/constants/](file:///C:/Users/seith/StudioProjects/saithcommissionshop/lib/core/constants/)
- `[MOVE]` `lib/theme/` -> [lib/core/theme/](file:///C:/Users/seith/StudioProjects/saithcommissionshop/lib/core/theme/)
- `[MOVE]` `lib/utils/` -> [lib/core/utils/](file:///C:/Users/seith/StudioProjects/saithcommissionshop/lib/core/utils/)
- `[NEW]` [lib/core/network/](file:///C:/Users/seith/StudioProjects/saithcommissionshop/lib/core/network/)
- `[NEW]` [lib/core/storage/](file:///C:/Users/seith/StudioProjects/saithcommissionshop/lib/core/storage/)
- `[MOVE]` `lib/widgets/` (shared) -> [lib/core/widgets/](file:///C:/Users/seith/StudioProjects/saithcommissionshop/lib/core/widgets/)

### 2. Data Layer
Handles data operations, API calls, models, and local storage.

- `[MOVE]` `lib/models/` -> [lib/data/models/](file:///C:/Users/seith/StudioProjects/saithcommissionshop/lib/data/models/)
- `[MOVE]` `lib/services/` -> [lib/data/services/](file:///C:/Users/seith/StudioProjects/saithcommissionshop/lib/data/services/)
- `[NEW]` [lib/data/repositories/](file:///C:/Users/seith/StudioProjects/saithcommissionshop/lib/data/repositories/)

### 3. Modules Layer (Feature-based)
Contains feature-specific Presentation (UI) and State Management (Providers).

- `[NEW]` [lib/modules/](file:///C:/Users/seith/StudioProjects/saithcommissionshop/lib/modules/)
    - `auth/`: Login, Signup, Onboarding, Splash.
    - `home/`: Admin and Customer Home.
    - `cart/`: Cart and Checkout.
    - `orders/`: Order history, Invoice lists, Manual Invoices.
    - `products/`: Products and Stock management.
    - `analytics/`: Profit and Analytics.
    - `customers/`: Customer management and Ledgers.
    - `suppliers/`: Supplier management.
    - `notifications/`: Notifications.
    - `profile/`: Admin and Customer Profiles.
    - `reminders/`: Reminders and History.
    - `scanner/`: Invoice scanner.
    - `settings/`: Settings.
    - `common/`: Shared module widgets/controllers.

Each module will have:
- `views/`: For screen/page files.
- `providers/`: For feature-specific state management (moving from `lib/provider/`).
- `widgets/`: For feature-specific widgets.

### 4. Routes Layer
Centralized navigation.

- `[NEW]` [lib/routes/app_routes.dart](file:///C:/Users/seith/StudioProjects/saithcommissionshop/lib/routes/app_routes.dart)

### 5. Main Entry
- `[MODIFY]` [lib/main.dart](file:///C:/Users/seith/StudioProjects/saithcommissionshop/lib/main.dart) to reflect new imports and routing.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure all imports are correctly updated and there are no compilation errors.

### Manual Verification
- Verify the app builds and runs successfully.
- Check that navigation works as expected through the new `app_routes.dart`.
