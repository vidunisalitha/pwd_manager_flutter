# PeekAKey

PeekAKey is a Flutter password manager built to store service credentials in an encrypted local vault. It uses a PIN-based unlock flow, optional biometric authentication, and device-backed secure storage to keep sensitive data protected on the phone.

## Features

- PIN-based sign up and sign in.
- Optional biometric unlock for returning users.
- Encrypted password vault for storing service names, usernames, and passwords.
- Add, update, search, and delete saved service entries.
- Reveal or hide individual passwords, plus a global peek mode.
- Update username and PIN from the settings screen.
- Theme selection with light, dark, and system modes.
- Logout flow with secure session reset.

## Security Features

- PINs are processed with Argon2id before being stored.
- The app stores the PIN hash and salt in secure device storage, not in plain text.
- Vault entries are encrypted before being written to the local database.
- The vault database uses SQLCipher for encrypted SQLite storage.
- Biometric login is protected by the device biometric system via `local_auth`.
- Cached biometric PIN access is stored in secure storage and removed when biometrics are disabled.
- Android biometric support uses `FlutterFragmentActivity`, which is required by `local_auth`.
- iOS secure storage uses Keychain accessibility configured for first-unlock behavior.
- Theme and biometric preference values are also persisted in secure storage.

## Tech Stack

- Flutter
- Provider for app state
- Cryptography package for PIN hashing and key derivation
- `flutter_secure_storage` for protected local secrets
- `sqflite_sqlcipher` for encrypted database storage
- `local_auth` for biometric authentication

## Requirements

- Flutter SDK `^3.11.5`
- Dart `^3.11.5`
- Android Studio, Xcode, or another Flutter-compatible development environment
- A physical device is recommended for biometric testing

## Getting Started

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Run the app

```bash
flutter run
```

### 3. Build for release

```bash
flutter build apk
flutter build ios
```

## Usage

### First launch

- Create a username and 4-digit PIN.
- The app stores your login data locally and creates the encrypted vault state.

### Unlocking the app

- Enter your PIN to unlock the vault.
- If biometric login has been enabled, you can unlock using Face ID, Touch ID, fingerprint, or the device biometric prompt depending on the phone.

### Managing vault entries

- Tap the add button to create a new service entry.
- Tap a service card to view stored credentials.
- Long-press a service card to edit the entry.
- Use search to quickly filter saved services.

### Settings

- Update your username and PIN.
- Enable or disable biometric login.
- Switch between light, dark, and system themes.
- Sign out from the current session.

## Project Structure

```text
lib/
  core/
    crypto/        PIN hashing, key derivation, and encryption helpers
    utils/         biometric helpers and shared utilities
  data/
    database/      local database setup and SQLCipher access
    local/         secure storage wrapper
    models/        account and domain models
    repositories/  auth and vault persistence logic
  presentation/
    providers/     app state and session providers
    screens/       login, vault, and settings screens
    widgets/       reusable UI components
```

## Security Notes

- This app is designed for local, on-device storage.
- There is no remote sync or cloud backup layer in the current project.
- If the device is wiped or secure storage is cleared, access to the vault data may be lost.
- Biometric login depends on the device supporting biometrics and on the platform configuration being correct.

## Troubleshooting

- If biometric authentication fails on Android, ensure the app is using `FlutterFragmentActivity`.
- If login fails after changing the PIN, reinstall the app or clear app data only if you intentionally want to reset the local vault.
- For emulator testing, make sure the emulator has biometrics configured.

## License

No license has been specified for this project yet.
