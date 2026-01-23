# shellcheck shell=bash
# shellcheck disable=SC2034

# -----------------------------------------------------------------
# Usage: Source this file in other scripts: source ./utils.sh
# -----------------------------------------------------------------

# -----------------------------------------------------------------
# Exit on error and undefined variable
set -euo pipefail

# -----------------------------------------------------------------
# Colors
if [[ -z "${NO_COLOR:-}" ]] && [[ -t 1 ]]; then
  C_CYAN=$(tput setaf 6)
  C_GRAY=$(tput setaf 7)
  C_GREEN=$(tput setaf 2)
  C_MAGENTA=$(tput setaf 5)
  C_RED=$(tput setaf 1)
  C_YELLOW=$(tput setaf 3)
  C_RESET=$(tput sgr0)
else
  C_CYAN=""
  C_GRAY=""
  C_GREEN=""
  C_MAGENTA=""
  C_RED=""
  C_YELLOW=""
  C_RESET=""
fi

# -----------------------------------------------------------------
# Helper functions for common checks
is_dry_run() {
  [[ "${DRY_RUN:-0}" == "1" ]]
}

# -----------------------------------------------------------------
# Print script header with description
print_script_header() {
  local description="$1"

  echo "${C_CYAN}$(printf '%*s' $((${#THIS} + ${#description} + 3)) '' | tr ' ' '-')${C_RESET}"
  echo "${C_CYAN}[${THIS}] ${description}${C_RESET}"

  if is_dry_run; then
    echo "${C_YELLOW}Using DRY_RUN=1${C_RESET}"
  fi
}

print_done() {
  echo "${C_CYAN}[${THIS}] DONE${C_RESET}"
}

# -----------------------------------------------------------------
# Print section header
print_section() {
  local section="$1"
  echo "${C_MAGENTA}>>> ${section}${C_RESET}"
}

# -----------------------------------------------------------------
# Print info
print_info() {
  local message="$1"
  echo "${C_GRAY}info: ${message}${C_RESET}"
}

# -----------------------------------------------------------------
# Print warning
print_warning() {
  local message="$1"
  echo "${C_YELLOW}warning: ${message}${C_RESET}"
}

# -----------------------------------------------------------------
# Print error
print_error() {
  local message="$1"
  echo "${C_RED}error: ${message}${C_RESET}" >&2
}

# -----------------------------------------------------------------
# Sleep with countdown display
sleep_with_countdown()
{
  if is_dry_run; then
    return
  fi

  local message="$1"
  local countdown="$2"
  local i

  printf "%s..." "${message}"
  for ((i = countdown; i >= 1; i--)); do
    printf "\r\033[K%s... %ss" "${message}" "${i}"
    sleep 1
  done
  printf "\r\033[K%s... Done!\n" "${message}"
}

# -----------------------------------------------------------------
# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# -----------------------------------------------------------------
# Validate commands are available
require_commands() {
  if is_dry_run; then
    return
  fi

  local missing_commands=()

  for cmd in "$@"; do
    if ! command_exists "$cmd"; then
      missing_commands+=("$cmd")
    fi
  done

  if [ ${#missing_commands[@]} -ne 0 ]; then
    print_error "Missing required commands:"
    for cmd in "${missing_commands[@]}"; do
      print_error "  - $cmd"
    done
    exit 1
  fi
}

# -----------------------------------------------------------------
# Validate environment variable is set
require_env_vars() {
  local missing_vars=()

  for var_name in "$@"; do
    local var_value="${!var_name:-}"
    if [[ -z "$var_value" ]]; then
      missing_vars+=("$var_name")
    fi
  done

  if [ ${#missing_vars[@]} -ne 0 ]; then
    print_error "Missing required environment variables:"
    for var_name in "${missing_vars[@]}"; do
      print_error "  - $var_name"
    done
    exit 1
  fi
}

# -----------------------------------------------------------------
# Run command with dry-run support
run_command() {
  if is_dry_run; then
    echo "${C_GRAY}dry-run: $*${C_RESET}"
  else
    "$@"
  fi
}

# -----------------------------------------------------------------
# Retry command with dry-run support
retry_command() {
  if is_dry_run; then
    echo "${C_GRAY}dry-retry: $*${C_RESET}"
  else
    local n=0

    until [[ $n -ge 5 ]]; do
      "$@" && return 0
      n=$((n+1))
      sleep $((2**n))
    done

    return 1
  fi
}

# -----------------------------------------------------------------
# Check if running as specific user
require_user() {
  if is_dry_run && [[ "${IGNORE_USER:-0}" == "1" ]]; then
    return
  fi

  local required_user="$1"
  local current_user
  current_user="$(whoami)"

  if [[ "$current_user" != "$required_user" ]]; then
    print_error "This script must be run as user '${required_user}' (currently: ${current_user})"
    exit 1
  fi
}

# -----------------------------------------------------------------
# Check for sudo access
require_sudo() {
  if is_dry_run; then
    return
  fi

  if ! sudo -v 2>/dev/null; then
    print_error "This script requires passwordless sudo access"
    exit 1
  fi
}

# -----------------------------------------------------------------
# Check for passwordless sudo access
require_sudo_passwordless() {
  if is_dry_run; then
    return
  fi

  if ! sudo -n true 2>/dev/null; then
    print_error "This script requires passwordless sudo access"
    exit 1
  fi
}

# -----------------------------------------------------------------
# Signal that a reboot is required
# Call this from a step script to indicate reboot is needed
signal_reboot_required() {
  touch "${INSTALL_REBOOT_FILE}"
}

# -----------------------------------------------------------------
# Replace expressions like {{ prefix.NAME }} in the given template
# with the value of the variable NAME (incl. from env vars).
replace_handlebars_with_prefix() {
  local template="$1"
  local prefix="$2"

  while [[ $template =~ \{\{[[:space:]]*${prefix}\.([a-zA-Z0-9._-]+)[[:space:]]*\}\} ]]; do
    local match="${BASH_REMATCH[0]}"
    local name="${BASH_REMATCH[1]}"
    printf -v template '%s' "${template//"$match"/"${!name:-}"}"
  done

  echo "$template"
}

# -----------------------------------------------------------------
# GIT_ROOT_DIR
#
# Try git first, fall back to relative path from install/
if command -v git &> /dev/null && git rev-parse --show-toplevel &> /dev/null; then
    GIT_ROOT_DIR="$(git rev-parse --show-toplevel)"
else
    # Assume _utils.sh is in <project>/install/, so root is parent directory
    GIT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# -----------------------------------------------------------------
# INSTALL_TMP_DIR
#
# Set a directory for temporary install files
INSTALL_TMP_DIR="${GIT_ROOT_DIR}/install/.install"

# -----------------------------------------------------------------
# INSTALL_REBOOT_FILE, INSTALL_ETC_ENVIRONMENT
#
# Set directories for reboot/environment handling
INSTALL_REBOOT_FILE="${INSTALL_TMP_DIR}/reboot"
INSTALL_ETC_ENVIRONMENT="${INSTALL_TMP_DIR}/environment"

# -----------------------------------------------------------------
# Transactions
ON_EXIT_COMMANDS=()

run_command_on_exit() {
  ON_EXIT_COMMANDS+=("$*")
}

on_exit() {
  if [ ${#ON_EXIT_COMMANDS[@]} -gt 0 ]; then
    for cmd in "${ON_EXIT_COMMANDS[@]}"; do
      if is_dry_run; then
        echo "${C_GRAY}dry-run (on exit): ${cmd}${C_RESET}"
      else
        eval "${cmd}"
      fi
    done
  fi
}

trap on_exit EXIT
