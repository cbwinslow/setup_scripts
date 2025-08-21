#!/usr/bin/env python3
import argparse
import subprocess
import yaml
from pathlib import Path

CONFIG = Path(__file__).parent / "scripts" / "config" / "package_sets.yml"


def load_sets():
    """
    Load package set definitions from the CONFIG YAML file and return the parsed content.
    
    Returns:
        The result of `yaml.safe_load` on CONFIG (typically a dict mapping set names to lists of script paths).
    
    Raises:
        OSError: If the CONFIG file cannot be opened (e.g., missing or permission error).
        yaml.YAMLError: If the file cannot be parsed as valid YAML.
    """
    with CONFIG.open() as f:
        return yaml.safe_load(f)


def run_script(script: str) -> None:
    """
    Execute a shell script file using Bash.
    
    Runs the given script path with `bash` and requires a zero exit status. The `script` argument should be a path to an executable shell script or a file containing shell commands.
    
    Raises:
        subprocess.CalledProcessError: If the invoked script exits with a non-zero status.
    """
    subprocess.run(["bash", script], check=True)


def main():
    """
    Entry point for the CLI that installs named package sets defined in the YAML config.
    
    Parses command-line arguments (one or more package set names) and for each name:
    - If the name is not present in the loaded sets, prints "Unknown package set: <name>" and continues.
    - If present, runs each script listed for that set using run_script(script).
    
    Behavior:
    - Expects a positional argument "sets" (one or more package set names).
    - Loads package sets via load_sets() and executes scripts sequentially via run_script().
    - Does not catch exceptions from load_sets() (e.g., file I/O or YAML parsing errors) or from run_script() (e.g., subprocess.CalledProcessError); those will propagate.
    """
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
