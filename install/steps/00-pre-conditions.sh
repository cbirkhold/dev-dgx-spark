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
print_script_header "Checking pre-conditions"
# -----------------------------------------------------------------

if is_dry_run && [[ "${IGNORE_PRE_CONDITIONS:-0}" == "1" ]]; then
    print_warning "Skipping pre-condition checks due to DRY_RUN=1 and IGNORE_PRE_CONDITIONS=1"
    exit 0
fi

# -----------------------------------------------------------------
# Check OS
if [ "$(uname -s)" != "Linux" ]; then
    print_error "OS must be Linux (current: $(uname -s))"
    exit 1
fi

# -----------------------------------------------------------------
# Check architecture
if [ "$(uname -m)" != "aarch64" ]; then
    print_error "Architecture must be aarch64 (current: $(uname -m))"
    exit 1
fi

# -----------------------------------------------------------------
# Check user has sudo
require_sudo

# -----------------------------------------------------------------
print_done
# =================================================================
