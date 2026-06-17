# Releasing & Homebrew distribution

Releases are built, signed (Developer ID), notarized, and published by
[`.github/workflows/release.yml`](.github/workflows/release.yml) when you push a
version tag. A Homebrew cask in your tap then points at the release asset.

## One-time setup

### 1. GitHub secrets (repo → Settings → Secrets and variables → Actions)

Signing:

| Secret | What it is |
|---|---|
| `BUILD_CERTIFICATE_BASE64` | Your **Developer ID Application** certificate exported as `.p12`, then base64-encoded: `base64 -i cert.p12 \| pbcopy` |
| `P12_PASSWORD` | The password you set when exporting the `.p12` |
| `KEYCHAIN_PASSWORD` | Any random string (used for the throwaway CI keychain) |
| `APPLE_TEAM_ID` | Your 10-character Team ID (Apple Developer → Membership) |

Notarization (App Store Connect API key — Users and Access → Integrations → App Store Connect API → generate a key with **Developer** access):

| Secret | What it is |
|---|---|
| `AC_API_KEY_BASE64` | The downloaded `AuthKey_XXXX.p8`, base64-encoded |
| `AC_API_KEY_ID` | The key ID (e.g. `2X9R4HXF34`) |
| `AC_API_ISSUER_ID` | The issuer UUID shown above the keys list |

Optional (auto-bump the cask on release):

| Secret | What it is |
|---|---|
| `TAP_GITHUB_TOKEN` | A PAT with write access to `thkobierecki/homebrew-tap`. If unset, the workflow skips the tap update and you bump it manually. |

#### Exporting the Developer ID certificate

If you don't have a `.p12` yet: in Xcode → Settings → Accounts → your team →
**Manage Certificates** → **+** → **Developer ID Application**. Then in
**Keychain Access**, find that certificate, right-click → **Export**, choose
`.p12`, and set a password (that's `P12_PASSWORD`).

### 2. Create the Homebrew tap

The tap repo `thkobierecki/homebrew-tap` holds the cask (already created by
setup). Users install with:

```sh
brew install --cask thkobierecki/tap/clipboard-manager
```

## Cutting a release

```sh
# bump MARKETING_VERSION in the Xcode target if you like, then:
git tag v1.0.0
git push origin v1.0.0
```

The workflow builds → signs → notarizes → staples → publishes the release with
`ClipboardManager.zip` attached, and (if `TAP_GITHUB_TOKEN` is set) updates the
cask's `version` + `sha256` automatically.

If you didn't set `TAP_GITHUB_TOKEN`, copy the `sha256` from the workflow's
job summary and update `Casks/clipboard-manager.rb` in the tap repo manually.
