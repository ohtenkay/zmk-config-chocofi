import argparse
import os
from pathlib import Path
import shlex
import subprocess

import yaml


parser = argparse.ArgumentParser(description="Build keyboard firmware from build.yaml")
parser.add_argument("side", choices=["left", "right", "all"], nargs="?", default="all")
args = parser.parse_args()
root = Path(os.environ["ZMK_CONFIG_ROOT"])
workspace = root / ".zmk"
if not (workspace / "zephyr/CMakeLists.txt").is_file():
    parser.error("Sources are missing. Run zmk-setup first.")

matrix = yaml.safe_load((root / "build.yaml").read_text())["include"]
for side in (["left", "right"] if args.side == "all" else [args.side]):
    targets = [t for t in matrix if f"corne_{side}" in t.get("shield", "").split()]
    if len(targets) != 1:
        parser.error(f"Expected exactly one corne_{side} target in build.yaml")
    target = targets[0]
    subprocess.run(
        [
            "west", "build", "-p", "always",
            "-s", str(workspace / "zmk/app"),
            "-d", str(root / "build" / side),
            "-b", target["board"],
            *(["-S", target["snippet"]] if "snippet" in target else []),
            "--", f"-DSHIELD={target['shield']}",
            f"-DZMK_CONFIG={root / 'config'}",
            f"-DZMK_EXTRA_MODULES={root}",
            *shlex.split(target.get("cmake-args", "")),
        ],
        cwd=workspace,
        check=True,
    )
    print(f"Firmware: {root / 'build' / side / 'zephyr/zmk.uf2'}", flush=True)
