# Super Duper Achievement Icons

A versioned, game-neutral catalog of achievement icons for Super Duper. Add each game under `games/<bundle-id>/<bundle-version>/`; the root `index.json` lists available packs. The first pack covers 92 Game Center achievements in Galaxy on Fire 2 HD 1.1.4.

GitHub Pages serves the [catalog](https://joewebkid.github.io/SuperDuperAchievementIcons/) and direct image URLs. Each game manifest pins bundle ID, version, executable SHA-256, image hashes, byte lengths, and provenance. A matching ID is not proof of an observed unlock.

## Adding another game

Use `games/<bundle-id>/<bundle-version>/manifest.json` and list it in the
root `index.json`. Every icon needs its real Game Center identifier, source,
SHA-256 and byte length. The app can fetch any exact-revision pack named by an
`achievement` patch; no GOF2-specific URL is built into the icon loader.
Do not publish guessed achievements or icons without a known source.

Icon artwork belongs to its respective rights holders. Source images for this first pack were archived from the [GOF2 HD iOS achievements page](https://trophieshunter.com/games/galaxy-on-fire-2-hd-ios). The files are hosted separately from emulator code and original IPA contents.
