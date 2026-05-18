# Pet Life — Android Release Checklist v1.0

## Build identity

- App name: Pet Life
- Android package/applicationId: com.petlife.pet_life
- Version target: 1.0.0+1
- Release artifact: Android App Bundle (.aab)

## Technical checks

- `flutter analyze` passes
- `flutter test` passes
- `flutter build apk --debug` passes
- `flutter build appbundle --release` passes
- AndroidManifest contains `POST_NOTIFICATIONS`
- App label is `Pet Life`
- No medical diagnosis, triage, prescription or dosage calculation is present
- Store purchase actions are hidden until real billing configuration is complete
- Restore purchases is hidden until real billing configuration is complete

## Android permissions

Current permissions:

- `android.permission.POST_NOTIFICATIONS`

Usage:

- Notifications are used only for reminders and due dates created by the user.
- Pet Life does not send promotional notifications in v1.0.

## Data and privacy

Pet Life v1.0 stores user-entered data locally on the device:

- Pet profiles
- Reminders
- Documents metadata
- Local document files selected by the user
- Settings-related local state

Pet Life v1.0 does not create a cloud account.

Required in-app data controls:

- Privacy Policy screen
- Terms of Service screen
- Medical-veterinary disclaimer screen
- Local JSON data export
- Local data deletion

## Subscription readiness

Current state:

- Free/Premium model exists
- Premium pricing copy exists:
  - 3,99 €/month
  - 29,99 €/year
- Paywall is informational
- Real store purchases are disabled
- Restore purchases is hidden

Before enabling real purchases:

- Create App Store / Play Store products
- Configure product IDs:
  - `pet_life_premium_monthly`
  - `pet_life_premium_annual`
- Add billing SDK or RevenueCat integration
- Add restore purchases button only after real implementation
- Add server/store receipt validation strategy

## Release build commands

```powershell
flutter clean
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build appbundle --release

Expected output:

build\app\outputs\bundle\release\app-release.aab
Manual smoke test on Android
Install/run debug build
Complete onboarding
Add pet
Add reminder
Check notification permission section
Add document
Open document
Delete document
Export data
Delete local data
Open Premium paywall
Confirm no fake purchase actions are visible
Confirm no diagnosis/triage/prescription/dosage features are visible
Release blocker list

Do not release if any of these are true:

flutter analyze fails
Any test fails
Release AAB build fails
AndroidManifest does not include notification permission
App shows fake purchase/restore actions
App claims to diagnose, prescribe, triage or calculate dosage
Privacy Policy is missing
Data export/delete controls are missing