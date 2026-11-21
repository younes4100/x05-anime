<div align="center">

<img src="assets/icon/app_icon.png" width="128" alt="X05 ANIME" />

# X05 ANIME

**Track. Discover. Watch. Read.**

A modern, open-source home for anime, movies, series, manga and light novels —
on Android, Android TV, iOS and tvOS.

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%203.0-1677FF?style=for-the-badge)](LICENSE)
![Flutter](https://img.shields.io/badge/Built%20with-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Platforms](https://img.shields.io/badge/Android%20%C2%B7%20TV%20%C2%B7%20iOS%20%C2%B7%20tvOS-0B1226?style=for-the-badge)

</div>

---

## Overview

X05 ANIME keeps your whole media life in one place. Pick a mode — **Streaming**,
**Manga** or **Novel** — and the app adapts its sources, reader and player around
it. Lists, progress and history stay together, whether you are on a phone, a TV
or a tablet.

The interface is built around a deep-navy, electric-blue identity: a sharp
geometric X with a play-button core, designed to stay legible from a 20 px iOS
Settings icon to a 4K tvOS Top Shelf.

> **New — X05 Recap:** a private, offline dashboard for your watch history.
> Episodes, hours, titles, day streak, a six-month activity chart and a
> completion score, all computed on-device. Nothing leaves the device.

> **Website + admin:** the `web/` folder contains the full X05 ANIME site,
> Supabase password-reset/deep-link pages and a Supabase-authenticated admin
> panel. See [`web/DEPLOY.md`](web/DEPLOY.md) for setup.

---

## Features

| | |
|---|---|
| 🎬 **Streaming** | Anime, movies and series with a full-featured player, subtitles, quality selection and resume support. |
| 📚 **Manga & novels** | Dedicated readers, chapter downloads and offline libraries. |
| 📈 **Tracking** | AniList, MAL, Simkl and MangaBaka progress sync. |
| 🔄 **Sync** | Backup, restore and profile-aware data across devices. |
| 📺 **TV-first UI** | A real D-pad interface for Android TV and Apple TV — not a stretched phone layout. |
| ⬇️ **Downloads** | Background video, chapter and subtitle downloads with a public `Download/X05 ANIME` folder. |
| ✨ **X05 Recap** | Watch statistics, streaks and a six-month chart, generated locally. |
| 🎨 **Personal** | Themes, accent colours, fonts, launcher-icon styles and rich Discord presence. |

---

## Platforms

| Platform | Status |
|---|---|
| 🤖 Android | ✅ Supported |
| 📺 Android TV | ✅ Supported |
| 🍎 iPhone / iPad | 🧪 Beta |
| 📺 Apple TV | 🧪 Beta |
| 🪟 Windows | 🚧 In progress |

iOS and tvOS cannot load CloudStream, Aniyomi or Mihon extensions. X05 ANIME's
own JavaScript sources, player, downloads and trackers work normally.

---

## Fork configuration

X05 ANIME is a rebranded fork. A few endpoints still point at upstream
infrastructure because no replacement was supplied. They work, but replace
them before publishing your own build:

| Area | Where | What to change |
|---|---|---|
| Accounts & cloud sync | `Environment.supabaseUrl`, `supabaseAnonKey`, `vpsSyncUrl` | Pass `--dart-define=SUPABASE_URL=...`, `SUPABASE_ANON_KEY=...`, `VPS_SYNC_URL=...` |
| Share / TV-pair web pages | `Environment.siteBaseUrl` | Your domain serving `/open/` and `/pair/` |
| Community links | `kDiscordInviteUrl`, `community_sheet.dart`, `settings_about.dart` | Your own Telegram / Discord invites |
| Log reports & profile avatars | `kLogIntakeUrl` | Your own Cloudflare Worker |
| Discord Rich Presence | `DiscordConfig.applicationId`, `appLogoUrl` | Register a Discord app named X05 and upload its logo |
| In-app updater | `UpdateService._repo` — currently empty, so checks are hidden | Your GitHub `owner/repo` releases |
| Announcements | `kAnnouncementsUrl` — currently empty, so the feed is off | Your own `announcements.json` |

The `x05://` deep-link scheme, Android `applicationId`
(`com.spyou.watch_app`), iOS/tvOS bundle IDs, Hive box names and channel names
are **intentionally unchanged**: existing installs, tracker OAuth redirects and
backups depend on them. They are not presented as branding in the UI. Change
the IDs only if you are publishing a completely fresh listing.

---

## Build from source

Requirements: Flutter (stable channel), Dart, Android SDK; Xcode for iOS/tvOS.

```bash
flutter pub get
flutter run
```

Release builds:

```bash
# Android phones — one APK per ABI
flutter build apk --release --split-per-abi

# Android TV
flutter build apk --release --target-platform android-arm64

# iOS / tvOS
flutter build ios --release
flutter build ipa --release
```

X05 ANIME bundles one ready-to-use provider (`providers/hianime.js`) so a fresh
install can play videos immediately. Additional sources are installed by the
user from the provider hub; extractors stay bundled because they are shared
video-host helpers, not providers.

---

## Brand assets

All launcher, TV, iOS and tvOS artwork is generated from one geometry source:

```bash
node tool/gen_brand_assets.mjs
```

The script uses headless Chrome to rasterise the SVGs, then trims the transparent
in-app lockups with Python + Pillow. Source artwork lives in `assets/brand/`:

| File | Use |
|---|---|
| `x05-icon.svg` | Primary app icon (Signature palette) |
| `x05-icon-ice.svg` | Ice palette |
| `x05-icon-midnight.svg` | Midnight palette |
| `x05-mark.svg` | Transparent X + play mark |
| `x05-wordmark.svg` | X05 ANIME lockup |
| `x05-tv-banner.svg` | Android TV banner |
| `x05-top-shelf*.svg` | tvOS Top Shelf |

The in-app `X05Mark` and `X05Wordmark` widgets in
`lib/core/brand/x05_brand.dart` draw the same geometry natively, so branding
stays crisp without loading a raster.

---

## Disclaimer

> [!IMPORTANT]
> **X05 ANIME is a tracking and management tool only.** It does not host,
> provide, distribute or maintain streaming content or extensions.

- **User responsibility** — You are solely responsible for how you use the app
  and any third-party services or extensions you choose to use, and for
  complying with applicable laws, copyright and intellectual-property rights.
- **No liability** — The developers disclaim liability for misuse, legal issues
  or violations arising from user actions. Concerns about third-party services
  or extensions belong to their creators.
- **Services** — X05 ANIME integrates with official APIs of supported services.
  Third-party extensions remain the responsibility of their creators.

---

## License & attribution

X05 ANIME is licensed under the **GNU GPL-3.0**. See [LICENSE](LICENSE) for the
full terms and [NOTICE.md](NOTICE.md) for upstream attribution.

This project is a rebranded derivative of the open-source **X05** project
by Krishna Vishwakarma (“Spyou”) and its contributors:

- Upstream: <https://github.com/x05-anime/app>
- Original copyright and license notices are preserved.

The X05 ANIME name, logo and visual identity are original to this fork. They do
not imply endorsement by the upstream authors.

<div align="center">

<img src="assets/icon/wordmark.png" width="280" alt="X05 ANIME" />

*Built for people who take their watchlists seriously.*

</div>
