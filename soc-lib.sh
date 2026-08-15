#!/usr/bin/env bash

# Define visual indicators for the terminal output to enhance readability.
# - `OK`: White Heavy Check Mark (Unicode: U+2705), indicates success.
# - `YUP`: Check Mark (Unicode: U+2713), also indicates confirmation or success.
# - `WRN`: High Voltage Sign (Unicode: U+26A1), used to signal warnings or cautions.
# - `ERR`: Cross Mark (Unicode: U+274C), indicates errors or failure.
OK=✅
YUP=✓
WRN=⚡
ERR=❌

# Handles errors by printing the source file and line number where the error
# occurred. Usage: error_handler <source_file> <line_number>
error_handler() {
  local src="$1"
  local line="$2"

  echo "${ERR} Error: in ${src} at line ${line}" >&2
}

# Removes a temporary file, if it exists, and prints a confirmation message.
# Usage: remove_tmp_file <file_path>
remove_tmp_file() {
  local file_to_remove="$1"

  if [[ -f "$file_to_remove" ]]; then
    rm -f "${file_to_remove}"
    echo "${YUP} Temporary file '${file_to_remove}' has been deleted"
  fi
}

# Check if GitHub CLI (gh) is installed
check_if_gh_installed() {
  if ! command -v gh &> /dev/null; then
    echo -n "${ERR} GitHub CLI (gh) is not installed on your computer. " >&2
    echo "Install to continue: https://cli.github.com/" >&2
    return 1
  elif [[ "${VERBOSE}" -eq 1 ]]; then
    echo "${YUP} 'GitHub CLI (gh)' is installed on your computer."
  fi
}

check_if_git_installed() {
  if ! command -v git &> /dev/null; then
    echo -n "${ERR} 'git' is not installed on your computer. " >&2
    echo "Install to continue: https://www.git-scm.com/downloads" >&2
    return 1
  elif [[ "${VERBOSE}" -eq 1 ]]; then
    echo "${YUP} 'git' is installed on your computer."
  fi
}

check_if_sed_installed() {
  if ! command -v sed &> /dev/null; then
    echo -n "${ERR} 'sed' – a command-line utility for parsing and " >&2
    echo -n "transforming text is not installed. Install it to continue: " >&2
    echo "https://www.gnu.org/software/sed/" >&2
    return 1
  elif [[ "${VERBOSE}" -eq 1 ]]; then
    echo "${YUP} 'sed' is installed on your computer."
  fi
}

check_if_grep_installed() {
  if ! command -v grep &> /dev/null; then
    echo -n "${ERR} 'grep' – a command-line utility for searching text " >&2
    echo -n "that match a regular expression is not installed. " >&2
    echo "Install it to continue:https://www.gnu.org/software/grep/ " >&2
    return 1
  elif [[ "${VERBOSE}" -eq 1 ]]; then
    echo "${YUP} 'grep' is installed on your computer."
  fi
}

check_if_jq_installed() {
  if ! command -v jq &> /dev/null; then
    echo -n "${ERR} 'jq' – a lightweight and flexible command-line JSON " >&2
    echo -n "processor is not installed. Install it to continue. " >&2
    echo "https://stedolan.github.io/jq/download/" >&2
    return 1
  elif [[ "${VERBOSE}" -eq 1 ]]; then
    echo "${YUP} 'jq' is installed on your computer."
  fi
}

check_if_date_installed() {
  if ! command -v date &> /dev/null; then
    echo -n "${ERR} 'date' – a command-line utility for displaying the " >&2
    echo -n "system date and time is not installed. Install it to continue. " >&2
    echo "https://www.gnu.org/software/coreutils/" >&2
    return 1
  elif [[ "${VERBOSE}" -eq 1 ]]; then
    echo "${YUP} 'date' is installed on your computer."
  fi
}

check_if_touch_installed() {
  if ! command -v touch &> /dev/null; then
    echo -n "${ERR} 'touch' – a command-line utility for changing file " >&2
    echo -n "timestamps is not installed. Install it to continue. " >&2
    echo "https://www.gnu.org/software/coreutils/" >&2
    return 1
  elif [[ "${VERBOSE}" -eq 1 ]]; then
    echo "${YUP} 'touch' is installed on your computer."
  fi
}
