from __future__ import annotations

import argparse
import os
import pathlib
import subprocess
from typing import List
import re

PASS = 0
FAIL = 1


def check_modules(arg: str, folder: pathlib.Path) -> None:
    for file_path in folder.rglob("*.tf"):
        if ".terraform" in str(file_path.resolve()):
            continue
        with open(file_path.resolve(), "r") as file:
            if arg in file.read():
                print(
                    "These Modules have a dependancy on the module you have changed, please test these modules and/or bump their version"
                )
                print(file_path.resolve())


def main(argv: List[str] | None = None) -> int:
    ISSUE = ""
    parser = argparse.ArgumentParser()
    parser.add_argument("filenames", nargs="*", help="Filenames to fix")
    args = parser.parse_args(argv)
    get_root_folder = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
    )
    root_folder = get_root_folder.stdout.replace("\n", "")
    print(root_folder)
    files_folder = pathlib.Path(root_folder).joinpath("checkatrade")
    gcp_folder = pathlib.Path(root_folder).joinpath("gcp")
    pattern = re.compile(r"\.\./|\.\./\.\./")
    for arg in args.filenames:
        arg = os.path.dirname(arg)
        arg = pattern.sub("", arg)
        print(arg)

        checka = check_modules(arg, files_folder)
        if checka != "":
            ISSUE = "notice"
        gcp = check_modules(arg, gcp_folder)
        print(gcp)
        if gcp != "":
            ISSUE = "notice"

    if ISSUE != "":
        return FAIL
    else:
        return PASS


if __name__ == "__main__":
    raise SystemExit(main())
