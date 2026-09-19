# Implementation Plan - ComMobi-Tracker Enhanced Features

We are applying core UI/UX updates to the "ComMobi-Tracker" mobile application, focusing on responsiveness, authentication flow, persistent bottom navigation, micro-animations, and a redesigned high-impact emergency alert system.

## Proposed Changes

### Configuration & Dependencies

#### [MODIFY] [pubspec.yaml](file:///c:/Users/TANDAH/OneDrive/Documents/unicef_app/pubspec.yaml)
- Add dependencies:
  - `flutter_screenutil: ^5.9.3` for pixel-perfect display adaptations (text `.sp` scaling, sizes `.w` / `.h`).
  - `flutter_animate: ^4.5.2` for professional micro-animations (statistics cards fade/slides, emergency alerts pulsing).
- Declare asset files under `flutter:`:
  ```yaml
  assets:
    - assets/images/unicef_logo.png
    - assets/images/minproff_logo.png
  ```

---

### Core State & Authentication Layout

#### [NEW] [login_screen.dart](file:///c:/Users/TANDAH/OneDrive/Documents/unicef_app/lib/screens/login_screen.dart)
- Side-by-side display of UNICEF and MINPROFF logos.
- Fields: Facilitator Phone/ID, PIN Code.
- Toggles: "Remember Me", "Offline Mode Login" badge.
- Validation: Verifies credentials against sqlite (simulated/local auth check) and redirects to structural navigation hub.

#### [NEW] [nav_hub_screen.dart](file:///c:/Users/TANDAH/OneDrive/Documents/unicef_app/lib/screens/nav_hub_screen.dart)
- Persistent Bottom Navigation Bar implementing Material 3 `NavigationBar`.
- Links 4 tabs to corresponding screens:
  - Tab 1: Dashboard (`HomeScreen.dart`)
  - Tab 2: Family Directory (`FamilyListScreen.dart`)
  - Tab 3: GSP community sessions (`GroupSessionScreen.dart`)
  - Tab 4: Settings & Data flow pipeline (`SettingsScreen.dart`)

---

### UI & Animations Adjustments

#### [MODIFY] [home_screen.dart](file:///c:/Users/TANDAH/OneDrive/Documents/unicef_app/lib/screens/home_screen.dart)
- Wrap layouts in `ScreenUtilInit`.
- Implement responsive grids for statistics cards.
- Add entrance slide/fade-in animations to statistics cards via `flutter_animate`.
- Add "Power BI Data Pipeline Info Card" explaining SQLite -> API -> PostgreSQL -> Power BI.
- Redesign **Emergency Safeguarding Card**:
  - Pulsing red shield symbol (pulse animation).
  - Open modal dialog for reporting child exploitation/abuse with local sqlite entry encryption.

#### [MODIFY] [form_screen.dart](file:///c:/Users/TANDAH/OneDrive/Documents/unicef_app/lib/screens/form_screen.dart)
- Implement helpful explanatory text/tooltips under complex question fields in the 10-module accordion checklist.
- Make checking/radio scaling responsive with wrapping fixes.

#### [MODIFY] [main.dart](file:///c:/Users/TANDAH/OneDrive/Documents/unicef_app/lib/main.dart)
- Initialize `ScreenUtilInit` in MaterialApp.
- Route initial screen to `LoginScreen`.

---

## Verification Plan

### Automated Tests & Compile Checks
- Run `flutter pub get` and verify dependency matches.
- Run `flutter analyze` ensuring 0 compile errors and fully responsive widget builds.
