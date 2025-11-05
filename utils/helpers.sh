#!/bin/bash
# Utility functions for the project

# Source configuration
source "$(dirname "${BASH_SOURCE[0]}")/../config/config.sh"

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"$DATETIME_FORMAT")
    echo "[$timestamp] [$level] $message" >> "$LOGS_DIR/delays.log"
    echo "[$timestamp] [$level] $message" >&2
}

# Convert time to seconds since midnight
time_to_seconds() {
    local time_str="$1"
    local hours minutes seconds
    
    IFS=: read -r hours minutes seconds <<< "$time_str"
    echo $(( 10#$hours * 3600 + 10#$minutes * 60 + 10#${seconds:-0} ))
}

# Calculate delay in minutes
calculate_delay_minutes() {
    local scheduled="$1"
    local actual="$2"
    
    local scheduled_sec=$(time_to_seconds "$scheduled")
    local actual_sec=$(time_to_seconds "$actual")
    
    local delay_sec=$((actual_sec - scheduled_sec))
    local delay_min=$((delay_sec / 60))
    
    echo "$delay_min"
}

# Check if file exists and is not empty
validate_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        log_message "ERROR" "File not found: $file"
        return 1
    fi
    if [[ ! -s "$file" ]]; then
        log_message "WARN" "File is empty: $file"
        return 1
    fi
    return 0
}

# Create timestamp for filenames
get_timestamp() {
    date +"%Y%m%d_%H%M%S"
}

# Get today's date
get_today() {
    date +"$DATE_FORMAT"
}

# Archive old logs
rotate_logs() {
    local retention_days="$LOG_RETENTION_DAYS"
    log_message "INFO" "Rotating logs older than $retention_days days"
    find "$LOGS_DIR" -name "*.log" -mtime +$retention_days -delete 2>/dev/null
}
