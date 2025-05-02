# team51-user-removal

A wrapper script for the team51 CLI tool to remove multiple users from WordPress sites.

## Overview

This script enhances the functionality of the `team51 wpcom:delete-site-wp-user` command by allowing you to process multiple email addresses in one go. It provides several input methods and additional features to make the user removal process more efficient.

## Features

- **Multiple Input Methods**:
  - Interactive prompt for entering emails one by one
  - Command-line arguments for specifying emails directly
  - File input for processing a list of emails from a text file

- **Additional Features**:
  - Confirmation prompt before processing each email (with option to skip)
  - Colorized output for better readability
  - Summary of results after all operations
  - Error handling for failed operations
  - Automatic logging to timestamped files (logfile_YYYYMMDD_HHMM.txt) with option to disable
  - Option to show only summary (suppress detailed output)

## Installation

1. Clone this repository or download the script:
   ```bash
   git clone https://github.com/yourusername/team51-user-removal.git
   ```

2. Make the script executable (if not already):
   ```bash
   chmod +x team51-user-removal.sh
   ```

3. Ensure the `team51` CLI tool is installed and properly configured on your system.

## Usage

### Basic Usage

Run the script without any arguments to enter interactive mode:

```bash
./team51-user-removal.sh
```

This will prompt you to enter email addresses one by one. Press Enter on an empty line to finish input.

### Command-line Arguments

```bash
./team51-user-removal.sh [OPTIONS]
```

### Options

- `-h, --help`: Display help information and exit
- `-e, --email EMAIL [...]`: Specify one or more email addresses
- `-f, --file FILE`: Read email addresses from a file (one per line)
- `-y, --yes`: Skip confirmation for each email (auto-confirm)
- `-s, --summary`: Show only summary (suppress detailed output)
- `-n, --no-log`: Disable logging (default: logs to logfile_YYYYMMDD_HHMM.txt)

### Examples

1. Process a single email:
   ```bash
   ./team51-user-removal.sh -e user@automattic.com
   ```

2. Process multiple emails:
   ```bash
   ./team51-user-removal.sh -e user1@automattic.com user2@automattic.com
   ```

3. Read emails from a file:
   ```bash
   ./team51-user-removal.sh -f emails.txt
   ```

4. Skip confirmation prompts:
   ```bash
   ./team51-user-removal.sh -f emails.txt -y
   ```

5. Disable logging:
   ```bash
   ./team51-user-removal.sh -e user@automattic.com -n
   ```

6. Show only summary (suppress detailed output):
   ```bash
   ./team51-user-removal.sh -f emails.txt -s
   ```

## File Format

When using the `-f, --file` option, the file should contain one email address per line. Lines starting with `#` are treated as comments and ignored. Empty lines are also ignored.

Example file content:
```
# List of users to remove
user1@automattic.com
user2@automattic.com
user3@automattic.com
```

## Notes

- The script validates email addresses using a basic regex pattern.
- For each email, the script runs: `team51 wpcom:delete-site-wp-user EMAIL --multiple all`
- The script captures and displays the full output from the team51 CLI tool.
- A summary is displayed after all operations are complete.
- By default, all output is logged to a timestamped file (e.g., `logfile_20250502_1348.txt`) in the same directory as the script. This prevents overwriting logs when running the script multiple times.

## Requirements

- Bash shell
- team51 CLI tool installed and configured
