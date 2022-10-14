from __future__ import annotations
import argparse
import re
import os
from pathlib import Path

PASS = 0
FAIL = 1


def main(argv: Sequence[str] | None = None) -> int:
    ISSUE = ""
    parser = argparse.ArgumentParser()
    parser.add_argument("filenames", nargs="*", help="Filenames to fix")
    args = parser.parse_args(argv)
    # dir(args)

    for arg in args.filenames:
        folder = re.search("(.*/).*.tf", arg)
        # print(folder.group(1))
        data = ""
        path = Path(os.getcwd())
        root_path = str(path.absolute())

        hcl_path = re.search("(.*/gcp-terraform/?).*", root_path)

        hcl = hcl_path.group(1) + "/folders/terragrunt.hcl"

        with open(hcl, "r+") as file:
            # lines = file.readlines()
            in_recording_mode = False
            for line in file:
                # print(line)
                if not in_recording_mode:
                    if line.startswith("    terraform {"):

                        data += line

                        in_recording_mode = True
                elif line.startswith("  EOF"):
                    break
                    print(line)
                    in_recording_mode = False
                else:
                    data += line

        print(data)
        provider_location = folder.group(1) + "provider.tf"
        with open(provider_location, "w+") as provider:
            provider.write(data)
        provider.close()

    if ISSUE != "":
        return FAIL
    else:
        return PASS


if __name__ == "__main__":
    raise SystemExit(main())
