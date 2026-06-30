<p align="center">
  <img src="assets/driftfin_wordmark.png#gh-light-mode-only" alt="Driftfin" width="420">
  <img src="assets/driftfin_wordmark_white.png#gh-dark-mode-only" alt="Driftfin" width="420">
</p>

<h4 align="center">A cross-platform Jellyfin frontend built on top of <a href="https://flutter.dev/" target="_blank">Flutter</a>.</h4>

<p align="center"><i><b>Driftfin</b> is a fork of <a href="https://github.com/DonutWare/Fladder">Fladder</a> by DonutWare, continued under the same <a href="./LICENSE">GPL-3.0</a> license. Huge thanks to the original authors. See <a href="#credits--attribution">Credits &amp; Attribution</a>.</i></p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#download">Download</a> •
  <a href="#roadmap">Roadmap</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#credits--attribution">Credits</a> •
  <a href="#license">License</a>
</p>

<div align="center">

  [![Checks](https://github.com/HamadTheIronside/Driftfin/actions/workflows/checks.yaml/badge.svg?branch=develop)](https://github.com/HamadTheIronside/Driftfin/actions/workflows/checks.yaml)
  [![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/HamadTheIronside/Driftfin/total)](https://github.com/HamadTheIronside/Driftfin/releases/latest)
  [![GitHub Release](https://img.shields.io/github/v/release/HamadTheIronside/Driftfin?display_name=tag)](https://github.com/HamadTheIronside/Driftfin/releases/latest)
  [![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)

</div>

## Features

**Playback**
- Direct play, transcode, and offline playback
- Watch Together — synchronised group playback (Jellyfin SyncPlay) with in-session chat
- Subtitle timing offset, fine-tuned during playback
- Media-segment skipping (intro / credits / etc.)
- Trickplay timeline scrubbing
- Next-up overview when watching a queue

**Library**
- Browse, refresh content, and edit metadata
- Download items and keep watch progress in sync across devices
- Server management and multiple-user / multiple-server switching
- Jellyseerr / Seerr integration
- Comic book reading support (`.cbz`, `.cbr`)

**Interface**
- Adaptive layout for phone, tablet, TV, and desktop
- Dark / light mode with multiple color styles
- Keyboard shortcuts

### Platforms

| Mobile | Desktop | Other |
|--------|---------|-------|
| Android (+ TV), iOS | Windows, macOS, Linux | Web, Docker |

## Download

Prebuilt binaries for every platform are on the [**releases page**](https://github.com/HamadTheIronside/Driftfin/releases). Platform-specific install and usage notes live in [INSTALL.md](./INSTALL.md).

**Docker:**
```
ghcr.io/hamadtheironside/driftfin:latest
ghcr.io/hamadtheironside/driftfin-rootless:latest
```

**Web:** [try the hosted web build](https://hamadtheironside.github.io/Driftfin)
> [!NOTE]
> The GitHub-hosted web build only allows `https` connections (a GitHub limitation). Self-hosted web builds work fine over plain `http`.

> [!WARNING]
> On Windows, some Flutter apps are flagged as false positives by Windows Defender. This is a known Flutter/Defender issue, not malware.

## Roadmap

What's planned and in progress lives on the [**Driftfin Roadmap**](https://github.com/users/HamadTheIronside/projects/5). Have an idea? [Open a feature request](https://github.com/HamadTheIronside/Driftfin/issues/new/choose).

## Contributing

Interested in contributing? A few ways to help:

**🐛 Reporting bugs**
- Check that the issue hasn't already been [reported](https://github.com/HamadTheIronside/Driftfin/issues).
- Include clear, detailed steps to reproduce — it makes fixing the bug much faster.

**🚀 Pull requests**
- For new features or large changes, open an issue first so work isn't duplicated.
- Keep PRs short and focused — avoid bundling unrelated fixes.
- **Tests are required**: every bugfix and new feature must include unit and widget tests (`test/`, `*_test.dart`). CI runs `flutter test` on every PR and must pass.

**🌐 Translations**
- Translations live in `lib/l10n/app_*.arb`. Edit the relevant file (keys are defined in `app_en.arb`) and open a PR.

See [CONTRIBUTING.md](./CONTRIBUTING.md) and [DEVELOPEMENT.md](./DEVELOPEMENT.md) for setup and full guidelines.

## Credits & Attribution

**Driftfin is a fork of [Fladder](https://github.com/DonutWare/Fladder) by DonutWare.** All credit for the original application goes to the Fladder authors and contributors; Driftfin builds on their work and continues under the same GPL-3.0 license. Changes made in this fork are tracked in this repository's git history.

This software is built with [Flutter](https://flutter.dev/) and many open-source packages (see [`pubspec.yaml`](./pubspec.yaml)).

## License

This project is licensed under the GNU General Public License v3.0 — the same license as the upstream [Fladder](https://github.com/DonutWare/Fladder) project. See the [LICENSE](./LICENSE) file for the full text.
