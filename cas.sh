#!/bin/bash

# Function to display help message
function display_help() {
  echo "Usage: $0 INPUT_FILE DESTINATION_FOLDER"
  echo ""
  echo "INPUT_FILE: A file where each line contains a git repository URL."
  echo "DESTINATION_FOLDER: The folder where repositories will be cloned."
  exit 1
}

# Validate parameters
if [[ $# -ne 2 ]]; then
  echo "Error: Invalid number of arguments."
  display_help
fi

INPUT_FILE=$1
DESTINATION_FOLDER=$2

# Get the directory where the script is located
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Resolve INPUT_FILE and DESTINATION_FOLDER relative to the script's directory, if necessary
if [[ ! "$INPUT_FILE" = /* ]]; then
  INPUT_FILE="$SCRIPT_DIR/$INPUT_FILE"
fi

if [[ ! "$DESTINATION_FOLDER" = /* ]]; then
  DESTINATION_FOLDER="$SCRIPT_DIR/$DESTINATION_FOLDER"
fi

# Check if the input file exists and is a regular file
if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Error: INPUT_FILE '$INPUT_FILE' does not exist or is not a regular file."
  exit 1
fi

# Create destination folder if it does not exist
if [[ ! -d "$DESTINATION_FOLDER" ]]; then
  mkdir -p "$DESTINATION_FOLDER" || {
    echo "Error: Failed to create folder '$DESTINATION_FOLDER'"
    exit 1
  }
fi

# Change to the destination directory
cd "$DESTINATION_FOLDER" || {
  echo "Error: Unable to navigate to folder '$DESTINATION_FOLDER'"
  exit 1
}

# Process each line in the input file
while IFS= read -r GIT_URL; do
  # Skip empty lines
  GIT_URL=$(echo "$GIT_URL" | xargs) # Trim leading/trailing whitespace

  if [[ -z "$GIT_URL" ]]; then
    continue
  fi

  # Debugging output (you can remove this once it works)
  echo "Cloning repository: $GIT_URL"

  # Clone the repository and capture the output folder name
  git clone "$GIT_URL"
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to clone repository '$GIT_URL'"
    exit 1
  fi

  # Get the actual cloned directory name from the URL
  REPO_NAME=$(basename "$GIT_URL" .git)

  # Check if the folder exists after cloning
  if [[ ! -d "$REPO_NAME" ]]; then
    echo "Error: Cloned repository folder '$REPO_NAME' not found."
    exit 1
  fi

  # Navigate to the cloned repository folder
  cd "$REPO_NAME" || {
    echo "Error: Failed to enter directory '$REPO_NAME'"
    exit 1
  }

  # Run semgrep ci command
  semgrep ci || {
    echo "Error: semgrep ci failed for repository '$REPO_NAME'"
    exit 1
  }

  # Go back to the parent directory (destination folder)
  cd ..

done <"$INPUT_FILE"

# Success message
echo "All repositories cloned and scanned successfully!"
exit 0
