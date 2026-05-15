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
- flutter_local_notifications per notifiche locali
- timezone + flutter_timezone per scheduling locale
- file_picker per selezione file
- path_provider per archivio locale app ed export
- open_filex per apertura documenti

## Stato progetto

### Completato

- Creazione progetto Flutter
- Avvio su emulatore Android
- Localizzazione IT/EN
- Onboarding iniziale
- Disclaimer no diagnosi
- Home multi-pet
- Bottom navigation funzionante: Home, Calendario, Impostazioni
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
- Modello locale `Reminder`
- Storage locale promemoria
- Creazione promemoria
- Stati promemoria: attivo, completato, rimandato, saltato
- Notifiche locali per promemoria
- Modulo Promemoria visibile nella dashboard
- Home con prossime scadenze
- Calendario globale cross-pet
- Filtro calendario per pet
- Modello locale `PetDocument`
- Archivio documenti locale per pet
- Selezione file
- Apertura documento
- Eliminazione documento
- Impostazioni
- Privacy Policy in-app
- Termini di servizio in-app
- Disclaimer medico-veterinario in-app
- Export dati locali JSON
- Cancellazione dati locali

### Prossima fase

- Miglioramento UX permessi notifiche
- Paywall e subscription readiness
- Account deletion readiness per eventuale account cloud
- Preparazione store listing

## Comandi principali

```powershell
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug
flutter run
Regole prodotto non negoziabili
Nessuna diagnosi medica
Nessun triage
Nessuna prescrizione
Nessun calcolo dosaggi
Nessuna sostituzione del veterinario
Tutte le feature health sono solo tracking e organizzazione
Tutte le stringhe devono essere localizzate almeno in italiano e inglese