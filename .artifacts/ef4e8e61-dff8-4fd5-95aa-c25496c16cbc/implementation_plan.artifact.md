# Unified Premium Light UI Transformation

The user wants to remove the dark/charcoal background and unify the entire app with a consistent color scheme. This plan transforms the app into a **Premium Light** aesthetic using **Signature Emerald Green** accents.

## Proposed Changes

### [Theme System Overhaul]

#### [MODIFY] [app_theme.dart](file:///C:/Users/seith/StudioProjects/saithcommissionshop/lib/theme/app_theme.dart)
- **[UPDATE] `SColors`**:
    - **Background**: Revert to a clean, professional **Light Grey/White** (`0xFFF5F7FA`).
    - **Surface**: Set to pure **White** (`0xFFFFFFFF`).
    - **Accent**: Keep the vivid **Emerald Green** (`0xFF2ECC71`).
- **[UPDATE] `SText`**:
    - Revert all text styles to use **Dark Colors** (`Color(0xFF1A1A2E)` for primary, `Color(0xFF5A6472)` for secondary) to ensure perfect readability on the light background.
- **[UPDATE] `SShadow`**:
    - Redefine shadows for Light Mode: Soft grey dual-shadows for the 3D effect.
- **[UPDATE] `AppTheme`**:
    - Restore the standard `lightTheme` configuration as the default.
    - Set `AppBarTheme` to use the Emerald Green gradient.
    - Standardize `CardTheme` and `InputDecorationTheme` for the light style.

### [UI Cleanup across Pages]

#### [MODIFY] [customer_home_page.dart](file:///C:/Users/seith/StudioProjects/saithcommissionshop/lib/pages/customer_home_page.dart) & [admin_home_page.dart](file:///C:/Users/seith/StudioProjects/saithcommissionshop/lib/pages/admin_home_page.dart)
- **Header**: Ensure the header gradient uses the vibrant Emerald Green.
- **Tiles/Cards**: Verify that all stat tiles and KPI cards use the unified light `SColors.surface` and dark text.
- **Floating Nav**: Update the bottom bar to a light, translucent style with a white/blurred background.

## Verification Plan

### Manual Verification
- **Visual Audit**: Navigate through all tabs (Dashboard, Invoices, Stock, More) and secondary pages (Settings, Customers).
- **Consistency Check**: Verify that the background is consistently light across the whole app.
- **Readability Check**: Ensure all text is sharp, dark, and easy to read.
- **3D Depth**: Confirm the "popped out" effect is still visible and professional in light mode.
