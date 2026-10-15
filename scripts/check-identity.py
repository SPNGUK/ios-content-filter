#!/usr/bin/env python3
"""Fail if bundle identifiers drift from shared/identity.props."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROPS = ROOT / "shared" / "identity.props"


def prop(name: str, text: str) -> str:
    match = re.search(rf"<{name}>([^<]+)</{name}>", text)
    if not match:
        sys.exit(f"shared/identity.props is missing <{name}>")
    return match.group(1).strip()


def require(path: Path, needle: str, failures: list[str]) -> None:
    if not path.is_file():
        failures.append(f"missing file {path.relative_to(ROOT)}")
        return
    body = path.read_text(encoding="utf-8")
    if needle not in body:
        failures.append(f"{path.relative_to(ROOT)} does not contain {needle}")


def main() -> int:
    text = PROPS.read_text(encoding="utf-8")
    host = prop("FilterHostBundleId", text)
    data = prop("FilterDataBundleId", text)
    control = prop("FilterControlBundleId", text)
    group = prop("FilterAppGroupId", text)
    keychain = prop("FilterKeychainAccessGroupSuffix", text)
    team = prop("FilterTeamIdPlaceholder", text)

    failures: list[str] = []
    csproj = ROOT / "src" / "IosContentFilter" / "IosContentFilter.csproj"
    identity = ROOT / "src" / "IosContentFilter" / "FilterIdentity.cs"
    swift = ROOT / "extensions" / "FilterExtensions" / "Shared" / "FilterConstants.swift"
    pbx = ROOT / "extensions" / "FilterExtensions" / "FilterExtensions.xcodeproj" / "project.pbxproj"
    host_ent = ROOT / "src" / "IosContentFilter" / "Platforms" / "iOS" / "Entitlements.plist"
    data_ent = ROOT / "extensions" / "FilterExtensions" / "FilterData" / "FilterData.entitlements"
    control_ent = ROOT / "extensions" / "FilterExtensions" / "FilterControl" / "FilterControl.entitlements"

    require(csproj, "$(FilterHostBundleId)", failures)
    require(csproj, "identity.props", failures)
    for value in (host, data, control, group, keychain, team):
        require(identity, value, failures)
        require(swift, value, failures)

    require(pbx, data, failures)
    require(pbx, control, failures)
    require(pbx, "com.apple.product-type.app-extension", failures)

    for ent in (host_ent, data_ent, control_ent):
        require(ent, group, failures)
        require(ent, f"$(AppIdentifierPrefix){keychain}", failures)
        require(ent, "content-filter-provider", failures)

    require(host_ent, "com.apple.developer.family-controls", failures)

    sample = (ROOT / "shared" / "rules.sample.json").read_text(encoding="utf-8")
    if '"version": 1' not in sample or '"defaultDecision": "allow"' not in sample:
        failures.append("shared/rules.sample.json must be version 1 with defaultDecision allow")

    if failures:
        print("Identity check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        return 1

    print("Identity check passed")
    print(f"  host:     {host}")
    print(f"  data:     {data}")
    print(f"  control:  {control}")
    print(f"  group:    {group}")
    print(f"  keychain: {keychain}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
