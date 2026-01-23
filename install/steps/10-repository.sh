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
print_script_header "Initializing repository (lfs, submodules, ...)"
# -----------------------------------------------------------------

# -----------------------------------------------------------------
# Check requirements
require_commands git
require_env_vars GIT_ROOT_DIR

# -----------------------------------------------------------------
# Git
print_section "Initializing Git submodules"

run_command git submodule update --init --recursive

print_section "Initializing Git LFS"

cd "${GIT_ROOT_DIR}/sdks/vendor/isaaclab" || exit 1
run_command git lfs install
run_command git lfs pull
cd - > /dev/null || exit 1

cd "${GIT_ROOT_DIR}/sdks/vendor/isaacsim" || exit 1
run_command git lfs install
run_command git lfs pull
cd - > /dev/null || exit 1

# -----------------------------------------------------------------
print_done
# =================================================================
