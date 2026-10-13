set -euo pipefail
if [[ $# -lt 1 || $# -gt 2 || ( "$1" != left && "$1" != right ) ]]; then
  echo 'Usage: zmk-flash left|right [/path/to/NICENANO]' >&2
  exit 2
fi

firmware="$ZMK_CONFIG_ROOT/build/$1/zephyr/zmk.uf2"
if [[ ! -f "$firmware" ]]; then
  echo "Firmware is missing. Run zmk-build $1 first." >&2
  exit 1
fi

is_nice_nano() {
  [[ -f "$1/INFO_UF2.TXT" ]] && grep -Eiq '^Board-ID:.*(nice.?nano)' "$1/INFO_UF2.TXT"
}

if [[ $# == 2 ]]; then
  drive="$2"
else
  mounts="$(findmnt --json --list --output TARGET)"
  mapfile -d '' -t mountpoints < <(python -c 'import json, sys; sys.stdout.write("".join(fs["target"] + "\0" for fs in json.load(sys.stdin)["filesystems"]))' <<< "$mounts")
  drives=()
  for candidate in "${mountpoints[@]}"; do
    if is_nice_nano "$candidate"; then
      drives+=("$candidate")
    fi
  done
  if [[ ${#drives[@]} == 0 ]]; then
    echo 'No mounted nice!nano found. Connect one half, double-tap reset, and wait for it to mount.' >&2
    exit 1
  elif [[ ${#drives[@]} != 1 ]]; then
    echo 'Multiple nice!nano drives found. Connect only one half or specify its mount path:' >&2
    printf '  %s\n' "${drives[@]}" >&2
    exit 1
  fi
  drive="${drives[0]}"
fi

if ! is_nice_nano "$drive"; then
  echo 'Select the mounted nice!nano bootloader drive (double-tap reset).' >&2
  exit 1
fi

cp "$firmware" "$drive/zmk.uf2"
sync
echo "Flashed $1. The keyboard should restart automatically."
