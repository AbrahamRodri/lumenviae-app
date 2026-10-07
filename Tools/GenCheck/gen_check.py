#!/usr/bin/env python3
"""Checks that every generated file still matches what its generator writes.

Each generator is run in a scratch copy of the files it reads, never in the
repository: the copy keeps the repository's layout, since every generator
finds its inputs from its own location. Its outputs are then compared with
the checked-in ones. The working tree is left byte-identical, and the run
checks this (`git status --porcelain` before and after).

Offline by default. A generator that needs the network, or a cache that is
absent, is reported "skipped" and never fails the run; `--online` lets it
fetch.

Usage:
    python3 Tools/GenCheck/gen_check.py
    python3 Tools/GenCheck/gen_check.py --online
    python3 Tools/GenCheck/gen_check.py --only chants
    python3 Tools/GenCheck/gen_check.py --list

Python 3 standard library only.
"""
import argparse
import filecmp
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]


class Generator:
    def __init__(self, name, inputs, outputs, steps, regenerate,
                 needs_cache=None, offline=True, note=""):
        self.name = name
        self.inputs = inputs          # paths (files or dirs, globs) copied into the scratch tree
        self.outputs = outputs        # paths compared after the run
        self.steps = steps            # commands run inside the scratch tree
        self.regenerate = regenerate  # the command a person runs to fix a stale output
        self.needs_cache = needs_cache
        self.offline = offline
        self.note = note


GENERATORS = [
    Generator(
        "prayer-book",
        inputs=["Tools/PrayerBook", "app/Data/PrayerBook", "app/Data/BilingualConsecrationPrayers.swift",
                "app/Data/RosaryPrayers.swift"],
        outputs=["Tools/PrayerBook/prayer_book.json"],
        steps=[["python3", "Tools/PrayerBook/export.py"]],
        regenerate="python3 Tools/PrayerBook/export.py   (then copy to the server's priv/rosary_audio/)",
    ),
    Generator(
        "chants",
        inputs=["Tools/Chants/generate.py", "Tools/Chants/chants.json", "Tools/ChantLines/*.json",
                "app/Data/ChantCatalogData.swift"],
        outputs=["app/Data/ChantCatalogData.swift"],
        steps=[["python3", "Tools/Chants/generate.py", "--text-only"],
               ["python3", "Tools/Chants/generate.py", "--lines-only"]],
        regenerate="python3 Tools/Chants/generate.py --text-only && python3 Tools/Chants/generate.py --lines-only",
        note="words and timed lines only; recordings and scores need a full (online) run",
    ),
    Generator(
        "true-devotion",
        inputs=["Tools/TrueDevotion/build_book.py", "Tools/TrueDevotion/verify_book.py",
                "Tools/TrueDevotion/chapters", "app/Resources/TrueDevotionBook.json",
                "Tools/TrueDevotion/VERIFICATION.md"],
        outputs=["app/Resources/TrueDevotionBook.json", "Tools/TrueDevotion/VERIFICATION.md"],
        steps=[["python3", "Tools/TrueDevotion/build_book.py"],
               ["python3", "Tools/TrueDevotion/verify_book.py"]],
        regenerate="python3 Tools/TrueDevotion/build_book.py && python3 Tools/TrueDevotion/verify_book.py",
    ),
    Generator(
        "icons",
        inputs=["Tools/IconAudit/draw.py", "app/Assets.xcassets/Icons/lv-*.imageset"],
        outputs=["app/Assets.xcassets/Icons/lv-*.imageset"],
        steps=[["python3", "Tools/IconAudit/draw.py"]],
        regenerate="python3 Tools/IconAudit/draw.py",
        note="the lv-* glyphs (lv-breviary is drawn by hand and left alone)",
    ),
    Generator(
        "scriptural-rosary",
        inputs=["Tools/ScripturalRosary/generate.py", "Tools/ScripturalRosary/cache",
                "Tools/ScripturalRosary/scriptural_rosary.json", "app/Data/ScripturalRosaryData.swift"],
        outputs=["app/Data/ScripturalRosaryData.swift", "Tools/ScripturalRosary/scriptural_rosary.json"],
        steps=[["python3", "Tools/ScripturalRosary/generate.py"]],
        regenerate="python3 Tools/ScripturalRosary/generate.py",
        needs_cache="Tools/ScripturalRosary/cache",
        note="reads the Douay-Rheims from cache/, or the network with --online",
    ),
]


def expand(pattern, base):
    if any(ch in pattern for ch in "*?["):
        return sorted(base.glob(pattern))
    path = base / pattern
    return [path] if path.exists() else []


def copy_in(gen, scratch):
    for pattern in gen.inputs:
        for src in expand(pattern, ROOT):
            dest = scratch / src.relative_to(ROOT)
            dest.parent.mkdir(parents=True, exist_ok=True)
            if src.is_dir():
                shutil.copytree(src, dest, ignore=shutil.ignore_patterns("__pycache__"))
            else:
                shutil.copy2(src, dest)


def differing(gen, scratch):
    """Outputs whose generated copy differs from the repository's."""
    stale = []
    for pattern in gen.outputs:
        real = {p.relative_to(ROOT) for p in expand(pattern, ROOT)}
        made = {p.relative_to(scratch) for p in expand(pattern, scratch)}
        for relpath in sorted(real | made):
            a, b = ROOT / relpath, scratch / relpath
            if not a.exists() or not b.exists():
                stale.append(f"{relpath} ({'missing from the repository' if not a.exists() else 'not generated'})")
            elif a.is_dir():
                cmp = filecmp.dircmp(a, b, ignore=["__pycache__", ".DS_Store"])
                stale += [f"{relpath}/{name}" for name in diff_tree(cmp)]
            elif a.read_bytes() != b.read_bytes():
                stale.append(str(relpath))
    return stale


def diff_tree(cmp, prefix=""):
    out = [prefix + n for n in cmp.diff_files + cmp.left_only + cmp.right_only]
    for name, sub in cmp.subdirs.items():
        out += diff_tree(sub, prefix + name + "/")
    # dircmp's shallow compare trusts size and mtime; check contents
    for name in cmp.same_files:
        if (pathlib.Path(cmp.left) / name).read_bytes() != (pathlib.Path(cmp.right) / name).read_bytes():
            out.append(prefix + name)
    return out


def porcelain():
    return subprocess.run(["git", "status", "--porcelain", "--untracked-files=all"], cwd=ROOT,
                          capture_output=True, text=True, check=True).stdout


def run(gen, online, verbose):
    if not gen.offline and not online:
        return "skipped", "needs the network (run with --online)", []
    if gen.needs_cache and not (ROOT / gen.needs_cache).exists() and not online:
        return "skipped", f"no cache ({gen.needs_cache}); run with --online to fetch", []
    with tempfile.TemporaryDirectory(prefix=f"gencheck-{gen.name}-") as tmp:
        scratch = pathlib.Path(tmp)
        copy_in(gen, scratch)
        env = dict(os.environ, PYTHONDONTWRITEBYTECODE="1")
        for step in gen.steps:
            proc = subprocess.run(step, cwd=scratch, capture_output=True, text=True, env=env)
            if verbose and proc.stdout.strip():
                print("    " + proc.stdout.strip().replace("\n", "\n    "))
            if proc.returncode != 0:
                tail = (proc.stderr or proc.stdout).strip().splitlines()[-3:]
                return "failed", f"`{' '.join(step)}` exited {proc.returncode}: " + " / ".join(tail), []
        stale = differing(gen, scratch)
    return ("stale" if stale else "ok"), "", stale


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--online", action="store_true", help="let generators that need the network fetch")
    parser.add_argument("--only", action="append", help="check only this generator (repeatable)")
    parser.add_argument("--list", action="store_true", help="list the generators and what they write")
    parser.add_argument("-v", "--verbose", action="store_true", help="show each generator's own output")
    args = parser.parse_args()

    if args.list:
        for gen in GENERATORS:
            print(f"{gen.name:18} {', '.join(gen.outputs)}")
            if gen.note:
                print(f"{'':18} {gen.note}")
        return 0

    chosen = [g for g in GENERATORS if not args.only or g.name in args.only]
    unknown = set(args.only or []) - {g.name for g in GENERATORS}
    if unknown:
        sys.exit(f"unknown generator(s): {', '.join(sorted(unknown))}; see --list")

    before = porcelain()
    failures = 0
    counts = {}
    for gen in chosen:
        status, reason, stale = run(gen, args.online, args.verbose)
        counts[status] = counts.get(status, 0) + 1
        print(f"{status:8} {gen.name}" + (f": {reason}" if reason else ""))
        for path in stale:
            print(f"         stale: {path}")
        if stale:
            print(f"         regenerate: {gen.regenerate}")
        if status in ("stale", "failed"):
            failures += 1
    after = porcelain()
    if before != after:
        print("gen-check: the working tree changed during the run; this is a bug in gen-check")
        print(subprocess.run(["git", "diff", "--stat"], cwd=ROOT, capture_output=True, text=True).stdout)
        return 2
    summary = ", ".join(f"{n} {s}" for s, n in sorted(counts.items()))
    print(f"gen-check: {summary}; working tree unchanged")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
