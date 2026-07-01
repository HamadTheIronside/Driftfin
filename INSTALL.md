# Installation instructions

Platform-specific installation instructions can be found in this document.

*Use the links below to jump to your platform.*

- [Windows](#windows)
- [macOS](#macos)
- [Linux](#linux)
	- [Flatpak](#flatpak)
	- [Ubuntu/Debian](#ubuntudebian)
	- [Arch](#arch)
	- [Fedora](#fedora)
- [Android](#android)
- [iOS](#iosipados)
	- [Sideloadly](#sideloadly)
- [Docker](#docker)
- [Web](#web)


## Windows

### Installer

Download the latest `.exe` installer from the [Releases](https://github.com/HamadTheIronside/Driftfin/releases) page and open it. Follow the on-screen instructions.

### Portable

Download the latest `.zip` file from the [Releases](https://github.com/HamadTheIronside/Driftfin/releases) page and extract it somewhere on your PC.

Run `driftfin.exe` to start the application.

## macOS

1. Download the latest `*.dmg` file from the [Releases](https://github.com/HamadTheIronside/Driftfin/releases) page.

2. Open it and copy the Driftfin application file into your `Applications` folder, or another place on your Mac.

3. Right-click the application and click Open while holding `Control`. This will bypass the unidentified developer warning.

> [!TIP]
> Alternatively, to allow the app to run, open `System Settings > Privacy & Security > Scroll down to Security > Open Anyway`.

## Linux

### Flatpak

Download the latest `.flatpak` file from the [Releases](https://github.com/HamadTheIronside/Driftfin/releases) page and install it.

> [!NOTE]
> Driftfin is not published to Flathub.

### Ubuntu/Debian

> [!TIP]
> If you experience issues attempting to run Driftfin with the process exiting with `libmpv` shared library errors, you may need to install `libmpv-dev` by running `sudo apt install libmpv-dev`.

Download the latest Linux `.zip` file from the [Releases](https://github.com/HamadTheIronside/Driftfin/releases) page and extract it somewhere on your computer.

Open a terminal and `cd` to the directory where you extracted Driftfin to. Run `./Driftfin` to open the application.

### Arch

Driftfin does not provide an AUR package yet. Download the latest Linux `.zip` from the [Releases](https://github.com/HamadTheIronside/Driftfin/releases) page (see the [Ubuntu/Debian](#ubuntudebian) steps), or use the [Flatpak](#flatpak) above.

### Fedora

> [!TIP]
> If you experience issues attempting to run Driftfin with the process exiting with `libmpv` shared library errors, you may need to install `mpvlibs` by running `yum install mpvlibs`.

Download the latest Linux `.zip` file from the [Releases](https://github.com/HamadTheIronside/Driftfin/releases) page and extract it somewhere on your computer.

Open a terminal and `cd` to the directory where you extracted Driftfin to. Run `./Driftfin` to open the application.

## Android

> [!IMPORTANT]
> Alpha support added in v0.8.0 and contributions to add further support are always appreciated.

1. Download the latest `.apk` file from the [Releases](https://github.com/HamadTheIronside/Driftfin/releases) page and save it to your device.

2. Open it to start the installation. You may need to allow unknown apps to be installed on your device, as this will be disallowed by default.

> [!NOTE]
> Driftfin is not yet published to the Play Store.

## iOS/iPadOS

### Sideloadly

> [!NOTE]
> Installing using Sideloadly is the only method of using Driftfin on iOS or iPadOS at this time, until a signed App Store build is available.

> [!IMPORTANT]
> If you are using Windows, you must install the web versions of iTunes and iCloud (**not the Microsoft Store versions**) before installing Sideloadly. You can download them [here](https://www.apple.com/itunes/download/win64) and [here](https://updates.cdn-apple.com/2020/windows/001-39935-20200911-1A70AA56-F448-11EA-8CC0-99D41950005E/iCloudSetup.exe).

1. Download and install Sideloadly from their [downloads page](https://sideloadly.io/#download).

2. Download the latest iOS IPA file from the [Releases](https://github.com/HamadTheIronside/Driftfin/releases) page and save it to your computer.

3. Plug your device into your computer and open iTunes.

4. Click the device icon in the top left next to the navigation buttons.

5. Ensure **Sync with this device over Wi-Fi** is checked.

6. Click Apply, then Done, then close iTunes.

7. Open Sideloadly and click the Open IPA button in the top left. Select the IPA you downloaded earlier.

8. Make sure your device is listed under **iDevice**. It will usually look like this: `<device name> (<iOS version>) <UDID> @USB`.

9. Enter your Apple ID in the **Apple ID** box. Creating a second Apple ID is recommended, but not required.

10. Click Start. You will be prompted to enter your Apple ID password. Enter it and allow any two-factor authentication, if required.

11. The installation process will take a while. Once it's finished, you will see the Driftfin icon on your home screen or in your App Library.

> [!NOTE]
> Your password is only used for authentication to Apple's servers. It is not sent to any third parties.

> [!IMPORTANT]
> Once installed, Driftfin will only be valid for 7 days. Enabling auto refresh will keep the app from expiring (this should already be enabled). Your computer needs to be on for this to occur.

## Docker

You can install Driftfin on your server to provide an alternate Jellyfin dashboard.

Copy the contents of the [docker-compose.yml](https://raw.githubusercontent.com/HamadTheIronside/Driftfin/refs/heads/develop/docker-compose.yml) file and save it to your server.

Run `docker-compose up -d` to start the container. It will be available on `http://<server-ip>`.

> [!TIP]
> We recommend changing the `BASE_URL` environment variable to the URL you use to access Jellyfin, as this will skip entering it when you load the web UI.

You can also preconfigure Seerr with this environment variable:

- `SEERR_BASE_URL`: String URL for your Seerr/Jellyseerr instance.

Example:

```env
BASE_URL=https://jellyfin.example.com
SEERR_BASE_URL=https://seerr.example.com
```

### Opt-in crash reporting

Driftfin has no crash reporting by default. If you'd like to catch field issues on the instance you're serving, set a [Sentry](https://sentry.io) DSN:

- `SENTRY_DSN`: String URL of your Sentry project's DSN.

```env
SENTRY_DSN=https://examplePublicKey@o0.ingest.sentry.io/0
```

Setting this only makes crash reporting *available* — it stays off until a user flips **Settings → Advanced → Send crash reports** themselves. No DSN means the toggle can't send anywhere and no Sentry SDK calls are made, regardless of the setting.

## Web

You can also manually copy the web .zip build to any static file server such as Nginx, Caddy, or Apache

> [!TIP]
> You can preconfigure Driftfin by placing a config file in [assets/config/config.json](https://github.com/HamadTheIronside/Driftfin/blob/develop/config/config.json)

`config.json` options:

```json
{
	"baseUrl": "https://jellyfin.example.com",
	"seerrBaseUrl": "https://seerr.example.com",
	"sentryDsn": "https://examplePublicKey@o0.ingest.sentry.io/0"
}
```

- `baseUrl`: String. Presets Jellyfin URL on login.
- `seerrBaseUrl`: String. Presets Seerr URL in personal settings.
- `sentryDsn`: String. Optional. Same as the Docker `SENTRY_DSN` variable above — makes the in-app crash reporting toggle available; users still opt in themselves.
