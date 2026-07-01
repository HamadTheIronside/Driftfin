# 🚀 Driftfin Dev Setup

## 🔧 Requirements

Ensure the following tools are installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (latest stable)
- [Android Studio](https://developer.android.com/studio) (for Android development and emulators)
- [VS Code](https://code.visualstudio.com/) with:
  - Flutter extension
  - Dart extension

Verify your Flutter setup with:

```bash
flutter doctor
```

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/HamadTheIronside/Driftfin.git
cd Driftfin

# Install dependencies
flutter pub get
```

## 🐧 Linux Dependencies

If you're on **Linux**, install the `mpv` dependency:

```bash
sudo apt install libmpv-dev
```

## 🛠️ Running the App

1. **Connect a device** or launch an emulator.
2. In VS Code:
   - Select the target device (bottom right corner).
   - Press `F5` or go to **Run > Start Debugging**.
   - If prompted, select **"Run Anyway"**.

## ⚙️ Code Generation

Generate build files (e.g., for `json_serializable`, `freezed`, etc.):

```bash
flutter pub run build_runner build
```

> Tip: Use `watch` for continuous builds during development:
```bash
flutter pub run build_runner watch
```
Update localization definitions:
```bash
flutter gen-l10n
```
Format files to spec:
```bash
dart format --line-length 120 ./lib/
```

## 🐞 Crash Reporting (optional)

Driftfin ships with opt-in [Sentry](https://sentry.io) crash reporting, off by default. It stays fully inert — no SDK
init, no network calls — unless **both**:

1. The app was built with a DSN: `flutter build <target> --dart-define=SENTRY_DSN=https://examplePublicKey@o0.ingest.sentry.io/0`
   (Web deployments can instead set the `SENTRY_DSN` env var at container runtime — see [INSTALL.md](INSTALL.md) — so a
   single Web build can serve multiple Sentry projects.)
2. The user flips **Settings → Advanced → Send crash reports** in the app themselves.

See `lib/bootstrap/app_bootstrap.dart` (`sentryDsn`, `resolvedSentryDsn`) and `lib/main.dart` for how the two are combined.

## 🌐 Using a demo Server
You can use a fake server from Jellyfin.
https://demo.jellyfin.org/stable/web/