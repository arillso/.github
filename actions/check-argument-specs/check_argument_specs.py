#!/usr/bin/env python3
"""Check that all variables in defaults/main.yml are documented in meta/argument_specs.yml.

Checks:
    1. Variables in defaults/ but missing from argument_specs (error)
    2. Variables in argument_specs but missing from defaults/ (warning)
    3. Default value mismatches between defaults/ and argument_specs (warning)
    4. Missing description in argument_specs options/suboptions (warning)
    5. Missing type in argument_specs options/suboptions (warning)
    6. Recursive suboptions quality validation (independent of default values)
    7. Default value keys not covered by suboptions (warning)
    8. Suboption default mismatches against parent default value (warning)

Outputs GitHub Actions annotations (::error::, ::warning::) for PR integration.
"""

import sys
from pathlib import Path

import yaml

ROLES_DIR = Path("roles")


def load_yaml(path):
    """Load a YAML file and return its contents."""
    if not path.exists():
        return {}
    with open(path) as f:
        data = yaml.safe_load(f)
    return data if data else {}


def extract_argspec_options(argument_specs):
    """Extract all options from argument_specs across all entry points."""
    options_map = {}
    specs = argument_specs.get("argument_specs", {})
    if not isinstance(specs, dict):
        return options_map
    for _entry_point, entry_data in specs.items():
        if not isinstance(entry_data, dict):
            continue
        options = entry_data.get("options", {})
        if not isinstance(options, dict):
            continue
        for var_name, var_meta in options.items():
            options_map[var_name] = var_meta if isinstance(var_meta, dict) else {}
    return options_map


def check_spec_quality(options, file_path, prefix, issues):
    """Recursively check that all options/suboptions have description and type."""
    if not isinstance(options, dict):
        return

    for key, meta in sorted(options.items()):
        if not isinstance(meta, dict):
            continue

        full_key = f"{prefix}.{key}" if prefix else key

        if not meta.get("description"):
            issues.append((
                "warning",
                file_path,
                full_key,
                "missing 'description' in argument_specs",
            ))

        if not meta.get("type"):
            issues.append((
                "warning",
                file_path,
                full_key,
                "missing 'type' in argument_specs",
            ))

        # Recurse into suboptions regardless of default values
        suboptions = meta.get("options")
        if isinstance(suboptions, dict) and suboptions:
            check_spec_quality(suboptions, file_path, full_key, issues)


def check_defaults_against_suboptions(spec_meta, default_value, spec_file, defaults_file, var_prefix, issues):
    """Recursively check that keys in default values are covered by suboptions."""
    spec_type = spec_meta.get("type", "")
    suboptions = spec_meta.get("options")

    if not isinstance(suboptions, dict) or not suboptions:
        # No suboptions defined but default is a non-empty dict/list-of-dicts
        if spec_type == "dict" and isinstance(default_value, dict) and default_value:
            issues.append((
                "warning",
                spec_file,
                var_prefix,
                f"type is 'dict' with {len(default_value)} default keys but no suboptions defined",
            ))
        return

    # Collect items to check based on type
    if spec_type == "dict" and isinstance(default_value, dict):
        items_to_check = [default_value]
    elif spec_type == "list" and spec_meta.get("elements") == "dict" and isinstance(default_value, list):
        items_to_check = [item for item in default_value if isinstance(item, dict)]
    else:
        return

    if not items_to_check:
        return

    # Collect all keys across all items
    default_keys = set()
    for item in items_to_check:
        default_keys.update(item.keys())

    suboption_keys = set(suboptions.keys())

    # Keys in defaults but not in suboptions
    for key in sorted(default_keys - suboption_keys):
        issues.append((
            "warning",
            defaults_file,
            f"{var_prefix}.{key}",
            "present in default value but not documented in suboptions",
        ))

    # Check suboption defaults against actual default values
    for key in sorted(default_keys & suboption_keys):
        sub_meta = suboptions[key]
        if not isinstance(sub_meta, dict):
            continue

        # Compare suboption default with actual value in parent default
        if "default" in sub_meta:
            for item in items_to_check:
                if key in item and sub_meta["default"] != item[key]:
                    issues.append((
                        "warning",
                        defaults_file,
                        f"{var_prefix}.{key}",
                        f"suboption default mismatch: defaults={item[key]!r} vs argument_specs={sub_meta['default']!r}",
                    ))
                    break

        # Recurse deeper
        for item in items_to_check:
            if key in item:
                check_defaults_against_suboptions(
                    sub_meta, item[key], spec_file, defaults_file, f"{var_prefix}.{key}", issues,
                )
                break


def check_role(role_path):
    """Check a single role for argument spec issues."""
    issues = []
    defaults_file = role_path / "defaults" / "main.yml"
    argspec_file = role_path / "meta" / "argument_specs.yml"

    if not defaults_file.exists():
        return issues

    if not argspec_file.exists():
        issues.append(("error", argspec_file, "-", "meta/argument_specs.yml does not exist"))
        return issues

    defaults = load_yaml(defaults_file)
    argument_specs = load_yaml(argspec_file)

    if not isinstance(defaults, dict):
        return issues

    argspec_options = extract_argspec_options(argument_specs)
    defaults_vars = set(defaults.keys())
    argspec_vars = set(argspec_options.keys())

    # 1. Variables in defaults but not in argument_specs
    for var in sorted(defaults_vars - argspec_vars):
        issues.append(("error", defaults_file, var, "defined in defaults/ but missing from argument_specs"))

    # 2. Variables in argument_specs but not in defaults
    for var in sorted(argspec_vars - defaults_vars):
        issues.append((
            "warning",
            argspec_file,
            var,
            "in argument_specs but not in defaults/ (may be entry-point specific or required)",
        ))

    # 3. Check common variables
    for var in sorted(defaults_vars & argspec_vars):
        meta = argspec_options.get(var, {})

        # Top-level default value mismatch
        if "default" in meta:
            spec_default = meta["default"]
            actual_default = defaults.get(var)
            if spec_default != actual_default:
                issues.append((
                    "warning",
                    defaults_file,
                    var,
                    f"default value mismatch: defaults={actual_default!r} vs argument_specs={spec_default!r}",
                ))

        # Check default value keys against suboptions
        check_defaults_against_suboptions(
            meta, defaults.get(var), argspec_file, defaults_file, var, issues,
        )

    # 4. Recursively check spec quality (description, type) for ALL options
    check_spec_quality(argspec_options, argspec_file, "", issues)

    return issues


def main():
    if not ROLES_DIR.exists():
        print("No roles/ directory found, skipping check.")
        sys.exit(0)

    roles = sorted(p for p in ROLES_DIR.iterdir() if p.is_dir())
    total_errors = 0
    total_warnings = 0

    for role_path in roles:
        issues = check_role(role_path)
        for severity, file_path, var, message in issues:
            print(f"::{severity} file={file_path}::{role_path.name}: [{var}] {message}")
            if severity == "error":
                total_errors += 1
            else:
                total_warnings += 1

    print(f"\nSummary: {len(roles)} roles checked, {total_errors} error(s), {total_warnings} warning(s)")

    if total_errors > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
