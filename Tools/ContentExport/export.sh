#!/usr/bin/env bash
# Tools/ContentExport/export.sh — writes the Prayer Book's words and the
# chant catalog, as the app compiles them today, in the shape of the
# server's two documents (GET /api/v2/prayer-book, /api/v2/chant-library):
#
#   Tools/ContentExport/out/prayer_book.json    the book's prayers and chapters
#   Tools/ContentExport/out/chant_library.json  the catalog's groups and chants,
#                                               asset urls null (the server's
#                                               upload fills them)
#   Tools/ContentExport/out/chant_assets.json   every recording and score file,
#                                               repo-relative path, bytes, sha256
#
# It runs appTests/ContentExportTests on the tools' simulator with
# CONTENT_EXPORT_WRITE=1: the test encodes the compiled data, writes it,
# and checks it decodes back to exactly what the app compiles. Without the
# variable the same test only checks the files are current.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
TEST_RUNNER_CONTENT_EXPORT_WRITE=1 Tools/dev test -only appTests/ContentExportTests
ls -l Tools/ContentExport/out
