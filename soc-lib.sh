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
