<div align="center">

<img src="app_logo.png" width="120" alt="ConvetChat">

# ConvetChat

**A simple and private Matrix client.**

*Simple. Private. Decentralized.*

[![Latest release](https://img.shields.io/github/v/release/frevod/convetchat)](https://github.com/frevod/convetchat/releases/latest)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Matrix](https://img.shields.io/badge/Matrix-000000?logo=matrix&logoColor=white)](https://matrix.org)
[![License: MIT](https://img.shields.io/badge/license-MIT-brightgreen)](LICENSE)

</div>

ConvetChat is an open-source messenger built on [Matrix](https://matrix.org),
written in Flutter. No lock-in to a single company: your account lives on
a homeserver and talks to the whole Matrix federation.

Don't want to pick a server — just sign up on our `convet.xyz`.
And you can discuss the project itself in the room
[!oEuUdFKRnvFJximJEB:convet.xyz](https://matrix.to/#/%21oEuUdFKRnvFJximJEB%3Aconvet.xyz).

## Features

- 🔐 End-to-end encryption on the Rust vodozemac stack — the same cryptography Element uses
- ✅ Emoji-based device verification (SAS) and cross-signing
- 🔑 SSO-only login (MAS): no passwords — nothing to steal or leak. This is a deliberate decision
- 🗝️ Encrypted key backup: passphrase or recovery key
- 🔒 Credentials live only in the system keystore, never in plaintext
- 📩 Direct and group chats, public room directory
- 📎 Photo and video albums with captions
- 🎙️ Voice messages
- ⭕ Round video messages — no other Matrix client has them. Front-camera recording up to 60 seconds, and where rounds aren't supported the message simply shows up as a regular video — nothing breaks
- 🔁 Message forwarding between rooms
- 📲 Push notifications via a Matrix-compatible gateway, including on your own server
- 🎨 Material 3 Expressive on Android, native Cupertino on iOS
- 🌗 Light and dark themes, dynamic color
- 📋 Built-in log viewer
- 🤫 Analytics and crash reports — only with your consent, off by default

## Limitations

The project is under active development, so here's honestly what's missing so far:

- 📞 No voice or video calls
- 🤖 Android — APK from GitHub. No Google Play yet
- 🍎 iOS — in testing. No App Store release yet
- 🖥️ Windows, Linux, macOS, Web — planned, no timeline

## Installation

### Android

Download the APK from the [latest release](https://github.com/frevod/convetchat/releases/latest) page:

| File | Who it's for | Size |
| --- | --- | --- |
| `convetchat-arm64-v8a.apk` | Most modern phones | ~51 MB |
| `convetchat-universal.apk` | If you're not sure which one you need | ~127 MB |
| `convetchat-armeabi-v7a.apk` | Older devices | ~49 MB |
| `convetchat-x86_64.apk` | Emulators | ~54 MB |

Android will warn you about installing from an unknown source — that's normal
for apps installed directly instead of from Google Play.

### iOS

The iOS version is in testing, no App Store release yet.

## Building from source

Requirements: Flutter SDK, Dart `^3.13.2`, Android SDK (for Android),
Xcode on macOS (for iOS).

```bash
git clone https://github.com/frevod/convetchat.git
cd convetchat
flutter pub get
cp .env.example .env
flutter run
```

`.env` is needed for the in-app Telegram feedback form. Never commit
secrets, tokens, or signing keys.

Useful:

```bash
flutter analyze   # static analysis
flutter test      # tests
flutter build apk # build APK
```

> Building for Android requires your own `android/app/google-services.json`
> (not committed). Debug builds use the `com.convet.convetchat.debug`
> application id — it needs a client entry too.

## Bugs and feedback

Bugs are expected — the project is young. Found one:

1. Check the [existing issues](https://github.com/frevod/convetchat/issues).
2. Nothing similar — open a new one: what happened, reproduction steps, screenshots or logs.
3. Never post passwords, tokens, or recovery keys in issues.

## Contributing

Ideas, bugs, and pull requests are welcome. Create a branch, make your changes,
open a Pull Request.

## License

[MIT](LICENSE).

## Links

- GitHub: <https://github.com/frevod/convetchat>
- Releases: <https://github.com/frevod/convetchat/releases>
- Homeserver: `convet.xyz`
- Project room: [!oEuUdFKRnvFJximJEB:convet.xyz](https://matrix.to/#/%21oEuUdFKRnvFJximJEB%3Aconvet.xyz)
- Matrix: <https://matrix.org/>

---

<div align="center">

⭐ If you like the project, give it a star.

</div>
