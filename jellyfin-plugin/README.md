# Driftfin — Jellyfin server plugin

Optional Jellyfin **server** plugin that stores Driftfin's client integration
settings — Jellyseerr/Overseerr, Sonarr, Radarr and Trakt — **once, on the
server**, so every Driftfin client pulls one shared configuration instead of
each user re-entering URLs and API keys on every device.

The Driftfin app works **fully without this plugin** — it just falls back to its
normal per-device settings. Install the plugin only if you want centrally
managed integrations.

## How it works

- The plugin exposes `GET /Driftfin/Config`, which returns the configured
  integrations as JSON to any authenticated Jellyfin user. Driftfin calls this
  on login; a `404` simply means the plugin isn't installed.
- An admin edits the values from **Dashboard → Plugins → Driftfin**
  (or via the admin-only `POST /Driftfin/Config`).
- Any integration that is enabled **and** fully filled in becomes
  *server-managed*: Driftfin uses those values and shows the matching in-app
  fields as read-only ("Managed by server").

> **Security note:** `GET /Driftfin/Config` returns the stored values —
> including API keys — to every logged-in user (this matches how Driftfin
> already lets each user hold these keys client-side). Don't enable it on a
> server where untrusted users shouldn't see your *.arr keys.

Per-user secrets are never centralized: Trakt OAuth tokens and Jellyseerr
session cookies are still established locally on each device.

## Build from source

Requires the .NET 8 SDK.

```bash
dotnet build jellyfin-plugin/Jellyfin.Plugin.Driftfin/Jellyfin.Plugin.Driftfin.csproj -c Release
```

The plugin DLL lands in
`jellyfin-plugin/Jellyfin.Plugin.Driftfin/bin/Release/net8.0/Jellyfin.Plugin.Driftfin.dll`.

### Important: target ABI

`build.yaml` (`targetAbi`) and the `Jellyfin.Controller` package version in the
`.csproj` must match the **Jellyfin server version you run**. The defaults
target Jellyfin **10.10.x / net8.0**. If you run a different version, bump both
before building.

## Package / release

Use [`jprm`](https://github.com/oddstr13/jellyfin-plugin-repository-manager) to
build a release zip and manifest entry:

```bash
pip install jprm
jprm plugin build jellyfin-plugin
```

Or grab the zip produced by the `Plugin (Jellyfin)` GitHub Actions workflow
(`.github/workflows/plugin.yaml`).

## Install into Jellyfin

**Manual:** unzip the build output into a `Driftfin` folder under your Jellyfin
`plugins/` directory and restart the server.

**Via a plugin repository:** publish the zip + manifest produced by `jprm`,
then add the manifest URL in **Dashboard → Plugins → Repositories**, install
"Driftfin", and restart.

Then open **Dashboard → Plugins → Driftfin** and fill in the integrations.
