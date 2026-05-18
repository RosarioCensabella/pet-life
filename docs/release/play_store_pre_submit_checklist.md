# Pet Life — Play Store Pre-Submit Checklist v1.0

## Build

- [ ] Run `flutter analyze`
- [ ] Run `flutter test`
- [ ] Run `flutter build appbundle --release`
- [ ] Verify AAB exists at `build/app/outputs/bundle/release/app-release.aab`
- [ ] Verify AAB signing with `jarsigner`
- [ ] Confirm Git working tree is clean
- [ ] Confirm keystore is not tracked by Git
- [ ] Confirm `android/key.properties` is not tracked by Git

## Play Console setup

- [ ] Create app in Play Console
- [ ] App name: Pet Life
- [ ] Default language: Italian or English
- [ ] App category: Lifestyle
- [ ] App type: App
- [ ] Free/paid app setting: Free
- [ ] Upload signed AAB
- [ ] Complete App content sections
- [ ] Complete Data safety
- [ ] Complete Health apps declaration if shown
- [ ] Complete Content rating questionnaire
- [ ] Complete Target audience
- [ ] Complete Ads declaration
- [ ] Add privacy policy URL
- [ ] Add app access instructions
- [ ] Add store listing assets
- [ ] Add contact email
- [ ] Add website if available

## Store listing

- [ ] Short description added
- [ ] Full description added
- [ ] Medical-veterinary disclaimer included
- [ ] Screenshots added
- [ ] Feature graphic added
- [ ] App icon uploaded
- [ ] No “diagnosis” claim
- [ ] No “triage” claim
- [ ] No “prescription” claim
- [ ] No “dosage calculation” claim
- [ ] No “replace veterinarian” claim
- [ ] No fake purchase claim

## Data Safety

- [ ] Confirm no backend sync is enabled
- [ ] Confirm no analytics SDK is enabled
- [ ] Confirm no crash reporting SDK is enabled
- [ ] Confirm no ads SDK is enabled
- [ ] Confirm no account system is enabled
- [ ] Declare local data behavior accurately
- [ ] Declare data deletion controls
- [ ] Declare no data sharing if still accurate
- [ ] Update answers before submission if any SDK has been added

## Health declaration

- [ ] State Pet Life is a pet care organizer/diary
- [ ] State that Pet Life does not diagnose
- [ ] State that Pet Life does not triage
- [ ] State that Pet Life does not prescribe
- [ ] State that Pet Life does not calculate dosages
- [ ] State that Pet Life does not provide emergency guidance
- [ ] State that users should contact a veterinarian

## Subscriptions

Current v1.0:

- [ ] Premium is informational only
- [ ] No purchase button visible
- [ ] Restore purchases not visible
- [ ] Billing SDK not enabled
- [ ] Play Console in-app products not required for this build

Before enabling subscriptions:

- [ ] Create subscription products
- [ ] Connect billing implementation
- [ ] Show store-returned prices
- [ ] Add restore purchases
- [ ] Add manage/cancel subscription link
- [ ] Update privacy and Data Safety
- [ ] Test closed/internal release

## Permissions

- [ ] `POST_NOTIFICATIONS` present
- [ ] Notification permission requested from Settings, not aggressively at startup
- [ ] Notification purpose explained
- [ ] No promotional notifications in v1.0

## Manual review script

- [ ] Install app
- [ ] Complete onboarding
- [ ] Read disclaimer
- [ ] Add pet
- [ ] Add reminder
- [ ] Complete reminder
- [ ] Postpone reminder
- [ ] Skip reminder
- [ ] Open calendar
- [ ] Add document
- [ ] Open document
- [ ] Delete document
- [ ] Open Settings
- [ ] Open Privacy Policy
- [ ] Open Terms
- [ ] Open Disclaimer
- [ ] Export data
- [ ] Delete local data
- [ ] Open Premium
- [ ] Confirm no purchase/restore action visible
- [ ] Confirm no medical advice features visible

## Release blockers

Do not submit if:

- [ ] Tests fail
- [ ] AAB release build fails
- [ ] AAB signing fails
- [ ] Privacy policy URL is missing
- [ ] Store listing implies medical advice
- [ ] Paywall implies active purchases but billing is not configured
- [ ] Data Safety answers do not match the build
- [ ] Keystore or passwords appear in Git