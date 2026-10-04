#!/usr/bin/env bash

# Shared library of common helper functions for the project.
# This file is intended to be sourced by shell scripts that need access to the
# shared functionality defined here.

# Set up strict error handling to make debugging easier and improve reliability.
# - `+o errexit`: Disable the script's abort-on-first-error feature.
# - `-o nounset`: Aborts the script if an uninitialized variable is used.
# - `-o errtrace`: Allows the ERR trap to be inherited by functions, command substitutions, and subshells.

set +o errexit
set -o nounset
set -o errtrace

# Establish a trap for any error that occurs, calling the `error_handler`
# function with the source file and line number as arguments.
trap 'error_handler ${BASH_SOURCE} ${LINENO}' ERR

# Define visual indicators for the terminal output to enhance readability.
# - `OK`: White Heavy Check Mark (Unicode: U+2705), indicates success.
# - `YUP`: Check Mark (Unicode: U+2713), also indicates confirmation or success.
# - `WRN`: High Voltage Sign (Unicode: U+26A1), used to signal warnings or cautions.
# - `ERR`: Cross Mark (Unicode: U+274C), indicates errors or failure.
export OK=$'\u2705'
export YUP=$'\u2713'
export WRN=$'\u26A1'
export ERR=$'\u274C'

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

check_if_platform_cli_installed() {
  if ! command -v "${SOC_PLATFORM_CLI}" &>/dev/null; then
    echo "${ERR} Platform CLI '${SOC_PLATFORM_CLI}' is not installed." >&2
    return 1
  fi
}

# Updates the contents of a temporary file by replacing specific text.
# It checks for the presence of SOURCE_REPOS_OWNER and then replaces it with GH_ORG_NAME.
# Additionally, it iterates through repositories to replace other specified text.
update_tmp_file() {

  # Check if the correct number of non-empty arguments is passed
  if [[ "$#" -ne 1 || -z "$1" ]]; then
    echo "${ERR} Invalid number of arguments or empty argument." >&2
    echo "${WRN} Usage: ${FUNCNAME[0]} <temporary_file>"
    exit 1
  fi

  local tmp_file="$1"

  if grep -q "${SOURCE_REPOS_OWNER}" "${tmp_file}"; then
    # Perform the replacement in the temporary file
    sed -i "s/${SOURCE_REPOS_OWNER}/${GH_ORG_NAME}/g" "${tmp_file}"

    command_status=$?

    if (( command_status != 0 )); then
      echo -n "${ERR} An error occurred while updating the " >&2
      echo "temporary file: ${tmp_file}" >&2
      exit 1
    fi
  else
    echo -n "${WRN} Text to be replaced '${SOURCE_REPOS_OWNER}' "
    echo "was not found in the file: '${tmp_file}'."
  fi


  # Iterate through repositories
  for ((i=1; i<"${#SOURCE_REPOS[@]}"; i++)); do

    local word_to_replace="${SOURCE_REPOS[i]}"
    local new_word="${TARGET_REPOS[i]}"

    if grep -q "${word_to_replace}" "${tmp_file}"; then
      # Perform the replacement in the temporary file
      sed -i "s/${word_to_replace}/${new_word}/g" "${tmp_file}"

      command_status=$?

      if (( command_status != 0 )); then
        echo -n "${ERR} An error occurred while updating the " >&2
        echo "temporary file: '${tmp_file}'" >&2
        exit 1
      fi
    else
      echo -n "${WRN} Text to be replaced '${word_to_replace}' "
      echo "was not found in the file: '${tmp_file}'."
    fi
  done
}

# Sets descriptions for the target repositories in the target organization.
# Usage: set_repos_descriptions
set_repos_descriptions() {

  # Iterate through repositories
  for ((i=0; i<"${#TARGET_REPOS[@]}"; i++)); do

    # Setting website link in the target repositories"
    set_repo_description \
      "${GH_ORG_NAME}" \
      "${TARGET_REPOS[i]}" \
      "${TARGET_REPO_DESCRIPTION}"

    command_status=$?

    if (( command_status != 0 )); then
      echo -n "${ERR} An error occurred while setting a website link in the " >&2
      echo "${GH_ORG_NAME}"/"${TARGET_REPOS[i]} repository" >&2
      exit 1
    fi
  done
  echo "$OK Setting the website links has been completed"
}

# Create repositories in GH_ORG_NAME from SOURCE_REPOS_OWNER templates. Usage:
# create_private_repos_from_templates
create_private_repos_from_templates() {

  for ((i=0; i<"${#SOURCE_REPOS[@]}"; i++)); do

    # Create a repository in an organization from a template.
    create_platform_repo_from_template \
      "${SOURCE_REPOS_OWNER}" \
      "${SOURCE_REPOS[i]}" \
      "${GH_ORG_NAME}" \
      "${TARGET_REPOS[i]}"

    command_status=$?

    if (( command_status != 0 )); then
      echo -n "${ERR} An error occurred while creating the " >&2
      echo -n "${GH_ORG_NAME}/${TARGET_REPOS[i]} repository from " >&2
      echo "the ${SOURCE_REPOS_OWNER}/${SOURCE_REPOS[i]} template" >&2
      exit 1
    fi
  done
  echo "${OK} Creating repositories has been completed"
}

# Checks if repositories listed in the array in the config file exist. Aborts
# the script with an error message if any repository does not exist. Usage:
# check_if_repos_exist <repos_owner> <repos_name> <repos>
check_if_repos_exist() {

  if [[ "$#" -lt 2 ]]; then
    echo -n "${ERR} Insufficient arguments provided for the " >&2
    echo "'${FUNCNAME[0]}' function." >&2
    exit 1
  fi

  local repos_owner="$1"
  shift # Remove the argument
  local repos_name="$1"
  shift # Remove the argument to treat the rest as an array
  local -a repos=("$@")

  # Initialize a flag to track if any repository does not exist
  local repo_noexists=0

  for ((i=0; i<"${#repos[@]}"; i++)); do
    # Check if the repository exists
    if check_if_platform_repo_exists "${repos_owner}" "${repos[i]}"; then
      echo -n "${YUP} Repository ${repos_owner}/${repos[i]} "
      echo "exists as expected."
    else
      echo "${ERR} Repository ${repos_owner}/${repos[i]} no exists." >&2
      repo_noexists=1
    fi
  done

  # Check the flag and exit if any repository does not exist
  if [[ "${repo_noexists}" -eq 1 ]]; then
    echo -n "${ERR} For proper functioning of '${FUNCNAME[1]}' command, " >&2
    echo -n "it is required that the repositories listed in the " >&2
    echo -n "'${repos_name}' array in the config file exist " >&2
    echo "on the '${repos_owner}' platform account." >&2
    exit 1
  else
    echo -n "${OK} The check to see if the '${repos_name}' "
    echo "repositories exist has been completed."
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

# Checks if repositories listed in the array in the config file do not already
# exist. Aborts the script with an warning message if any repository already
# exists. Usage: check_if_repos_noexist <repos_owner> <repos_name> <repos>
check_if_repos_noexist() {

  local repos_owner="$1"
  shift # Remove the argument
  local repos_name="$1"
  shift # Remove the argument to treat the rest as an array
  local -a repos=("$@")

  # Initialize a flag to track if any repository already exists
  local repo_exists=0

  for ((i=0; i<"${#repos[@]}"; i++)); do
    # Check if the repository exists
    if ! check_if_platform_repo_exists "${repos_owner}" "${repos[i]}"; then
      echo -n "${YUP} Repository ${repos_owner}/${repos[i]} "
      echo "not yet exists as expected."
    else
      echo "${WRN} Repository ${repos_owner}/${repos[i]} already exists."
      repo_exists=1
    fi
  done

  # Check the flag and exit with a warning if any repository already exists. The
  # presence of repositories may be due to synchronizing repositories beforehand
  # or already having own repositories with the same names as the source ones.
  if [[ "${repo_exists}" -eq 1 ]]; then
    echo -n "${WRN} One or more repositories listed in the '${repos_name}'"
    echo -n " array in the config file already exist on the "
    echo "'${repos_owner}' platform account."
    exit 1
  else
    echo -n "${OK} The check to see if the '${repos_name}' "
    echo "repositories exist has been completed."
  fi
}

# Checks if repositories in source repo owner platform account and listed in the
# array in the config file are templates. Attempt to make them templates if they
# are not already. Aborts the script with an error message if any repository is
# not a template. Usage: ensure_repos_as_templates <repos_owner> <repos_name>
# <repos>
ensure_repos_as_templates() {

  local repos_owner="$1"
  shift # Remove the argument
  local repos_name="$1"
  shift # Remove the argument to treat the rest as an array
  local -a repos=("$@")

  # Initialize a flag to track if any repository is not a template
  local repo_is_not_template=0

  for ((i=0; i<"${#repos[@]}"; i++)); do
    # Check if the repository is a template
    if check_if_repo_is_template "${repos_owner}" "${repos[i]}"; then
      echo -n "${YUP} Repository ${repos_owner}/${repos[i]} "
      echo "is a template as expected."
    else
      echo -n "${WRN} Repository ${repos_owner}/${repos[i]} is not a template. "
      echo "Attempting to make it a template..."
      # Attempt to convert the repository to a template
      if set_repo_as_template "${repos_owner}" "${repos[i]}"; then
        echo "${YUP} Successfully transformed into a template."
      else
        echo "${WRN} Failed to transform into a template."
        repo_is_not_template=1
      fi
    fi
  done

  # Check the flag and exit with a error if any repository is not a template.
  if [[ "${repo_is_not_template}" -eq 1 ]]; then
    echo -n "${ERR} For proper functioning of '${FUNCNAME[1]}' command, " >&2
    echo -n "it is required that the repositories in '${repos_owner}' " >&2
    echo -n "platform account and listed in the '${repos_name}' array " >&2
    echo "in the config file are templates." >&2
    exit 1
  else
    echo -n "${OK} The check to see if the '${repos_name}' repositories "
    echo "are templates has been completed."
  fi
}

check_git_configs() {

  local git_user_name
  local git_user_email

  git_user_name=$(git config --global user.name)
  git_user_email=$(git config --global user.email)

  # Check if the user has set up the git user name and email
  if [[ -z "${git_user_email}" ]]; then
    echo -n "${WRN} Git user email is not set. You can set it up with: "
    echo "'git config --global user.email \"your_email@example.com\"'."
  fi

  if [[ -z "${git_user_name}" ]]; then
    echo -n "${ERR} Git user name is not set. For proper functioning of " >&2
    echo -n "'${FUNCNAME[1]}' command, it is required that the git user " >&2
    echo -n "name is set up on the local machine. Please run:" >&2
    echo "'git config --global user.name \"Your Name\"'." >&2
    exit 1
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

# Updates repository files without cloning the entire repository.
# This function iterates through a list of files, performing the following steps
# for each:
# 1. Creates a temporary file to work with the file's content.
# 2. Retrieves the SHA of the current file in the repository to allow for its update.
# 3. Downloads the file content from the repository to the temporary file.
# 4. Applies changes to the content within the temporary file.
# 5. Uploads the updated content back to the repository, replacing the old file.
#
# NOTE: This is the shared, platform independent workflow. Every platform
# dependent operation is delegated to a hook function that must be provided by
# the sourced platform specific library (for GitHub it is the 'soc-lib-gh.sh'
# file): 'get_target_repo_full_name', 'check_if_repo_file_exists',
# 'get_file_sha', 'download_repo_file_contents_to_tmp_file', 'update_tmp_file'
# and 'update_repo_file_contents'.
# Usage: update_repo_without_cloning
update_repo_without_cloning() {

  local file_sha
  local tmp_file
  local info_file=''
  local repo_full_name

  # Get the full name ('owner/repository') of the repository to update
  repo_full_name="$(get_target_repo_full_name)"

  for ((attempt=1; attempt<=10; attempt++)); do
    if [[ -n "${info_file}" ]]; then
      break
    fi

    for source_file in "${SOURCE_MAIN_REPO_INFO_FILES[@]}"; do
      if check_if_repo_file_exists "${source_file}"; then
        info_file="${source_file}"
        break
      fi
    done

    if [[ -z "${info_file}" ]]; then
      sleep 1
    fi
  done

  if [[ -z "${info_file}" ]]; then
    echo "${ERR} None of the configured info files exists in '${repo_full_name}'." >&2
    echo "${ERR} Expected one of: ${SOURCE_MAIN_REPO_INFO_FILES[*]}" >&2
    return 1
  fi

  # Generate two temporary files and get sha of each source file
  for source_file in "${SOURCE_MAIN_REPO_INFO_FILES[@]}"; do

    if ! check_if_repo_file_exists "${source_file}"; then
      echo "${WRN} The '${source_file}' file does not exist in '${repo_full_name}'; skipping it."
      continue
    fi
    # Create a temporary file
    tmp_file="$(mktemp)"
    command_status=$?
    if (( command_status != 0 )); then
      echo "${ERR} Unable to create a temporary file" >&2
      exit 1
    else
      echo "${YUP} Temporary file '${tmp_file}' has been created"
    fi

    # Remove the temporary file if the script exits unexpectedly. This ensures that even if the
    # script fails or is interrupted, the temporary file does not remain on disk.
    # NOTE: ShellCheck may warn about SC2064 here (variable expansion at trap assignment), but this
    # is intentional.
    # shellcheck disable=SC2064
    trap "remove_tmp_file ${tmp_file}" EXIT

    # Get the file SHA
    file_sha=$(get_file_sha "${source_file}")
    command_status=$?
    if (( command_status == 0 )); then
      echo "${YUP} The SHA for the '${source_file}' file has been obtained"
    else
      echo "${file_sha}" >&2
      exit 1
    fi

    # Download the file contents to the temporary file
    download_repo_file_contents_to_tmp_file "${source_file}" "${tmp_file}"
    # Update the temporary file
    update_tmp_file "${tmp_file}"
    # Update the repository file contents
    update_repo_file_contents "${tmp_file}" "${file_sha}" "${source_file}"

    # Remove the temporary file
    if [[ -f "${tmp_file}" ]]; then
      rm -f "${tmp_file}"
      echo "${YUP} Temporary file ${tmp_file} has been deleted"
      echo
    fi
  done

  echo "${OK} The repo '${TARGET_REPOS[0]}' has been updated"
}

# Creates a new project in the organization from a specified template.
# It's intended to copy a project from another source into the target
# organization under a new title. Usage: create_project_from_template
create_project_from_template() {

  local project_number

  project_number=$(get_project_number)
  command_status=$?
  if (( command_status == 0 )); then
    if [[ -n "${project_number}" ]]; then
      echo -n "${WRN} Project with the '${TARGET_PROJECT_TITLE}' title "
      echo "already exists in the '${GH_ORG_NAME}' organization."
      return 0
    fi
  else
    echo "${project_number}" >&2
    exit 1
  fi

  copy_project_from_template \
    "${SOURCE_PROJECT_NUMBER}" \
    "${SOURCE_PROJECT_OWNER}" \
    "${TARGET_PROJECT_TITLE}"

  command_status=$?
  if (( command_status == 0 )); then
    echo "${OK} The project '${TARGET_PROJECT_TITLE}' has been created."
  else
    echo -n "${ERR} An error occurred while copying the project " >&2
    echo "from ${SOURCE_PROJECT_OWNER} to '${GH_ORG_NAME}'." >&2
  fi
}

# TODO:
# Add function validations on global variables from system_config.sh
# END:
