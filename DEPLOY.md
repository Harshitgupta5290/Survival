# Deployment Guide — Survival: Hunter Chronicles

Three deployment targets: **Vercel** (live web), **Google Play** (Android), **Gumroad** (sell the build).

---

## Prerequisites (all targets)

| Tool | Version | Download |
|---|---|---|
| Godot | 4.5 stable | [godotengine.org/download](https://godotengine.org/download) |
| Export Templates | must match Godot version | Editor → Manage Export Templates |

Install export templates inside Godot:  
`Editor → Manage Export Templates → Download` (or install from the `.tpz` file).

---

## Step 1 — Build the Web Export

All three targets start from the same web build.

1. Open Godot → Import `godot_project/project.godot`
2. **Project → Export → Web** (preset is already configured)
3. Click **Export Project**

Output: `build/web/` — contains `index.html`, `.pck`, `.wasm`, `.js`, `.worker.js`

> If the `build/web/` folder doesn't exist yet, Godot creates it automatically.

---

## Target 1 — Vercel (Live Web)

`vercel.json` at the repo root is already configured with:
- `outputDirectory: "build/web"` — Vercel serves from here
- `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` headers — **required** for Godot web exports (they use `SharedArrayBuffer`; without these headers the game silently fails in Chrome/Firefox)
- Immutable cache on `.pck` / `.wasm` / `.js`, no-cache on `index.html`

### Deploy

```bash
# Install Vercel CLI once
npm i -g vercel

# From repo root — first deploy (follow prompts)
vercel

# Subsequent deploys
vercel --prod
```

Or connect the GitHub repo at [vercel.com/new](https://vercel.com/new) — it auto-deploys on every push to `main`.

### Verify it works

Open the deployed URL. The game should start within 2–3 seconds. If you see a blank canvas or console errors about `SharedArrayBuffer`, the COOP/COEP headers are not being applied — check that `vercel.json` is at the repo root and that the `outputDirectory` matches where you exported.

---

## Target 2 — Google Play (Android)

### 2a — Create a release keystore (one-time)

```bash
keytool -genkey -v \
  -keystore godot_project/release.keystore \
  -alias survival \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass YOUR_PASSWORD -keypass YOUR_PASSWORD \
  -dname "CN=YourName, OU=Games, O=YourStudio, L=City, S=State, C=IN"
```

Replace `YOUR_PASSWORD` with a strong password you'll remember.

> **The keystore is gitignored. Keep a backup somewhere safe — losing it means you can never update the app.**

### 2b — Set the keystore password in export_presets.cfg

Open `godot_project/export_presets.cfg` and find the Android preset. Replace both `CHANGE_ME` values:

```ini
keystore/debug_password="YOUR_PASSWORD"
keystore/release_password="YOUR_PASSWORD"
```

Also update `keystore/debug_user` and `keystore/release_user` to `"survival"` (or whatever alias you used).

### 2c — Create launcher icons

The Android preset references these files (create them from any PNG editor):

| File | Size | Purpose |
|---|---|---|
| `assets/img/icons/icon_192.png` | 192×192 | Main launcher icon |
| `assets/img/icons/icon_adaptive_fg.png` | 432×432 | Adaptive icon foreground |
| `assets/img/icons/icon_adaptive_bg.png` | 432×432 | Adaptive icon background (solid color or pattern) |

Google's [icon design guide](https://developer.android.com/distribute/google-play/resources/icon-design-specifications): foreground should be centered in the middle 66%, background should be a solid dark color.

### 2d — Export the AAB

1. In Godot: **Project → Export → Android**
2. Click **Export Project** (not "Export PCK/ZIP")
3. Output: `build/android/survival_hunter_chronicles.aab`

The preset already has:
- `package/unique_name = "com.harshit.survival_hunter_chronicles"`
- `version/code = 2`, `version/name = "1.0.1"`
- `architectures/arm64-v8a = true` (64-bit only — Play Store requirement)
- `permissions/internet = true` (for Firebase leaderboard)
- `screen/immersive_mode = true`, landscape orientation

> Play Store **requires** `.aab`. It will reject a raw `.apk`.

### 2e — Upload to Google Play

1. Go to [play.google.com/console](https://play.google.com/console)
2. Pay the one-time $25 developer fee
3. **Create app** → Android → Free/Paid
4. **Release → Production → Create new release** → upload the `.aab`
5. Fill in the store listing:

**Store listing copy (ready to paste):**

> **Title:** Survival: Hunter Chronicles  
> **Short description:** Fight through enemy hordes in this intense 2D side-scrolling shooter.  
> **Full description:**  
> Blast your way through 7 hand-crafted levels, pick up weapons, and face a brutal 3-phase boss. Unlock the Shotgun and Sniper Rifle as you level up. Features Endless Mode with AI-generated infinite waves, Daily Challenges, achievements, XP progression, and an online leaderboard.  
> Touch controls appear automatically on mobile.  
> **Category:** Action  
> **Content rating:** Teen (Fantasy Violence)

6. Submit for review — typically 1–3 days.

### Version bump checklist (future updates)

Before each release, increment in `export_presets.cfg`:
```ini
version/code=3          # must increase every upload
version/name="1.0.2"    # displayed to users
```

---

## Target 3 — Gumroad

Gumroad sells the web build as a downloadable ZIP (buyers run it locally or host it themselves).

### 3a — Package the build

After exporting (Step 1):

```bash
cd build
zip -r survival_hunter_chronicles_web.zip web/
```

This creates a single ZIP buyers can unzip and open `index.html` in a browser.

> Note: `index.html` must be served from a local server to work — browsers block `file://` for WASM. Include a note in your product description: *"Unzip and open with a local server (VS Code Live Server, or `python -m http.server`)"*  
> — or tell buyers to use the Vercel link instead and sell the Gumroad listing as "pay-what-you-want" with a live link.

### 3b — Optional: also include the source

```bash
# From repo root
zip -r survival_source.zip godot_project/ \
  --exclude "godot_project/.godot/*" \
  --exclude "*.keystore"
```

Selling both the web build and the Godot source project is common — buyers who want to mod or learn from the code pay a higher tier.

### 3c — Create the Gumroad listing

1. Go to [gumroad.com](https://gumroad.com) → New Product → Digital
2. Upload `survival_hunter_chronicles_web.zip` (and optionally the source ZIP)
3. Use this cover image spec: **1280×720px** PNG/JPG
4. Paste the store copy from [Target 2e](#2e--upload-to-google-play) above — same description works for both stores

### PWA note

The web export has PWA enabled (`progressive_web_app/enabled=true`). When deployed to Vercel, visitors can install the game to their home screen/desktop via the browser's "Add to Home Screen" prompt. Mention this in the Gumroad description as a feature.

---

## File reference

| File | Purpose |
|---|---|
| `vercel.json` | Vercel output dir + COOP/COEP headers |
| `godot_project/export_presets.cfg` | Godot export config for Web + Android |
| `godot_project/release.keystore` | Android signing key (**gitignored, don't commit**) |
| `build/web/` | Web export output (gitignored) |
| `build/android/` | Android AAB output (gitignored) |

---

## Troubleshooting

**Vercel: game loads but is black/silent**  
→ Check browser console for `SharedArrayBuffer` errors. Confirm the COOP/COEP headers are present (`curl -I https://your-site.vercel.app | grep -i cross`).

**Android: "App not installed" / signature mismatch**  
→ You have a debug build on the device. Uninstall it first, then install the signed release build.

**Android: Play Store rejects the upload**  
→ Verify the file is `.aab` not `.apk`, and that `version/code` is higher than the last uploaded version.

**Gumroad: buyers can't open the game**  
→ Add a note in the product description that the ZIP must be served from a local HTTP server, not opened directly via `file://`.
