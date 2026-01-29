#!/bin/bash

# -----------------------------------------------------------------
# Work relative to the script directory
BASH_SOURCE_TOP="${BASH_SOURCE[0]:-${0}}"
# shellcheck disable=SC2034  # THIS is used by sourced _utils.sh
THIS=$(basename -- "${BASH_SOURCE_TOP}")

if ! cd -- "$(dirname -- "${BASH_SOURCE_TOP}")" > /dev/null 2>&1; then
    echo "error: failed to 'cd' to the script directory!" >&2
    exit 1
fi

# -----------------------------------------------------------------
# Source utilities
# shellcheck disable=SC1091
source ../_utils.sh

# =================================================================
print_script_header "Building Isaac Sim"
# -----------------------------------------------------------------

# -----------------------------------------------------------------
# Check requirements
require_commands gcc g++ update-alternatives
require_env_vars GIT_ROOT_DIR INSTALL_TMP_DIR
require_sudo

ISAACSIM_PATH="${GIT_ROOT_DIR}/sdks/vendor/isaacsim"

# -----------------------------------------------------------------
# NVIDIA Isaac Sim
run_command sudo update-alternatives --set gcc /usr/bin/gcc-11
run_command_on_exit sudo update-alternatives --auto gcc
run_command gcc --version

run_command sudo update-alternatives --set g++ /usr/bin/g++-11
run_command_on_exit sudo update-alternatives --auto g++
run_command g++ --version

cd "${ISAACSIM_PATH}" || exit 1

run_command ./build.sh

cd - > /dev/null || exit 1

# -----------------------------------------------------------------
# Link Isaac Sim release from root of repo
cd "${GIT_ROOT_DIR}" || exit 1

run_command ln -sfn "sdks/vendor/isaacsim/_build/linux-aarch64/release" "_isaac_sim"

cd - > /dev/null || exit 1

# -----------------------------------------------------------------
print_done
# =================================================================
