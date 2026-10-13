{ pkgs, config, inputs, ... }:
let
  # ZMK v0.3 uses Zephyr 3.5, which needs CMake 3 and an older ARM compiler.
  toolchain = import inputs.zmk-toolchain { system = pkgs.stdenv.hostPlatform.system; };
  python = toolchain.python3.withPackages (ps: with ps; [
    west pyelftools pyyaml pykwalify canopen packaging progress psutil
    pylink-square pyserial requests anytree intelhex protobuf grpcio-tools
  ]);
in
{
  packages = with pkgs; [
    python git toolchain.cmake ninja gnumake gperf dtc toolchain.gcc-arm-embedded util-linux
  ];

  env = {
    ZMK_CONFIG_ROOT = config.devenv.root;
    ZEPHYR_BASE = "${config.devenv.root}/.zmk/zephyr";
    Zephyr_DIR = "${config.devenv.root}/.zmk/zephyr/share/zephyr-package/cmake";
    ZEPHYR_TOOLCHAIN_VARIANT = "cross-compile";
    CROSS_COMPILE = "${toolchain.gcc-arm-embedded}/bin/arm-none-eabi-";
  };

  scripts.zmk-setup.exec = ''
    set -euo pipefail
    mkdir -p "$ZMK_CONFIG_ROOT/.zmk/config"
    cp "$ZMK_CONFIG_ROOT/config/west.yml" "$ZMK_CONFIG_ROOT/.zmk/config/west.yml"
    cd "$ZMK_CONFIG_ROOT/.zmk"
    if [[ ! -d .west ]]; then
      west init -l config
    fi
    west update --narrow --fetch-opt=--depth=1
  '';

  scripts.zmk-build.exec = ''
    exec python ${./scripts/build.py} "$@"
  '';

  scripts.zmk-flash.exec = builtins.readFile ./scripts/flash.sh;
}
