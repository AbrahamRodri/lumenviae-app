# App Store Connect

`Tools/AppStore/asc.py` (or `Tools/dev asc …`) releases the app from the
command line. It shows where a release stands, bumps the version, archives
and uploads the build, writes the App Store's What's New, sends builds to
TestFlight and submits a version for review.

```bash
Tools/dev asc status       # start here
Tools/dev asc --help       # every command
```

## Rules

- **Every command that changes something is a dry run unless given
  `--confirm`.** This covers App Store Connect, the developer account's
  signing and `project.pbxproj`. A dry run prints exactly what it would do
  (each request's method, path and body, or the xcodebuild command) and
  does nothing. Read-only commands (`setup`, `status`, `versions`,
  `builds`, `groups`) take no flag.
- **Submitting for review: a Claude session must ask Abraham in chat, and
  have his yes for that version, before it runs `submit --confirm`. It
  must ask every time.** A yes for one version is not a yes for the next.
  The dry run (`submit 4.1` without `--confirm`) is always fine. It shows
  what would be sent, and should be pasted into the question.
- The API key never enters the repository, a log or a terminal. The tool
  reads the key file, signs short-lived tokens (19 minutes; Apple allows
  20) and never prints the key or a token.

## One-time setup (Abraham)

1. In App Store Connect, go to **Users and Access → Integrations → App
   Store Connect API → Team Keys**. Generate a key with the **App
   Manager** role. **Admin** is needed only if Xcode must create a
   distribution certificate for cloud signing on the first archive. Note
   the **Key ID** and the **Issuer ID** shown above the list.
2. Download the key (`AuthKey_<KEYID>.p8`; Apple allows one download) and
   put it where Apple's tools look:

   ```bash
   mkdir -p ~/.appstoreconnect/private_keys
   mv ~/Downloads/AuthKey_*.p8 ~/.appstoreconnect/private_keys/
   chmod 600 ~/.appstoreconnect/private_keys/AuthKey_*.p8
   ```

3. Write `~/.appstoreconnect/config.json` (outside the repo):

   ```json
   { "key_id": "ABC123DEFG", "issuer_id": "69a6de70-xxxx-xxxx-xxxx-xxxxxxxxxxxx" }
   ```

   The environment can be used instead: `ASC_KEY_ID`, `ASC_ISSUER_ID`, and
   optionally `ASC_KEY_PATH`.
4. Check it: `Tools/dev asc setup`, then `Tools/dev asc status`.

The repository's `.gitignore` refuses `*.p8` as a guard. The key still
belongs in `~/.appstoreconnect`, never in the repository.

## Keeping the version current

`Tools/dev asc versioning` (read-only; `asc status` ends with the same
summary) compares the project with App Store Connect and the repository.
It reports:

- whether `MARKETING_VERSION` is past the version live on the store
- whether App Store Connect has that version yet
- whether `CURRENT_PROJECT_VERSION` is past the highest build uploaded
- whether CHANGELOG.md has a `## <version>` section
- whether the in-app `WhatsNewRelease` has notes for it

It ends by listing anything to do before the next upload. `--strict` makes
that list exit 1. `archive` and `upload` refuse a build number App Store
Connect already has, instead of letting Apple reject it after the upload.

**Claude sessions keep this current.** At the start of any release work,
or whenever a session changes what the next version will hold, it runs
`asc versioning` and applies what it lists. A build behind App Store
Connect is fixed with `bump --next-build --confirm`. A version already
live gets `bump --version X.Y --confirm` after asking Abraham which number
the next version should carry. A missing CHANGELOG section gets one. The
session then commits the bump with the change it belongs to.

## A release, step by step

```bash
# 0. Where things stand, and what to fix first
Tools/dev asc versioning

# 1. The version and build number (app target only; shows the diff)
Tools/dev asc bump --version 4.1 --build 1            # dry run
Tools/dev asc bump --version 4.1 --build 1 --confirm
# ...commit the bump with the release's other changes

# 2. Archive and upload (Release, generic iOS device, automatic signing)
Tools/dev asc archive --confirm      # .build/archives/LumenViae-4.1-1.xcarchive
Tools/dev asc upload --confirm       # Apple processes it for some minutes
Tools/dev asc builds                 # wait for VALID

# 3. TestFlight, if wanted
Tools/dev asc groups
Tools/dev asc testflight 1 --version 4.1 --group "Friends" --notes "Try the new Chant Library." --confirm

# 4. The App Store version and its notes
Tools/dev asc create-version 4.1 --confirm
Tools/dev asc whats-new 4.1 --file notes.txt --confirm
Tools/dev asc attach-build 4.1 1 --confirm

# 5. Review: dry run, show Abraham, and only on his yes:
Tools/dev asc submit 4.1
Tools/dev asc submit 4.1 --confirm
```

`bump --next-build` takes one past the higher of the project's build
number and the highest build App Store Connect holds. Xcode's own uploads
renumber builds, so the project's number can trail far behind: the project
said 5 while App Store Connect held 61. A new upload of the same version
needs a new build number.

## Two different What's New

- **The App Store's What's New** is the text on the App Store page,
  set with `asc whats-new`. It lives in App Store Connect.
- **The app's own What's New sheet** (`app/Views/WhatsNew/`, described in
  CLAUDE.md under "What's New and the first-use tour") is shown inside the
  app after an update. It appears only for a version that
  `WhatsNewRelease.all` lists, matching `MARKETING_VERSION` exactly. Add a
  `WhatsNewRelease` in the app's code for a version that should show one.
  `asc bump` reminds you when the version changes.

The two may say similar things, but they are written and shipped
separately.

## What it uses

- Apple's App Store Connect API (`/v1/apps`, `appStoreVersions`,
  `appStoreVersionLocalizations`, `builds`, `betaGroups`,
  `betaBuildLocalizations`, `reviewSubmissions`, `reviewSubmissionItems`).
- `xcodebuild archive` and `xcodebuild -exportArchive` with an
  `app-store-connect` / `upload` export. Both are authenticated with the
  API key (`-authenticationKeyPath/ID/IssuerID`, `-allowProvisioningUpdates`),
  so no Apple ID password is involved. The archive and upload logs are kept
  in `.build/archives/`.
- `openssl` for the ES256 signature (its DER output is converted to the
  raw r||s that JWS needs). Otherwise only the Python standard library.
- Export compliance: the target already sets
  `ITSAppUsesNonExemptEncryption = NO`, so builds need no compliance answer.

## Tests

```bash
python3 Tools/AppStore/test_asc.py
```

The tests sign with a P-256 key made in a temporary directory and check
each signature with openssl, along with the token's header and claims
(`aud` appstoreconnect-v1, a lifetime of at most 20 minutes). They also
check the bump (the app target only, a dry run unless confirmed) and that
a dry run sends nothing. They do not reach App Store Connect. The first
real call is `asc setup` with Abraham's key.
