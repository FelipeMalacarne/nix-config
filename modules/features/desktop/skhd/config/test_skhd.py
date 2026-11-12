"""Check rendered skhd chords, including reordered modifier duplicates."""

import pathlib
import re
import sys


def chords(text):
    seen = set()
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        chord, separator, _ = line.partition(":")
        assert separator, f"Missing command separator: {line}"
        modifiers, key = re.split(r"\s+-\s+", chord.strip(), maxsplit=1)
        normalized = (tuple(sorted(modifiers.replace(" ", "").split("+"))), key.strip())
        assert normalized not in seen, f"Duplicate skhd chord: {chord}"
        seen.add(normalized)
    return seen


def main():
    for duplicate in ("alt - 4 : a\nalt - 4 : b", "alt + shift - x : a\nshift + alt - x : b"):
        try:
            chords(duplicate)
        except AssertionError:
            pass
        else:
            raise AssertionError("Duplicate-chord regression fixture was not rejected")

    text = pathlib.Path(sys.argv[1]).read_text()
    chords(text)
    for binding in (
        'alt + shift - w : skhd -k "cmd - q"',
        "alt + ctrl - w : yabai -m window --resize top:0:-48",
        "alt + shift - x : yabai -m window --space next; yabai -m space --focus next",
        "alt + ctrl + shift - x : yabai -m space --mirror x-axis",
        "alt + shift - y : yabai -m space --mirror y-axis",
    ):
        assert binding in text, f"Missing preserved action: {binding}"
    print("skhd chords are unique and preserve the selected actions")


if __name__ == "__main__":
    main()
