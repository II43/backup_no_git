# backup_no_git
Recursively backup all files in a given directory and its subdirectories.

<h1>Motivation</h1>
There are other (and much better) tools for creating back ups of your files and folders. Yet the motivation for creating this script is to have simple script to transparently just copy all files while skipping folder under Git version control. Nothing more, nothing less.


<br>
<h1>Description</h1>
This script creates a backup of all files in the specified directory tree. It has following important features:

* It is recursive and thus backs up all subdirectories too.
* It skips thes folder that are Git repositories but stores their information in a text file.
* It skips hidden folders.
* It creates the backup in current directory from where it is run.
* It preserves the absolute directory structure.
* By default runs in dry-run mode.

<h1>Usage</h1>
<pre>
./backup_no_git.sh [OPTIONS] <directory_path_to_be_backed_up>p
Arguments:
  <directory_path_to_be_backed_up> The directory to be backed up recursively.

Options:
  --execute        (Optional) Executes the backup action.
                   By default (if this option is absent), this script runs in dry-run mode.
  --help           (Optional) Display this help message and exit.
</pre>