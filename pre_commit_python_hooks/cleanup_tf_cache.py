from __future__ import annotations
import argparse
import re
import os
import shutil


PASS = 0
FAIL = 1


def main(argv: Sequence[str] | None = None) -> int:
    ISSUE = ""
    parser = argparse.ArgumentParser()
    parser.add_argument("filenames", nargs="*", help="Filenames to fix")
    args = parser.parse_args(argv)

    for arg in args.filenames:
        folder = re.search("(.*/).*.tf", arg)

        tf_cache_location = folder.group(1) + ".terraform"
        tf_lock = folder.group(1) + ".terraform.lock.hcl"
        if not os.path.isdir(tf_cache_location):
            ISSUE = "Failed"
            print(tf_cache_location)
            print(ISSUE)
        else:
            shutil.rmtree(tf_cache_location)
            os.remove(tf_lock)

    if ISSUE != "":
        return FAIL
    else:
        return PASS


if __name__ == "__main__":
    raise SystemExit(main())
