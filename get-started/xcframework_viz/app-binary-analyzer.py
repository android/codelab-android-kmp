#!/usr/bin/env python3
"""
app-binary-analyzer: Analyze embedded frameworks inside a built iOS .app bundle.

Proves that duplicate Kotlin/Native runtime symbols exist in the final app product,
not just in the standalone XCFrameworks.

Usage:
    python3 app-binary-analyzer.py <path/to/App.app>
    python3 app-binary-analyzer.py <path/to/App.app> --json
    python3 app-binary-analyzer.py <path/to/App.app> --symbols

This script:
1. Scans .app/Frameworks/ for all embedded .framework bundles
2. Extracts symbols from each framework binary using nm
3. Classifies symbols (runtime, stdlib, kotlinx, objc, user API, etc.)
4. Cross-framework duplicate analysis
5. Outputs a report proving dual runtime presence in the final app
"""

import os
import sys
import subprocess
import json
import argparse
import re
from pathlib import Path
from collections import defaultdict
from dataclasses import dataclass, field
from typing import Dict, List, Set, Tuple


# ─── Symbol categories (same as xcframework-analyzer.py) ─────────────────────

CATEGORIES = {
    "kotlin_runtime": re.compile(
        r'('
        r'_konan_|_Kotlin_ObjCExport_referer|kotlin\.konan\.|KonanAllocator'
        r'|kotlin_native_runtime|_Kotlin_mm_|konan_objc_|_kotlin_objc'
        r'|Kotlin_launchers|konanTerminate|RuntimeCheck|FreezeHook'
        r'|InitializationManager|MemoryState|GarbageCollect'
        r'|_ZN6kotlin|__ZN6kotlin'
        r'|_ZN5konan|__ZN5konan'
        r'|_ZN12_GLOBAL__N_1|__ZN12_GLOBAL__N_1'
        r'|_Kotlin_ObjCExport|Kotlin_ObjCExport'
        r'|blockToKotlinImp|SwiftObject_toKotlinImp|SwiftObject_release'
        r'|boxedBooleanToKotlinImp|convertKotlinObjectToRetained'
        r'|getOrCreateClass|getOrCreateTypeInfo|setAssociatedTypeInfo'
        r'|incorrectNumberFactory|incorrectNumberInitialization'
        r'|ReportBacktraceToIosCrashLog|printlnMessage'
        r')'
    ),
    "kotlin_stdlib": re.compile(
        r'(kfun:kotlin\.|ktypew:kotlin\.|kclass:kotlin\.|_kotlin_stdlib|kfun:#main|kfun:kotlin#)'
    ),
    "kotlinx": re.compile(
        r'(kfun:kotlinx\.|ktypew:kotlinx\.|kclass:kotlinx\.|kifacetable:kotlinx\.|kintf:kotlinx\.)'
    ),
    "objc_export": re.compile(r'(_OBJC_CLASS_\$_|_OBJC_METACLASS_\$_|_OBJC_IVAR_\$_)'),
    "kotlin_user_api": re.compile(r'(kfun:|ktypew:|kclass:)'),
    "cinterop": re.compile(r'(cinterop_|_knbridge|_kn_objc_|interop_)'),
    "swift": re.compile(r'^_\$s'),
    "cpp_rtti": re.compile(r'^(__ZTI|__ZTS|__ZTV)'),
    "cpp_symbols": re.compile(r'^__Z'),
}

CATEGORY_LABELS = {
    "kotlin_runtime": "Kotlin/Native Runtime",
    "kotlin_stdlib": "Kotlin Stdlib",
    "kotlinx": "kotlinx libraries",
    "objc_export": "ObjC Export (class/metaclass)",
    "kotlin_user_api": "Kotlin User API (kfun/kclass)",
    "cinterop": "cinterop bridges",
    "swift": "Swift symbols",
    "cpp_rtti": "C++ RTTI",
    "cpp_symbols": "C++ symbols",
    "other": "Other",
}

ALL_CATEGORIES = list(CATEGORIES.keys()) + ["other"]


# ─── Data classes ────────────────────────────────────────────────────────────

@dataclass
class FrameworkInfo:
    name: str
    path: str
    binary_path: str
    arch: str = ""
    symbols: Dict[str, List[str]] = field(default_factory=lambda: defaultdict(list))
    all_defined: Set[str] = field(default_factory=set)
    total_defined: int = 0
    binary_size: int = 0
    linked_libs: List[str] = field(default_factory=list)


def classify_symbol(sym: str) -> str:
    for cat, regex in CATEGORIES.items():
        if regex.search(sym):
            return cat
    return "other"


def extract_symbols(binary_path: str) -> Tuple[Set[str], Dict[str, List[str]]]:
    """Run nm on a binary and classify symbols."""
    defined = set()
    categorized = defaultdict(list)
    try:
        # macOS nm: -U = exclude undefined symbols
        # Include ALL defined symbols (global + local) to catch debug builds
        result = subprocess.run(
            ["nm", "-U", binary_path],
            capture_output=True, text=True, timeout=60
        )
        for line in result.stdout.splitlines():
            parts = line.strip().split(maxsplit=2)
            if len(parts) >= 3:
                sym = parts[2]
                defined.add(sym)
                cat = classify_symbol(sym)
                categorized[cat].append(sym)
            elif len(parts) == 2 and parts[0] in ('t', 'T', 's', 'S', 'd', 'D'):
                sym = parts[1]
                defined.add(sym)
                cat = classify_symbol(sym)
                categorized[cat].append(sym)
    except Exception as e:
        print(f"  Warning: nm failed for {binary_path}: {e}", file=sys.stderr)
    return defined, categorized


def get_linked_libs(binary_path: str) -> List[str]:
    """Get linked libraries using otool."""
    libs = []
    try:
        result = subprocess.run(
            ["otool", "-L", binary_path],
            capture_output=True, text=True, timeout=30
        )
        for line in result.stdout.splitlines()[1:]:
            lib = line.strip().split(" (")[0].strip()
            if lib:
                libs.append(lib)
    except Exception:
        pass
    return libs


def get_architectures(binary_path: str) -> List[str]:
    """Get architectures from a binary."""
    try:
        result = subprocess.run(
            ["lipo", "-info", binary_path],
            capture_output=True, text=True, timeout=10
        )
        output = result.stdout.strip()
        if ":" in output:
            return output.split(":")[-1].strip().split()
    except Exception:
        pass
    return ["unknown"]


def analyze_app_bundle(app_path: str, target_arch: str = None) -> List[FrameworkInfo]:
    """Scan .app/Frameworks/ and analyze each embedded framework."""
    frameworks_dir = os.path.join(app_path, "Frameworks")
    if not os.path.isdir(frameworks_dir):
        print(f"Error: No Frameworks/ directory in {app_path}", file=sys.stderr)
        sys.exit(1)

    frameworks = []
    for entry in sorted(os.listdir(frameworks_dir)):
        if not entry.endswith(".framework"):
            continue
        fw_path = os.path.join(frameworks_dir, entry)
        name = entry.replace(".framework", "")
        binary_path = os.path.join(fw_path, name)

        if not os.path.isfile(binary_path):
            continue

        archs = get_architectures(binary_path)
        arch_label = ", ".join(archs)

        info = FrameworkInfo(
            name=name,
            path=fw_path,
            binary_path=binary_path,
            arch=arch_label,
        )

        info.binary_size = os.path.getsize(binary_path)
        info.all_defined, info.symbols = extract_symbols(binary_path)
        info.total_defined = len(info.all_defined)
        info.linked_libs = get_linked_libs(binary_path)

        frameworks.append(info)

    return frameworks


def find_duplicates(frameworks: List[FrameworkInfo]) -> Dict[str, List[str]]:
    """Find symbols that exist in multiple frameworks."""
    sym_to_frameworks = defaultdict(list)
    for fw in frameworks:
        for sym in fw.all_defined:
            sym_to_frameworks[sym].append(fw.name)
    return {sym: fws for sym, fws in sym_to_frameworks.items() if len(fws) > 1}


def print_report(app_path: str, frameworks: List[FrameworkInfo], duplicates: Dict[str, List[str]], show_symbols: bool = False):
    """Print human-readable report."""
    app_name = os.path.basename(app_path)

    print(f"\n{'='*70}")
    print(f"  iOS App Bundle Symbol Analysis: {app_name}")
    print(f"{'='*70}\n")
    print(f"  App path: {app_path}")
    print(f"  Embedded frameworks: {len(frameworks)}\n")

    # Per-framework breakdown
    for fw in frameworks:
        print(f"  {'─'*60}")
        print(f"  Framework: {fw.name}")
        print(f"  Binary size: {fw.binary_size / 1024:.0f} KB")
        print(f"  Architecture: {fw.arch}")
        print(f"  Total defined symbols: {fw.total_defined}")
        print()

        print(f"    {'Category':<35} {'Count':>8}")
        print(f"    {'─'*35} {'─'*8}")
        for cat in ALL_CATEGORIES:
            count = len(fw.symbols.get(cat, []))
            if count > 0:
                label = CATEGORY_LABELS.get(cat, cat)
                print(f"    {label:<35} {count:>8}")
        print()

        if show_symbols:
            for cat in ALL_CATEGORIES:
                syms = fw.symbols.get(cat, [])
                if syms:
                    label = CATEGORY_LABELS.get(cat, cat)
                    print(f"    [{label}] ({len(syms)} symbols):")
                    for s in sorted(syms)[:50]:
                        print(f"      {s}")
                    if len(syms) > 50:
                        print(f"      ... and {len(syms) - 50} more")
                    print()

    # Cross-framework duplicate analysis
    if len(frameworks) >= 2 and duplicates:
        dup_by_cat = defaultdict(list)
        for sym, fws in duplicates.items():
            cat = classify_symbol(sym)
            dup_by_cat[cat].append(sym)

        print(f"\n  {'='*60}")
        print(f"  CROSS-FRAMEWORK DUPLICATE SYMBOLS IN APP BUNDLE")
        print(f"  {'='*60}\n")
        print(f"  Total duplicate symbols: {len(duplicates)}\n")

        print(f"    {'Category':<35} {'Dup Count':>10} {'% of smaller fw':>16}")
        print(f"    {'─'*35} {'─'*10} {'─'*16}")

        min_total = min(fw.total_defined for fw in frameworks)
        for cat in ALL_CATEGORIES:
            dups = dup_by_cat.get(cat, [])
            if dups:
                label = CATEGORY_LABELS.get(cat, cat)
                pct = len(dups) / min_total * 100 if min_total > 0 else 0
                print(f"    {label:<35} {len(dups):>10} {pct:>15.1f}%")

        total_pct = len(duplicates) / min_total * 100 if min_total > 0 else 0
        print(f"    {'─'*35} {'─'*10} {'─'*16}")
        print(f"    {'TOTAL':<35} {len(duplicates):>10} {total_pct:>15.1f}%")

        # Highlight critical finding
        runtime_dups = len(dup_by_cat.get("kotlin_runtime", []))
        stdlib_dups = len(dup_by_cat.get("kotlin_stdlib", []))
        print(f"\n  CRITICAL FINDING:")
        print(f"  The final iOS app bundle contains TWO independent copies of:")
        print(f"    - Kotlin/Native Runtime: {runtime_dups} duplicate symbols")
        print(f"    - Kotlin Stdlib: {stdlib_dups} duplicate symbols")
        print(f"  These are loaded as separate dylibs in the app process.")
        print(f"  Each framework has its own GC, type system, and ObjC class hierarchy.\n")


def output_json(app_path: str, frameworks: List[FrameworkInfo], duplicates: Dict[str, List[str]]):
    """Output analysis as JSON."""
    dup_by_cat = defaultdict(list)
    for sym, fws in duplicates.items():
        cat = classify_symbol(sym)
        dup_by_cat[cat].append(sym)

    result = {
        "app_path": app_path,
        "frameworks": [],
        "cross_framework_duplicates": {
            "total": len(duplicates),
            "by_category": {
                CATEGORY_LABELS.get(cat, cat): len(syms)
                for cat, syms in dup_by_cat.items()
            }
        }
    }

    for fw in frameworks:
        fw_data = {
            "name": fw.name,
            "binary_size_bytes": fw.binary_size,
            "architecture": fw.arch,
            "total_defined_symbols": fw.total_defined,
            "by_category": {
                CATEGORY_LABELS.get(cat, cat): len(fw.symbols.get(cat, []))
                for cat in ALL_CATEGORIES
                if len(fw.symbols.get(cat, [])) > 0
            },
            "linked_libraries": fw.linked_libs,
        }
        result["frameworks"].append(fw_data)

    print(json.dumps(result, indent=2))


def main():
    parser = argparse.ArgumentParser(
        description="Analyze embedded frameworks in an iOS .app bundle"
    )
    parser.add_argument("app_path", help="Path to .app bundle")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    parser.add_argument("--symbols", action="store_true", help="Show symbol lists")
    args = parser.parse_args()

    app_path = args.app_path
    if not os.path.isdir(app_path):
        print(f"Error: {app_path} is not a directory", file=sys.stderr)
        sys.exit(1)

    if not app_path.endswith(".app"):
        print(f"Warning: {app_path} does not end with .app", file=sys.stderr)

    frameworks = analyze_app_bundle(app_path)
    if not frameworks:
        print("No embedded frameworks found in the app bundle.", file=sys.stderr)
        sys.exit(1)

    duplicates = find_duplicates(frameworks)

    if args.json:
        output_json(app_path, frameworks, duplicates)
    else:
        print_report(app_path, frameworks, duplicates, show_symbols=args.symbols)


if __name__ == "__main__":
    main()
