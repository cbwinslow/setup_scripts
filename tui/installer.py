#!/usr/bin/env python3
import curses
import subprocess
import yaml
from pathlib import Path

CONFIG = Path(__file__).parent.parent / "scripts" / "config" / "package_sets.yml"


def load_sets():
    with CONFIG.open() as f:
        return yaml.safe_load(f)


def run_script(script):
    subprocess.run(["bash", script], check=True)


def main(stdscr):
    curses.curs_set(0)
    sets = load_sets()
    options = list(sets.keys())
    idx = 0
    while True:
        stdscr.clear()
        stdscr.addstr(0, 0, "Select package set (q to quit, enter to run):")
        for i, opt in enumerate(options):
            mode = curses.A_REVERSE if i == idx else curses.A_NORMAL
            stdscr.addstr(i + 1, 0, opt, mode)
        key = stdscr.getch()
        if key in (curses.KEY_UP, ord('k')):
            idx = (idx - 1) % len(options)
        elif key in (curses.KEY_DOWN, ord('j')):
            idx = (idx + 1) % len(options)
        elif key in (curses.KEY_ENTER, ord('\n')):
            for script in sets[options[idx]]:
                run_script(script)
            stdscr.addstr(len(options) + 2, 0, "Done. Press any key.")
            stdscr.getch()
        elif key in (ord('q'), 27):
            break


if __name__ == "__main__":
    curses.wrapper(main)
