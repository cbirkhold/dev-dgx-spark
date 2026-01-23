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
print_script_header "Installing Isaac Lab"
# -----------------------------------------------------------------

# -----------------------------------------------------------------
# Check requirements
require_env_vars GIT_ROOT_DIR

ISAACLAB_PATH="${GIT_ROOT_DIR}/sdks/vendor/isaaclab"

# -----------------------------------------------------------------
# NVIDIA Isaac Lab
print_section "Installing Isaac Lab"

cd "${ISAACLAB_PATH}" || exit 1

# Link Isaac Lab
run_command ln -sfn "../isaacsim/_build/linux-aarch64/release" "_isaac_sim"

# Install Isaac Lab (and dependencies) in the Isaac Sim setup
run_command ./isaaclab.sh -p -m pip install --upgrade pip
run_command ./isaaclab.sh --install

cd - > /dev/null || exit 1

# -----------------------------------------------------------------
print_done
# =================================================================
