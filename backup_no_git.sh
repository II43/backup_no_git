#!/bin/bash

# Please note that portions of this script were generated with assistance from the Google's Gemini AI

# --- Functions ---

# Function to print all subdirectories of a given directory
backup_subdirectories() {
  local dir="$1"
  if [ -d "$dir" ]; then
    backup_files "$dir"
    find "$dir" -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d $'\0' subdir; do
        # for subdir in $SUBDIRECTORIES; do
        # Check if the subdirectory contains a .git repository
        if contains_git_repo "$subdir"; then
            echo "Skipping backup for '$subdir' (contains .git repository)"
            local dest_dir="$(pwd)${subdir}"
            echo "$dest_dir"
            store_git_repo_info "$subdir" "$dest_dir" 
        elif is_hidden_directory "$subdir"; then
            echo "Skipping backup for hidden directory and its subdirectories: '$subdir'"
        else
            # echo "Backing up '$subdir'..."
            backup_subdirectories "$subdir"
        fi
    done
  else
    echo "Error: Directory '$dir' not found."
  fi
}

# Function to print all files in a given directory
backup_files() {
  local dir="$1"
  if [ -d "$dir" ]; then
    find "$dir" -maxdepth 1 -type f -print0 | while IFS= read -r -d $'\0' file; do
    #for file in $FILES; do
      echo "$file"
      copy_file_preserving_path "$file" $(pwd)
    done
  else
    echo "Error: Directory '$dir' not found."
  fi
}

copy_file_preserving_path() {
  local source_file="$1"
  local new_base_dir="$2"
 
  # Extract the directory part of the source file's absolute path
  local source_dir=$(dirname "$source_file")

  # Construct the full destination directory path
  local dest_dir="${new_base_dir}${source_dir}"

  # Create the destionation directory and copy the file if not in dry-run mode
  if ! $DRY_RUN; then
    if ! mkdir -p "$dest_dir"; then
      echo "Error: Failed to create destination directory '$dest_dir'." >&2
      return 1
    fi

    #    The trailing slash on "$dest_dir/" ensures 'cp' treats it as a directory.
    if ! cp "$source_file" "$dest_dir/"; then
      echo "Error: Failed to copy '$source_file' to '$dest_dir/'." >&2
      return 1
    fi
  fi
  
  # Print message what happened
  echo "Successfully copied '$source_file' to '${dest_dir}/$(basename "$source_file")'"
  return 0
}

# Function to check if a directory contains a .git subdirectory
contains_git_repo() {
  local dir="$1"
  if [ -d "$dir/.git" ]; then
    return 0 # True
  else
    return 1 # False
  fi
}

# Function to check if a directory is hidden (starts with a dot)
is_hidden_directory() {
  local dir="$1"
  local base_name=$(basename "$dir")
  if [[ "$base_name" == .* ]]; then
    return 0 # True
  else
    return 1 # False
  fi
}

store_git_repo_info() {
    local dir="$1"
    local dest_dir="$2"

    # Create the destionation directory if not in dry-run mode
    if ! $DRY_RUN; then
      if ! mkdir -p "$dest_dir"; then
          echo "Error: Failed to create destination directory '$dest_dir'." >&2
          return 1
      fi
    fi

    local info_file="$dest_dir/git-info.txt"
    # Subshell
    ( 
        cd "$dir" 2>/dev/null || continue
        # Check if the current directory is a Git repository work tree.
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
          repo_path="$(pwd)" # Get the absolute path of the repository's working directory.

          # Store the repository information if not in dry-run mode
          if ! $DRY_RUN; then
            echo "---------------------------------------------------" > "$info_file"
            echo "Repository path: $repo_path" >> "$info_file"
          fi
    
          # Get current branch
          current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
          if [ -z "$current_branch" ]; then
              current_branch="(DETACHED HEAD / no branch)"
          fi

          # Get origin URL
          origin_url=$(git remote get-url origin 2>/dev/null)
          if [ -z "$origin_url" ]; then
              origin_url="(No 'origin' remote configured)"
          fi

          # Store the repository information if not in dry-run mode
          if ! $DRY_RUN; then
            echo "  Origin:     $origin_url" >> "$info_file"
            echo "  Branch:     $current_branch" >> "$info_file"
            echo "---------------------------------------------------" >> "$info_file"
          fi
          # Print message what happened
          echo "Successfully stored git repository info to '$info_file'"
        fi
  )
  # End of subshell. 
  # The 'cd' command's effect is confined to this subshell.
}

# Function to display the help message.
show_help() {
  echo "Usage: $0 [OPTIONS] <directory_path_to_be_backed_up>"
  echo "       $0 --help"
  echo ""
  echo "Recursively backup all files in a given directory and its subdirectories."
  echo ""
  echo "Arguments:"
  echo "  <directory_path_to_be_backed_up> The directory to be backed up recursively."
  echo ""
  echo "Options:"
  echo "  --execute        (Optional) Executes the backup action."
  echo "                   By default (if this option is absent), this script runs in dry-run mode."
  echo "  --help           (Optional) Display this help message and exit."
  echo ""
  echo "Description:"
  echo "  This script creates a backup of all files in the specified directory tree."
  echo "  It has following important features: "
  echo "    * It is recursive and thus backs up all subdirectories too."
  echo "    * It skips thes folder that are Git repositories but stores their information in a text file."
  echo "    * It skips hidden folders."
  echo "    * It creates the backup in current directory from where it is run."
  echo "    * It preserves the absolute directory structure."
  echo "    * By default runs in dry-run mode."
  echo ""  
}

main() {
  # --- Argument Parsing ---
  # Initialize START_DIR to empty. It will store the path to the directory.
  BACKED_UP_DIR=""
  DRY_RUN=true

  # Export DRY_RUN to make it available in subshells.
  export DRY_RUN

  # Parse arguments using a while loop and shift.
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --execute) # Option to trigger actual action
        DRY_RUN=false # Set DRY_RUN to false to enable execution
        shift # Consume the --execute argument
        ;;
      --help)
        show_help
        exit 0 # Exit immediately after showing help
        ;;
      *)
        if [ -n "$BACKED_UP_DIR" ]; then
          echo "Error: Too many arguments. Only one directory path is allowed." >&2 # Output error to stderr
          echo "For usage information, run: $0 --help" >&2
          exit 1
        fi
        BACKED_UP_DIR="$1" # Assign the current argument as the directory path
        shift # Consume the directory path argument
        ;;
    esac
  done

  # --- Main Script Logic ---
  if [ -z "$BACKED_UP_DIR" ]; then
    echo "Error: Directory path to be backed up is required." >&2
    show_help
    exit 1
  fi

  if [ ! -d "$BACKED_UP_DIR" ]; then
      echo "Error: Provided directory '$BACKED_UP_DIR' does not exist or is not a directory." >&2
      exit 1
  fi

  BACKED_UP_DIR_ABSOLUTE=$(realpath "$BACKED_UP_DIR")
  if [ $? -ne 0 ] || [ -z "$BACKED_UP_DIR_ABSOLUTE" ]; then
      echo "Error: Failed to resolve absolute path for '$BACKED_UP_DIR'." >&2
      exit 1
  fi

  backup_subdirectories "$BACKED_UP_DIR_ABSOLUTE"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
