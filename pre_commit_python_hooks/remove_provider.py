from __future__ import annotations
import argparse
import re
import os
import pathlib


PASS = 0
FAIL = 1


def main(argv: Sequence[str] | None = None) -> int:
    ISSUE = ""
    parser = argparse.ArgumentParser()
    parser.add_argument("filenames", nargs="*", help="Filenames to fix")
    args = parser.parse_args(argv)

    for arg in args.filenames:
        folder = re.search("(.*/).*.tf", arg)

        provider_location = folder.group(1) + "provider.tf"
        if not os.path.isfile(provider_location):
            ISSUE = "Failed"

            print(f"{ISSUE} theres no proider.tf")
        else:
            os.remove(provider_location)

    if ISSUE != "":
        return FAIL
    else:
        return PASS


if __name__ == "__main__":
    raise SystemExit(main())
