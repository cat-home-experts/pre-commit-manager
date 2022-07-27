from __future__ import annotations
import argparse


PASS = 0
FAIL = 1


def main(argv: Sequence[str] | None = None) -> int:
    ISSUE = ""
    parser = argparse.ArgumentParser()
    parser.add_argument("filenames", nargs="*", help="Filenames to fix")
    args = parser.parse_args(argv)
    # print(args)

    for arg in args.filenames:
        with open(arg, "r+") as file:
            lines = file.readlines()

            for index, line in enumerate(lines):

                if "# tf:ignore" in line:
                    continue

                elif "source =" and "ref=latest" in line:
                    module = lines[index - 1].replace("{", "").strip("\n").strip(" ")
                    ISSUE = "Failed"
                    print(f"{arg}:{module} is using latest")
                # return FAIL
    if ISSUE != "":
        return FAIL
    else:
        return PASS


if __name__ == "__main__":
    raise SystemExit(main())
