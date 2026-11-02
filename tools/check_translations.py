"""Check every shipped catalog for coverage and compatible formatting."""

import json
import re
from pathlib import Path

from update_translations import ROOT, collect_messages


def read_catalog(path: Path):
    result = {}
    message = None
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith("msgid "):
            message = json.loads(line[6:])
        elif line.startswith("msgstr "):
            if message in result:
                raise ValueError(f"Duplicate message in {path}: {message!r}")
            result[message] = json.loads(line[7:])
    result.pop("", None)
    return result


def main():
    expected = set(collect_messages())
    for path in sorted((ROOT / "localization").glob("*.po")):
        catalog = read_catalog(path)
        assert set(catalog) == expected, (path.name, "Missing", expected - set(catalog),
                                          "Obsolete", set(catalog) - expected)
        for source, translated in catalog.items():
            assert translated, (path.name, "Empty translation", source)
            assert re.findall(r"%%|%[ds]", source) == re.findall(r"%%|%[ds]", translated), (
                path.name, "Incompatible placeholders", source)
            assert source.count("\n") == translated.count("\n"), (
                path.name, "Incompatible line breaks", source)
            prefix = re.match(r"^\s*", source)[0]
            assert translated.startswith(prefix), (path.name, "Missing whitespace prefix", source)
        print(f"{path.name}: {len(catalog)} complete, format-compatible translations")


if __name__ == "__main__":
    main()
