# Maintaining Driftfin (fork of Fladder)

Driftfin is a fork of [Fladder](https://github.com/DonutWare/Fladder) by DonutWare,
under GPL-3.0. This file documents how to keep it in sync with upstream and how to
cut releases. (Branding/license credit lives in `README.md`.)

## Remotes

```bash
git remote -v
# origin    https://github.com/HamadTheIronside/Driftfin   (your fork)
# upstream  https://github.com/DonutWare/Fladder            (original)

# one-time, if upstream is missing:
git remote add upstream https://github.com/DonutWare/Fladder.git
```

## What the fork changes

The rebrand is in two buckets:

1. **Visible branding** (~11 files, rarely conflicts) — app name "Driftfin", icons,
   bundle IDs `app.driftfin`, deep-link scheme `driftfin://`, README, pubspec `name`.
2. **Internal Dart package rename** (~480 files) — `package:fladder/` → `package:driftfin/`.
   This is invisible to users but is the reason upstream merges need a re-apply step:
   upstream keeps writing `package:fladder/` in new/changed files.

The rename is re-applied mechanically by [`tool/rebrand.sh`](tool/rebrand.sh).

## Syncing upstream into the fork

```bash
git fetch upstream
git checkout develop
git merge upstream/develop        # resolve conflicts (mostly import lines)
tool/rebrand.sh                   # re-rename any new package:fladder/ imports
fvm flutter pub get
fvm flutter analyze               # must be clean before committing
git add -A && git commit          # finish the merge
git push origin develop
```

Tips that make merges painless:

- **Enable rerere once** so Git remembers how you resolved the recurring import
  conflicts and auto-applies them next time:
  ```bash
  git config rerere.enabled true
  ```
- If a merge conflict is *only* `package:fladder/` vs `package:driftfin/`, you can
  take **either** side and then run `tool/rebrand.sh` — it normalizes everything to
  `driftfin` regardless.
- Always use **`fvm flutter`** (pinned 3.35.7 via `.fvmrc`), not a system `flutter`.

## Releasing

Releases are built by GitHub Actions in [`.github/workflows/release.yml`](.github/workflows/release.yml)
— **Web + Windows + iOS (unsigned)** — and published as a GitHub Release.

```bash
# pick the next version (see scheme below), then:
git tag v0.10.3-driftfin.1
git push origin v0.10.3-driftfin.1
# -> Actions builds the three platforms and publishes the release with binaries.
```

You can also trigger `release.yml` manually from the **Actions** tab (workflow_dispatch)
for a dry build without publishing.

### Versioning scheme

Track the upstream base version and append a fork counter, so it's always clear which
Fladder release you're built on:

```
v<upstream-version>-driftfin.<n>
e.g.  v0.10.3-driftfin.1   (first Driftfin release on top of Fladder 0.10.3)
      v0.10.3-driftfin.2   (another Driftfin release, still on 0.10.3)
      v0.11.0-driftfin.1   (after merging upstream 0.11.0)
```

The `pubspec.yaml` `version:` stays at the upstream base (e.g. `0.10.3+1`); the git
tag carries the `-driftfin.N` suffix. The release title/asset names use the tag.

### The inherited upstream pipeline

`.github/workflows/build.yml` is Fladder's full multi-platform pipeline (Android,
macOS, Linux/flatpak, Play Console, web deploy). It's **kept** so upstream merges stay
clean, but its auto-triggers are **disabled** (workflow_dispatch only) because it needs
secrets this fork doesn't have (Android keystore, Play Console, a `FLADDER_BOT` GitHub
App). Driftfin uses `release.yml` instead. If you ever want Android or the full set,
wire up those secrets and re-enable `build.yml`'s triggers.

## Known fork leftovers (cosmetic / deferred)

- **App icon & splash art** still use Fladder's image (`icons/production/fladder_icon.png`,
  referenced by `flutter_native_splash` + `icons_launcher`). Replace with a Driftfin logo
  PNG, then regenerate icons to fully rebrand the visuals.
- **l10n help text** in some translations still mentions `fladder:///login` (instructional
  strings only — functionally the scheme is `driftfin://`).
- **`ColorThemes.fladder`** — an internal color-theme enum value is still named `fladder`;
  left as-is because renaming it would break users' persisted theme preference.
- **Android / macOS / Linux** configs are not rebranded (not target platforms).
- **DonutWare's copyright** is intentionally preserved (correct under GPL-3.0).
