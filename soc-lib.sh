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

# VALIDATION FUNCTIONS----------------------------------------------------------#
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


validate_non_empty_string() {
  if [[ "$#" -lt 2 ]]; then
    echo -n "${ERR} Insufficient arguments provided for the " >&2
    echo "'${FUNCNAME[0]}' function." >&2
    exit 1
  fi

  local var_name="$1"
  local var_value="$2"

  if [[ -z "${var_value}" ]]; then
    echo "${ERR} '${var_name}' is empty." >&2
    return 1
  elif [[ "${VERBOSE}" -eq 1 ]]; then
    echo "${YUP} '${var_name}' is non-empty: '${var_value}'."
  fi
}

validate_owner_name() {
  if [[ "$#" -lt 2 ]]; then
    echo -n "${ERR} Insufficient arguments provided for the " >&2
    echo "'${FUNCNAME[0]}' function." >&2
    exit 1
  fi

  local var_name="$1"
  local var_value="$2"

  if [[ "${var_value}" =~ ^[a-zA-Z0-9]+(-[a-zA-Z0-9]+)*$ ]]; then
    if [[ "${VERBOSE}" -eq 1 ]]; then
      echo "${YUP} '${var_name}' has valid value: '${var_value}'."
    fi
  else
    echo "${ERR} '${var_name}' has invalid value: '${var_value}'." >&2
    return 1
  fi
}

validate_team_name() {
  if [[ "$#" -lt 2 ]]; then
    echo -n "${ERR} Insufficient arguments provided for the " >&2
    echo "'${FUNCNAME[0]}' function." >&2
    exit 1
  fi

  local var_name="$1"
  local var_value="$2"

  if [[ "${var_value}" =~ ^[a-zA-Z0-9]+([_-][a-zA-Z0-9]+)*$ ]]; then
    if [[ "${VERBOSE}" -eq 1 ]]; then
      echo "${YUP} '${var_name}' has valid value: '${var_value}'."
    fi
  else
    echo "${ERR} '${var_name}' has invalid value: '${var_value}'." >&2
    return 1
  fi
}

validate_numeric() {
  if [[ "$#" -lt 2 ]]; then
    echo -n "${ERR} Insufficient arguments provided for the " >&2
    echo "'${FUNCNAME[0]}' function." >&2
    exit 1
  fi

  local var_name="$1"
  local var_value="$2"

  if ! [[ "${var_value}" =~ ^[0-9]+$ ]]; then
    echo "${ERR} '${var_name}' has not numeric value: '${var_value}'." >&2
    return 1
  elif [[ "${VERBOSE}" -eq 1 ]]; then
    echo "${YUP} '${var_name}' has numeric value: '${var_value}'."
  fi
}

# Function to validate non-empty arrays
validate_non_empty_array() {
  if [[ "$#" -lt 2 ]]; then
    echo -n "${ERR} Insufficient arguments provided for the " >&2
    echo "'${FUNCNAME[0]}' function." >&2
    exit 1
  fi

  local var_name="$1"
  shift # Remove the first argument to treat the rest as an array
  local -a arr=("$@")

  if [[ "${#arr[@]}" -eq 0 ]]; then
    echo "${ERR} '${var_name}' is an empty array." >&2
    return 1
  elif [[ "${VERBOSE}" -eq 1 ]]; then
    echo
    echo "${YUP} '${var_name}' is a non-empty array: ${arr[*]}."
    echo
  fi
}

# Function to validate no empty elements in an array
validate_no_empty_array_elements() {
  if [[ "$#" -lt 2 ]]; then
    echo -n "${ERR} Insufficient arguments provided for the " >&2
    echo "'${FUNCNAME[0]}' function." >&2
    exit 1
  fi

  local var_name="$1"
  shift # Remove the first argument to treat the rest as an array
  local -a arr=("$@")

  for element in "${arr[@]}"; do
    if [[ -z "${element}" ]]; then
      echo "${ERR} '${var_name}' contains an empty element." >&2
      return 1
    fi
  done

  if [[ "${VERBOSE}" -eq 1 ]]; then
    echo "${YUP} '${var_name}' has no empty elements."
  fi
}

# Function to validate repo names for each element in an array
validate_repo_names() {
  if [[ "$#" -lt 2 ]]; then
    echo -n "${ERR} Insufficient arguments provided for the " >&2
    echo "'${FUNCNAME[0]}' function." >&2
    exit 1
  fi

  local var_name="$1"
  shift # Remove the first argument to treat the rest as an array
  local -a arr=("$@")

  for element in "${arr[@]}"; do
    if ! [[ "${element}" =~ ^[a-zA-Z0-9_.-]+$ ]]; then
      echo -n "${ERR} '${var_name}' contains a non-valid element: " >&2
      echo -n "'${element}'. Repository names can only contain alphanumeric " >&2
      echo -n "characters, dot ('.'),  hyphen-minus character ('-'), " >&2
      echo "and the underscore ('_')." >&2
      return 1
    fi
  done

  if [[ "${VERBOSE}" -eq 1 ]]; then
    echo "${YUP} All elements in '${var_name}' are valid."
  fi
}

# Function to validate user names for each element in an array
validate_user_names() {
  # The array of user names can be empty, so we need to check if at least one
  # element is provided.
  if [[ "$#" -lt 1 ]]; then
    echo -n "${ERR} Insufficient arguments provided for the " >&2
    echo "'${FUNCNAME[0]}' function." >&2
    exit 1
  fi

  local var_name="$1"
  shift # Remove the first argument to treat the rest as an array
  local -a arr=("$@")

  # Proceed only if the array is not empty
  if [[ "${#arr[@]}" -eq 0 ]]; then
    if [[ "${VERBOSE}" -eq 1 ]]; then
      echo "${YUP} The array '${var_name}' is empty. No validation needed."
    fi
    return 0
  fi

  for element in "${arr[@]}"; do
    if ! [[ "${element}" =~ ^[a-zA-Z0-9-]+$ ]]; then
      echo -n "${ERR} '${var_name}' contains a non-valid element: " >&2
      echo -n "'${element}'. User names can be empty or contain alphanumeric" >&2
      echo " characters and hyphen-minus character ('-')." >&2
      return 1
    fi
  done

  if [[ "${VERBOSE}" -eq 1 ]]; then
    echo "${YUP} All elements in '${var_name}' are valid."
  fi
}

# Function to check for duplicate elements in an array
validate_no_duplicates() {
  # Evaluation of this function needs 'set +u', otherwise will be terminated by
  # 'set -u'
  local is_set_nounset=''

  [[ "$-" == *u* ]] && is_set_nounset='true' || is_set_nounset='false'
  set +u

  if [[ "$#" -lt 2 ]]; then
    echo -n "${ERR} Insufficient arguments provided for the " >&2
    echo "'${FUNCNAME[0]}' function." >&2
    exit 1
  fi

  local var_name="$1"
  shift # Remove the first argument to treat the rest as an array
  local -a arr=("$@")
  local -A arr_map=()

  for element in "${arr[@]}"; do
    if [[ -n "${arr_map[${element}]}" ]]; then
      echo "${ERR} '${var_name}' has duplicate elements: '${element}'." >&2
      return 1
    fi
    arr_map["${element}"]=1
  done

  if [[ "${VERBOSE}" -eq 1 ]]; then
    echo "${YUP} '${var_name}' has no duplicates."
  fi

  "${is_set_nounset}" || set +u
}

# TODO:
# Add function validations on global variables from system_config.sh
# END:
