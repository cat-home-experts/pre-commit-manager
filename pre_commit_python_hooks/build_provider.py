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
        print(folder.group(1))
        data = ""
        path = Path(os.getcwd())
        rootpath = path.absolute

        hclpath = re.search("(.*/gcp-terraform/).*", rootpath)
        hcl = hclpath + "folders/terragrunt.hcl"
        with open(hcl, "r+") as file:
            # lines = file.readlines()
            inRecordingMode = False
            for line in file:
                # print(line)
                if not inRecordingMode:
                    if line.startswith("    terraform {"):

                        data += line

                        inRecordingMode = True
                elif line.startswith("  EOF"):
                    break
                    print(line)
                    inRecordingMode = False
                else:
                    data += line

        print(data)
        providerLocation = folder.group(1) + "provider.tf"
        with open(providerLocation, "w+") as provider:
            provider.write(data)
        provider.close()

    if ISSUE != "":
        return FAIL
    else:
        return PASS


if __name__ == "__main__":
    raise SystemExit(main())
