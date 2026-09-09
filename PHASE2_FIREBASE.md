# SafeRider Phase 2 — Firebase Foundation

The app now uses Cloud Firestore as the authoritative application data store. Firebase Authentication remains responsible for credentials.

## Collections

- `users`
- `parents`
- `drivers`
- `students`
- `rides`
- `payments`
- `expenses`
- `notifications`
- `systemLogs`

## Important

The Firestore console can remain empty. Collections and documents are created by the app when accounts and records are created.

For development, the Firebase console may temporarily be in test mode. Before production, deploy `firestore.rules` and validate the rules in the Firebase Emulator/Rules Playground.

## Authentication

Enable **Email/Password** in Firebase Authentication.

Admin accounts should be created in Firebase Authentication and have a corresponding:

`users/{adminUid}`

with:

```text
email: admin email
role: admin
```

Do not store passwords in Firestore.
