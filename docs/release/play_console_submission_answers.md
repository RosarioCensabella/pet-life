# Pet Life — Play Console Submission Answers v1.0

## Build submitted

- App name: Pet Life
- Package name: com.petlife.pet_life
- Version: 1.0.0+1
- Artifact: build/app/outputs/bundle/release/app-release.aab
- Release type: Android App Bundle signed with local upload key

## App category

Recommended category:

- Lifestyle

Alternative category:

- Productivity

Reason:

Pet Life is an organizer, diary and document archive for pet care. It is not a medical diagnosis or veterinary telemedicine app.

## App access

Question: Does all or part of the app have restricted access?

Recommended answer for current v1.0:

- No

Reason:

- No login is required.
- No account is required.
- No subscription purchase is required to access the current app features.
- The Premium screen is informational only.
- Store purchase actions and restore purchases are hidden in this build.

Reviewer notes:

Pet Life can be reviewed without credentials. Complete onboarding, then use the app normally.

Suggested reviewer instructions:

1. Open the app.
2. Tap “Accetta e continua” / “Accept and continue”.
3. Add a pet from Home.
4. Open the pet dashboard.
5. Test Reminders and Documents.
6. Open Settings to review Privacy Policy, Terms, Disclaimer, Notifications, Export and Delete local data.
7. Open Premium from Settings. Premium is informational only; no purchase action is available in this build.

## Ads

Question: Does your app contain ads?

Recommended answer:

- No

Reason:

Pet Life v1.0 does not include ads SDKs and does not show advertising.

## Content rating

Recommended questionnaire direction:

- App category: Utility / Lifestyle-style app
- No violence
- No sexual content
- No gambling
- No user-generated public content
- No social networking
- No location sharing
- No online purchases enabled in current build
- No medical treatment advice
- No diagnosis or triage

Important:

If the questionnaire asks about health/medical content, answer truthfully that Pet Life contains pet care organization content and medical-veterinary disclaimers, but does not provide diagnosis, triage, prescriptions, treatment recommendations or dosage calculations.

## Target audience

Recommended answer:

- Adults / general audience
- Not designed specifically for children

Reason:

The app is designed for pet owners managing reminders, documents and care tasks.

## News declaration

Recommended answer:

- No

Reason:

Pet Life is not a news or magazine app.

## Government apps declaration

Recommended answer:

- No

Reason:

Pet Life is not affiliated with a government entity.

## Financial features declaration

Recommended answer:

- No

Reason:

Pet Life v1.0 does not provide financial products, loans, payments, credit, insurance brokerage or regulated financial services. It may later allow users to record pet expenses, but no financial service is offered in v1.0.

## Health apps declaration

Recommended direction:

Pet Life should be declared as an app with pet care organization features only if Play Console asks about health-related functionality.

Suggested description:

Pet Life is a pet care organizer and diary. It helps users store pet profiles, reminders, document metadata and local documents. The app does not provide medical or veterinary diagnosis, triage, treatment recommendations, prescriptions, dosage calculations or emergency guidance. Users are repeatedly instructed to contact a veterinarian for health concerns.

Capabilities present:

- Pet profile organization
- Reminder organization
- Local document archive
- Calendar of user-created reminders
- Medical-veterinary disclaimer

Capabilities not present:

- Diagnosis
- Triage
- Clinical advice
- Prescriptions
- Dosage calculation
- Treatment plan generation
- Emergency guidance
- Telemedicine
- Vet consultation
- Medical device functionality
- Integration with health sensors
- Human health data collection

## Data Safety — current implementation

Important note:

The current v1.0 implementation stores user-entered data locally on the device and does not sync to a backend. Verify this again before submission if analytics, crash reporting, authentication, billing SDKs or cloud services are added.

### Does the app collect or share user data?

Recommended answer for current v1.0:

- Data collected: No, if Google Play’s form treats “collection” as data transmitted off the user’s device to the developer or third parties.
- Data shared: No.

Reason:

- No backend service is configured.
- No analytics SDK is enabled.
- No crash reporting SDK is enabled.
- No account system is enabled.
- Pet data, reminders and documents are stored locally on the user’s device.
- Export is user-initiated and creates a local JSON file.

If Play Console asks about data handled locally:

State that data is stored locally on-device and can be exported or deleted by the user.

### Data categories handled locally

Pet Life v1.0 handles these data types locally:

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
- Local document files selected by the user
- Local document paths
- Local export JSON files

### Data sharing

Recommended answer:

- No data is shared with third parties in v1.0.

### Data deletion

Recommended answer:

- Users can delete local app data inside the app.

In-app path:

Settings → Gestione dati / Data management → Elimina dati locali / Delete local data

### Data export

In-app path:

Settings → Gestione dati / Data management → Esporta dati / Export data

### Encryption in transit

Recommended answer:

- Not applicable for app user data in current v1.0 because user-entered data is not transmitted to a backend.

If a future cloud service is added:

- Use HTTPS/TLS.
- Update Data Safety.
- Update Privacy Policy.
- Update Terms.
- Add account deletion if accounts are introduced.

## Privacy Policy

Current status:

- In-app Privacy Policy exists.
- A public privacy policy URL is still required for Play Console before production release.

Temporary instruction:

Publish the public privacy policy text from `docs/release/public_privacy_policy.md` on a stable web page controlled by the developer.

Do not submit production until the privacy policy URL is live and accessible without login.

## Subscriptions

Current v1.0 state:

- Premium model exists.
- Paywall is informational.
- Store purchases are not enabled.
- Restore purchases is hidden.
- Product IDs are reserved in code/docs:
  - pet_life_premium_monthly
  - pet_life_premium_annual

Recommended Play Console answer for current submitted build:

- In-app purchases/subscriptions: No, if no billing SDK/products are enabled in the submitted artifact.

Before enabling subscriptions:

- Configure Google Play Billing or RevenueCat.
- Create products in Play Console.
- Show accurate pricing from the store.
- Add restore purchases.
- Add cancellation/manage subscription link.
- Update Data Safety if billing SDK data collection applies.
- Update screenshots if Premium purchase buttons become visible.
- Run a closed test before production.

## App integrity and signing

Current state:

- AAB is signed with local upload key.
- Keystore and key.properties are ignored by Git.
- Google Play App Signing should be enabled in Play Console.

Do not commit:

- android/key.properties
- android/keystore/
- *.jks
- *.keystore

## Final reviewer note

Suggested Play Console note:

Pet Life is a pet care organizer, diary and local document archive. It does not provide medical or veterinary diagnosis, triage, prescriptions, treatment recommendations, dosage calculations or emergency guidance. Premium is informational only in this submitted build; no purchase or restore action is available.