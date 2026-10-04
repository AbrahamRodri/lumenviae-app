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


if __name__ == "__main__":
    unittest.main(verbosity=2)
