# Chocofi ZMK config

Local builds use Nix and [devenv](https://devenv.sh/), with the same ZMK v0.3
manifest and nice!nano v2 + nice!view targets as GitHub Actions.

## Build

```sh
devenv shell
zmk-setup
zmk-build          # both halves
# or: zmk-build left / zmk-build right
```

`zmk-setup` downloads ZMK, Zephyr and modules into the ignored `.zmk/`
workspace. Run it again after changing `config/west.yml` or to update the
sources within the manifest's revisions. The first download can take a while.
Nix packages are pinned in `devenv.lock`; west revisions remain controlled by
`config/west.yml` (branches can move).

`zmk-build` reads `build.yaml`, uses the keymap and config in `config/`, and
builds each half from scratch. Firmware is written to
`build/left/zephyr/zmk.uf2` and `build/right/zephyr/zmk.uf2`.

## Flash

Connect **one half** over USB and double-tap its reset button to enter the
bootloader. Once the `NICENANO` drive is mounted, select the connected half:

```sh
zmk-flash left
# Connect the right half and double-tap reset:
zmk-flash right
```

On this machine, udiskie automatically mounts the bootloader drive.
The command detects mounted nice!nano bootloaders and checks the drive before
copying the UF2. If multiple drives are connected, it requires an explicit
path: `zmk-flash left /run/media/$USER/NICENANO`. You
must select the correct half; the bootloader cannot distinguish left from
right. The controller disconnects and restarts after accepting the firmware.
Flashing does not happen automatically when entering the environment or building.

References: [ZMK native setup](https://zmk.dev/docs/development/local-toolchain/setup/native)
and [building and flashing](https://zmk.dev/docs/development/local-toolchain/build-flash).
