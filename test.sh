#!/bin/bash

set -euo pipefail

# -----------------------------------------------------------------
# Work relative to the script directory
BASH_SOURCE_TOP="${BASH_SOURCE[0]:-${0}}"

if ! cd -- "$(dirname -- "${BASH_SOURCE_TOP}")" > /dev/null 2>&1; then
    echo "error: failed to 'cd' to the script directory!" >&2
    exit 1
fi

# -----------------------------------------------------------------
# Use run.sh to execute the script in the proper environment
ISAAC_SIM_EXAMPLES="sdks/vendor/isaacsim/source/standalone_examples"

./run.sh "${ISAAC_SIM_EXAMPLES}/testing/isaacsim.core.api/test_time_stepping.py"
./run.sh "${ISAAC_SIM_EXAMPLES}/testing/isaacsim.simulation_app/test_headless_no_rendering.py"
