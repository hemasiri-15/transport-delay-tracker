#!/bin/bash
# Main orchestrator script for Transport Delay Tracker

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utilities and config
source "$SCRIPT_DIR/../utils/helpers.sh"

# Print banner
print_banner() {
    echo ""
    echo "========================================"
    echo "   🚍 TRANSPORT DELAY TRACKER 🚊"
    echo "========================================"
    echo "   Date: $(get_today)"
    echo "   Time: $(date +"%H:%M:%S")"
    echo "========================================"
    echo ""
}

# Function to run the complete pipeline
run_pipeline() {
    log_message "INFO" "Starting Transport Delay Tracker Pipeline"
    
    # Step 1: Data Ingestion
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "STEP 1: Data Ingestion"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    bash "$SCRIPT_DIR/ingest_data.sh"
    local ingest_status=$?
    if [[ $ingest_status -ne 0 ]]; then
        log_message "ERROR" "Data ingestion failed"
        echo "❌ Pipeline failed at ingestion step"
        return 1
    fi
    echo "✅ Data ingestion complete"
    
    # Step 2: Delay Calculation
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "STEP 2: Delay Calculation"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    bash "$SCRIPT_DIR/calculate_delays.sh"
    local calc_status=$?
    if [[ $calc_status -ne 0 ]]; then
        log_message "ERROR" "Delay calculation failed"
        echo "❌ Pipeline failed at calculation step"
        return 1
    fi
    echo "✅ Delay calculation complete"
    
    # Step 3: Report Generation
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "STEP 3: Report Generation"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    bash "$SCRIPT_DIR/generate_reports.sh"
    local report_status=$?
    if [[ $report_status -ne 0 ]]; then
        log_message "ERROR" "Report generation failed"
        echo "❌ Pipeline failed at report generation step"
        return 1
    fi
    echo "✅ Report generation complete"
    
    # Step 4: Send Alerts
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "STEP 4: Alert Checks"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    bash "$SCRIPT_DIR/send_alerts.sh"
    local alert_status=$?
    if [[ $alert_status -ne 0 ]]; then
        log_message "WARN" "Alert processing had issues (mailx may not be installed)"
        echo "⚠️  Alert check completed with warnings"
    else
        echo "✅ Alert check complete"
    fi
    
    # Step 5: Log Rotation
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "STEP 5: Maintenance"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    rotate_logs
    echo "✅ Maintenance complete"
    
    echo ""
    log_message "INFO" "Pipeline execution complete!"
    echo ""
    
    # Display summary
    display_summary
    
    return 0
}

# Function to display execution summary
display_summary() {
    echo ""
    echo "========================================"
    echo "   📊 EXECUTION SUMMARY"
    echo "========================================"
    
    local today=$(get_today)
    
    # Check for generated files
    echo ""
    echo "Generated Files:"
    echo "----------------"
    
    if [[ -f "$PROCESSED_DIR/delays_calculated_$today.csv" ]]; then
        local delay_count=$(tail -n +2 "$PROCESSED_DIR/delays_calculated_$today.csv" 2>/dev/null | wc -l)
        echo "✓ Delay data: $delay_count records"
    else
        echo "✗ Delay data: Not found"
    fi
    
    if [[ -f "$REPORTS_DIR/daily/report_$today.csv" ]]; then
        echo "✓ CSV Report: $REPORTS_DIR/daily/report_$today.csv"
    else
        echo "✗ CSV Report: Not generated"
    fi
    
    if [[ -f "$REPORTS_DIR/daily/report_$today.html" ]]; then
        echo "✓ HTML Report: $REPORTS_DIR/daily/report_$today.html"
    else
        echo "✗ HTML Report: Not generated"
    fi
    
    # Check PDF report
    if [[ -f "$REPORTS_DIR/daily/report_$today.pdf" ]]; then
        local pdf_size=$(du -h "$REPORTS_DIR/daily/report_$today.pdf" 2>/dev/null | cut -f1)
        echo "✓ PDF Report: $REPORTS_DIR/daily/report_$today.pdf ($pdf_size)"
    else
        echo "✗ PDF Report: Not generated"
    fi
    
    # Show statistics
    if [[ -f "$PROCESSED_DIR/statistics_$today.txt" ]]; then
        echo ""
        echo "Statistics:"
        echo "-----------"
        cat "$PROCESSED_DIR/statistics_$today.txt"
    fi
    
    # Show alerts
    if [[ -f "$PROCESSED_DIR/heavily_delayed_$today.txt" ]]; then
        local alert_count=$(tail -n +2 "$PROCESSED_DIR/heavily_delayed_$today.txt" 2>/dev/null | wc -l)
        if [[ $alert_count -gt 0 ]]; then
            echo ""
            echo "⚠️  Alerts: $alert_count heavily delayed vehicles"
        else
            echo ""
            echo "✅ No critical delays detected"
        fi
    fi
    
    echo ""
    echo "========================================"
    echo ""
}

# Function to show help
show_help() {
    cat << 'EOF'

Transport Delay Tracker - Main Script
======================================

Usage: bash scripts/main.sh [OPTIONS]

OPTIONS:
    run         Run the complete pipeline (default)
    ingest      Run only data ingestion
    calculate   Run only delay calculation
    report      Run only report generation
    alert       Run only alert checks
    copy        Copy reports to Windows Desktop
    clean       Clean old data files
    cron        Set up automated scheduling
    status      Check cron job status
    help        Show this help message

EXAMPLES:
    bash scripts/main.sh              # Run full pipeline
    bash scripts/main.sh cron         # Set up automation
    bash scripts/main.sh status       # Check cron status

EOF
}

# Function to clean old data
clean_data() {
    echo "Cleaning old data files..."
    log_message "INFO" "Manual cleanup initiated"
    
    find "$LIVE_FEED_DIR" -name "*.json" -mtime +7 -delete 2>/dev/null
    find "$PROCESSED_DIR" -name "*.txt" -mtime +7 -delete 2>/dev/null
    find "$PROCESSED_DIR" -name "*.csv" -mtime +7 -delete 2>/dev/null
    find "$REPORTS_DIR/daily" -name "*.csv" -mtime +30 -delete 2>/dev/null
    find "$REPORTS_DIR/daily" -name "*.html" -mtime +30 -delete 2>/dev/null
    
    echo "✅ Cleanup complete"
    log_message "INFO" "Cleanup complete"
}

# Main execution
main() {
    print_banner
    
    # Parse command line arguments
    local command="${1:-run}"
    
    case "$command" in
        run)
            run_pipeline
            exit $?
            ;;
        ingest)
            echo "Running data ingestion only..."
            bash "$SCRIPT_DIR/ingest_data.sh"
            exit $?
            ;;
        calculate)
            echo "Running delay calculation only..."
            bash "$SCRIPT_DIR/calculate_delays.sh"
            exit $?
            ;;
        report)
            echo "Running report generation only..."
            bash "$SCRIPT_DIR/generate_reports.sh"
            exit $?
            ;;
        alert)
            echo "Running alert checks only..."
            bash "$SCRIPT_DIR/send_alerts.sh"
            exit $?
            ;;
        clean)
            clean_data
            exit 0
            ;;
        cron)
            bash "$SCRIPT_DIR/setup_cron.sh"
            ;;
        status)
            bash "$SCRIPT_DIR/check_cron.sh"
            ;;
        help|--help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
