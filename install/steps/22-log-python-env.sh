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
print_script_header "Logging Python environment"
# -----------------------------------------------------------------

# -----------------------------------------------------------------
# Check requirements
require_env_vars GIT_ROOT_DIR INSTALL_TMP_DIR

ISAACLAB_PATH="${GIT_ROOT_DIR}/sdks/vendor/isaaclab"

# -----------------------------------------------------------------
# Python info
run_command "${ISAACLAB_PATH}/isaaclab.sh" -p -c '
import sys
import site

venv = sys.prefix if sys.prefix != sys.base_prefix else "no"

print(f"Python: v{sys.version.split()[0]} {sys.executable}")
print(f"Python venv: {venv}")
print("Python user site packages:", site.getusersitepackages())
print("Python site packages:\n   " + "\n   ".join(filter(None, site.getsitepackages())))
print("Python sys.path:\n   " + "\n   ".join(filter(None, sys.path)))
'

# PyTorch info
run_command "${ISAACLAB_PATH}/isaaclab.sh" -p -c '
import torch

cuda = ("v" + torch.version.cuda + " (" + ", ".join(torch.cuda.get_arch_list()) + ")") if torch.cuda.is_available() else "disabled"
cudnn = ("v" + ".".join(str(torch.backends.cudnn.version())[:2])) if torch.backends.cudnn.enabled else "disabled"

print(f"PyTorch: v{torch.__version__}")
print(f"CUDA: {cuda}")
print(f"cuDNN: {cudnn}")
'

# Save package list
ISAACLAB_PIP_LIST="${INSTALL_TMP_DIR}/isaaclab-pip-list.txt"

# Ensure directory and remove old file
mkdir -p "${INSTALL_TMP_DIR}"
rm -f "${ISAACLAB_PIP_LIST}"

run_command "${ISAACLAB_PATH}/isaaclab.sh" -p -m pip list > "${ISAACLAB_PIP_LIST}"

# Keep as read-only for the record
chmod 400 "${ISAACLAB_PIP_LIST}"

# -----------------------------------------------------------------
print_done
# =================================================================
