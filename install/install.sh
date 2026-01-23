#!/bin/bash

# ------------------------------------------------------------------
# Usage: ./install.sh [--dry-run]
# -----------------------------------------------------------------

# -----------------------------------------------------------------
# Check for dry-run mode
if [[ "${1:-}" == "--dry-run" ]]; then
    export DRY_RUN=1
fi

# -----------------------------------------------------------------
# Work relative to the script directory
BASH_SOURCE_TOP="${BASH_SOURCE[0]:-${0}}"

if ! cd -- "$(dirname -- "${BASH_SOURCE_TOP}")" > /dev/null 2>&1; then
    echo "error: failed to 'cd' to the script directory!" >&2
    exit 1
fi

# -----------------------------------------------------------------
# Source utilities
# shellcheck disable=SC1091
source ./_utils.sh

# -----------------------------------------------------------------
# Check requirements
require_commands reboot sleep
require_env_vars INSTALL_TMP_DIR
require_sudo

# -----------------------------------------------------------------
# Installation steps
# -----------------------------------------------------------------

STEP_PATTERN="[0-9]*-*.sh"

# -----------------------------------------------------------------
# STEP_SCRIPT
mkdir -p "${INSTALL_TMP_DIR}"
PROGRESS_FILE="${INSTALL_TMP_DIR}/progress"

if [[ -f "${PROGRESS_FILE}" ]]; then
    STEP_SCRIPT=$(cat "${PROGRESS_FILE}")
else
    STEP_SCRIPT=$(find ./steps -maxdepth 1 -type f -name "${STEP_PATTERN}" | sort | head -n 1)
fi

# -----------------------------------------------------------------
# Run step scripts
while [[ -n "${STEP_SCRIPT}" ]]; do
    # Check if we have a modified /etc/environment
    if [[ -f "${INSTALL_ETC_ENVIRONMENT}" ]]; then
        # shellcheck disable=SC1090
        set -a && source "${INSTALL_ETC_ENVIRONMENT}" && set +a
    fi

    "${STEP_SCRIPT}"

    # Find next STEP_SCRIPT
    NEXT_STEP_SCRIPT=$(find ./steps -maxdepth 1 -type f -name "${STEP_PATTERN}" | sort | grep -A 1 "^${STEP_SCRIPT}$" | tail -1)

    # Last step will not return a new value. No step will be empty.
    if [[ "${NEXT_STEP_SCRIPT}" == "${STEP_SCRIPT}" ]] || [[ -z "${NEXT_STEP_SCRIPT}" ]]; then
        STEP_SCRIPT=""
    else
        STEP_SCRIPT="${NEXT_STEP_SCRIPT}"
    fi

    # Save progress before potential reboot
    echo "${STEP_SCRIPT}" > "${PROGRESS_FILE}"

    # Check if step requested a reboot
    if [[ -f "${INSTALL_REBOOT_FILE}" ]]; then
        unlink "${INSTALL_REBOOT_FILE}"

        # In non-interactive mode, skip reboot
        if [[ ! -t 0 ]]; then
            echo "warning: Skipping reboot in non-interactive mode!"
            continue
        fi

        echo "The system needs to reboot to continue the installation."
        read -p "Do you want to reboot now? (y/N): " -n 1 -r
        echo

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            if [[ -n "${STEP_SCRIPT}" ]]; then
                echo "${C_YELLOW}Run this script again to continue after manual reboot!${C_RESET}"
            fi

            exit 0
        fi

        sleep_with_countdown "Rebooting in" 5
        sudo reboot
        exit 0
    fi
done

# Installation complete
echo "${C_GREEN}Installation complete${C_RESET}"
