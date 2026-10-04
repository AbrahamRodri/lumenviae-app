#!/usr/bin/env python3
"""App Store Connect from the command line: see where a release stands,
build and upload it, write its notes, and send it for review.

    Tools/dev asc status            # start here: the app, its versions, builds, groups

Every command that changes anything (App Store Connect, the developer
account's signing, or project.pbxproj) is a DRY RUN unless given
--confirm. A dry run prints exactly what would be done (each request's
method, path and body) and does nothing.

    SUBMITTING FOR REVIEW: a Claude session must ask Abraham in chat, and
    have his yes for that version, before running `submit --confirm`.
    Every time. A yes for one version is not a yes for the next.

Credentials (never in the repository, never printed):
    ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8   the API key
    ~/.appstoreconnect/config.json   {"key_id": "...", "issuer_id": "..."}
or the environment: ASC_KEY_ID, ASC_ISSUER_ID, and optionally ASC_KEY_PATH.
`asc setup` checks them. Tools/AppStore/README.md says how to make the key.

Python 3 standard library and the openssl CLI (for the ES256 signature).
"""
import argparse
import base64
import difflib
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[2]
PBXPROJ = ROOT / "app.xcodeproj" / "project.pbxproj"
BUNDLE_ID = "com.lumenviae.app"
TEAM_ID = "UMW55JA6M2"
API = "https://api.appstoreconnect.apple.com"
CONFIG_DIR = pathlib.Path(os.environ.get("ASC_CONFIG_DIR", pathlib.Path.home() / ".appstoreconnect"))
ARCHIVES = ROOT / ".build" / "archives"
TOKEN_LIFETIME = 19 * 60  # Apple allows at most 20 minutes
DEFAULT_LOCALE = "en-US"


class Fail(Exception):
    """An error the user can act on; printed without a traceback."""


# --- Credentials ---------------------------------------------------------------

def credentials():
    """(key_id, issuer_id, key_path) from the environment or the config file."""
    config = {}
    path = CONFIG_DIR / "config.json"
    if path.exists():
        try:
            config = json.loads(path.read_text())
        except ValueError:
            raise Fail(f"{path} is not valid JSON")
    key_id = os.environ.get("ASC_KEY_ID") or config.get("key_id")
    issuer = os.environ.get("ASC_ISSUER_ID") or config.get("issuer_id")
    if not key_id or not issuer:
        raise Fail("no App Store Connect key configured: set ASC_KEY_ID and ASC_ISSUER_ID, "
                   f"or write {path} (see Tools/AppStore/README.md), then run `asc setup`")
    key_path = pathlib.Path(os.environ.get("ASC_KEY_PATH") or config.get("key_path")
                            or CONFIG_DIR / "private_keys" / f"AuthKey_{key_id}.p8").expanduser()
    if not key_path.exists():
        raise Fail(f"the key file is missing: {key_path}")
    return key_id, issuer, key_path


# --- The token -------------------------------------------------------------------

def b64url(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def der_to_raw(der, size=32):
    try:
        return _der_to_raw(der, size)
    except IndexError:
        raise ValueError("truncated DER signature") from None


def _der_to_raw(der, size=32):
    """An ECDSA signature as openssl writes it (DER: a SEQUENCE of two
    INTEGERs) to the raw r||s that JWS's ES256 wants, each left-padded to
    `size` bytes."""
    def read_length(buf, i):
        first = buf[i]
        if first < 0x80:
            return first, i + 1
        count = first & 0x7F
        if count == 0 or count > 2:
            raise ValueError("unsupported DER length")
        return int.from_bytes(buf[i + 1:i + 1 + count], "big"), i + 1 + count

    if not der or der[0] != 0x30:
        raise ValueError("not a DER SEQUENCE")
    length, i = read_length(der, 1)
    if i + length != len(der):
        raise ValueError("DER SEQUENCE length does not match")
    parts = []
    for _ in range(2):
        if der[i] != 0x02:
            raise ValueError("expected a DER INTEGER")
        n, i = read_length(der, i + 1)
        value = der[i:i + n].lstrip(b"\x00")
        if len(value) > size:
            raise ValueError("INTEGER longer than the curve")
        parts.append(value.rjust(size, b"\x00"))
        i += n
    if i != len(der):
        raise ValueError("trailing bytes after the signature")
    return b"".join(parts)


def raw_to_der(raw):
    """The inverse of der_to_raw, for the tests' verification."""
    def integer(b):
        b = b.lstrip(b"\x00") or b"\x00"
        if b[0] & 0x80:
            b = b"\x00" + b
        return b"\x02" + bytes([len(b)]) + b
    half = len(raw) // 2
    body = integer(raw[:half]) + integer(raw[half:])
    return b"\x30" + bytes([len(body)]) + body


def sign_es256(message, key_path):
    if not shutil.which("openssl"):
        raise Fail("openssl is not on the PATH")
    proc = subprocess.run(["openssl", "dgst", "-sha256", "-sign", str(key_path)],
                          input=message, capture_output=True)
    if proc.returncode != 0:
        # openssl's message names the file at most, never the key's contents
        raise Fail("openssl could not sign with the API key (is it an App Store Connect .p8?)")
    return der_to_raw(proc.stdout)


def make_token(key_id, issuer, key_path, now=None):
    now = int(time.time() if now is None else now)
    header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    claims = {"iss": issuer, "iat": now, "exp": now + TOKEN_LIFETIME, "aud": "appstoreconnect-v1"}
    signing_input = (b64url(json.dumps(header, separators=(",", ":")).encode()) + "." +
                     b64url(json.dumps(claims, separators=(",", ":")).encode()))
    signature = sign_es256(signing_input.encode("ascii"), key_path)
    return signing_input + "." + b64url(signature)


# --- The API ---------------------------------------------------------------------

class Client:
    def __init__(self, dry_run=True):
        self.dry_run = dry_run
        self._token = None
        self._token_made = 0
        self._creds = None

    def token(self):
        if self._token is None or time.time() - self._token_made > TOKEN_LIFETIME - 60:
            self._creds = self._creds or credentials()
            self._token = make_token(*self._creds)
            self._token_made = time.time()
        return self._token

    def request(self, method, path, body=None, params=None):
        url = API + path
        if params:
            url += "?" + urllib.parse.urlencode(params, safe="[],")
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(url, data=data, method=method, headers={
            "Authorization": "Bearer " + self.token(),
            "Content-Type": "application/json",
        })
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                raw = resp.read()
                return json.loads(raw) if raw else {}
        except urllib.error.HTTPError as e:
            raise Fail(f"{method} {path}: HTTP {e.code}: {api_errors(e.read())}") from None
        except urllib.error.URLError as e:
            raise Fail(f"{method} {path}: {e.reason}") from None

    def get(self, path, **params):
        return self.request("GET", path, params=params or None)

    def get_all(self, path, **params):
        """Every page of a list."""
        out = self.get(path, **params)
        data = list(out.get("data", []))
        nxt = out.get("links", {}).get("next")
        while nxt:
            out = self.request("GET", nxt[len(API):])
            data += out.get("data", [])
            nxt = out.get("links", {}).get("next")
        return data

    def write(self, method, path, body=None):
        """A change: printed always, sent only when not a dry run."""
        print(f"  {method} {path}")
        if body is not None:
            print("  " + json.dumps(body, indent=2, ensure_ascii=False).replace("\n", "\n  "))
        if self.dry_run:
            return None
        return self.request(method, path, body)


def api_errors(raw):
    try:
        errors = json.loads(raw).get("errors", [])
        return "; ".join(f"{e.get('title', '')}: {e.get('detail', '')}".strip(": ") for e in errors) or raw[:300]
    except ValueError:
        return raw[:300].decode("utf-8", "replace") if isinstance(raw, bytes) else str(raw)[:300]


# --- Lookups ---------------------------------------------------------------------

def find_app(client):
    apps = client.get("/v1/apps", **{"filter[bundleId]": BUNDLE_ID, "fields[apps]": "name,bundleId,sku"})["data"]
    if not apps:
        raise Fail(f"no app with bundle id {BUNDLE_ID} in this App Store Connect account")
    return apps[0]


def app_versions(client, app_id, limit=10):
    return client.get(f"/v1/apps/{app_id}/appStoreVersions", **{
        "filter[platform]": "IOS", "limit": str(limit),
        "fields[appStoreVersions]": "versionString,appVersionState,appStoreState,releaseType,createdDate,build",
        "include": "build",
    })


def find_version(client, app_id, version_string):
    out = client.get(f"/v1/apps/{app_id}/appStoreVersions", **{
        "filter[platform]": "IOS", "filter[versionString]": version_string, "include": "build"})
    if not out["data"]:
        raise Fail(f"no App Store version {version_string}; create it with `asc create-version {version_string}`")
    return out["data"][0], out.get("included", [])


def find_build(client, app_id, build_number, version_string=None):
    params = {"filter[app]": app_id, "filter[version]": str(build_number), "sort": "-uploadedDate",
              "include": "preReleaseVersion",
              "fields[builds]": "version,processingState,uploadedDate,expired,preReleaseVersion",
              "fields[preReleaseVersions]": "version"}
    if version_string:
        params["filter[preReleaseVersion.version]"] = version_string
    out = client.get("/v1/builds", **params)
    if not out["data"]:
        raise Fail(f"no build {build_number}" + (f" of {version_string}" if version_string else "") +
                   " in App Store Connect (still uploading? `asc builds` lists what has arrived)")
    return out["data"][0]


def state_of(version):
    a = version["attributes"]
    return a.get("appVersionState") or a.get("appStoreState") or "?"


# --- The project's version numbers ---------------------------------------------------

def app_config_blocks(text):
    """(start, end) of every XCBuildConfiguration block of the app target:
    the ones whose bundle id is the app's own, not the tests'."""
    blocks = []
    for m in re.finditer(r"\n\t\t[0-9A-F]{24} /\* \w+ \*/ = \{\n\t\t\tisa = XCBuildConfiguration;.*?\n\t\t\};",
                         text, re.S):
        if re.search(r"PRODUCT_BUNDLE_IDENTIFIER = " + re.escape(BUNDLE_ID) + r";", m.group(0)):
            blocks.append((m.start(), m.end()))
    return blocks


def project_versions(text=None):
    text = PBXPROJ.read_text() if text is None else text
    found = set()
    for start, end in app_config_blocks(text):
        block = text[start:end]
        mv = re.search(r"MARKETING_VERSION = ([^;]+);", block)
        bn = re.search(r"CURRENT_PROJECT_VERSION = ([^;]+);", block)
        found.add((mv.group(1) if mv else None, bn.group(1) if bn else None))
    if len(found) != 1:
        raise Fail(f"the app target's configurations disagree on their version: {sorted(found)}")
    return found.pop()


def bumped(text, version=None, build=None):
    out, last = [], 0
    for start, end in app_config_blocks(text):
        block = text[start:end]
        if version:
            block = re.sub(r"MARKETING_VERSION = [^;]+;", f"MARKETING_VERSION = {version};", block)
        if build:
            block = re.sub(r"CURRENT_PROJECT_VERSION = [^;]+;", f"CURRENT_PROJECT_VERSION = {build};", block)
        out += [text[last:start], block]
        last = end
    out.append(text[last:])
    return "".join(out)


# --- Commands ------------------------------------------------------------------------

def cmd_setup(args):
    print(f"config dir: {CONFIG_DIR}")
    key_id, issuer, key_path = credentials()
    print(f"key id:     {key_id}")
    print(f"issuer id:  {issuer[:8]}…")
    print(f"key file:   {key_path}")
    mode = key_path.stat().st_mode & 0o777
    if mode & 0o077:
        print(f"warning: the key file is readable by others (mode {mode:o}); run: chmod 600 '{key_path}'")
    make_token(key_id, issuer, key_path)
    print("token:      signed (not shown)")
    app = find_app(Client())
    print(f"app:        {app['attributes']['name']} ({BUNDLE_ID}), id {app['id']}")
    print("setup: ok")


def cmd_status(args):
    client = Client()
    version, build = project_versions()
    print(f"project:   {version} ({build})   [app.xcodeproj]")
    app = find_app(client)
    print(f"app:       {app['attributes']['name']} ({BUNDLE_ID}), id {app['id']}")
    out = app_versions(client, app["id"], limit=5)
    builds_by_id = {b["id"]: b for b in out.get("included", []) if b["type"] == "builds"}
    print("versions:")
    for v in out["data"]:
        rel = (v.get("relationships", {}).get("build", {}) or {}).get("data")
        b = builds_by_id.get(rel["id"]) if rel else None
        attached = f"build {b['attributes']['version']}" if b else "no build"
        print(f"  {v['attributes']['versionString']:8} {state_of(v):28} {attached}")
    cmd_builds(argparse.Namespace(limit=5, version=None), client, app)


def cmd_versions(args):
    client = Client()
    app = find_app(client)
    for v in app_versions(client, app["id"], limit=args.limit)["data"]:
        a = v["attributes"]
        print(f"{a['versionString']:8} {state_of(v):28} {a.get('releaseType') or '':10} {a.get('createdDate', '')[:10]}")


def cmd_builds(args, client=None, app=None):
    client = client or Client()
    app = app or find_app(client)
    params = {"filter[app]": app["id"], "sort": "-uploadedDate", "limit": str(args.limit),
              "include": "preReleaseVersion",
              "fields[builds]": "version,processingState,uploadedDate,expired,preReleaseVersion",
              "fields[preReleaseVersions]": "version"}
    if args.version:
        params["filter[preReleaseVersion.version]"] = args.version
    out = client.get("/v1/builds", **params)
    pre = {p["id"]: p["attributes"]["version"] for p in out.get("included", [])}
    print("builds:")
    if not out["data"]:
        print("  (none)")
    for b in out["data"]:
        a = b["attributes"]
        rel = b.get("relationships", {}).get("preReleaseVersion", {}).get("data")
        ver = pre.get(rel["id"], "?") if rel else "?"
        print(f"  {ver:8} ({a['version']:>4})  {a['processingState']:10} uploaded {a.get('uploadedDate', '')[:16]}"
              + ("  EXPIRED" if a.get("expired") else ""))


def cmd_groups(args):
    client = Client()
    app = find_app(client)
    for g in client.get_all(f"/v1/apps/{app['id']}/betaGroups", **{"fields[betaGroups]": "name,isInternalGroup"}):
        kind = "internal" if g["attributes"].get("isInternalGroup") else "external"
        print(f"{g['attributes']['name']:30} {kind:9} id {g['id']}")


def cmd_bump(args):
    text = PBXPROJ.read_text()
    old_version, old_build = project_versions(text)
    build = args.build
    if args.next_build:
        if not old_build or not old_build.isdigit():
            raise Fail(f"CURRENT_PROJECT_VERSION is {old_build!r}; give --build N")
        highest = highest_uploaded_build()
        build = str(max(int(old_build), highest or 0) + 1)
        if highest is not None:
            print(f"highest build in App Store Connect: {highest}; project: {old_build}")
        else:
            print("App Store Connect not reachable or not configured; counting from the project alone")
    if not args.version and not build:
        raise Fail("give --version X.Y, --build N or --next-build")
    if args.version and not re.fullmatch(r"\d+(\.\d+){0,2}", args.version):
        raise Fail(f"{args.version!r} is not a version (X, X.Y or X.Y.Z)")
    new = bumped(text, args.version, build)
    if new == text:
        print("nothing to change")
        return
    diff = difflib.unified_diff(text.splitlines(), new.splitlines(), "a/app.xcodeproj/project.pbxproj",
                                "b/app.xcodeproj/project.pbxproj", lineterm="", n=0)
    print("\n".join(diff))
    print(f"{old_version} ({old_build}) -> {args.version or old_version} ({build or old_build})")
    if args.version and args.version != old_version:
        print("note: the in-app What's New sheet shows notes only for a version WhatsNewRelease.all lists "
              "(app/Views/WhatsNew); the App Store's What's New text is set separately with `asc whats-new`.")
    if not args.confirm:
        print("dry run: add --confirm to write project.pbxproj")
        return
    PBXPROJ.write_text(new)
    print("wrote app.xcodeproj/project.pbxproj")


def highest_uploaded_build():
    """The highest build number App Store Connect holds for the app, or
    None when it cannot be asked. Xcode's own uploads renumber builds, so
    the project's CURRENT_PROJECT_VERSION can trail far behind."""
    try:
        client = Client()
        app = find_app(client)
        out = client.get("/v1/builds", **{"filter[app]": app["id"], "sort": "-uploadedDate", "limit": "50",
                                          "fields[builds]": "version"})
    except Fail:
        return None
    numbers = [int(b["attributes"]["version"]) for b in out["data"] if b["attributes"]["version"].isdigit()]
    return max(numbers) if numbers else None


def auth_flags():
    key_id, issuer, key_path = credentials()
    return ["-allowProvisioningUpdates", "-authenticationKeyPath", str(key_path),
            "-authenticationKeyID", key_id, "-authenticationKeyIssuerID", issuer]


def shown(cmd):
    out, skip = [], False
    for part in cmd:
        if skip:
            out.append("<redacted>")
            skip = False
            continue
        out.append(part)
        skip = part in ("-authenticationKeyIssuerID",)
    return " ".join(out)


def archive_path(version, build):
    return ARCHIVES / f"LumenViae-{version}-{build}.xcarchive"


def cmd_archive(args):
    version, build = project_versions()
    path = archive_path(version, build)
    cmd = ["xcodebuild", "archive", "-project", str(ROOT / "app.xcodeproj"), "-scheme", "app",
           "-configuration", "Release", "-destination", "generic/platform=iOS",
           "-archivePath", str(path)] + auth_flags()
    print(f"archive {version} ({build}) -> {path.relative_to(ROOT)}")
    print("+ " + shown(cmd))
    if not args.confirm:
        print("dry run: add --confirm to archive (it may create signing assets in the developer account)")
        return
    ARCHIVES.mkdir(parents=True, exist_ok=True)
    log = ARCHIVES / f"archive-{version}-{build}.log"
    with open(log, "w") as fh:
        rc = subprocess.run(cmd, stdout=fh, stderr=subprocess.STDOUT).returncode
    if rc != 0:
        tail = log.read_text().splitlines()[-25:]
        raise Fail("archive failed; last lines of " + str(log.relative_to(ROOT)) + ":\n" + "\n".join(tail))
    print(f"archived; log at {log.relative_to(ROOT)}")


def cmd_upload(args):
    version, build = project_versions()
    path = archive_path(version, build)
    if not path.exists() and args.confirm:
        raise Fail(f"no archive at {path.relative_to(ROOT)}; run `asc archive --confirm` first")
    options = {
        "method": "app-store-connect", "destination": "upload", "teamID": TEAM_ID,
        "signingStyle": "automatic", "uploadSymbols": True, "manageAppVersionAndBuildNumber": False,
    }
    with tempfile.TemporaryDirectory(prefix="asc-export-") as tmp:
        plist = pathlib.Path(tmp) / "ExportOptions.plist"
        plist.write_text(to_plist(options))
        cmd = ["xcodebuild", "-exportArchive", "-archivePath", str(path),
               "-exportOptionsPlist", str(plist), "-exportPath", str(pathlib.Path(tmp) / "export")] + auth_flags()
        print(f"upload {version} ({build}) to App Store Connect, export options {json.dumps(options)}")
        print("+ " + shown(cmd))
        if not args.confirm:
            print("dry run: add --confirm to upload")
            return
        log = ARCHIVES / f"upload-{version}-{build}.log"
        with open(log, "w") as fh:
            rc = subprocess.run(cmd, stdout=fh, stderr=subprocess.STDOUT).returncode
    if rc != 0:
        tail = log.read_text().splitlines()[-25:]
        raise Fail("upload failed; last lines of " + str(log.relative_to(ROOT)) + ":\n" + "\n".join(tail))
    print(f"uploaded; App Store Connect takes some minutes to process it (`asc builds`). Log: {log.relative_to(ROOT)}")


def to_plist(d):
    def value(v):
        if isinstance(v, bool):
            return "<true/>" if v else "<false/>"
        return f"<string>{v}</string>"
    body = "".join(f"\t<key>{k}</key>\n\t{value(v)}\n" for k, v in d.items())
    return ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
            f'<plist version="1.0">\n<dict>\n{body}</dict>\n</plist>\n')


def cmd_create_version(args):
    client = Client(dry_run=not args.confirm)
    app = find_app(client)
    print(f"create App Store version {args.version} ({args.release_type}):")
    client.write("POST", "/v1/appStoreVersions", {"data": {
        "type": "appStoreVersions",
        "attributes": {"platform": "IOS", "versionString": args.version, "releaseType": args.release_type},
        "relationships": {"app": {"data": {"type": "apps", "id": app["id"]}}},
    }})
    done(client)


def read_text_arg(args):
    if args.file:
        return pathlib.Path(args.file).read_text(encoding="utf-8").strip()
    if args.text:
        return args.text.strip()
    raise Fail("give --text '...' or --file notes.txt")


def cmd_whats_new(args):
    client = Client(dry_run=not args.confirm)
    text = read_text_arg(args)
    if len(text) > 4000:
        raise Fail(f"What's New is {len(text)} characters; App Store Connect allows 4000")
    app = find_app(client)
    version, _ = find_version(client, app["id"], args.version)
    locs = client.get(f"/v1/appStoreVersions/{version['id']}/appStoreVersionLocalizations")["data"]
    loc = next((l for l in locs if l["attributes"]["locale"] == args.locale), None)
    if not loc:
        raise Fail(f"version {args.version} has no {args.locale} localization (has: "
                   + ", ".join(l["attributes"]["locale"] for l in locs) + ")")
    current = loc["attributes"].get("whatsNew") or ""
    print(f"What's New for {args.version} ({args.locale}), now:\n  " + (current.replace("\n", "\n  ") or "(empty)"))
    print("set to:")
    client.write("PATCH", f"/v1/appStoreVersionLocalizations/{loc['id']}", {"data": {
        "type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": {"whatsNew": text}}})
    done(client)


def cmd_attach_build(args):
    client = Client(dry_run=not args.confirm)
    app = find_app(client)
    version, _ = find_version(client, app["id"], args.version)
    build = find_build(client, app["id"], args.build, args.version)
    state = build["attributes"]["processingState"]
    if state != "VALID":
        raise Fail(f"build {args.build} is {state}, not VALID yet; wait for processing (`asc builds`)")
    print(f"attach build {args.build} to version {args.version}:")
    client.write("PATCH", f"/v1/appStoreVersions/{version['id']}/relationships/build",
                 {"data": {"type": "builds", "id": build["id"]}})
    done(client)


def cmd_testflight(args):
    client = Client(dry_run=not args.confirm)
    app = find_app(client)
    build = find_build(client, app["id"], args.build, args.version)
    groups = client.get_all(f"/v1/apps/{app['id']}/betaGroups", **{"fields[betaGroups]": "name,isInternalGroup"})
    group = next((g for g in groups if g["attributes"]["name"].lower() == args.group.lower()), None)
    if not group:
        raise Fail(f"no TestFlight group {args.group!r}; groups: " + ", ".join(g["attributes"]["name"] for g in groups))
    if args.notes or args.notes_file:
        notes = pathlib.Path(args.notes_file).read_text("utf-8").strip() if args.notes_file else args.notes.strip()
        locs = client.get(f"/v1/builds/{build['id']}/betaBuildLocalizations")["data"]
        loc = next((l for l in locs if l["attributes"]["locale"] == args.locale), None)
        print(f"What to Test ({args.locale}):")
        if loc:
            client.write("PATCH", f"/v1/betaBuildLocalizations/{loc['id']}", {"data": {
                "type": "betaBuildLocalizations", "id": loc["id"], "attributes": {"whatsNew": notes}}})
        else:
            client.write("POST", "/v1/betaBuildLocalizations", {"data": {
                "type": "betaBuildLocalizations", "attributes": {"locale": args.locale, "whatsNew": notes},
                "relationships": {"build": {"data": {"type": "builds", "id": build["id"]}}}}})
    print(f"add build {args.build} to the group {group['attributes']['name']}:")
    client.write("POST", f"/v1/betaGroups/{group['id']}/relationships/builds",
                 {"data": [{"type": "builds", "id": build["id"]}]})
    done(client)


def cmd_submit(args):
    client = Client(dry_run=not args.confirm)
    app = find_app(client)
    version, included = find_version(client, app["id"], args.version)
    rel = (version.get("relationships", {}).get("build", {}) or {}).get("data")
    if not rel:
        raise Fail(f"version {args.version} has no build attached; `asc attach-build {args.version} N` first")
    build = next((b for b in included if b["type"] == "builds" and b["id"] == rel["id"]), None)
    locs = client.get(f"/v1/appStoreVersions/{version['id']}/appStoreVersionLocalizations")["data"]
    missing = [l["attributes"]["locale"] for l in locs if not (l["attributes"].get("whatsNew") or "").strip()]
    if missing and not args.allow_empty_notes:
        raise Fail("What's New is empty for " + ", ".join(missing) +
                   " (`asc whats-new`), or pass --allow-empty-notes for a first release")
    print(f"submit {args.version} (build {build['attributes']['version'] if build else '?'}, "
          f"now {state_of(version)}) for App Review:")
    open_subs = client.get("/v1/reviewSubmissions", **{
        "filter[app]": app["id"], "filter[platform]": "IOS",
        "filter[state]": "READY_FOR_REVIEW"})["data"]
    if open_subs:
        sub_id = open_subs[0]["id"]
        print(f"  (reusing the open review submission {sub_id})")
    else:
        made = client.write("POST", "/v1/reviewSubmissions", {"data": {
            "type": "reviewSubmissions", "attributes": {"platform": "IOS"},
            "relationships": {"app": {"data": {"type": "apps", "id": app["id"]}}}}})
        sub_id = made["data"]["id"] if made else "<new submission>"
    client.write("POST", "/v1/reviewSubmissionItems", {"data": {
        "type": "reviewSubmissionItems",
        "relationships": {
            "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub_id}},
            "appStoreVersion": {"data": {"type": "appStoreVersions", "id": version["id"]}}}}})
    client.write("PATCH", f"/v1/reviewSubmissions/{sub_id}", {"data": {
        "type": "reviewSubmissions", "id": sub_id, "attributes": {"submitted": True}}})
    if client.dry_run:
        print("dry run. A Claude session must ask Abraham in chat, and have his yes for this version, "
              "before running this again with --confirm.")
    else:
        print("submitted for review")


def done(client):
    print("dry run: nothing was sent; add --confirm to send" if client.dry_run else "done")


# --- Entry -----------------------------------------------------------------------------

def main(argv=None):
    parser = argparse.ArgumentParser(prog="asc", description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)

    def command(name, fn, help, writes=False):
        p = sub.add_parser(name, help=help, description=help)
        p.set_defaults(fn=fn)
        if writes:
            p.add_argument("--confirm", action="store_true", help="really do it (default: dry run)")
        return p

    command("setup", cmd_setup, "check the key and config, sign a token, find the app")
    command("status", cmd_status, "the project's version, the App Store versions, the latest builds")
    p = command("versions", cmd_versions, "list App Store versions")
    p.add_argument("--limit", type=int, default=10)
    p = command("builds", cmd_builds, "list uploaded builds and their processing state")
    p.add_argument("--limit", type=int, default=10)
    p.add_argument("--version", help="only builds of this version (e.g. 4.1)")
    command("groups", cmd_groups, "list TestFlight groups")

    p = command("bump", cmd_bump, "set MARKETING_VERSION and/or CURRENT_PROJECT_VERSION for the app target",
                writes=True)
    p.add_argument("--version", help="the marketing version, e.g. 4.1")
    p.add_argument("--build", help="the build number")
    p.add_argument("--next-build", action="store_true",
                   help="one past the highest of the project's build number and App Store Connect's")

    command("archive", cmd_archive, "archive a Release build for the App Store (.build/archives)", writes=True)
    command("upload", cmd_upload, "export the archive and upload it to App Store Connect", writes=True)

    p = command("create-version", cmd_create_version, "create an App Store version", writes=True)
    p.add_argument("version")
    p.add_argument("--release-type", default="AFTER_APPROVAL",
                   choices=["AFTER_APPROVAL", "MANUAL", "SCHEDULED"])

    p = command("whats-new", cmd_whats_new, "set a version's App Store What's New text", writes=True)
    p.add_argument("version")
    p.add_argument("--text")
    p.add_argument("--file")
    p.add_argument("--locale", default=DEFAULT_LOCALE)

    p = command("attach-build", cmd_attach_build, "choose the build a version ships", writes=True)
    p.add_argument("version")
    p.add_argument("build")

    p = command("testflight", cmd_testflight, "add a build to a TestFlight group, with What to Test",
                writes=True)
    p.add_argument("build")
    p.add_argument("--group", required=True)
    p.add_argument("--version", help="the build's marketing version, if build numbers repeat")
    p.add_argument("--notes")
    p.add_argument("--notes-file")
    p.add_argument("--locale", default=DEFAULT_LOCALE)

    p = command("submit", cmd_submit,
                "submit a version for App Review. A Claude session must ask Abraham in chat first, every time.",
                writes=True)
    p.add_argument("version")
    p.add_argument("--allow-empty-notes", action="store_true")

    args = parser.parse_args(argv)
    try:
        args.fn(args)
    except Fail as e:
        print(f"asc: {e}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        return 130
    return 0


if __name__ == "__main__":
    sys.exit(main())
