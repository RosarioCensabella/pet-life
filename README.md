# Pet Life

Pet Life è una app B2C multilingua per proprietari di cani, gatti e altri animali domestici.

L'app è posizionata come diario intelligente, organizzatore, archivio documenti e assistente per la cura del pet.

## Disclaimer medico-veterinario

Pet Life aiuta a organizzare informazioni e promemoria.  
Non fornisce diagnosi, terapie, prescrizioni o indicazioni mediche.  
Per sintomi preoccupanti o persistenti, l'utente deve contattare il veterinario.

## Stack iniziale

- Flutter
- Dart
- Riverpod
- go_router
- ARB localization IT/EN
- Material 3
- shared_preferences per persistenza locale iniziale

## Stato progetto

### Completato

- Creazione progetto Flutter
- Avvio su emulatore Android
- Localizzazione IT/EN
- Onboarding iniziale
- Disclaimer no diagnosi
- Home vuota multi-pet
- Bottom navigation base
- Test widget per onboarding IT/EN
- Modello locale `Pet`
- Form "Aggiungi pet"
- Persistenza locale dei pet
- Home con lista animali
- Dashboard profilo pet
- Modifica profilo pet
- Archiviazione pet
- Feature flag centralizzati
- Dashboard modulare del pet con solo moduli completi visibili

### Prossima fase

- Primo modulo completo: promemoria locali
- Notifiche locali
- Stati promemoria: attivo, completato, rimandato, saltato

## Comandi principali

```powershell
flutter gen-l10n
flutter analyze
flutter test
flutter run
Regole prodotto non negoziabili
Nessuna diagnosi medica
Nessun triage
Nessuna prescrizione
Nessun calcolo dosaggi
Nessuna sostituzione del veterinario
Tutte le feature health sono solo tracking e organizzazione
Tutte le stringhe devono essere localizzate almeno in italiano e inglese