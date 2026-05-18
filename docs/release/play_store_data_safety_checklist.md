# Pet Life — Google Play Data Safety Checklist v1.0

Google Play requires developers to complete the Data safety section in Play Console, explaining whether and how the app collects, shares, and protects user data.

## App data model v1.0

Pet Life v1.0 stores user-entered data locally on the device.

Data categories handled locally:

- Pet name
- Pet species
- Pet estimated age
- Breed
- Sex
- Microchip text field
- Veterinarian name text field
- Reminder titles
- Reminder dates
- Reminder notes
- Document titles
- Document categories
- Document notes
- Local document file paths
- Locally selected document files

## Cloud/account status

- No cloud account in v1.0
- No sign-in in v1.0
- No backend database in v1.0
- No server-side data sync in v1.0

## Data export and deletion

In-app controls:

- Export local data as JSON
- Delete local data from the device

If future versions add account creation, Google Play account deletion requirements must be implemented before release.

## Data sharing

Current intended answer:

- Pet Life does not sell personal data.
- Pet Life v1.0 does not send pet health data to a backend.
- Pet Life v1.0 does not share user-entered pet data with third parties.

## Analytics and crash reporting

Current v1.0 state:

- Analytics not enabled
- Crash reporting not enabled

If Firebase Analytics, Crashlytics or another SDK is added later, update this checklist and the Play Console Data safety form before release.

## Permissions

### Notifications

Permission:

- `POST_NOTIFICATIONS`

Purpose:

- Send reminders for due dates and care tasks created by the user.

Not used for:

- Advertising
- Promotional push notifications
- Medical advice
- Emergency alerts

## Medical/veterinary positioning

Pet Life is an organizer, diary and document archive.

Pet Life does not provide:

- Diagnoses
- Triage
- Prescriptions
- Treatment plans
- Dosage calculations
- Emergency medical guidance

## Play Console answers to review before submission

- Does the app collect or share user data?
- Is data encrypted in transit?
- Can users request data deletion?
- Does the app use permissions in a way consistent with the declared purpose?
- Does the app include health-related claims?
- Does the app include subscriptions or in-app purchases?

## Release note

Before production release, verify that the Play Console Data safety form exactly matches the app behavior in the submitted build.

Google Play’s Data safety form is required in Play Console and is shown to users on the store listing, so it must match the submitted build behavior. ---