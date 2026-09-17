#!/usr/bin/env python3
"""Check WCAG AA contrast for the text colours exposed by bundled themes."""

from __future__ import annotations

import json
import pathlib
import sys
import tomllib

MINIMUM_CONTRAST = 4.5  # WCAG 2 AA for normal-sized text
ROOT = pathlib.Path(__file__).resolve().parents[1]
# These are line and wrap markers rather than textual content. They must stay
# subtle so they do not compete with the editor text.
NON_TEXT_HELIX_STYLES = {"ui.virtual.indent-guide", "ui.virtual.wrap"}
JJUI_SELECTION_FOREGROUNDS = {
    "#f8f8f2",
    "#a6b0b8",
    "#72afe4",
    "#8be0fd",
    "#46bd72",
    "#ca94ff",
    "#ffb3b5",
    "#ff8878",
    "#e6db74",
    "#f0cc04",
}


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


def check_jjui(path: pathlib.Path, failures: list[str]) -> None:
    colours = tomllib.loads(path.read_text())["colors"]
    canvas = colours["text"]["bg"]
    for name, style in colours.items():
        if not isinstance(style, dict) or "fg" not in style:
            continue
        require_contrast(f"{path.name}: {name}", style["fg"], style.get("bg", canvas), failures)
    selected_background = colours["revisions:selected"]["bg"]
    for foreground in JJUI_SELECTION_FOREGROUNDS:
        require_contrast(
            f"{path.name}: inherited jj colour {foreground} on selection",
            foreground,
            selected_background,
            failures,
        )


def check_yazi(path: pathlib.Path, failures: list[str]) -> None:
    theme = tomllib.loads(path.read_text())
    canvas = theme["app"]["overall"]["bg"]
    for section, styles in theme.items():
        if not isinstance(styles, dict):
            continue
        for name, style in styles.items():
            definitions = style if isinstance(style, list) else [style]
            for index, definition in enumerate(definitions):
                if not isinstance(definition, dict) or "fg" not in definition:
                    continue
                suffix = f"[{index}]" if isinstance(style, list) else ""
                require_contrast(
                    f"{path.name}: {section}.{name}{suffix}",
                    definition["fg"],
                    definition.get("bg", canvas),
                    failures,
                )


def check_glow(path: pathlib.Path, failures: list[str]) -> None:
    style = json.loads(path.read_text())
    canvas = style["document"]["background_color"]
    for name, definition in style.items():
        if not isinstance(definition, dict) or "color" not in definition:
            continue
        require_contrast(
            f"{path.name}: {name}", definition["color"], definition.get("background_color", canvas), failures
        )


def check_pi(path: pathlib.Path, failures: list[str]) -> None:
    theme = json.loads(path.read_text())
    palette = theme.get("vars", {})
    colours = theme["colors"]

    def resolve_pi(colour: str | int) -> str:
        if isinstance(colour, int):
            raise ValueError(f"256-colour values are not supported by the contrast checker: {colour}")
        return palette.get(colour, colour)

    background = resolve_pi(palette["background"])
    for name in (
        "accent",
        "border",
        "borderAccent",
        "success",
        "error",
        "warning",
        "muted",
        "dim",
        "text",
        "thinkingText",
        "toolTitle",
        "toolOutput",
        "mdHeading",
        "mdLink",
        "mdLinkUrl",
        "mdCode",
        "mdCodeBlock",
        "mdCodeBlockBorder",
        "mdQuote",
        "mdQuoteBorder",
        "mdHr",
        "mdListBullet",
        "toolDiffAdded",
        "toolDiffRemoved",
        "toolDiffContext",
        "syntaxComment",
        "syntaxKeyword",
        "syntaxFunction",
        "syntaxVariable",
        "syntaxString",
        "syntaxNumber",
        "syntaxType",
        "syntaxOperator",
        "syntaxPunctuation",
    ):
        require_contrast(f"{path.name}: {name}", resolve_pi(colours[name]), background, failures)

    for foreground, surface in (
        ("userMessageText", "userMessageBg"),
        ("customMessageText", "customMessageBg"),
        ("customMessageLabel", "customMessageBg"),
        ("toolOutput", "toolPendingBg"),
        ("toolOutput", "toolSuccessBg"),
        ("toolOutput", "toolErrorBg"),
    ):
        require_contrast(
            f"{path.name}: {foreground} on {surface}",
            resolve_pi(colours[foreground]),
            resolve_pi(colours[surface]),
            failures,
        )

    require_contrast(
        f"{path.name}: searchMatchText on searchMatchBg",
        resolve_pi(colours["searchMatchText"]),
        resolve_pi(colours["searchMatchBg"]),
        failures,
    )


def check_herdr(path: pathlib.Path, failures: list[str]) -> None:
    colours = tomllib.loads(path.read_text())["theme"]["custom"]
    text = colours["text"]
    for name in ("surface_dim", "sidebar_bg", "panel_bg", "active_row_bg", "selection_bg"):
        require_contrast(f"{path.name}: text on {name}", text, colours[name], failures)
    for name in ("accent", "red", "green", "blue", "yellow"):
        require_contrast(f"{path.name}: {name}", colours[name], colours["panel_bg"], failures)


def main() -> int:
    failures: list[str] = []
    for path in sorted((ROOT / "themes").glob("*.toml")):
        if path.name.startswith("helix-"):
            check_helix(path, failures)
        elif path.name.startswith("jjui-"):
            check_jjui(path, failures)
        elif path.name.startswith("rio-"):
            check_rio(path, failures)
        elif path.name.startswith("yazi-"):
            check_yazi(path, failures)
        else:
            failures.append(f"{path}: unsupported theme format; add a contrast checker")
    check_herdr(ROOT / "herdr.toml", failures)
    check_glow(ROOT / "themes/glow-lucario.json", failures)
    check_pi(ROOT / "themes/pi-lucario.json", failures)
    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    print("All theme text/background pairs meet WCAG AA (4.5:1).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
