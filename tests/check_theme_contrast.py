#!/usr/bin/env python3
"""Check WCAG AA contrast for the text colours exposed by bundled themes."""

from __future__ import annotations

import pathlib
import sys
import tomllib

MINIMUM_CONTRAST = 4.5  # WCAG 2 AA for normal-sized text
ROOT = pathlib.Path(__file__).resolve().parents[1]
# These are line and wrap markers rather than textual content. They must stay
# subtle so they do not compete with the editor text.
NON_TEXT_HELIX_STYLES = {"ui.virtual.indent-guide", "ui.virtual.wrap"}


def luminance(colour: str) -> float:
    if len(colour) != 7 or not colour.startswith("#"):
        raise ValueError(f"expected a #RRGGBB colour, got {colour!r}")
    channels = [int(colour[index : index + 2], 16) / 255 for index in (1, 3, 5)]
    linear = [
        channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4
        for channel in channels
    ]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def contrast(foreground: str, background: str) -> float:
    lighter, darker = sorted((luminance(foreground), luminance(background)), reverse=True)
    return (lighter + 0.05) / (darker + 0.05)


def resolve(colour: str, palette: dict[str, str]) -> str:
    return palette.get(colour, colour)


def require_contrast(label: str, foreground: str, background: str, failures: list[str]) -> None:
    ratio = contrast(foreground, background)
    if ratio < MINIMUM_CONTRAST:
        failures.append(
            f"{label}: {foreground} on {background} has {ratio:.2f}:1 contrast; "
            f"need at least {MINIMUM_CONTRAST}:1"
        )


def check_helix(path: pathlib.Path, failures: list[str]) -> None:
    theme = tomllib.loads(path.read_text())
    palette = theme["palette"]
    canvas = resolve(theme["ui.background"]["bg"], palette)
    for name, style in theme.items():
        if name in NON_TEXT_HELIX_STYLES:
            continue
        if not isinstance(style, dict) or "fg" not in style:
            continue
        foreground = resolve(style["fg"], palette)
        background = resolve(style.get("bg", canvas), palette)
        require_contrast(f"{path.name}: {name}", foreground, background, failures)


def check_rio(path: pathlib.Path, failures: list[str]) -> None:
    colours = tomllib.loads(path.read_text())["colors"]
    background = colours["background"]
    for name, foreground in colours.items():
        if name == "background":
            continue
        require_contrast(f"{path.name}: {name}", foreground, background, failures)


def main() -> int:
    failures: list[str] = []
    for path in sorted((ROOT / "themes").glob("*.toml")):
        if path.name.startswith("helix-"):
            check_helix(path, failures)
        elif path.name.startswith("rio-"):
            check_rio(path, failures)
        else:
            failures.append(f"{path}: unsupported theme format; add a contrast checker")
    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    print("All theme text/background pairs meet WCAG AA (4.5:1).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
