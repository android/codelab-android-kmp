#!/usr/bin/env python3
"""
xcframework-analyzer: Analyze KMP/Kotlin Native XCFramework structure and symbols.

Usage:
    # Single XCFramework
    python3 xcframework-analyzer.py <path/to/Something.xcframework> [options]

    # Project mode (multiple XCFrameworks)
    python3 xcframework-analyzer.py --project <dir-containing-xcframeworks> [options]
    python3 xcframework-analyzer.py --project-config <project.json> [options]

Options:
    --symbols               Show full symbol list per slice
    --filter <pattern>      Filter symbols by regex (e.g. "kotlinx", "runtime")
    --json                  Output as JSON
    --headers               Show ObjC header summary
    --compare <path>        Compare two XCFrameworks (or two projects)
    --project <dir>         Analyze all .xcframework under a directory
    --project-config <f>    Load project config from JSON file
    --save-project <f>      Save discovered project config to JSON

Project config format (project.json):
    {
      "name": "MySDK",
      "frameworks": [
        { "path": "/path/to/Foundation.xcframework", "role": "foundation" },
        { "path": "/path/to/Business.xcframework",   "role": "business" }
      ]
    }
"""

import os
import sys
import subprocess
import plistlib
import json
import argparse
import re
from pathlib import Path
from collections import defaultdict
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple, Set


# ─── Symbol categories for KMP/Kotlin Native ──────────────────────────────────

CATEGORIES = {
    "kotlin_runtime":  re.compile(
        r'('
        # Kotlin-prefixed C symbols (already demangled or plain)
        r'_konan_|_Kotlin_ObjCExport_referer|kotlin\.konan\.|KonanAllocator'
        r'|kotlin_native_runtime|_Kotlin_mm_|konan_objc_|_kotlin_objc'
        r'|Kotlin_launchers|konanTerminate|RuntimeCheck|FreezeHook'
        r'|InitializationManager|MemoryState|GarbageCollect'
        # C++ mangled: kotlin:: namespace → _ZN6kotlin
        r'|_ZN6kotlin|__ZN6kotlin'
        # C++ mangled: konan:: namespace → _ZN5konan
        r'|_ZN5konan|__ZN5konan'
        # Known runtime C++ mangled patterns (anonymous namespace runtime funcs)
        # __ZN12_GLOBAL__N_1 = anonymous namespace
        r'|_ZN12_GLOBAL__N_1|__ZN12_GLOBAL__N_1'
        # ObjC export runtime bridges
        r'|_Kotlin_ObjCExport|Kotlin_ObjCExport'
        r'|blockToKotlinImp|SwiftObject_toKotlinImp|SwiftObject_release'
        r'|boxedBooleanToKotlinImp|convertKotlinObjectToRetained'
        r'|getOrCreateClass|getOrCreateTypeInfo|setAssociatedTypeInfo'
        r'|incorrectNumberFactory|incorrectNumberInitialization'
        r'|ReportBacktraceToIosCrashLog|printlnMessage'
        r')'
    ),
    "kotlin_stdlib":   re.compile(r'(kfun:kotlin\.|ktypew:kotlin\.|kclass:kotlin\.|_kotlin_stdlib|kfun:#main|kfun:kotlin#)'),
    "kotlinx":         re.compile(r'(kfun:kotlinx\.|ktypew:kotlinx\.|kclass:kotlinx\.|kifacetable:kotlinx\.|kintf:kotlinx\.)'),
    "objc_export":     re.compile(r'(_OBJC_CLASS_\$_|_OBJC_METACLASS_\$_|_OBJC_IVAR_\$_)'),
    "kotlin_user_api": re.compile(r'(kfun:|ktypew:|kclass:)'),
    "cinterop":        re.compile(r'(cinterop_|_knbridge|_kn_objc_|interop_)'),
    "swift":           re.compile(r'^_\$s'),
    "cpp_rtti":        re.compile(r'^(__ZTI|__ZTS|__ZTV)'),
    "cpp_symbols":     re.compile(r'^__Z'),
}

CATEGORY_LABELS = {
    "kotlin_runtime":  "Kotlin/Native Runtime",
    "kotlin_stdlib":   "Kotlin Stdlib",
    "kotlinx":         "kotlinx libraries",
    "objc_export":     "ObjC Export (class/metaclass)",
    "kotlin_user_api": "Kotlin User API (kfun/kclass)",
    "cinterop":        "cinterop bridges",
    "swift":           "Swift symbols",
    "cpp_rtti":        "C++ RTTI",
    "cpp_symbols":     "C++ symbols",
    "other":           "Other",
}

ALL_CATEGORIES = list(CATEGORIES.keys()) + ["other"]


# ─── Data classes ─────────────────────────────────────────────────────────────

@dataclass
class Symbol:
    address: str
    sym_type: str
    name: str
    category: str = field(init=False)
    is_defined: bool = field(init=False)

    def __post_init__(self):
        self.is_defined = self.sym_type.upper() != 'U'
        self.category = self._classify()

    def _classify(self) -> str:
        for cat, pattern in CATEGORIES.items():
            if pattern.search(self.name):
                return cat
        return "other"


@dataclass
class SliceInfo:
    identifier: str
    library_path: str
    archs: List[str]
    symbols: List[Symbol] = field(default_factory=list)
    linked_libs: List[str] = field(default_factory=list)
    linked_frameworks: List[str] = field(default_factory=list)
    binary_size: int = 0
    section_sizes: Dict[str, int] = field(default_factory=dict)


@dataclass
class FrameworkEntry:
    path: str
    role: Optional[str] = None  # e.g. "foundation", "business", or None


# ─── Core analyzer ────────────────────────────────────────────────────────────

class XCFrameworkAnalyzer:

    def __init__(self, path: str):
        self.path = Path(path).resolve()
        if not self.path.exists():
            raise FileNotFoundError(f"Not found: {self.path}")
        if not self.path.name.endswith(".xcframework"):
            raise ValueError(f"Not an XCFramework: {self.path.name}")
        self.info = self._read_plist()
        self.slices: List[SliceInfo] = []

    def _read_plist(self) -> dict:
        plist_path = self.path / "Info.plist"
        if not plist_path.exists():
            raise FileNotFoundError(f"Missing Info.plist in {self.path}")
        with open(plist_path, "rb") as f:
            return plistlib.load(f)

    def _run(self, cmd: List[str]) -> str:
        try:
            return subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True)
        except subprocess.CalledProcessError:
            return ""

    def _find_binary(self, library_path: str) -> Optional[Path]:
        lib = self.path / library_path
        if lib.suffix == ".framework":
            name = lib.stem
            for c in [lib / name, lib / "Versions" / "A" / name]:
                if c.exists():
                    return c
        elif lib.suffix == ".a":
            return lib if lib.exists() else None
        elif lib.exists():
            return lib
        return None

    def _get_archs(self, binary: Path) -> List[str]:
        out = self._run(["lipo", "-info", str(binary)])
        if "architectures in the fat file" in out:
            return out.split("are:")[-1].strip().split()
        elif "Non-fat file" in out:
            return [out.split("architecture:")[-1].strip()]
        return []

    def _get_symbols(self, binary: Path, arch: Optional[str] = None) -> List[Symbol]:
        cmd = ["nm", "-arch", arch, str(binary)] if arch else ["nm", str(binary)]
        out = self._run(cmd)
        symbols = []
        for line in out.splitlines():
            parts = line.strip().split(None, 2)
            if len(parts) == 3:
                symbols.append(Symbol(parts[0], parts[1], parts[2]))
            elif len(parts) == 2:
                symbols.append(Symbol("", parts[0], parts[1]))
        return symbols

    def _get_linked_libs(self, binary: Path) -> Tuple[List[str], List[str]]:
        out = self._run(["otool", "-L", str(binary)])
        libs, frameworks = [], []
        seen_lines = set()
        seen_frameworks = set()
        for line in out.splitlines()[1:]:
            line = line.strip().split("(")[0].strip()
            if not line or line in seen_lines:
                continue
            seen_lines.add(line)
            if ".framework/" in line:
                m = re.search(r'(\w+)\.framework', line)
                if m:
                    name = m.group(1)
                    if name not in seen_frameworks:
                        seen_frameworks.add(name)
                        frameworks.append(name)
            else:
                libs.append(line)
        # deduplicate libs too
        libs = list(dict.fromkeys(libs))
        return libs, frameworks

    def _get_section_sizes(self, binary: Path, arch: Optional[str] = None) -> Dict[str, int]:
        cmd = ["size", "-m"]
        if arch:
            cmd += ["-arch", arch]
        cmd.append(str(binary))
        out = self._run(cmd)
        sizes = {}
        for line in out.splitlines():
            m = re.match(r'Section\s+(\S+):\s+(\d+)', line)
            if m:
                sizes[m.group(1)] = int(m.group(2))
        return sizes

    def analyze(self):
        for lib_entry in self.info.get("AvailableLibraries", []):
            identifier = lib_entry.get("LibraryIdentifier", "unknown")
            library_path = lib_entry.get("LibraryPath", "")
            supported_archs = lib_entry.get("SupportedArchitectures", [])

            binary = self._find_binary(f"{identifier}/{library_path}")
            if not binary:
                self.slices.append(SliceInfo(identifier, library_path, supported_archs))
                continue

            archs = self._get_archs(binary)
            arch = archs[0] if archs else None
            libs, frameworks = self._get_linked_libs(binary)

            self.slices.append(SliceInfo(
                identifier=identifier,
                library_path=library_path,
                archs=archs or supported_archs,
                symbols=self._get_symbols(binary, arch),
                linked_libs=libs,
                linked_frameworks=frameworks,
                binary_size=binary.stat().st_size,
                section_sizes=self._get_section_sizes(binary, arch),
            ))

    def all_defined_symbols(self) -> Set[str]:
        return {s.name for sl in self.slices for s in sl.symbols if s.is_defined}


# ─── Project ──────────────────────────────────────────────────────────────────

class Project:
    def __init__(self, name: str, entries: List[FrameworkEntry]):
        self.name = name
        self.entries = entries
        self.analyzers: List[Tuple[FrameworkEntry, XCFrameworkAnalyzer]] = []

    @classmethod
    def from_directory(cls, directory: str) -> "Project":
        d = Path(directory)
        xcfs = sorted(d.glob("**/*.xcframework"))
        if not xcfs:
            raise FileNotFoundError(f"No .xcframework found under {directory}")
        entries = [FrameworkEntry(path=str(p)) for p in xcfs]
        return cls(name=d.name, entries=entries)

    @classmethod
    def from_config(cls, config_path: str) -> "Project":
        with open(config_path) as f:
            cfg = json.load(f)
        name = cfg.get("name", Path(config_path).stem)
        entries = [
            FrameworkEntry(path=e["path"], role=e.get("role"))
            for e in cfg.get("frameworks", [])
        ]
        return cls(name=name, entries=entries)

    def save_config(self, output_path: str):
        cfg = {
            "name": self.name,
            "frameworks": [
                {"path": e.path, "role": e.role or ""}
                for e in self.entries
            ]
        }
        with open(output_path, "w") as f:
            json.dump(cfg, f, indent=2)
        print(f"Project config saved to {output_path}")

    def analyze(self, verbose_stream=None):
        for entry in self.entries:
            print(f"  Analyzing {Path(entry.path).name} ...", file=verbose_stream or sys.stdout)
            az = XCFrameworkAnalyzer(entry.path)
            az.analyze()
            self.analyzers.append((entry, az))


# ─── Formatting helpers ───────────────────────────────────────────────────────

def fmt_size(n: int) -> str:
    for unit in ["B", "KB", "MB", "GB"]:
        if n < 1024:
            return f"{n:.1f} {unit}"
        n /= 1024
    return f"{n:.1f} GB"


def count_by_category(symbols: List[Symbol]) -> Dict[str, List[int]]:
    counts = defaultdict(lambda: [0, 0])
    for s in symbols:
        counts[s.category][0 if s.is_defined else 1] += 1
    return dict(counts)


# ─── Single XCFramework report ────────────────────────────────────────────────

def print_xcf_summary(analyzer: XCFrameworkAnalyzer, role: Optional[str] = None,
                      show_symbols: bool = False, filter_pattern: Optional[str] = None):
    path = analyzer.path
    info = analyzer.info
    role_str = f"  [{role}]" if role else ""
    print(f"\n{'='*70}")
    print(f"  XCFramework: {path.name}{role_str}")
    print(f"{'='*70}")
    print(f"  Format version : {info.get('XCFrameworkFormatVersion', '?')}")
    print(f"  Slices         : {len(analyzer.slices)}")

    for sl in analyzer.slices:
        defined = [s for s in sl.symbols if s.is_defined]
        undefined = [s for s in sl.symbols if not s.is_defined]

        print(f"\n  {'─'*66}")
        print(f"  Slice : {sl.identifier}")
        print(f"  {'─'*66}")
        print(f"  Library     : {sl.library_path}")
        print(f"  Archs       : {', '.join(sl.archs)}")
        print(f"  Binary size : {fmt_size(sl.binary_size)}")

        if sl.section_sizes:
            print(f"  Sections    :")
            for sec, sz in sorted(sl.section_sizes.items(), key=lambda x: -x[1]):
                print(f"    {sec:<28} {fmt_size(sz)}")

        if sl.linked_frameworks:
            print(f"  Linked Frameworks : {', '.join(sl.linked_frameworks)}")
        if sl.linked_libs:
            print(f"  Linked Libs :")
            for lib in sl.linked_libs:
                print(f"    {lib}")

        print(f"\n  Symbols: {len(sl.symbols)} total  |  {len(defined)} defined  |  {len(undefined)} external/undef")

        counts = count_by_category(sl.symbols)
        print(f"\n  {'Category':<33} {'Defined':>8} {'Undef':>8}")
        print(f"  {'─'*33} {'─'*8} {'─'*8}")
        for cat in ALL_CATEGORIES:
            d, u = counts.get(cat, [0, 0])
            if d + u == 0:
                continue
            label = CATEGORY_LABELS.get(cat, cat)
            print(f"  {label:<33} {d:>8} {u:>8}")

        runtime_count = sum(1 for s in sl.symbols if s.category == "kotlin_runtime" and s.is_defined)
        if runtime_count:
            print(f"\n  ⚠️  Kotlin/Native runtime EMBEDDED  ({runtime_count} symbols)")
        else:
            print(f"\n  ✓  Kotlin/Native runtime NOT embedded (thin/external)")

        stdlib_count = sum(1 for s in sl.symbols if s.category == "kotlin_stdlib" and s.is_defined)
        if stdlib_count:
            print(f"  ⚠️  Kotlin Stdlib EMBEDDED  ({stdlib_count} symbols)")
        else:
            print(f"  ✓  Kotlin Stdlib NOT embedded")

        objc_classes = sorted(
            s.name.replace("_OBJC_CLASS_$_", "")
            for s in sl.symbols
            if "_OBJC_CLASS_$_" in s.name and s.is_defined
        )
        if objc_classes:
            print(f"\n  ObjC Exported Classes ({len(objc_classes)}):")
            for cls in objc_classes:
                print(f"    {cls}")

        if show_symbols:
            syms = sl.symbols
            if filter_pattern:
                pat = re.compile(filter_pattern, re.IGNORECASE)
                syms = [s for s in syms if pat.search(s.name)]
            print(f"\n  Symbols{f' [filter={filter_pattern}]' if filter_pattern else ''}:")
            for s in sorted(syms, key=lambda x: x.name):
                status = "DEF" if s.is_defined else "EXT"
                print(f"    [{status}][{s.category:<16}][{s.sym_type}] {s.name}")

    print()


# ─── Project-level report ─────────────────────────────────────────────────────

def print_project_summary(project: Project, show_symbols: bool, filter_pattern: Optional[str]):
    total_size = sum(
        sl.binary_size
        for _, az in project.analyzers
        for sl in az.slices
    )
    print(f"\n{'#'*70}")
    print(f"  Project: {project.name}")
    print(f"  Frameworks: {len(project.analyzers)}  |  Total binary size: {fmt_size(total_size)}")
    print(f"{'#'*70}")

    for entry, az in project.analyzers:
        print_xcf_summary(az, role=entry.role, show_symbols=show_symbols,
                          filter_pattern=filter_pattern)

    # Cross-framework duplicate symbol analysis
    print(f"\n{'='*70}")
    print(f"  Cross-Framework Symbol Analysis")
    print(f"{'='*70}")

    sym_to_frameworks: Dict[str, List[str]] = defaultdict(list)
    for entry, az in project.analyzers:
        name = Path(az.path).name
        for sym in az.all_defined_symbols():
            sym_to_frameworks[sym].append(name)

    duplicates = {sym: fws for sym, fws in sym_to_frameworks.items() if len(fws) > 1}

    if not duplicates:
        print(f"\n  ✓  No duplicate defined symbols across frameworks.\n")
    else:
        dup_by_cat: Dict[str, List[str]] = defaultdict(list)
        for sym in duplicates:
            cat = Symbol("", "T", sym).category
            dup_by_cat[cat].append(sym)

        print(f"\n  ⚠️  {len(duplicates)} symbols defined in multiple frameworks!\n")
        print(f"  {'Category':<33} {'Dup symbols':>12}")
        print(f"  {'─'*33} {'─'*12}")
        for cat in ALL_CATEGORIES:
            count = len(dup_by_cat.get(cat, []))
            if count == 0:
                continue
            label = CATEGORY_LABELS.get(cat, cat)
            print(f"  {label:<33} {count:>12}")

        print(f"\n  Frameworks involved in duplication:")
        fw_dup_count: Dict[str, int] = defaultdict(int)
        for sym, fws in duplicates.items():
            for fw in fws:
                fw_dup_count[fw] += 1
        for fw, count in sorted(fw_dup_count.items(), key=lambda x: -x[1]):
            print(f"    {fw:<50} {count:>6} dup symbols")

    print()


def print_comparison(a1: XCFrameworkAnalyzer, a2: XCFrameworkAnalyzer):
    name1 = a1.path.name
    name2 = a2.path.name
    print(f"\n{'='*70}")
    print(f"  Comparison: {name1}  vs  {name2}")
    print(f"{'='*70}")

    syms1 = a1.all_defined_symbols()
    syms2 = a2.all_defined_symbols()
    shared = syms1 & syms2
    only1  = syms1 - syms2
    only2  = syms2 - syms1

    print(f"\n  {name1:<45}: {len(syms1):>7} defined")
    print(f"  {name2:<45}: {len(syms2):>7} defined")
    print(f"  Shared / duplicated                          : {len(shared):>7}")
    print(f"  Only in {name1:<36}: {len(only1):>7}")
    print(f"  Only in {name2:<36}: {len(only2):>7}")

    shared_by_cat: Dict[str, int] = defaultdict(int)
    for sym in shared:
        shared_by_cat[Symbol("", "T", sym).category] += 1

    print(f"\n  Shared symbols by category:")
    print(f"  {'Category':<33} {'Count':>8}")
    print(f"  {'─'*33} {'─'*8}")
    for cat in ALL_CATEGORIES:
        count = shared_by_cat.get(cat, 0)
        if count:
            print(f"  {CATEGORY_LABELS.get(cat, cat):<33} {count:>8}")

    print()


def print_headers(analyzer: XCFrameworkAnalyzer):
    print(f"\n{'='*70}")
    print(f"  ObjC Headers: {analyzer.path.name}")
    print(f"{'='*70}")
    for lib_entry in analyzer.info.get("AvailableLibraries", []):
        identifier = lib_entry.get("LibraryIdentifier", "")
        lib_path = lib_entry.get("LibraryPath", "")
        # Headers are inside the .framework bundle: <slice>/<framework>/Headers/
        framework_dir = analyzer.path / identifier / lib_path
        headers_path = framework_dir / "Headers"
        if not headers_path.exists():
            # fallback: old layout
            headers_path = analyzer.path / identifier / "Headers"
        if not headers_path.exists():
            continue
        print(f"\n  Slice: {identifier}")
        for h in sorted(headers_path.glob("*.h")):
            content = h.read_text(errors="ignore")
            interfaces = re.findall(r'@interface\s+(\w+)', content)
            protocols  = re.findall(r'@protocol\s+(\w+)', content)
            print(f"\n  ── {h.name} ──")
            if interfaces:
                print(f"    @interface : {', '.join(interfaces)}")
            if protocols:
                print(f"    @protocol  : {', '.join(protocols)}")
    print()


def output_json_single(analyzer: XCFrameworkAnalyzer) -> str:
    result = {
        "name": analyzer.path.name,
        "format_version": analyzer.info.get("XCFrameworkFormatVersion"),
        "slices": []
    }
    for sl in analyzer.slices:
        counts = count_by_category(sl.symbols)
        result["slices"].append({
            "identifier": sl.identifier,
            "library": sl.library_path,
            "archs": sl.archs,
            "binary_size_bytes": sl.binary_size,
            "linked_frameworks": sl.linked_frameworks,
            "has_kotlin_runtime": any(
                s.category == "kotlin_runtime" and s.is_defined for s in sl.symbols
            ),
            "has_kotlin_stdlib": any(
                s.category == "kotlin_stdlib" and s.is_defined for s in sl.symbols
            ),
            "symbol_counts": {
                cat: {"defined": c[0], "undefined": c[1]}
                for cat, c in counts.items()
            },
            "objc_exported_classes": sorted(
                s.name.replace("_OBJC_CLASS_$_", "")
                for s in sl.symbols
                if "_OBJC_CLASS_$_" in s.name and s.is_defined
            ),
        })
    return result


def output_json_project(project: Project) -> str:
    result = {
        "project": project.name,
        "frameworks": []
    }
    for entry, az in project.analyzers:
        fw = output_json_single(az)
        fw["role"] = entry.role
        result["frameworks"].append(fw)
    return json.dumps(result, indent=2)


# ─── Entry point ──────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Analyze KMP/Kotlin Native XCFramework structure and symbols",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument("xcframework", nargs="?", help="Path to .xcframework")
    parser.add_argument("--symbols",        action="store_true", help="Show full symbol list")
    parser.add_argument("--filter",         metavar="PATTERN",   help="Filter symbols by regex")
    parser.add_argument("--json",           action="store_true", help="Output as JSON")
    parser.add_argument("--headers",        action="store_true", help="Show ObjC header summary")
    parser.add_argument("--compare",        metavar="PATH",      help="Compare with another XCFramework")
    parser.add_argument("--project",        metavar="DIR",       help="Analyze all .xcframework in directory")
    parser.add_argument("--project-config", metavar="FILE",      help="Load project config from JSON")
    parser.add_argument("--save-project",   metavar="FILE",      help="Save discovered project config to JSON")
    args = parser.parse_args()

    project = None

    def info(msg):
        """Print progress info; redirect to stderr when --json is active to keep stdout clean."""
        print(msg, file=sys.stderr if args.json else sys.stdout)

    if args.project:
        info(f"Loading project from directory: {args.project}")
        project = Project.from_directory(args.project)
    elif args.project_config:
        info(f"Loading project config: {args.project_config}")
        project = Project.from_config(args.project_config)

    if project:
        if args.save_project:
            project.save_config(args.save_project)
        info(f"Analyzing {len(project.entries)} frameworks ...")
        project.analyze(verbose_stream=sys.stderr if args.json else None)
        if args.json:
            print(output_json_project(project))
        else:
            print_project_summary(project, show_symbols=args.symbols or bool(args.filter), filter_pattern=args.filter)
        return

    if not args.xcframework:
        parser.print_help()
        sys.exit(1)

    info(f"Analyzing {args.xcframework} ...")
    analyzer = XCFrameworkAnalyzer(args.xcframework)
    analyzer.analyze()

    if args.json:
        print(json.dumps(output_json_single(analyzer), indent=2))
        return

    print_xcf_summary(analyzer, show_symbols=args.symbols or bool(args.filter), filter_pattern=args.filter)

    if args.headers:
        print_headers(analyzer)

    if args.compare:
        print(f"Comparing with {args.compare} ...")
        other = XCFrameworkAnalyzer(args.compare)
        other.analyze()
        print_comparison(analyzer, other)


if __name__ == "__main__":
    main()
