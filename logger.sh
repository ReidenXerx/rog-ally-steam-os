#!/bin/bash
# ROG Ally Suite - Universal Logging System
# Captures all console output and script actions to a single log file

# Global logging configuration
readonly LOG_BASE_DIR="/home/deck/.local/share/rog-ally-suite/logs"
readonly SESSION_LOG_FILE="${LOG_BASE_DIR}/session-$(date +%Y%m%d-%H%M%S).log"
readonly LATEST_LOG_LINK="${LOG_BASE_DIR}/latest.log"

# Colors for console output (preserved in logs with ANSI codes)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

# Initialize logging system
init_logging() {
    # Ensure log directory exists
    mkdir -p "$LOG_BASE_DIR"
    
    # Create session log file
    cat > "$SESSION_LOG_FILE" << EOF
================================================================================
ROG Ally Suite - Session Log
Started: $(date)
User: $(whoami)
Working Directory: $(pwd)
Script: ${0##*/}
Arguments: $*
================================================================================

EOF
    
    # Create/update latest log symlink
    rm -f "$LATEST_LOG_LINK"
    ln -sf "$SESSION_LOG_FILE" "$LATEST_LOG_LINK"
    
    # Set up logging redirection
    exec > >(tee -a "$SESSION_LOG_FILE")
    exec 2> >(tee -a "$SESSION_LOG_FILE" >&2)
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SYSTEM] Logging initialized: $SESSION_LOG_FILE"
}

# Enhanced logging function that works with the global log
log_message() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Format the message with color and timestamp
    local formatted_message
    case "$level" in
        "INFO")     formatted_message="${BLUE}[INFO]${NC} $message" ;;
        "WARN")     formatted_message="${YELLOW}[WARN]${NC} $message" ;;
        "ERROR")    formatted_message="${RED}[ERROR]${NC} $message" ;;
        "SUCCESS")  formatted_message="${GREEN}[SUCCESS]${NC} $message" ;;
        "DEBUG")    formatted_message="${DIM}[DEBUG]${NC} $message" ;;
        "SYSTEM")   formatted_message="${PURPLE}[SYSTEM]${NC} $message" ;;
        *)          formatted_message="[$level] $message" ;;
    esac
    
    # Output to console (which also goes to log via tee)
    echo -e "$timestamp $formatted_message"
}

# Log command execution with full output capture
log_command() {
    local description="$1"
    shift
    local command="$*"
    
    log_message "SYSTEM" "Executing: $description"
    log_message "DEBUG" "Command: $command"
    echo "--- COMMAND OUTPUT START ---"
    
    local exit_code=0
    eval "$command" || exit_code=$?
    
    echo "--- COMMAND OUTPUT END (Exit Code: $exit_code) ---"
    log_message "SYSTEM" "Command completed with exit code: $exit_code"
    
    return $exit_code
}

# Log script execution
log_script_execution() {
    local script_path="$1"
    local description="$2"
    
    log_message "SYSTEM" "Starting script: $description"
    log_message "DEBUG" "Script path: $script_path"
    
    if [[ -f "$script_path" ]]; then
        echo "--- SCRIPT EXECUTION START: $(basename "$script_path") ---"
        
        local exit_code=0
        "$script_path" || exit_code=$?
        
        echo "--- SCRIPT EXECUTION END: $(basename "$script_path") (Exit Code: $exit_code) ---"
        log_message "SYSTEM" "Script completed: $description (Exit Code: $exit_code)"
        
        return $exit_code
    else
        log_message "ERROR" "Script not found: $script_path"
        return 1
    fi
}

# Log system information
log_system_info() {
    log_message "SYSTEM" "Capturing system information"
    echo "--- SYSTEM INFORMATION START ---"
    
    echo "Timestamp: $(date)"
    echo "User: $(whoami)"
    echo "Home: $HOME"
    echo "PWD: $(pwd)"
    echo "Shell: $SHELL"
    echo "PATH: $PATH"
    
    if [[ -f /etc/os-release ]]; then
        echo ""
        echo "OS Information:"
        cat /etc/os-release
    fi
    
    echo ""
    echo "System Load:"
    uptime
    
    echo ""
    echo "Memory Usage:"
    free -h
    
    echo ""
    echo "Disk Usage:"
    df -h /
    
    echo "--- SYSTEM INFORMATION END ---"
}

# Cleanup old log files
cleanup_logs() {
    local retention_days="${1:-30}"
    
    log_message "SYSTEM" "Cleaning up logs older than $retention_days days"
    
    # Find and remove old log files
    find "$LOG_BASE_DIR" -name "session-*.log" -mtime +$retention_days -delete 2>/dev/null || true
    
    local remaining_logs=$(find "$LOG_BASE_DIR" -name "session-*.log" | wc -l)
    log_message "SUCCESS" "Log cleanup completed. $remaining_logs session logs remaining."
}

# Get current log file path
get_current_log() {
    echo "$SESSION_LOG_FILE"
}

# Get latest log file path
get_latest_log() {
    echo "$LATEST_LOG_LINK"
}

# Show log location to user
show_log_location() {
    echo
    echo -e "${CYAN}📝 Full session log:${NC} $SESSION_LOG_FILE"
    echo -e "${CYAN}🔗 Latest log link:${NC} $LATEST_LOG_LINK"
    echo -e "${DIM}Use 'tail -f $LATEST_LOG_LINK' to follow the log in real-time${NC}"
    echo
}

# Export functions for use in other scripts
export -f log_message
export -f log_command
export -f log_script_execution
export -f log_system_info
export -f get_current_log
export -f get_latest_log
