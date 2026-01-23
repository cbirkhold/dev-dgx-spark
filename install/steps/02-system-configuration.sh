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
print_script_header "System-wide configuration"
# -----------------------------------------------------------------

# -----------------------------------------------------------------
# Check requirements
require_commands cp sysctl
require_env_vars INSTALL_TMP_DIR
require_sudo

# -----------------------------------------------------------------
# Install packages
print_section "Increasing fs.inotify limits"

# Range 50-69 is for local admin customizations
SYSCTL_CONFIG="60-inotify-dev-dgx-spark.conf"
SYSCTL_CONFIG_TMP="${INSTALL_TMP_DIR}/${SYSCTL_CONFIG}"

# Ensure directory and remove old file
mkdir -p "${INSTALL_TMP_DIR}"
rm -f "${SYSCTL_CONFIG_TMP}"

{
    echo "fs.inotify.max_user_watches=524288"
    echo "fs.inotify.max_user_instances=1024"
} > "${SYSCTL_CONFIG_TMP}"

run_command sudo cp "${SYSCTL_CONFIG_TMP}" "/etc/sysctl.d/${SYSCTL_CONFIG}"
run_command sudo sysctl -p "/etc/sysctl.d/${SYSCTL_CONFIG}"

# Keep as read-only for the record
chmod 400 "${SYSCTL_CONFIG_TMP}"

# -----------------------------------------------------------------
print_done
# =================================================================
