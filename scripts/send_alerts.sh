#!/bin/bash
# Script to send email alerts for heavily delayed routes

# Source utilities
source "$(dirname "$0")/../utils/helpers.sh"

# Function to send email alert
send_email_alert() {
    local subject="$1"
    local body="$2"
    local recipient="$ALERT_EMAIL"
    
    log_message "INFO" "Preparing email alert for $recipient"
    
    # Check if mailx is installed
    if ! command -v mailx &> /dev/null; then
        log_message "WARN" "mailx not installed. Email not sent. Install with: sudo apt-get install mailutils"
        log_message "INFO" "Alert would contain:"
        log_message "INFO" "Subject: $subject"
        return 1
    fi
    
    # Send email
    echo -e "$body" | mailx -s "$subject" "$recipient" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        log_message "INFO" "Email alert sent successfully"
        return 0
    else
        log_message "ERROR" "Failed to send email alert"
        return 1
    fi
}

# Function to check for critical delays and send alerts
check_and_alert() {
    local delay_file="$PROCESSED_DIR/delays_calculated_$(get_today).csv"
    local problem_file="$PROCESSED_DIR/heavily_delayed_$(get_today).txt"
    
    log_message "INFO" "Checking for critical delays"
    
    if ! validate_file "$problem_file"; then
        log_message "INFO" "No heavily delayed routes found"
        return 0
    fi
    
    # Count critical and major delays (fix for newline issue)
    local critical_count
    local major_count
    
    critical_count=$(tail -n +2 "$problem_file" 2>/dev/null | grep -c "CRITICAL" || echo "0")
    critical_count=$(echo "$critical_count" | tr -d '\n\r' | xargs)
    
    major_count=$(tail -n +2 "$problem_file" 2>/dev/null | grep -c "MAJOR" || echo "0")
    major_count=$(echo "$major_count" | tr -d '\n\r' | xargs)
    
    if [[ $critical_count -gt 0 ]] || [[ $major_count -gt 0 ]]; then
        log_message "ALERT" "Found $critical_count critical and $major_count major delays"
        
        # Prepare email body
        local email_body="🚨 PUBLIC TRANSPORT DELAY ALERT\n"
        email_body+="================================\n\n"
        email_body+="Date: $(get_today)\n"
        email_body+="Time: $(date +"%H:%M:%S")\n\n"
        email_body+="SUMMARY:\n"
        email_body+="--------\n"
        email_body+="🔴 Critical Delays (>$CRITICAL_DELAY min): $critical_count\n"
        email_body+="🟠 Major Delays (>$MAJOR_DELAY min): $major_count\n\n"
        email_body+="AFFECTED ROUTES:\n"
        email_body+="----------------\n"
        email_body+="$(cat "$problem_file")\n\n"
        email_body+="Please check the full HTML report for more details.\n"
        email_body+="Report location: $REPORTS_DIR/daily/report_$(get_today).html\n\n"
        email_body+="---\n"
        email_body+="This is an automated alert from the Transport Delay Tracker system.\n"
        
        # Send alert
        send_email_alert "🚨 Transport Delay Alert - $(get_today)" "$email_body"
    else
        log_message "INFO" "No critical alerts to send"
    fi
}

# Function to generate alert summary for logging
generate_alert_summary() {
    local problem_file="$PROCESSED_DIR/heavily_delayed_$(get_today).txt"
    
    if ! validate_file "$problem_file"; then
        log_message "INFO" "No alerts to summarize"
        return 0
    fi
    
    log_message "INFO" "Alert Summary:"
    
    while IFS=',' read -r route vehicle stop delay severity; do
        if [[ "$route" != "Route" ]]; then  # Skip header
            log_message "ALERT" "[$severity] $route - $vehicle at $stop: $delay min delay"
        fi
    done < "$problem_file"
}

# Main execution
main() {
    log_message "INFO" "========== Starting Alert Check =========="
    
    # Generate summary
    generate_alert_summary
    
    # Check and send alerts
    check_and_alert
    
    log_message "INFO" "========== Alert Check Complete =========="
    
    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi
