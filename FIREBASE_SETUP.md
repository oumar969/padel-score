# Firebase Setup

## Trin 1 — Opret Firebase projekt
1. Gå til https://console.firebase.google.com
2. Klik "Add project" → navngiv det "padel-score"
3. Deaktiver Google Analytics (ikke nødvendigt)
4. Klik "Create project"

## Trin 2 — Aktiver Firestore
1. I Firebase Console: Build → Firestore Database
2. Klik "Create database"
3. Vælg "Start in test mode" (vi tilføjer regler senere)
4. Vælg en server tæt på dig (fx europe-west)

## Trin 3 — Installer FlutterFire CLI
Kør i terminalen:
```
dart pub global activate flutterfire_cli
```

## Trin 4 — Konfigurer projektet
I projektmappen (C:\Users\oamma\projects\padel_score):
```
flutterfire configure
```
Vælg dit "padel-score" Firebase projekt og vælg Android + iOS + Web.
Dette erstatter automatisk `lib/firebase_options.dart`.

## Trin 5 — Kør appen
```
flutter run
```

## Firestore sikkerhedsregler (senere)
Når du er klar til at sikre databasen, sæt disse regler i Firebase Console:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /matches/{matchId} {
      allow read, write: if true; // Skift til auth-baseret adgang senere
    }
  }
}
```
