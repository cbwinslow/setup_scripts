#!/usr/bin/env python3
import argparse
import subprocess
import yaml
from pathlib import Path

CONFIG = Path(__file__).parent / "scripts" / "config" / "package_sets.yml"


def load_sets():
    with CONFIG.open() as f:
        return yaml.safe_load(f)


def run_script(script: str) -> None:
    subprocess.run(["bash", script], check=True)


def main():
    parser = argparse.ArgumentParser(
        description="Install groups of software defined in package_sets.yml"
    )
    parser.add_argument(
        "sets", nargs="+", help="Package set names to install (e.g., python docker)"
    )
    args = parser.parse_args()

    sets = load_sets()
    for name in args.sets:
        if name not in sets:
            print(f"Unknown package set: {name}")
            continue
        for script in sets[name]:
            run_script(script)


if __name__ == "__main__":
    main()
