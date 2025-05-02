#!/bin/bash

# team51-user-removal.sh
# A wrapper script for the team51 CLI tool to remove multiple users from WordPress sites

# ANSI color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize variables
emails=()
auto_confirm=false
log_file="log.txt"
summary_only=false
success_count=0
failure_count=0
failed_emails=()

# Create or clear the log file
> "$log_file"

# Function to display help information
show_help() {
    echo -e "${BLUE}team51-user-removal${NC} - A wrapper for the team51 CLI tool"
    echo
    echo "This script allows you to remove multiple users from WordPress sites using the team51 CLI."
    echo
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ./team51-user-removal.sh [OPTIONS]"
    echo
    echo -e "${YELLOW}Options:${NC}"
    echo "  -h, --help                 Show this help message and exit"
    echo "  -e, --email EMAIL [...]    Specify one or more email addresses"
    echo "  -f, --file FILE            Read email addresses from a file (one per line)"
    echo "  -y, --yes                  Skip confirmation for each email"
    echo "  -s, --summary              Show only summary (suppress detailed output)"
    echo "  -n, --no-log               Disable logging to log.txt"
    echo
    echo -e "${YELLOW}Examples:${NC}"
    echo "  ./team51-user-removal.sh                           # Interactive mode"
    echo "  ./team51-user-removal.sh -e user@example.com       # Single email"
    echo "  ./team51-user-removal.sh -e user1@example.com user2@example.com  # Multiple emails"
    echo "  ./team51-user-removal.sh -f emails.txt             # Read from file"
    echo "  ./team51-user-removal.sh -f emails.txt -y          # Auto-confirm"
    echo "  ./team51-user-removal.sh -e user@example.com -n    # Disable logging"
    echo
    exit 0
}

# Function to log messages
log_message() {
    local message="$1"
    echo -e "$message"
    if [[ -n "$log_file" ]]; then
        echo -e "$message" >> "$log_file"
    fi
}

# Function to prompt for email addresses interactively
prompt_for_emails() {
    log_message "${BLUE}Enter email addresses (one per line, empty line to finish):${NC}"
    while true; do
        read -r email
        if [[ -z "$email" ]]; then
            break
        fi
        if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            emails+=("$email")
        else
            log_message "${RED}Invalid email format: $email${NC}"
        fi
    done
}

# Function to read emails from a file
read_emails_from_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        log_message "${RED}Error: File not found: $file${NC}"
        exit 1
    fi
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^# ]]; then
            continue
        fi
        
        # Extract email from the line (in case there's other text)
        if [[ "$line" =~ ([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}) ]]; then
            emails+=("${BASH_REMATCH[1]}")
        else
            log_message "${YELLOW}Warning: No valid email found in line: $line${NC}"
        fi
    done < "$file"
}

# Function to remove a user using the team51 CLI
remove_user() {
    local email="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    log_message "\n${BLUE}[$timestamp] Processing: $email${NC}"
    
    if ! $auto_confirm; then
        read -p "Remove $email from all WordPress sites? (y/n): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            log_message "${YELLOW}Skipped: $email${NC}"
            return 0
        fi
    fi
    
    log_message "${BLUE}Running: team51 wpcom:delete-site-wp-user $email --multiple all${NC}"
    
    # Run the team51 command and capture output
    if ! $summary_only; then
        if team51 wpcom:delete-site-wp-user "$email" --multiple all; then
            log_message "${GREEN}Success: $email removed successfully${NC}"
            ((success_count++))
            return 0
        else
            log_message "${RED}Failed: Could not remove $email${NC}"
            ((failure_count++))
            failed_emails+=("$email")
            return 1
        fi
    else
        # Run in summary mode (suppress output)
        if team51 wpcom:delete-site-wp-user "$email" --multiple all &>/dev/null; then
            log_message "${GREEN}Success: $email removed successfully${NC}"
            ((success_count++))
            return 0
        else
            log_message "${RED}Failed: Could not remove $email${NC}"
            ((failure_count++))
            failed_emails+=("$email")
            return 1
        fi
    fi
}

# Function to display summary
show_summary() {
    local total=$((success_count + failure_count))
    
    log_message "\n${BLUE}=== Summary ===${NC}"
    log_message "Total emails processed: $total"
    log_message "${GREEN}Successful: $success_count${NC}"
    log_message "${RED}Failed: $failure_count${NC}"
    
    if [[ ${#failed_emails[@]} -gt 0 ]]; then
        log_message "\n${RED}Failed emails:${NC}"
        for email in "${failed_emails[@]}"; do
            log_message "  - $email"
        done
    fi
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            ;;
        -e|--email)
            shift
            while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
                if [[ "$1" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                    emails+=("$1")
                else
                    log_message "${RED}Invalid email format: $1${NC}"
                fi
                shift
            done
            continue
            ;;
        -f|--file)
            if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                read_emails_from_file "$2"
                shift 2
            else
                log_message "${RED}Error: --file requires a filename${NC}"
                exit 1
            fi
            ;;
        -y|--yes)
            auto_confirm=true
            shift
            ;;
        -n|--no-log)
            log_file=""
            shift
            ;;
        -s|--summary)
            summary_only=true
            shift
            ;;
        *)
            log_message "${RED}Unknown option: $1${NC}"
            show_help
            ;;
    esac
done

# If no emails provided, prompt for them
if [[ ${#emails[@]} -eq 0 ]]; then
    prompt_for_emails
fi

# Check if we have any emails to process
if [[ ${#emails[@]} -eq 0 ]]; then
    log_message "${RED}Error: No email addresses provided${NC}"
    exit 1
fi

# Display the list of emails to be processed
log_message "\n${BLUE}The following email addresses will be processed:${NC}"
for email in "${emails[@]}"; do
    log_message "  - $email"
done
log_message ""

# Process each email
for email in "${emails[@]}"; do
    remove_user "$email"
done

# Show summary
show_summary

exit 0
