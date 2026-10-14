#!/usr/bin/env python3
"""Tests for asc.py that need no App Store Connect account: the ES256
signature against a key made here, the token's shape, the version bump,
and that a dry run sends nothing.

    python3 Tools/AppStore/test_asc.py
"""
import base64
import io
import json
import os
import pathlib
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from unittest import mock

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import asc  # noqa: E402


def b64url_decode(s):
    return base64.urlsafe_b64decode(s + "=" * (-len(s) % 4))


class TokenTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        d = pathlib.Path(cls.tmp.name)
        cls.key = d / "AuthKey_TEST123456.p8"
        cls.pub = d / "pub.pem"
        # An App Store Connect key is a P-256 key in PKCS#8 PEM
        ec = subprocess.run(["openssl", "ecparam", "-name", "prime256v1", "-genkey", "-noout"],
                            capture_output=True, check=True).stdout
        pkcs8 = subprocess.run(["openssl", "pkcs8", "-topk8", "-nocrypt"], input=ec,
                               capture_output=True, check=True).stdout
        cls.key.write_bytes(pkcs8)
        subprocess.run(["openssl", "ec", "-in", str(cls.key), "-pubout", "-out", str(cls.pub)],
                       capture_output=True, check=True)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def verify(self, message, raw_sig):
        sig = pathlib.Path(self.tmp.name) / "sig.der"
        sig.write_bytes(asc.raw_to_der(raw_sig))
        proc = subprocess.run(["openssl", "dgst", "-sha256", "-verify", str(self.pub), "-signature", str(sig)],
                              input=message, capture_output=True)
        return proc.returncode == 0

    def test_signature_is_raw_64_bytes_and_verifies(self):
        for i in range(25):  # enough runs to meet r or s with a high bit set, or a short one
            message = f"message {i}".encode()
            raw = asc.sign_es256(message, self.key)
            self.assertEqual(len(raw), 64)
            self.assertTrue(self.verify(message, raw), f"run {i}")
            self.assertFalse(self.verify(message + b"!", raw))

    def test_token_shape(self):
        now = 1_800_000_000
        token = asc.make_token("TEST123456", "69a6de70-0000-47e3-e053-5b8c7c11a4d1", self.key, now=now)
        header_b64, claims_b64, sig_b64 = token.split(".")
        header = json.loads(b64url_decode(header_b64))
        claims = json.loads(b64url_decode(claims_b64))
        self.assertEqual(header, {"alg": "ES256", "kid": "TEST123456", "typ": "JWT"})
        self.assertEqual(claims["aud"], "appstoreconnect-v1")
        self.assertEqual(claims["iss"], "69a6de70-0000-47e3-e053-5b8c7c11a4d1")
        self.assertEqual(claims["iat"], now)
        self.assertLessEqual(claims["exp"] - claims["iat"], 20 * 60)
        self.assertGreater(claims["exp"], now)
        self.assertNotIn("=", token)
        self.assertTrue(self.verify(f"{header_b64}.{claims_b64}".encode(), b64url_decode(sig_b64)))


class DerTests(unittest.TestCase):
    def test_padding_and_leading_zero(self):
        r = b"\x00" * 31 + b"\x05"            # a short r
        s = b"\xff" + b"\x11" * 31            # a high bit: DER adds a zero byte
        der = asc.raw_to_der(r + s)
        self.assertEqual(asc.der_to_raw(der), r + s)

    def test_rejects_garbage(self):
        for bad in (b"", b"\x31\x00", b"\x30\x03\x02\x01\x01", b"\x30\x06\x02\x01\x01\x02\x01\x01\x00"):
            with self.assertRaises(ValueError):
                asc.der_to_raw(bad)


PBX = """
\t\tAAAAAAAAAAAAAAAAAAAAAAAA /* Debug */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tCURRENT_PROJECT_VERSION = 5;
\t\t\t\tMARKETING_VERSION = 4.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.lumenviae.app;
\t\t\t};
\t\t\tname = Debug;
\t\t};
\t\tBBBBBBBBBBBBBBBBBBBBBBBB /* Release */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tCURRENT_PROJECT_VERSION = 5;
\t\t\t\tMARKETING_VERSION = 4.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.lumenviae.app;
\t\t\t};
\t\t\tname = Release;
\t\t};
\t\tCCCCCCCCCCCCCCCCCCCCCCCC /* Debug */ = {
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.lumenviae.appTests;
\t\t\t};
\t\t\tname = Debug;
\t\t};
"""


class BumpTests(unittest.TestCase):
    def test_reads_the_app_target(self):
        self.assertEqual(asc.project_versions(PBX), ("4.0", "5"))

    def test_bumps_only_the_app_target(self):
        out = asc.bumped(PBX, "4.1", "6")
        self.assertEqual(asc.project_versions(out), ("4.1", "6"))
        self.assertIn("CURRENT_PROJECT_VERSION = 1;", out)    # the tests' target untouched
        self.assertIn("MARKETING_VERSION = 1.0;", out)
        self.assertEqual(out.count("MARKETING_VERSION = 4.1;"), 2)

    def test_real_project_is_readable(self):
        version, build = asc.project_versions()
        self.assertRegex(version, r"^\d+(\.\d+)*$")
        self.assertRegex(build, r"^\d+$")

    def test_bump_is_a_dry_run_without_confirm(self):
        before = asc.PBXPROJ.read_bytes()
        out = io.StringIO()
        with redirect_stdout(out):
            self.assertEqual(asc.main(["bump", "--version", "99.9", "--build", "999"]), 0)
        self.assertEqual(asc.PBXPROJ.read_bytes(), before)
        self.assertIn("dry run", out.getvalue())
        self.assertIn("MARKETING_VERSION = 99.9;", out.getvalue())


class NextBuildTests(unittest.TestCase):
    def run_bump(self, highest):
        out = io.StringIO()
        with mock.patch.object(asc, "highest_uploaded_build", return_value=highest), redirect_stdout(out):
            asc.main(["bump", "--next-build"])
        return out.getvalue()

    def test_counts_past_app_store_connect(self):
        _, build = asc.project_versions()
        out = self.run_bump(int(build) + 56)
        self.assertIn(f"CURRENT_PROJECT_VERSION = {int(build) + 57};", out)

    def test_counts_from_the_project_offline(self):
        _, build = asc.project_versions()
        out = self.run_bump(None)
        self.assertIn(f"CURRENT_PROJECT_VERSION = {int(build) + 1};", out)


class VersioningTests(unittest.TestCase):
    def test_version_order(self):
        self.assertLess(asc.version_tuple("3"), asc.version_tuple("4.0"))
        self.assertLess(asc.version_tuple("4.0"), asc.version_tuple("4.0.1"))
        self.assertLess(asc.version_tuple("4.9"), asc.version_tuple("4.10"))

    def test_archive_refuses_a_used_build(self):
        _, build = asc.project_versions()
        with mock.patch.object(asc, "highest_uploaded_build", return_value=int(build)):
            with self.assertRaises(asc.Fail):
                asc.require_fresh_build()
        with mock.patch.object(asc, "highest_uploaded_build", return_value=int(build) - 1):
            asc.require_fresh_build()
        with mock.patch.object(asc, "highest_uploaded_build", return_value=None):
            asc.require_fresh_build()   # offline: nothing to compare against


class DryRunTests(unittest.TestCase):
    def test_write_sends_nothing_in_a_dry_run(self):
        client = asc.Client(dry_run=True)
        with mock.patch.object(client, "request") as request, redirect_stdout(io.StringIO()) as out:
            result = client.write("PATCH", "/v1/x/1", {"data": {"attributes": {"whatsNew": "Hi"}}})
        request.assert_not_called()
        self.assertIsNone(result)
        self.assertIn("PATCH /v1/x/1", out.getvalue())
        self.assertIn('"whatsNew": "Hi"', out.getvalue())

    def test_shown_command_redacts_the_issuer(self):
        line = asc.shown(["xcodebuild", "-authenticationKeyID", "ABC", "-authenticationKeyIssuerID", "secret-issuer"])
        self.assertNotIn("secret-issuer", line)
        self.assertIn("<redacted>", line)

    def test_missing_credentials_is_a_plain_error(self):
        with tempfile.TemporaryDirectory() as d, mock.patch.object(asc, "CONFIG_DIR", pathlib.Path(d)), \
                mock.patch.dict(os.environ, {}, clear=False):
            for k in ("ASC_KEY_ID", "ASC_ISSUER_ID", "ASC_KEY_PATH"):
                os.environ.pop(k, None)
            with self.assertRaises(asc.Fail):
                asc.credentials()


def png(path, width, height, alpha=False):
    """A PNG header good enough for png_info (the pixels are never read)."""
    color_type = 6 if alpha else 2
    ihdr = width.to_bytes(4, "big") + height.to_bytes(4, "big") + bytes([8, color_type, 0, 0, 0])
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + (13).to_bytes(4, "big") + b"IHDR" + ihdr + b"\x00" * 4 + b"rest")


class FakeASC:
    """App Store Connect for one app, one version and one localization,
    answering the requests the listing commands make and recording every
    write."""

    def __init__(self, state="PREPARE_FOR_SUBMISSION", old_shots=("old-1.png", "old-2.png"), sets=True,
                 description="Old.", deliveries=None):
        self.state = state
        self.description = description
        self.old_shots = list(old_shots)
        self.has_set = sets
        self.writes = []
        self.deliveries = deliveries or {}
        self.made = 0
        self.in_set = len(self.old_shots)

    def request(self, method, path, body=None, params=None):
        path = path.split("?")[0]
        if method != "GET":
            self.writes.append((method, path, body))
        if method == "GET" and path == "/v1/apps":
            return {"data": [{"id": "APP", "attributes": {"name": "Lumen Viae"}}]}
        if method == "GET" and path == "/v1/apps/APP/appStoreVersions":
            return {"data": [{"id": "VER", "attributes": {"versionString": "4.0", "appVersionState": self.state}}]}
        if method == "GET" and path == "/v1/appStoreVersions/VER/appStoreVersionLocalizations":
            return {"data": [{"id": "LOC", "attributes": {
                "locale": "en-US", "description": self.description, "keywords": "rosary",
                "promotionalText": None}}]}
        if method == "GET" and path == "/v1/appStoreVersionLocalizations/LOC/appScreenshotSets":
            sets = [{"id": "SET", "attributes": {"screenshotDisplayType": "APP_IPHONE_67"}}] if self.has_set else []
            return {"data": sets}
        if method == "GET" and path == "/v1/appScreenshotSets/SET/appScreenshots":
            return {"data": [{"id": f"OLD{i}", "attributes": {"fileName": n}} for i, n in enumerate(self.old_shots)]}
        if method == "POST" and path == "/v1/appScreenshotSets":
            self.has_set = True
            return {"data": {"id": "SET"}}
        if method == "POST" and path == "/v1/appScreenshots":
            if self.in_set >= 10:  # Apple's limit per set
                raise asc.Fail("POST /v1/appScreenshots: HTTP 409: the set already holds 10 screenshots")
            self.in_set += 1
            self.made += 1
            size = body["data"]["attributes"]["fileSize"]
            return {"data": {"id": f"NEW{self.made}", "attributes": {"uploadOperations": [
                {"method": "PUT", "url": f"https://upload.example/{self.made}", "offset": 0, "length": size,
                 "requestHeaders": [{"name": "Content-Type", "value": "image/png"}]}]}}}
        if method == "GET" and path.startswith("/v1/appScreenshots/"):
            sid = path.rsplit("/", 1)[1]
            states = self.deliveries.get(sid, ["COMPLETE"])
            state = states.pop(0) if len(states) > 1 else states[0]
            return {"data": {"id": sid, "attributes": {"fileName": sid, "assetDeliveryState": {"state": state}}}}
        if method == "GET" and path == "/v1/reviewSubmissions":
            return {"data": [{"id": "SUB-OTHER", "attributes": {"state": "WAITING_FOR_REVIEW"}},
                             {"id": "SUB", "attributes": {"state": "WAITING_FOR_REVIEW"}}]}
        if method == "GET" and path == "/v1/reviewSubmissions/SUB/items":
            return {"data": [{"relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": "VER"}}}}]}
        if method == "GET" and path == "/v1/reviewSubmissions/SUB-OTHER/items":
            return {"data": [{"relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": "X"}}}}]}
        if method == "DELETE" and path.startswith("/v1/appScreenshots/"):
            self.in_set -= 1
            return {}
        if method == "PATCH":
            return {}
        raise AssertionError(f"unexpected {method} {path}")


class ListingTests(unittest.TestCase):
    def run_asc(self, fake, argv, puts=None):
        out = io.StringIO()
        with mock.patch.object(asc.Client, "request", lambda self, *a, **k: fake.request(*a, **k)), \
                mock.patch.object(asc, "put_parts", lambda path, ops: (puts if puts is not None else []).append(
                    (pathlib.Path(path).name, ops))), \
                mock.patch.object(asc.time, "sleep", lambda s: None), redirect_stdout(out):
            code = asc.main(argv)
        return code, out.getvalue()

    def shots_dir(self, names=("02.png", "01.png", "03.png"), size=(1320, 2868), alpha=False):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        d = pathlib.Path(tmp.name)
        for n in names:
            png(d / n, *size, alpha=alpha)
        (d / "notes.txt").write_text("not a screenshot")
        return d

    def test_listing_reads_and_writes_nothing(self):
        fake = FakeASC()
        code, out = self.run_asc(fake, ["listing", "4.0"])
        self.assertEqual(code, 0)
        self.assertEqual(fake.writes, [])
        self.assertIn("description (4/4000)", out)
        self.assertIn("APP_IPHONE_67: 2", out)

    def test_set_listing_is_a_dry_run_without_confirm(self):
        fake = FakeASC()
        code, out = self.run_asc(fake, ["set-listing", "4.0", "--description", "New.", "--promo-text", "Hi"])
        self.assertEqual(code, 0)
        self.assertEqual(fake.writes, [])
        self.assertIn('"description": "New."', out)
        self.assertIn('"promotionalText": "Hi"', out)
        self.assertNotIn('"keywords"', out)
        self.assertIn("dry run", out)

    def test_set_listing_sends_only_what_changed(self):
        fake = FakeASC()
        self.run_asc(fake, ["set-listing", "4.0", "--description", "Old.", "--keywords", "rosary,chant", "--confirm"])
        self.assertEqual(len(fake.writes), 1)
        method, path, body = fake.writes[0]
        self.assertEqual((method, path), ("PATCH", "/v1/appStoreVersionLocalizations/LOC"))
        self.assertEqual(body["data"]["attributes"], {"keywords": "rosary,chant"})

    def test_listing_limits(self):
        with self.assertRaises(asc.Fail):
            asc.check_listing_text(description="x" * 4001)
        with self.assertRaises(asc.Fail):
            asc.check_listing_text(keywords="x" * 101)
        with self.assertRaises(asc.Fail):
            asc.check_listing_text(keywords="rosary, chant")
        with self.assertRaises(asc.Fail):
            asc.check_listing_text(promo="x" * 171)
        asc.check_listing_text("x" * 4000, "x" * 100, "x" * 170)

    def test_set_listing_warns_when_the_version_is_in_review(self):
        fake = FakeASC(state="WAITING_FOR_REVIEW")
        _, out = self.run_asc(fake, ["set-listing", "4.0", "--description", "New."])
        self.assertIn("cancel-review", out)

    def test_screenshot_files_order_and_checks(self):
        d = self.shots_dir()
        self.assertEqual([f.name for f in asc.screenshot_files(d, "APP_IPHONE_67")], ["01.png", "02.png", "03.png"])
        with self.assertRaises(asc.Fail):
            asc.screenshot_files(self.shots_dir(size=(1179, 2556)), "APP_IPHONE_67")
        with self.assertRaises(asc.Fail):
            asc.screenshot_files(self.shots_dir(alpha=True), "APP_IPHONE_67")
        with self.assertRaises(asc.Fail):
            asc.screenshot_files(self.shots_dir(names=[f"{i:02}.png" for i in range(11)]), "APP_IPHONE_67")

    def test_screenshots_dry_run_sends_nothing(self):
        fake, puts = FakeASC(), []
        code, out = self.run_asc(fake, ["screenshots", "4.0", "--dir", str(self.shots_dir())], puts)
        self.assertEqual(code, 0)
        self.assertEqual(fake.writes, [])
        self.assertEqual(puts, [])
        self.assertIn("DELETE /v1/appScreenshots/OLD0", out)
        self.assertIn("dry run", out)

    def test_screenshots_upload_then_delete_the_old_then_order(self):
        fake, puts = FakeASC(deliveries={"NEW2": ["UPLOAD_COMPLETE", "COMPLETE"]}), []
        d = self.shots_dir()
        code, _ = self.run_asc(fake, ["screenshots", "4.0", "--dir", str(d), "--confirm"], puts)
        self.assertEqual(code, 0)
        self.assertEqual([p[0] for p in puts], ["01.png", "02.png", "03.png"])
        writes = [(m, p) for m, p, _ in fake.writes]
        reserves = [b["data"]["attributes"]["fileName"] for m, p, b in fake.writes if p == "/v1/appScreenshots"]
        self.assertEqual(reserves, ["01.png", "02.png", "03.png"])
        commit = next(b for m, p, b in fake.writes if (m, p) == ("PATCH", "/v1/appScreenshots/NEW1"))
        self.assertEqual(commit["data"]["attributes"],
                         {"uploaded": True, "sourceFileChecksum": asc.md5_of(d / "01.png")})
        first_delete = writes.index(("DELETE", "/v1/appScreenshots/OLD0"))
        last_commit = writes.index(("PATCH", "/v1/appScreenshots/NEW3"))
        self.assertGreater(first_delete, last_commit)
        method, path, body = fake.writes[-1]
        self.assertEqual(path, "/v1/appScreenshotSets/SET/relationships/appScreenshots")
        self.assertEqual([x["id"] for x in body["data"]], ["NEW1", "NEW2", "NEW3"])

    def test_screenshots_keep_the_old_set_when_one_fails(self):
        fake = FakeASC(deliveries={"NEW2": ["FAILED"]})
        code, _ = self.run_asc(fake, ["screenshots", "4.0", "--dir", str(self.shots_dir()), "--confirm"])
        self.assertEqual(code, 1)
        deleted = [p for m, p, _ in fake.writes if m == "DELETE"]
        self.assertEqual(deleted, [f"/v1/appScreenshots/NEW{i}" for i in (1, 2, 3)])   # the new, not the old
        self.assertEqual(fake.in_set, 2)

    def test_screenshots_delete_the_old_first_when_a_set_would_overflow(self):
        fake = FakeASC(old_shots=[f"old-{i}.png" for i in range(5)])
        d = self.shots_dir(names=[f"{i:02}.png" for i in range(1, 9)])
        code, out = self.run_asc(fake, ["screenshots", "4.0", "--dir", str(d), "--confirm"])
        self.assertEqual(code, 0, out)
        writes = [(m, p) for m, p, _ in fake.writes]
        last_old_delete = writes.index(("DELETE", "/v1/appScreenshots/OLD4"))
        first_reserve = writes.index(("POST", "/v1/appScreenshots"))
        self.assertLess(last_old_delete, first_reserve)
        self.assertEqual(fake.in_set, 8)
        self.assertEqual([x["id"] for x in fake.writes[-1][2]["data"]], [f"NEW{i}" for i in range(1, 9)])

    def test_screenshots_make_the_set_when_there_is_none(self):
        fake = FakeASC(sets=False, old_shots=())
        self.run_asc(fake, ["screenshots", "4.0", "--dir", str(self.shots_dir()), "--confirm"])
        self.assertEqual(fake.writes[0][1], "/v1/appScreenshotSets")
        self.assertEqual(fake.writes[0][2]["data"]["attributes"]["screenshotDisplayType"], "APP_IPHONE_67")

    def test_cancel_review_finds_the_versions_submission(self):
        fake = FakeASC(state="WAITING_FOR_REVIEW")
        code, out = self.run_asc(fake, ["cancel-review", "4.0"])
        self.assertEqual(code, 0)
        self.assertEqual(fake.writes, [])
        self.assertIn("PATCH /v1/reviewSubmissions/SUB\n", out)
        self.run_asc(fake, ["cancel-review", "4.0", "--confirm"])
        self.assertEqual(fake.writes, [("PATCH", "/v1/reviewSubmissions/SUB", {"data": {
            "type": "reviewSubmissions", "id": "SUB", "attributes": {"canceled": True}}})])


if __name__ == "__main__":
    unittest.main(verbosity=2)
