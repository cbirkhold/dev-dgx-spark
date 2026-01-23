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
print_script_header "Create Python venv (virtual environment)"
# -----------------------------------------------------------------

# -----------------------------------------------------------------
# Check requirements
require_commands cat
require_env_vars GIT_ROOT_DIR

ISAACLAB_PATH="${GIT_ROOT_DIR}/sdks/vendor/isaaclab"
ISAAC_PATH="${ISAACLAB_PATH}/_isaac_sim"
VENV_DIR="${GIT_ROOT_DIR}/.venv"

# -----------------------------------------------------------------
# Track the hashes of Isaac Sim scripts we are emulating
print_section "Checking Isaac Sim script hashes"

PYTHON_SH_HASH=$(shasum -a 256 "${ISAAC_PATH}/python.sh" | cut -d ' ' -f 1)
SETUP_PYTHON_ENV_HASH=$(shasum -a 256 "${ISAAC_PATH}/setup_python_env.sh" | cut -d ' ' -f 1)

if [ "${PYTHON_SH_HASH}" != "0737e3da91c91b866b231002498bf2430e9268011a2110caa10d369270ba3a79" ]; then
    echo "warning: unexpected hash for Isaac Sim python.sh script!" >&2
    echo "  expected: 0737e3da91c91b866b231002498bf2430e9268011a2110caa10d369270ba3a79" >&2
    echo "  actual:   ${PYTHON_SH_HASH}" >&2
fi

if [ "${SETUP_PYTHON_ENV_HASH}" != "532fa92d31e3df1660359d0051da2f198c9625963b4cf80c2d62c1c075b3a293" ]; then
    echo "warning: unexpected hash for Isaac Sim setup_python_env.sh script!" >&2
    echo "  expected: 532fa92d31e3df1660359d0051da2f198c9625963b4cf80c2d62c1c075b3a293" >&2
    echo "  actual:   ${SETUP_PYTHON_ENV_HASH}" >&2
fi

# -----------------------------------------------------------------
# Create venv
print_section "Creating venv"

run_command "${ISAACLAB_PATH}/isaaclab.sh" -p -m venv --prompt "dev-dgx-spark" "${VENV_DIR}"
run_command ln -sfn "${VENV_DIR}/bin/activate" "${GIT_ROOT_DIR}/activate"

run_command source "${GIT_ROOT_DIR}/activate"

# Upgrade venv pip
run_command pip install --upgrade pip
# Install readline (NVIDIA Python 3.11 is built without readline)
run_command pip install gnureadline

run_command deactivate

# -----------------------------------------------------------------
# Amend venv
print_section "Amending venv"

# Append WITHOUT variable expansion
run_command cat >> "${VENV_DIR}/bin/activate" << 'VAR_SAFE_RESTORE'

# Save original deactivate function as _venv_deactivate
_venv_deactivate="$(declare -f deactivate)"
eval "${_venv_deactivate/deactivate/_venv_deactivate}"

# List of variables to manage
_VENV_MANAGED_VARS="CARB_APP_PATH EXP_PATH ISAAC_PATH LD_LIBRARY_PATH LD_PRELOAD PYTORCH_JIT"

deactivate () {
    # Restore state of variables
    for var in ${_VENV_MANAGED_VARS}; do
        old_var="_OLD_${var}"
        if [ -n "${!old_var+set}" ]; then
            export "${var}"="${!old_var}"
            unset "${old_var}"
        else
            unset "${var}"
        fi
    done

    # Call original deactivate
    _venv_deactivate "$@"
}

# Save state of variables
for var in ${_VENV_MANAGED_VARS}; do
    [ -n "${!var+set}" ] && declare "_OLD_${var}=${!var}"
done
VAR_SAFE_RESTORE

# Append WITH variable expansion
run_command cat >> "${VENV_DIR}/bin/activate" << SETUP_ENV

# -----------------------------------------------------------------
# Isaac Sim normally sets these variables when python.sh is used to
# invoke the Python interpreter.
# -----------------------------------------------------------------

export ISAAC_PATH="${ISAAC_PATH}"

# CARB_APP_PATH: (carbonite framework) Omniverse kit executable
export CARB_APP_PATH="${ISAAC_PATH}/kit"
export EXP_PATH="${ISAAC_PATH}/apps"

# Normally set by setup_python_env.sh (sourced from python.sh)
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}${ISAAC_PATH}/.:${ISAAC_PATH}/exts/isaacsim.robot.schema/plugins/lib:${ISAAC_PATH}/exts/isaacsim.robot_motion.lula/pip_prebundle:${ISAAC_PATH}/exts/isaacsim.asset.exporter.urdf/pip_prebundle:${ISAAC_PATH}/kit:${ISAAC_PATH}/kit/kernel/plugins:${ISAAC_PATH}/kit/libs/iray:${ISAAC_PATH}/kit/plugins:${ISAAC_PATH}/kit/plugins/bindings-python:${ISAAC_PATH}/kit/plugins/carb_gfx:${ISAAC_PATH}/kit/plugins/rtx:${ISAAC_PATH}/kit/plugins/gpu.foundation"

# LD_PRELOAD: libgomp (aarch64 req.) + libcarb (Isaac Sim req.)
export LD_PRELOAD="${LD_PRELOAD:+$LD_PRELOAD:}/lib/aarch64-linux-gnu/libgomp.so.1:${ISAAC_PATH}/kit/libcarb.so"

# Disable PyTorch JIT/nvrtc (pending sm_121 Blackwell support)
export PYTORCH_JIT="0"
SETUP_ENV

run_command cat > "${VENV_DIR}/lib/python3.11/site-packages/_isaacsim.pth" << ISAACSIM_PYTHONPATH
# -----------------------------------------------------------------
# Isaac Sim normally appends these paths to PYTHONPATH in
# setup_python_env.sh when python.sh is used to invoke the Python
# interpreter. We instead set them here as part of the venv.
#
# As the default site-packages directory is now the one from the
# venv, we must add the site directory of the Isaac Sim setup. We
# do not add the standard library as it is included by default.
# -----------------------------------------------------------------

import site; site.addsitedir("${ISAAC_PATH}/kit/python/lib/python3.11/site-packages")

${ISAAC_PATH}/python_packages
${ISAAC_PATH}/exts/isaacsim.simulation_app
${ISAAC_PATH}/extsDeprecated/omni.isaac.kit
${ISAAC_PATH}/kit/kernel/py
${ISAAC_PATH}/kit/plugins/bindings-python
${ISAAC_PATH}/exts/isaacsim.robot_motion.lula/pip_prebundle
${ISAAC_PATH}/exts/isaacsim.asset.exporter.urdf/pip_prebundle
${ISAAC_PATH}/extscache/omni.kit.pip_archive-0.0.0+69cbf6ad.la64.cp311/pip_prebundle
${ISAAC_PATH}/exts/omni.isaac.core_archive/pip_prebundle
${ISAAC_PATH}/exts/omni.isaac.ml_archive/pip_prebundle
${ISAAC_PATH}/exts/omni.pip.compute/pip_prebundle
${ISAAC_PATH}/exts/omni.pip.cloud/pip_prebundle

# Install gnureadline as readline (NVIDIA Python 3.11 is built without readline)
import gnureadline; import sys; sys.modules['readline'] = gnureadline
ISAACSIM_PYTHONPATH

# -----------------------------------------------------------------
print_done
# =================================================================
