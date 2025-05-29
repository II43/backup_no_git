#!/bin/bash

# Please note that portions of this script were generated with assistance from the Google's Gemini AI

# Function to calculate SHA-1 hash of all content in a folder
calculate_folder_sha1() {
    local folder_path="$1"
    if [ ! -d "$folder_path" ]; then
        echo "Error: Folder '$folder_path' not found."
        return 1
    fi

    # Loop through Find all files and directories, sort them for consistent hashing,
    local SHA1S=""
    while IFS= read -r -d $'\0' item; do
        SHA1S+="$item\n"
        if [[ -f "$item" ]]; then
            # SHA1S+=$(cat "$item" | sha1sum | awk '{print $1}')
            SHA1S+=$(sha1sum "$item" | awk '{print $1}')
            SHA1S+="\n"
        fi
        # echo -e "$SHA1S"
    done < <(find "$folder_path" -print0)
    # echo -e "$SHA1S"
    SHA1=$(echo "$SHA1S" | sha1sum | awk '{print $1}')
    echo "$SHA1"
}

# Main test script execution
echo "--- TESTING STARTED ---"
SCRIPT_UNDER_TEST="../backup_no_git.sh"
SCRIPT_UNDER_TEST=$(realpath "$SCRIPT_UNDER_TEST")


if [ ! -f "$SCRIPT_UNDER_TEST" ]; then
    echo "Error: Provided script to be tested '$SCRIPT_UNDER_TEST' does not exist!" >&2
    echo "       This script is meant to be run from the 'tests' folder." >&2
    exit 1
else
    echo "Script under test: '$SCRIPT_UNDER_TEST'"
fi

# Testing folder
folder_to_hash="test_1"

# Make temporary folder
mkdir -p /tmp/testing 
cp -r "$folder_to_hash" /tmp/testing
folder_to_hash="/tmp/testing/$folder_to_hash"
echo "Test folder: '$folder_to_hash'"

cd /tmp/testing
eval "$SCRIPT_UNDER_TEST" "$folder_to_hash" "--execute > /dev/null 2>&1"

folder_hash=$(calculate_folder_sha1 "/tmp/testing/tmp")
echo "Actual SHA-1 of backed up folder: $folder_hash"

if [[ "$folder_hash" == "b609d13b863003805e1eb5b031729a1b5b87dfc1" ]]; then
  echo "TEST PASSED!"
else
  echo "TEST FAILED!"
fi

# Clean-up
rm -rf /tmp/testing
echo "--- DONE ---"
