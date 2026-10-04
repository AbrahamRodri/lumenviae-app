#!/usr/bin/env python3
"""Checks the app's Swift sources against the rules CLAUDE.md writes down.

Read-only: it never changes a source file. Each finding is printed as

    path:line: rule-id message

An error fails the run (exit 1) unless the baseline already holds it; a
warning is printed and never fails. The baseline (Tools/Lint/baseline.json)
records the errors that stood when a rule was introduced, keyed by the
rule, the file and a hash of the matched line, so edits elsewhere in a file
never disturb it. Fixing a baselined line simply drops it from the count;
`--update-baseline` rewrites the file to what stands now.

Usage:
    python3 Tools/Lint/lint.py                    # the whole app
    python3 Tools/Lint/lint.py app/Views/Foo.swift  # only these files
    python3 Tools/Lint/lint.py --all              # baselined errors too
    python3 Tools/Lint/lint.py --update-baseline
    python3 Tools/Lint/lint.py --self-test        # each rule against its fixtures
    python3 Tools/Lint/lint.py --list-rules

Python 3 standard library only.
"""
import argparse
import hashlib
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
APP = ROOT / "app"
HERE = pathlib.Path(__file__).resolve().parent
BASELINE = HERE / "baseline.json"
FIXTURES = HERE / "fixtures"

ERROR = "error"
WARNING = "warning"


# --- Source preparation ------------------------------------------------------

def blank_source(text, keep_strings):
    """The text with comments (and, unless kept, string contents) replaced by
    spaces, newlines preserved, so offsets and line numbers still match."""
    out = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if text.startswith("//", i):
            j = text.find("\n", i)
            j = n if j == -1 else j
            out.append(" " * (j - i))
            i = j
        elif text.startswith("/*", i):
            depth, j = 1, i + 2
            while j < n and depth:
                if text.startswith("/*", j):
                    depth, j = depth + 1, j + 2
                elif text.startswith("*/", j):
                    depth, j = depth - 1, j + 2
                else:
                    j += 1
            out.append(re.sub(r"[^\n]", " ", text[i:j]))
            i = j
        elif c == '"':
            # A string literal, plain or multi-line; interpolations are kept
            # as code would be too much for a linter, so they are blanked
            # with the string.
            triple = text.startswith('"""', i)
            delim = '"""' if triple else '"'
            j = i + len(delim)
            while j < n:
                if text[j] == "\\":
                    j += 2
                    continue
                if text.startswith(delim, j):
                    j += len(delim)
                    break
                if not triple and text[j] == "\n":
                    break
                j += 1
            chunk = text[i:j]
            if keep_strings:
                out.append(chunk)
            else:
                body = re.sub(r"[^\n]", " ", chunk[len(delim):len(chunk) - len(delim)])
                out.append(delim + body + delim if chunk.endswith(delim) and len(chunk) >= 2 * len(delim) else re.sub(r"[^\n]", " ", chunk))
            i = j
        else:
            out.append(c)
            i += 1
    return "".join(out)


def blank_previews(text):
    """#Preview blocks are fixtures for Xcode's canvas, never shipped:
    blanked, so a preview's bare .sheet is not taken for the app's."""
    out = text
    for m in re.finditer(r"#Preview\b[^{]*\{", text):
        end = matching_brace(text, m.end() - 1)
        out = out[:m.start()] + re.sub(r"[^\n]", " ", out[m.start():end]) + out[end:]
    return out


class Source:
    def __init__(self, path, text):
        self.path = path
        self.rel = rel(path)
        self.text = text
        self.lines = text.split("\n")
        self.code = blank_previews(blank_source(text, keep_strings=True))   # comments gone
        self.bare = blank_previews(blank_source(text, keep_strings=False))  # strings gone too
        self._starts = [0]
        for line in self.lines:
            self._starts.append(self._starts[-1] + len(line) + 1)

    def line_of(self, offset):
        lo, hi = 0, len(self._starts) - 1
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if self._starts[mid] <= offset:
                lo = mid
            else:
                hi = mid - 1
        return lo + 1


def rel(path):
    try:
        return str(pathlib.Path(path).resolve().relative_to(ROOT))
    except ValueError:
        return str(path)


def matching_brace(text, start):
    """The offset just past the brace that closes the one at `start`."""
    depth = 0
    for j in range(start, len(text)):
        if text[j] == "{":
            depth += 1
        elif text[j] == "}":
            depth -= 1
            if depth == 0:
                return j + 1
    return len(text)


def matching_paren(text, start):
    depth = 0
    for j in range(start, len(text)):
        if text[j] == "(":
            depth += 1
        elif text[j] == ")":
            depth -= 1
            if depth == 0:
                return j + 1
    return len(text)


# --- The index of types and helpers, for the sheet rules --------------------

class Index:
    """What the whole app defines: each type's body, and the helper
    functions whose bodies carry a sheet's background or its type cap."""

    TYPE_DECL = re.compile(r"\b(?:struct|class|enum|extension)\s+([A-Z]\w*)[^{]*\{")
    FUNC_DECL = re.compile(r"\bfunc\s+(\w+)\s*(?:<[^>]*>)?\s*\([^{]*\{")

    def __init__(self, sources):
        self.types = {}
        self.system_views = set()   # UIKit controllers wrapped for SwiftUI
        self.properties = {}        # `var name: some View { … }` bodies
        self.background_helpers = set()
        self.type_cap_helpers = set()
        for src in sources:
            for m in self.TYPE_DECL.finditer(src.bare):
                body = src.bare[m.end() - 1:matching_brace(src.bare, m.end() - 1)]
                self.types.setdefault(m.group(1), []).append(body)
                if "UIViewControllerRepresentable" in m.group(0):
                    self.system_views.add(m.group(1))
            for m in re.finditer(r"\bvar\s+(\w+)\s*:\s*some\s+View\s*\{", src.bare):
                body = src.bare[m.end() - 1:matching_brace(src.bare, m.end() - 1)]
                self.properties.setdefault(m.group(1), []).append(body)
            for m in self.FUNC_DECL.finditer(src.bare):
                body = src.bare[m.end() - 1:matching_brace(src.bare, m.end() - 1)]
                if "presentationBackground" in body:
                    self.background_helpers.add(m.group(1))
                if "DynamicTypeSize.appMaximum" in body:
                    self.type_cap_helpers.add(m.group(1))

    def presents_system_view(self, block):
        """A sheet whose content is a system controller (the mail composer):
        the system draws its own ground and type."""
        first = re.search(r"\b([A-Z]\w*)\s*[({]", block)
        return bool(first) and first.group(1) in self.system_views

    def satisfies(self, block, token, helpers, seen=None, depth=0):
        """Whether `block` carries `token` itself, through a helper, or
        through a type it builds whose own body does."""
        if token in block:
            return True
        if any(re.search(r"\." + re.escape(h) + r"\s*\(", block) for h in helpers):
            return True
        if depth >= 2:
            return False
        seen = seen if seen is not None else set()
        # A sheet built from a view property: `customStartSheet`
        for name in re.findall(r"(?<![.\w])([a-z]\w*)\b(?!\s*[:(])", block):
            if name in seen or name not in self.properties:
                continue
            seen.add(name)
            for body in self.properties[name]:
                if self.satisfies(body, token, helpers, seen, depth + 1):
                    return True
        for name in re.findall(r"\b([A-Z]\w*)\s*[({]", block):
            if name in seen or name not in self.types:
                continue
            seen.add(name)
            for body in self.types[name]:
                if self.satisfies(body, token, helpers, seen, depth + 1):
                    return True
        return False


# --- Rules -------------------------------------------------------------------

RULES = {}


def rule(rule_id, severity, summary):
    def register(fn):
        RULES[rule_id] = (severity, summary, fn)
        return fn
    return register


def exempt(src, *suffixes):
    return any(src.rel.endswith(s) for s in suffixes)


def regex_hits(src, pattern, text=None):
    text = src.code if text is None else text
    for m in re.finditer(pattern, text):
        yield src.line_of(m.start())


@rule("no-hex-color", ERROR,
      "a hex colour belongs to a theme's palette (Theme.swift) or, if it belongs to a thing, FixedColors.swift")
def no_hex_color(src, index):
    if exempt(src, "app/DesignSystem/Theme.swift", "app/DesignSystem/FixedColors.swift"):
        return
    for line in regex_hits(src, r"\b(?:Color|UIColor)\s*\(\s*hex\s*:", src.bare):
        yield line, "Color(hex:) outside Theme.swift / FixedColors.swift; name it there and read it through AppColors"


@rule("hairline-half-point", ERROR,
      "every hairline is AppLine.hairline; 0.5 never sits on a 3x pixel grid")
def hairline_half_point(src, index):
    for line in regex_hits(src, r"\blineWidth\s*:\s*0?\.5(?![0-9])", src.bare):
        yield line, "lineWidth 0.5; use AppLine.hairline"
    for line in regex_hits(src, r"\.frame\s*\([^)]*\b(?:height|width)\s*:\s*0?\.5(?![0-9])", src.bare):
        yield line, "a 0.5pt frame for a rule; use AppLine.hairline"


@rule("icon-through-appicon", ERROR,
      "the ph-/ch-/lv- glyphs are drawn through AppIcon, never Image(\"ph-…\")")
def icon_through_appicon(src, index):
    if exempt(src, "app/DesignSystem/AppIcon.swift"):
        return
    for line in regex_hits(src, r"\b(?:Image|UIImage)\s*\(\s*(?:named\s*:\s*)?\"(?:ph|ch|lv)-", src.code):
        yield line, "an icon asset loaded by name; draw it through AppIcon"


@rule("font-through-appfonts", ERROR,
      "every face goes through AppFonts; never Font.custom at a call site")
def font_through_appfonts(src, index):
    if exempt(src, "app/DesignSystem/Typography.swift"):
        return
    for line in regex_hits(src, r"\bFont\s*\.\s*custom\s*\(|\.font\s*\(\s*\.custom\s*\(", src.bare):
        yield line, "a custom font named at a call site; add a face to AppFonts"
    # UIFont(name:) with a face read from AppFonts is a measurement, and fine;
    # with a face's name written out it is a face AppFonts does not know.
    for line in regex_hits(src, r"\bUIFont\s*\(\s*name\s*:\s*\"", src.code):
        yield line, "a font face named at a call site; read its name from AppFonts"


SHEET_CALL = re.compile(r"\.(sheet|fullScreenCover)\s*\(")


def sheet_contents(src):
    """Each .sheet/.fullScreenCover call: its line, kind and content closure."""
    text = src.bare
    for m in SHEET_CALL.finditer(text):
        args_end = matching_paren(text, m.end() - 1)
        args = text[m.end():args_end - 1]
        content = None
        inner = re.search(r"\bcontent\s*:\s*\{", args)
        if inner:
            start = m.end() + inner.end() - 1
            content = text[start:matching_brace(text, start)]
        else:
            rest = text[args_end:]
            lead = re.match(r"\s*\{", rest)
            if lead:
                start = args_end + lead.end() - 1
                content = text[start:matching_brace(text, start)]
            else:
                ref = re.search(r"\bcontent\s*:\s*(\w+)", args)
                content = ref.group(1) + "(" if ref else ""
        yield src.line_of(m.start()), m.group(1), content


@rule("sheet-background", ERROR,
      "every .sheet carries .presentationBackground(AppColors.background) (or .sheetGround()) on its content")
def sheet_background(src, index):
    for line, kind, content in sheet_contents(src):
        if kind != "sheet" or index.presents_system_view(content):
            continue
        if not index.satisfies(content, "presentationBackground", index.background_helpers):
            yield line, ".sheet content has no presentationBackground; add .sheetGround() or .presentationBackground(AppColors.background)"


@rule("sheet-type-cap", ERROR,
      "every .sheet and .fullScreenCover caps its text at .dynamicTypeSize(...DynamicTypeSize.appMaximum)")
def sheet_type_cap(src, index):
    for line, kind, content in sheet_contents(src):
        if index.presents_system_view(content):
            continue
        if not index.satisfies(content, "DynamicTypeSize.appMaximum", index.type_cap_helpers):
            yield line, f".{kind} content has no .dynamicTypeSize(...DynamicTypeSize.appMaximum)"


# The system's own vocabulary, which CLAUDE.md allows: the ±10s skips,
# warnings, the prayed-day marker and plain arrows/triangles.
SYSTEM_SYMBOLS_ALLOWED = re.compile(
    r"^(gobackward|goforward|exclamationmark|triangle|checkmark|xmark|arrow|chevron|wifi|speaker)")


@rule("system-symbol-glyph", WARNING,
      "SF Symbols only where the system's vocabulary is the point; a door or devotional glyph is ph-/ch-/lv-")
def system_symbol_glyph(src, index):
    for m in re.finditer(r"\bImage\s*\(\s*systemName\s*:\s*(\"([^\"]*)\"|[^)]*)\)", src.code):
        name = m.group(2)
        if name is not None and SYSTEM_SYMBOLS_ALLOWED.match(name):
            continue
        shown = f'"{name}"' if name is not None else "a name chosen at run time"
        yield src.line_of(m.start()), f"Image(systemName:) with {shown}; if it is a door or devotional glyph, use AppIcon"


@rule("nav-bar-hidden", WARNING,
      "a page that hides the system bar must draw its own Back in every branch it can draw")
def nav_bar_hidden(src, index):
    pattern = r"\.navigationBarHidden\s*\(\s*true\s*\)|\.toolbar\s*\(\s*\.hidden\s*,\s*for\s*:\s*\.navigationBar\s*\)"
    for line in regex_hits(src, pattern, src.bare):
        yield line, "hides the system bar; make sure every branch (loading, error) draws a Back"


# --- Running -----------------------------------------------------------------

def load(paths):
    return [Source(p, p.read_text(encoding="utf-8")) for p in paths]


def app_files():
    return sorted(p for p in APP.rglob("*.swift"))


def lint(targets, index, only_rules=None):
    findings = []
    for src in targets:
        for rule_id, (severity, _, fn) in RULES.items():
            if only_rules and rule_id not in only_rules:
                continue
            for line, message in fn(src, index):
                text = src.lines[line - 1] if line - 1 < len(src.lines) else ""
                findings.append({
                    "rule": rule_id, "severity": severity, "path": src.rel,
                    "line": line, "message": message,
                    "hash": line_hash(text),
                })
    findings.sort(key=lambda f: (f["path"], f["line"], f["rule"]))
    return findings


def line_hash(text):
    normal = re.sub(r"\s+", " ", text.strip())
    return hashlib.sha1(normal.encode("utf-8")).hexdigest()[:12]


def baseline_key(f):
    return (f["rule"], f["path"], f["hash"])


def read_baseline():
    if not BASELINE.exists():
        return {}
    data = json.loads(BASELINE.read_text(encoding="utf-8"))
    return {(e["rule"], e["path"], e["hash"]): e.get("count", 1) for e in data.get("entries", [])}


def write_baseline(findings, sources_by_rel):
    counts = {}
    sample = {}
    for f in findings:
        if f["severity"] != ERROR:
            continue
        k = baseline_key(f)
        counts[k] = counts.get(k, 0) + 1
        src = sources_by_rel.get(f["path"])
        sample.setdefault(k, src.lines[f["line"] - 1].strip()[:120] if src else "")
    entries = [
        {"rule": k[0], "path": k[1], "hash": k[2], "count": counts[k], "line": sample[k]}
        for k in sorted(counts)
    ]
    BASELINE.write_text(json.dumps({
        "about": "Errors that stood when the rule came in. Fix one and it drops out; "
                 "regenerate with Tools/dev lint --update-baseline.",
        "entries": entries,
    }, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return len(entries), sum(counts.values())


def partition(findings, baseline):
    """New errors, baselined errors, warnings."""
    budget = dict(baseline)
    new, old, warnings = [], [], []
    for f in findings:
        if f["severity"] == WARNING:
            warnings.append(f)
            continue
        k = baseline_key(f)
        if budget.get(k, 0) > 0:
            budget[k] -= 1
            old.append(f)
        else:
            new.append(f)
    return new, old, warnings


def show(f, tag=""):
    level = "" if f["severity"] == ERROR else "warning: "
    print(f"{f['path']}:{f['line']}: {f['rule']} {level}{f['message']}{tag}")


def self_test():
    """Each rule's fixtures: hit.swift must give at least one finding of the
    rule, clean.swift none. The fixture's own types are indexed with the
    app's, as a real file's would be."""
    failures = 0
    app = load(app_files())
    for rule_id in RULES:
        folder = FIXTURES / rule_id
        hit, clean = folder / "hit.swift", folder / "clean.swift"
        if not hit.exists() or not clean.exists():
            print(f"FAIL {rule_id}: fixtures missing ({rel(folder)}/hit.swift, clean.swift)")
            failures += 1
            continue
        for path, want_hits in ((hit, True), (clean, False)):
            src = load([path])[0]
            index = Index(app + [src])
            found = [f for f in lint([src], index, {rule_id})]
            ok = bool(found) == want_hits
            if not ok:
                failures += 1
                what = "no finding" if want_hits else f"{len(found)} finding(s): " + "; ".join(
                    f"line {f['line']}" for f in found)
                print(f"FAIL {rule_id}: {path.name} gave {what}")
            else:
                print(f"ok   {rule_id}: {path.name} ({len(found)} finding(s))")
    print(f"self-test: {len(RULES)} rules, {failures} failure(s)")
    return 1 if failures else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("files", nargs="*", help="Swift files to check (default: all of app/)")
    parser.add_argument("--all", action="store_true", help="print baselined errors too")
    parser.add_argument("--no-warnings", action="store_true", help="print errors only")
    parser.add_argument("--update-baseline", action="store_true", help="rewrite baseline.json to what stands now")
    parser.add_argument("--self-test", action="store_true", help="run every rule against its fixtures")
    parser.add_argument("--list-rules", action="store_true")
    args = parser.parse_args()

    if args.list_rules:
        for rule_id, (severity, summary, _) in RULES.items():
            print(f"{rule_id:24} {severity:8} {summary}")
        return 0
    if args.self_test:
        return self_test()

    every = load(app_files())
    index = Index(every)
    by_rel = {s.rel: s for s in every}

    if args.update_baseline:
        if args.files:
            sys.exit("--update-baseline always covers the whole app; leave out the file list")
        unique, total = write_baseline(lint(every, index), by_rel)
        print(f"wrote {rel(BASELINE)}: {total} error(s) in {unique} entr{'y' if unique == 1 else 'ies'}")
        return 0

    if args.files:
        wanted = {rel(pathlib.Path(f)) for f in args.files}
        targets = [s for s in every if s.rel in wanted]
        # A Swift file outside app/ (a fixture, a new file elsewhere)
        targets += load([pathlib.Path(f) for f in args.files
                         if f.endswith(".swift") and rel(pathlib.Path(f)) not in by_rel and pathlib.Path(f).exists()])
    else:
        targets = every

    findings = lint(targets, index)
    new, old, warnings = partition(findings, read_baseline())
    for f in new:
        show(f)
    if args.all:
        for f in old:
            show(f, " (baselined)")
    if not args.no_warnings:
        for f in warnings:
            show(f)
    print(f"lint: {len(targets)} file(s), {len(new)} new error(s), "
          f"{len(old)} baselined, {len(warnings)} warning(s)")
    return 1 if new else 0


if __name__ == "__main__":
    sys.exit(main())
