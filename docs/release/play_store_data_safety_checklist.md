# Pet Life — Google Play Data Safety Checklist v1.0

## Current build behavior

Pet Life v1.0 stores user-entered data locally on the device.

The current build does not include:

- Cloud account
- Login
- Backend sync
- Analytics SDK
- Crash reporting SDK
- Ads SDK
- Billing SDK
- Social features
- Public user-generated content

## Data handled locally

Pet Life v1.0 handles the following data locally:

- Pet name
- Pet species
- Pet estimated age
- Breed
- Sex
- Microchip text field
- Veterinarian name text field
- Reminder titles
- Reminder dates and times
- Reminder notes
- Document titles
- Document categories
- Document notes
- Local document files selected by the user
- Local document file paths
- Exported JSON files created by the user

## Data Safety answer guidance

### Data collection

Recommended answer for the current v1.0 build:

- No user data is collected by the developer, if “collected” means transmitted off-device to the developer or a third party.

Reason:

- User-entered data remains local on the user’s device.
- No backend is configured.
- No analytics or crash SDK is enabled.
- No account is created.

Important:

If any SDK or backend is added later, this answer must be reviewed and updated.

### Data sharing

Recommended answer:

- No data is shared with third parties.

Reason:

- No user-entered data is transmitted to third parties in v1.0.

### Data deletion

Recommended answer:

- Users can delete local app data inside the app.

In-app path:

Settings → Data management → Delete local data

### Data export

In-app path:

Settings → Data management → Export data

### Encryption in transit

Recommended answer:

- Not applicable for user-entered pet data in v1.0 because the app does not transmit this data.

If a backend is added later:

- Use HTTPS/TLS.
- Update the privacy policy.
- Update Data Safety.
- Add account deletion if user accounts are introduced.

## Permissions

### Notification permission

Permission:

- `android.permission.POST_NOTIFICATIONS`

Purpose:

- Send reminders and due date notifications created by the user.

Not used for:

- Advertising
- Promotional notifications
- Medical advice
- Emergency guidance

## Account deletion

Current v1.0 state:

- No account creation.

Recommended answer:

- Not applicable, because Pet Life v1.0 does not create accounts.

If account creation is added later:

- Add in-app account deletion.
- Add web account deletion URL if required.
- Update Play Console Data Safety.

## Health declaration support

Pet Life is an organizer, diary and document archive for pet care.

Pet Life does not provide:

- Diagnosis
- Triage
- Prescriptions
- Treatment plans
- Dosage calculations
- Emergency guidance
- Vet consultation
- Human health services

Suggested declaration wording:

Pet Life helps users organize pet profiles, reminders and local documents. The app does not provide medical or veterinary advice, diagnosis, triage, prescriptions, dosage calculation or emergency guidance. Users are instructed to contact a veterinarian for health concerns.

## Subscription state

Current v1.0 state:

- Premium screen is informational only.
- No real purchases are enabled.
- Restore purchases is hidden.
- No billing SDK is active.

If billing is enabled later:

- Update Data Safety according to the billing SDK behavior.
- Update store listing.
- Add manage/cancel subscription method.
- Add restore purchases.
- Test in internal or closed testing before production.

## Final review before submission

Before submitting, verify:

- The AAB submitted is the same behavior described here.
- No analytics/crash/billing SDK has been added without updating Data Safety.
- Privacy Policy URL is live.
- Data Safety answers match the submitted artifact.
- Health declaration matches the submitted artifact.