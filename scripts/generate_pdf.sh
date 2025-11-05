#!/bin/bash
# Script to generate PDF reports from HTML

# Source utilities
source "$(dirname "$0")/../utils/helpers.sh"

# Function to generate PDF from HTML
generate_pdf_report() {
    local today=$(get_today)
    local html_file="$REPORTS_DIR/daily/report_$today.html"
    local pdf_file="$REPORTS_DIR/daily/report_$today.pdf"
    
    log_message "INFO" "Generating PDF report from HTML"
    
    # Check if HTML file exists
    if ! validate_file "$html_file"; then
        log_message "ERROR" "HTML report not found: $html_file"
        return 1
    fi
    
    # Check if wkhtmltopdf is installed
    if ! command -v wkhtmltopdf &> /dev/null; then
        log_message "ERROR" "wkhtmltopdf is not installed"
        log_message "INFO" "Install with: sudo apt-get install wkhtmltopdf"
        return 1
    fi
    
    log_message "INFO" "Converting HTML to PDF..."
    
    # Convert HTML to PDF with options
    wkhtmltopdf \
        --enable-local-file-access \
        --page-size A4 \
        --orientation Portrait \
        --margin-top 10mm \
        --margin-bottom 10mm \
        --margin-left 10mm \
        --margin-right 10mm \
        --enable-javascript \
        --javascript-delay 2000 \
        --no-stop-slow-scripts \
        --quiet \
        "$html_file" \
        "$pdf_file" 2>/dev/null
    
    if [[ $? -eq 0 ]] && [[ -f "$pdf_file" ]]; then
        log_message "INFO" "PDF report generated successfully: $pdf_file"
        
        # Get file size
        local size=$(du -h "$pdf_file" | cut -f1)
        log_message "INFO" "PDF size: $size"
        
        echo "$pdf_file"
        return 0
    else
        log_message "ERROR" "Failed to generate PDF report"
        return 1
    fi
}

# Function to generate PDF with alternative method (if wkhtmltopdf fails)
generate_pdf_alternative() {
    local today=$(get_today)
    local html_file="$REPORTS_DIR/daily/report_$today.html"
    local pdf_file="$REPORTS_DIR/daily/report_$today.pdf"
    
    log_message "WARN" "Trying alternative PDF generation method"
    
    # Check if weasyprint is available
    if command -v weasyprint &> /dev/null; then
        log_message "INFO" "Using weasyprint for PDF generation"
        weasyprint "$html_file" "$pdf_file" 2>/dev/null
        
        if [[ $? -eq 0 ]]; then
            log_message "INFO" "PDF generated with weasyprint"
            echo "$pdf_file"
            return 0
        fi
    fi
    
    log_message "ERROR" "No PDF generation tool available"
    log_message "INFO" "Install wkhtmltopdf: sudo apt-get install wkhtmltopdf"
    log_message "INFO" "Or install weasyprint: pip3 install weasyprint"
    return 1
}

# Main execution
main() {
    log_message "INFO" "========== Starting Report Generation =========="
    
    # Generate CSV report
    csv_report=$(generate_csv_report)
    
    if [[ -z "$csv_report" ]] || [[ ! -f "$csv_report" ]]; then
        log_message "ERROR" "CSV report generation failed"
        exit 1
    fi
    
    # Generate HTML report with charts
    html_report=$(generate_html_report)
    
    if [[ -z "$html_report" ]] || [[ ! -f "$html_report" ]]; then
        log_message "ERROR" "HTML report generation failed"
        exit 1
    fi
    
    # Generate PDF report (call the PDF script)
    log_message "INFO" "Generating PDF report..."
    bash "$(dirname "$0")/generate_pdf.sh"
    
    log_message "INFO" "========== Report Generation Complete =========="
    
    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi
