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
# Check if running in the correct virtual environment
if [[ "${VIRTUAL_ENV_PROMPT:-}" != "(dev-dgx-spark)"* ]]; then
    C_YELLOW=$(tput setaf 3)
    C_RESET=$(tput sgr0)

    echo "${C_YELLOW}warning: Expected to run in dev-dgx-spark virtual environment!${C_RESET}" >&2
fi

# -----------------------------------------------------------------
# Execute script
exec python "$@"
