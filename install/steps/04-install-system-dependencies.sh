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
print_script_header "Installing system-wide dependencies"
# -----------------------------------------------------------------

# -----------------------------------------------------------------
# Check requirements
require_commands apt update-alternatives
require_sudo

# -----------------------------------------------------------------
# Install packages
print_section "Updating package catalog"

run_command sudo apt update

print_section "Installing packages"

run_command sudo apt -y install \
    build-essential \
    cmake \
    g++-11 \
    gcc-11 \
    git \
    git-lfs \
    python3

run_command sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 110
run_command sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 130

run_command sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 110
run_command sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 130

# -----------------------------------------------------------------
print_done
# =================================================================
