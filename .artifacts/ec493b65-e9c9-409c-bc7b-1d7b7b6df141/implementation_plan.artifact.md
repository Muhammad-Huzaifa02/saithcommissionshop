# Add Real-time Weather to Home Headers

This plan ensures that real-time weather information is fetched and displayed prominently in both the Admin and Customer home page headers and dashboards.

## User Review Required

> [!NOTE]
> The app already has a weather system, but it may not be triggering correctly on app start. I will ensure it fetches data as soon as the home page is opened and add a more detailed weather card to the main dashboard for a better experience.

## Proposed Changes

### Weather Logic

#### [MODIFY] [weather_provider.dart](file:///C:/Users/seith/StudioProjects/saithcommissionshop/lib/provider/weather_provider.dart)
- Update constructor to trigger an initial `fetch()` so data is available as soon as the app loads.

### Admin Dashboard

#### [MODIFY] [admin_home_page.dart](file:///C:/Users/seith/StudioProjects/saithcommissionshop/lib/pages/admin_home_page.dart)
- Add `initState` to `_AdminHomePageState` to ensure `WeatherProvider.fetch()` is called.
- Insert the full `WeatherWidget()` card into the `_DashboardTab` list (after the KPI cards) to provide detailed weather and "business tips" based on conditions.

### Customer Dashboard

#### [MODIFY] [customer_home_page.dart](file:///C:/Users/seith/StudioProjects/saithcommissionshop/lib/pages/customer_home_page.dart)
- Add `initState` to `_CustomerHomePageState` to ensure `WeatherProvider.fetch()` is called.
- Insert the full `WeatherWidget()` card into the `_DashboardTab` list (after the KPI cards) for a premium look.

## Verification Plan

### Manual Verification
- Open the app as an Admin.
- **Expected**: A weather pill should appear in the header, and a detailed weather card should be visible on the dashboard.
- Open the app as a Customer.
- **Expected**: Similar weather information should be visible in the customer dashboard.
- Verify that the location and temperature reflect real-time data.
