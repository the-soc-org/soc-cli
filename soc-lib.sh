#!/usr/bin/env bash

# Shared library of common helper functions for the project.
# This file is intended to be sourced by shell scripts that need access to the
# shared functionality defined here.

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

# Forks repositories from SOURCE_REPOS_OWNER to GH_ORG_NAME without cloning
# them.
# Usage: fork_repositories
fork_repositories() {

  for ((i=0; i<"${#SOURCE_REPOS[@]}"; i++)); do

    # Fork the repository to the organization without cloning it locally.
    gh repo fork "${SOURCE_REPOS_OWNER}"/"${SOURCE_REPOS[i]}" \
       --org "${GH_ORG_NAME}" \
       --fork-name "${TARGET_REPOS[i]}" \
       --clone=false

    if [[ $? -ne 0 ]]; then
      echo -n "${ERR} An error occurred while forking the " >&2
      echo -n "${SOURCE_REPOS_OWNER}/${SOURCE_REPOS[i]} repository to " >&2
      echo "${GH_ORG_NAME}/${TARGET_REPOS[i]}" >&2
      exit 1
    fi
  done
  echo "${OK} Forking repositories has been completed"
}

# Create repositories in GH_ORG_NAME from SOURCE_REPOS_OWNER templates. Usage:
# create_private_repos_from_templates
create_private_repos_from_templates() {

  for ((i=0; i<"${#SOURCE_REPOS[@]}"; i++)); do

    # Create a repository in an organization from a template.
    gh repo create "${GH_ORG_NAME}"/"${TARGET_REPOS[i]}" \
       --template "${SOURCE_REPOS_OWNER}"/"${SOURCE_REPOS[i]}" \
       --private=true

    if [[ $? -ne 0 ]]; then
      echo -n "${ERR} An error occurred while creating the " >&2
      echo -n "${GH_ORG_NAME}/${TARGET_REPOS[i]} repository from " >&2
      echo "the ${SOURCE_REPOS_OWNER}/${SOURCE_REPOS[i]} template" >&2
      exit 1
    fi
  done
  echo "${OK} Creating repositories has been completed"
}

# Delete repositories listed in TARGET_REPOS array in user_config.sh file from
# GH_ORG_NAME. Usage: delete_repositories
delete_repositories() {

  for ((i=0; i<"${#TARGET_REPOS[@]}"; i++)); do

    # deleting a repo
    gh repo delete "$GH_ORG_NAME"/"${TARGET_REPOS[i]}" --yes

    if [[ $? -ne 0 ]]; then
      echo -n "${ERR} An error occurred while deleting the repository" >&2
      echo "$GH_ORG_NAME"/"${TARGET_REPOS[i]}" >&2
      exit 1
    fi
  done

  echo "${OK} Deletion of the repositories has been completed."
}

# Sets specified repositories in GH_ORG_NAME as private and marks them as
# templates.
# Usage: set_repo_as_private_template
set_repo_as_private_template() {

  for ((i=0; i<"${#TARGET_REPOS[@]}"; i++)); do

    gh repo edit "$GH_ORG_NAME"/"${TARGET_REPOS[i]}" \
       --visibility private \
       --template=true

    if [[ $? -ne 0 ]]; then
      echo -n "${ERR} An error occurred while setting the " >&2
      echo "$GH_ORG_NAME/${TARGET_REPOS[i]} repository as a private template" >&2
      exit 1
    fi
  done
  echo "${OK} Setting repositories as private templates has been completed"
}

check_repo_gh_pages_enabled() {
  # Local variable declaration for return value
  local has_pages

  has_pages=$(gh api \
                 --method GET \
                 --header "Accept: ${GH_API_ACCEPT_HEADER}" \
                 --header "X-GitHub-Api-Version: ${GH_API_VERSION_HEADER}" \
                 repos/"${GH_ORG_NAME}"/"${TARGET_REPOS[0]}" \
                 --jq '.has_pages')

  if [[ $? -eq 0 ]]; then
    echo "${has_pages}"
  else
    echo -n "${ERR} An error occurred while checking if GitHub Pages "
    echo "is enabled for '${GH_ORG_NAME}/${TARGET_REPOS[0]}'."
    exit 1
  fi
}

# Retrieves the SHA for a file in the first target repository.
get_file_sha() {

  # Check if the correct number of non-empty arguments is passed
  if [[ "$#" -ne 1 || -z "$1" ]]; then
    echo "${ERR} Invalid number of arguments or empty argument." >&2
    echo "${WRN} Usage: ${FUNCNAME[0]} <source_file>"
    exit 1
  fi

  # Local variable declaration for the return value
  local sha

  # Get the file SHA
  sha=$(gh api \
           --method GET \
           --header "Accept: ${GH_API_ACCEPT_HEADER}" \
           --header "X-GitHub-Api-Version: ${GH_API_VERSION_HEADER}" \
           repos/"${GH_ORG_NAME}"/"${TARGET_REPOS[0]}"/contents/"${source_file}" \
           --jq '.sha')

  if [[ $? -eq 0 ]]; then
    if [[ -n "${sha}" ]]; then
      echo "${sha}"
    else
      echo "${ERR} SHA for the '${source_file}' is emapty"
      exit 1
    fi
  else
    echo "${ERR} An error occurred while obtaining SHA for the '${source_file}'"
    exit 1
  fi
}

# Downloads the contents of a specified file from a repository to a temporary
# file.
download_repo_file_contents_to_tmp_file() {

  # Check if the correct number of non-empty arguments is passed
  if [[ "$#" -ne 2 || -z "$1" || -z "$2" ]]; then
    echo "${ERR} Invalid number of arguments or empty argument." >&2
    echo "${WRN} Usage: ${FUNCNAME[0]} <source_file> <temporary_file>"
    exit 1
  fi

  local source_file="$1"
  local tmp_file="$2"

  gh api \
     --method GET \
     --header "Accept: ${GH_API_ACCEPT_HEADER}" \
     --header "X-GitHub-Api-Version: ${GH_API_VERSION_HEADER}" \
     repos/"${GH_ORG_NAME}"/"${TARGET_REPOS[0]}"/contents/"${source_file}" \
     --jq '.content' | base64 --decode > "${tmp_file}"

  # Check whether the operation was successful
  if [[ $? -eq 0 ]]; then
    echo -n "${YUP} The content of the '${source_file}' has been written "
    echo "to the '${tmp_file}'"
  else
    echo -n "${ERR} An error occurred while downloading '${source_file}' " >&2
    echo "or writing its content to the '${tmp_file}'" >&2
    exit 1
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

    if [[ $? -ne 0 ]]; then
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

      if [[ $? -ne 0 ]]; then
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

# Retrieves the unique ID of a project by its title within a GitHub
# organization.  This ID is essential for operations that modify project
# settings or link the project to other entities. The function lists all
# projects under the specified organization and filters by title to find the
# correct project ID. Usage: get_project_id
get_project_id() {
  # Local variable declaration for the return value
  local project_id

  # List projects under a specific organization and extract the project ID using
  # jq based on the title.
  project_id=$(gh project list \
                  --owner "${GH_ORG_NAME}" \
                  --format 'json' \
                  --jq ".projects[] | select(.title == \"${TARGET_PROJECT_TITLE}\") | .id")

  if [[ $? -eq 0 ]]; then
      echo "${project_id}"
  else
    echo -n "${ERR} An error occurred while obtaining the ID of the "
    echo -n "'${TARGET_PROJECT_TITLE}' project from the '${GH_ORG_NAME}' "
    echo "organization."
    exit 1
  fi
}

# Retrieves the unique ID of a team by its name within a GitHub organization.
# This ID is used for assigning permissions or linking the team to projects and
# repositories. The function uses a GraphQL query to fetch the team ID based on
# the provided team name.
# Usage: get_team_id
get_team_id() {
  # Local variable declaration for the return value
  local team_id

  # Define a GraphQL query to retrieve the team ID from the GitHub API.
  local query="
  {
    organization(login: \"${GH_ORG_NAME}\") {
      team(slug: \"${GH_TEAM_NAME}\") {
        id
      }
    }
  }
  "

  # Execute the GraphQL query and extract the team ID using
  # jq.
  team_id=$(gh api graphql \
               --raw-field query="${query}" \
               --jq '.data.organization.team.id')

  if [[ $? -eq 0 ]]; then
    echo "${team_id}"
  else
    echo -n "${ERR} An error occurred while obtaining the ID of the "
    echo "'${GH_TEAM_NAME}' team from the '${GH_ORG_NAME}' organization"
    exit 1
  fi
}

# Fetches the unique ID of a GitHub user based on their login. This function is
# crucial for operations that require user identification, such as assigning
# roles or permissions. It verifies the provided argument and utilizes a
# GraphQL query to retrieve the user ID.
get_user_id() {
  # Check if the correct number of non-empty arguments is passed
  if [[ "$#" -ne 1 || -z "$1" ]]; then
    echo "${ERR} Invalid number of arguments or empty argument." >&2
    echo "${WRN} Usage: ${FUNCNAME[0]} <github_login>"
    exit 1
  fi

  local gh_login="$1"

  # Local variable declaration for the return value
  local user_id

  local query="
  {
    user(login: \"${gh_login}\") {
      id
    }
  }
  "

  user_id=$(gh api graphql \
               --raw-field query="${query}" \
               --jq '.data.user.id')

  if [[ $? -eq 0 ]]; then
    if [[ -n "${user_id}" ]]; then
      echo "${user_id}"
    else
      echo -n "${ERR} The obtained ID of the '${gh_login}' user "
      echo -n "is empty: the '${gh_login}' user does not exist. "
      echo -n "Check the 'user_config' file to see if you have entered "
      echo "the 'GH_TEAM_MEMBERS_EXCLUDED_FROM_REVIEWING' correctly."
      exit 1
    fi
  else
    echo -n "${ERR} An error occurred while obtaining the ID "
    echo "of the '${gh_login}' user."
    exit 1
  fi
}

# Retrieves the numeric ID of a team within a GitHub organization. This ID is
# essential for certain API calls that require team identification. The script
# uses the GitHub CLI to query the GitHub API and extract the team's numeric ID.
# Usage: get_team_number
get_team_number() {
  # Local variable declaration for the return value
  local team_number

  # Retrieve the team number
  team_number=$(gh api \
                   --method GET \
                   --header "Accept: ${GH_API_ACCEPT_HEADER}" \
                   --header "X-GitHub-Api-Version: ${GH_API_VERSION_HEADER}" \
                   /orgs/"${GH_ORG_NAME}"/teams/"${GH_TEAM_NAME}" \
                   --jq '.id')

  if [[ $? -eq 0 ]]; then
    echo "${team_number}"
  else
    echo -n "${ERR} An error occurred while obtaining the number of the "
    echo "'${GH_TEAM_NAME}' team from the '${GH_ORG_NAME}' organization."
    exit 1
  fi
}

get_invitation_id_by_email() {
  # Check if the correct number of non-empty arguments is passed
  if [[ "$#" -ne 1 || -z "$1" ]]; then
    echo "${ERR} Invalid number of arguments or empty argument." >&2
    echo "${WRN} Usage: ${FUNCNAME[0]} <email>"
    exit 1
  fi

  # local variable declaration
  local email="$1"
  local invitation_id

  # Fetch all pending invitations and find the one matching the email
  invitation_id=$(gh api \
                     --method GET \
                     --header "Accept: ${GH_API_ACCEPT_HEADER}" \
                     --header "X-GitHub-Api-Version: ${GH_API_VERSION_HEADER}" \
                     /orgs/"${GH_ORG_NAME}"/invitations \
                     --jq ".[] | select(.email==\"${email}\") | .id")

  if [[ $? -eq 0 ]]; then
    echo "${invitation_id}"
  else
    echo -n "${ERR} An error occurred while obtaining the id of invitation to "
    echo "'${GH_ORG_NAME}' organization."
    exit 1
  fi
}

# Retrieves the project ID for a specified project title within a GitHub
# organization.
# Usage: get_project_number
get_project_number() {
  # Local variable declaration for the return value
  local project_number

  # List projects under a specific organization and extract the project ID using
  # jq based on the title.
  project_number=$(gh project list \
                  --owner "${GH_ORG_NAME}" \
                  --format 'json' \
                  --jq ".projects[] | select(.title == \"${TARGET_PROJECT_TITLE}\") | .number")

  if [[ $? -eq 0 ]]; then
    echo "${project_number}"
  else
    echo -n "${ERR} An error occurred while obtaining the number of the "
    echo -n "'${TARGET_PROJECT_TITLE}' project from the '${GH_ORG_NAME}' "
    echo "organization."
    exit 1
  fi
}

# Creates a set of private repositories from templates without cloning them.
# Usage: create_repo_from_template
create_repo_from_template() {
  # Iterate through the source repositories and create private repositories from
  # templates
  for ((i=0; i<"${#SOURCE_REPOS[@]}"; i++)); do

    # Create private repo from the template without cloning it.
    gh repo create "${GH_ORG_NAME}"/"${TARGET_REPOS[i]}" \
       --private \
       --template "${GH_ORG_NAME}"/"${SOURCE_REPOS[i]}" \
       --clone=false

    if [[ $? -ne 0 ]]; then
      echo -n "${ERR} An error occurred while creating the " >&2
      echo "${GH_ORG_NAME}/${TARGET_REPOS[i]} repo from the " >&2
      echo "${GH_ORG_NAME}/${SOURCE_REPOS[i]} template" >&2
      exit 1
    fi
  done
  echo "${OK} Creating repos from templates has been completed"
}

# Assigns a repository to a specific team within the GitHub organization.
# Usage: assign_repo_to_team
assign_repo_to_team() {
  # Assigning a first argument to a local variable
  local repo="$1"

  # Add a repository to the team
  gh api \
     --header "Accept: ${GH_API_ACCEPT_HEADER}" \
     --header "X-GitHub-Api-Version: ${GH_API_VERSION_HEADER}" \
     --method PUT \
     /orgs/"${GH_ORG_NAME}"/teams/"${GH_TEAM_NAME}"/repos/"${GH_ORG_NAME}"/"${repo}" \
     --raw-field permission="${GH_TEAM_REPO_PERMISSION}" \
     --silent

  # Check if the command succeeded
  if [[ $? -eq 0 ]]; then
    echo -n "Repository '${repo}' was successfully added to "
    echo "the '${GH_TEAM_NAME}' team."
  else
    echo -n "${ERR} An error occurred while adding the repository '${repo}' " >&2
    echo "to the '${GH_TEAM_NAME}' team in the '${GH_ORG_NAME}' organization." >&2
    exit 1
  fi
}

# Removes a repository from a specific team within the GitHub organization.
# Usage: remove_repo_from_team <repository_name>
remove_repo_from_team() {
  # Assigning the first argument to a local variable
  local repo="$1"

  # Remove the repository from the team
  gh api \
     --header "Accept: ${GH_API_ACCEPT_HEADER}" \
     --header "X-GitHub-Api-Version: ${GH_API_VERSION_HEADER}" \
     --method DELETE \
     /orgs/"${GH_ORG_NAME}"/teams/"${GH_TEAM_NAME}"/repos/"${GH_ORG_NAME}"/"${repo}" \
     --silent

  # Check if the command succeeded
  if [[ $? -eq 0 ]]; then
    echo -n "${YUP} Repository '${repo}' was successfully removed from "
    echo "the '${GH_TEAM_NAME}' team."
  else
    echo -n "${ERR} An error occurred while removing the repository '${repo}' " >&2
    echo "from the '${GH_TEAM_NAME}' team in the '${GH_ORG_NAME}' organization." >&2
    exit 1
  fi
}

# Get the team's repositories list. Usage: get_team_repos_list
get_team_repos_list() {

  # Declare a local variable for the api response to avoid printing potential
  # errors to the pager; instead, we print them directly to the console.
  local response

  # API request for a team's repos list
  response=$(gh api \
     --header "Accept: ${GH_API_ACCEPT_HEADER}" \
     --header "X-GitHub-Api-Version: ${GH_API_VERSION_HEADER}" \
     --method GET \
     /orgs/"${GH_ORG_NAME}"/teams/"${GH_TEAM_NAME}"/repos \
     --paginate \
     --jq '.[].name')

  # Check if the command succeeded
  if [[ $? -eq 0 ]]; then
    echo "${response}"
  else
    echo -n "${ERR} An error occurred while getting the repository list of " >&2
    echo "the '${GH_TEAM_NAME}' team in the '${GH_ORG_NAME}' organization." >&2
    exit 1
  fi
}

get_team_members_list() {

  # Expect exactly one argument: name of output array
  if [[ "$#" -ne 1 || -z "$1" ]]; then
    echo "${ERR} Usage: ${FUNCNAME[0]} <output_array_name>" >&2
    exit 1
  fi

  # Name reference to caller's array
  local -n _team_members="$1"
  local status

  mapfile -t _team_members < <(
    gh api \
       --header "Accept: ${GH_API_ACCEPT_HEADER}" \
       --header "X-GitHub-Api-Version: ${GH_API_VERSION_HEADER}" \
       --method GET \
       /orgs/"${GH_ORG_NAME}"/teams/"${GH_TEAM_NAME}"/members \
       --paginate \
       --jq '.[].login'
  )
  status=$?

  if [[ $status -ne 0 ]]; then
    echo -n "${ERR} An error occurred while obtaining the members list of " >&2
    echo "the '${GH_TEAM_NAME}' team from the '${GH_ORG_NAME}' organization." >&2
    exit 1
  fi
}

get_team_member_role() {

  # Check if the correct number of non-empty arguments is passed
  if [[ "$#" -ne 1 || -z "$1" ]]; then
    echo "${ERR} Invalid number of arguments or empty argument." >&2
    echo "${WRN} Usage: ${FUNCNAME[0]} <user_nickname>"
    exit 1
  fi

  local member="$1"
  # Declare a local variable for the return value
  local member_role

  member_role=$(gh api \
                --header "Accept: ${GH_API_ACCEPT_HEADER}" \
                --header "X-GitHub-Api-Version: ${GH_API_VERSION_HEADER}" \
                --method GET \
                /orgs/"${GH_ORG_NAME}"/teams/"${GH_TEAM_NAME}"/memberships/"${member}" \
                --jq '.role')

  if [[ $? -eq 0 ]]; then
    echo "${member_role}"
  else
    echo -n "${ERR} An error occurred while obtaining the '${GH_TEAM_NAME}'"
    echo " team member role in the '${GH_ORG_NAME}' organization. "
    exit 1
  fi
}

# Deletes a specified team from the GitHub organization.
# Usage: delete_team
delete_team() {
  # API request for a team deletion
  gh api \
     --method DELETE \
     --header "Accept: ${GH_API_ACCEPT_HEADER}" \
     --header "X-GitHub-Api-Version: ${GH_API_VERSION_HEADER}" \
     /orgs/"${GH_ORG_NAME}"/teams/"${GH_TEAM_NAME}" \
     --silent

  # Check whether the operation was successful
    if [[ $? -eq 0 ]]; then
      echo -n "${OK} The '${GH_TEAM_NAME}' team has been deleted "
      echo "from the '${GH_ORG_NAME}' organization."
    else
      echo -n "${ERR} An error occurred while deleting the '${GH_TEAM_NAME}'" >&2
      echo " team from the '${GH_ORG_NAME}' organization." >&2
      exit 1
    fi
}

# Deletes the entire GitHub organization.
# Usage: delete_organization
delete_organization() {
  # API request for an organization deletion
  gh api \
     --method DELETE \
     --header "Accept: ${GH_API_ACCEPT_HEADER}" \
     --header "X-GitHub-Api-Version: ${GH_API_VERSION_HEADER}" \
     /orgs/"${GH_ORG_NAME}" \
     --silent

  # Check whether the operation was successful
  if [[ $? -eq 0 ]]; then
    echo "${OK} The '${GH_ORG_NAME}' organization has been deleted "
  else
    echo -n "${ERR} An error occurred while deleting the " >&2
    echo "'${GH_ORG_NAME}' organization" >&2
    exit 1
  fi
}

# VALIDATION FUNCTIONS----------------------------------------------------------#
# Check if the configured platform CLI is installed
check_if_platform_cli_installed() {
  if ! command -v "${SOC_PLATFORM_CLI}" &>/dev/null; then
    echo "${ERR} Platform CLI '${SOC_PLATFORM_CLI}' is not installed." >&2
    return 1
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
