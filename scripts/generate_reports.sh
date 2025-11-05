#!/bin/bash
# Script to generate CSV and HTML reports with charts

# Source utilities
source "$(dirname "$0")/../utils/helpers.sh"

# Function to generate CSV report
generate_csv_report() {
    local delay_file="$PROCESSED_DIR/delays_calculated_$(get_today).csv"
    local output_file="$REPORTS_DIR/daily/report_$(get_today).csv"
    
    log_message "INFO" "Generating CSV report"
    
    if ! validate_file "$delay_file"; then
        log_message "ERROR" "Delay file not found"
        return 1
    fi
    
    # Group by route and calculate statistics
    echo "Route,Total_Trips,On_Time_Count,On_Time_%,Avg_Delay_Min,Max_Delay_Min" > "$output_file"
    
    tail -n +2 "$delay_file" | awk -F',' -v threshold="$ON_TIME_THRESHOLD" '
    {
        route = $2
        delay = $7
        
        total[route]++
        sum_delay[route] += delay
        
        if (delay <= threshold) {
            on_time[route]++
        }
        
        if (delay > max_delay[route]) {
            max_delay[route] = delay
        }
    }
    END {
        for (route in total) {
            on_time_count = on_time[route] + 0
            on_time_pct = (on_time_count / total[route]) * 100
            avg_delay = sum_delay[route] / total[route]
            printf "%s,%d,%d,%.2f,%.2f,%d\n", route, total[route], on_time_count, on_time_pct, avg_delay, max_delay[route]
        }
    }
    ' >> "$output_file"
    
    log_message "INFO" "CSV report generated: $output_file"
    echo "$output_file"
}

# Function to prepare chart data from delay file
prepare_chart_data() {
    local delay_file="$1"
    
    # Extract data for charts
    # Route names
    local routes=$(tail -n +2 "$delay_file" | awk -F',' '{print $2}' | sort -u | tr '\n' ',' | sed 's/,$//')
    
    # Average delay by route
    local avg_delays=$(tail -n +2 "$delay_file" | awk -F',' '
    {
        route = $2
        delay = $7
        total[route]++
        sum_delay[route] += delay
    }
    END {
        for (route in total) {
            printf "%.2f,", sum_delay[route] / total[route]
        }
    }' | sed 's/,$//')
    
    # On-time percentage by route
    local ontime_pct=$(tail -n +2 "$delay_file" | awk -F',' -v threshold="$ON_TIME_THRESHOLD" '
    {
        route = $2
        delay = $7
        total[route]++
        if (delay <= threshold) {
            on_time[route]++
        }
    }
    END {
        for (route in total) {
            printf "%.2f,", (on_time[route] / total[route]) * 100
        }
    }' | sed 's/,$//')
    
    # Severity counts
    local critical_count=$(tail -n +2 "$delay_file" | grep -c "CRITICAL" || echo 0)
    local major_count=$(tail -n +2 "$delay_file" | grep -c "MAJOR" || echo 0)
    local minor_count=$(tail -n +2 "$delay_file" | grep -c "MINOR" || echo 0)
    local ontime_count=$(tail -n +2 "$delay_file" | grep -c "ON_TIME" || echo 0)
    
    echo "$routes|$avg_delays|$ontime_pct|$critical_count|$major_count|$minor_count|$ontime_count"
}

# Function to generate HTML report with charts
generate_html_report() {
    local delay_file="$PROCESSED_DIR/delays_calculated_$(get_today).csv"
    local stats_file="$PROCESSED_DIR/statistics_$(get_today).txt"
    local output_file="$REPORTS_DIR/daily/report_$(get_today).html"
    
    log_message "INFO" "Generating HTML report with charts"
    
    if ! validate_file "$stats_file"; then
        log_message "ERROR" "Statistics file not found"
        return 1
    fi
    
    # Read statistics
    local total_vehicles=$(grep "Total Vehicles:" "$stats_file" | cut -d':' -f2 | xargs)
    local on_time=$(grep "On-Time Vehicles:" "$stats_file" | cut -d':' -f2 | xargs)
    local on_time_pct=$(grep "On-Time Percentage:" "$stats_file" | cut -d':' -f2 | xargs)
    local avg_delay=$(grep "Average Delay:" "$stats_file" | cut -d':' -f2 | sed 's/ minutes//' | xargs)
    local max_delay=$(grep "Maximum Delay:" "$stats_file" | cut -d':' -f2 | sed 's/ minutes//' | xargs)
    
    # Prepare chart data
    local chart_data=$(prepare_chart_data "$delay_file")
    IFS='|' read -r routes avg_delays ontime_pcts critical_count major_count minor_count ontime_count <<< "$chart_data"
    
    # Generate HTML
    cat > "$output_file" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
HTMLEOF

    echo "    <title>$REPORT_TITLE - $(get_today)</title>" >> "$output_file"
    
    cat >> "$output_file" << 'HTMLEOF'
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            min-height: 100vh;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            padding: 40px;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }
        header {
            border-bottom: 4px solid #667eea;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }
        h1 {
            color: #333;
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .meta-info {
            color: #666;
            font-size: 0.95em;
        }
        .meta-info span {
            margin-right: 20px;
        }
        h2 {
            color: #667eea;
            margin: 30px 0 20px 0;
            font-size: 1.8em;
            border-left: 5px solid #667eea;
            padding-left: 15px;
        }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 25px;
            margin: 30px 0;
        }
        .metric {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 12px;
            text-align: center;
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.3);
            transition: transform 0.3s ease;
        }
        .metric:hover {
            transform: translateY(-5px);
        }
        .metric.success {
            background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
            box-shadow: 0 5px 15px rgba(56, 239, 125, 0.3);
        }
        .metric.warning {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
            box-shadow: 0 5px 15px rgba(245, 87, 108, 0.3);
        }
        .metric.info {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
            box-shadow: 0 5px 15px rgba(79, 172, 254, 0.3);
        }
        .metric-value {
            font-size: 3em;
            font-weight: bold;
            margin: 15px 0;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
        }
        .metric-label {
            font-size: 1em;
            opacity: 0.95;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .charts-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(500px, 1fr));
            gap: 30px;
            margin: 30px 0;
        }
        .chart-container {
            background: white;
            padding: 25px;
            border-radius: 12px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
        }
        .chart-title {
            font-size: 1.3em;
            color: #333;
            margin-bottom: 20px;
            font-weight: 600;
            text-align: center;
        }
        canvas {
            max-height: 400px;
        }
        .table-container {
            overflow-x: auto;
            margin: 20px 0;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        table {
            width: 100%;
            border-collapse: collapse;
            background: white;
        }
        th, td {
            padding: 15px;
            text-align: left;
            border-bottom: 1px solid #eee;
        }
        th {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            font-weight: 600;
            text-transform: uppercase;
            font-size: 0.85em;
            letter-spacing: 0.5px;
            position: sticky;
            top: 0;
        }
        tr {
            transition: background-color 0.2s ease;
        }
        tr:hover {
            background-color: #f8f9fa;
        }
        .status-critical {
            color: #dc3545;
            font-weight: bold;
            background: #ffe6e6;
            padding: 5px 10px;
            border-radius: 5px;
            display: inline-block;
        }
        .status-major {
            color: #fd7e14;
            font-weight: bold;
            background: #fff3cd;
            padding: 5px 10px;
            border-radius: 5px;
            display: inline-block;
        }
        .status-minor {
            color: #ffc107;
            font-weight: bold;
            background: #fff8e1;
            padding: 5px 10px;
            border-radius: 5px;
            display: inline-block;
        }
        .status-ontime {
            color: #28a745;
            font-weight: bold;
            background: #d4edda;
            padding: 5px 10px;
            border-radius: 5px;
            display: inline-block;
        }
        .status-early {
            color: #17a2b8;
            font-weight: bold;
            background: #d1ecf1;
            padding: 5px 10px;
            border-radius: 5px;
            display: inline-block;
        }
        .footer {
            margin-top: 50px;
            padding-top: 30px;
            border-top: 2px solid #eee;
            text-align: center;
            color: #999;
            font-size: 0.9em;
        }
        .delay-positive {
            color: #dc3545;
            font-weight: 600;
        }
        .delay-negative {
            color: #28a745;
            font-weight: 600;
        }
        @media print {
            body {
                background: white;
                padding: 0;
            }
            .container {
                box-shadow: none;
            }
            .metric:hover {
                transform: none;
            }
        }
        @media (max-width: 768px) {
            .charts-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
HTMLEOF

    cat >> "$output_file" << HTMLEOF2
            <h1>🚍 $REPORT_TITLE</h1>
            <div class="meta-info">
                <span><strong>📅 Report Date:</strong> $(get_today)</span>
                <span><strong>🕐 Generated:</strong> $(date +"%H:%M:%S")</span>
            </div>
        </header>
        
        <h2>📊 Summary Statistics</h2>
        <div class="summary">
            <div class="metric info">
                <div class="metric-label">Total Vehicles</div>
                <div class="metric-value">$total_vehicles</div>
            </div>
            <div class="metric success">
                <div class="metric-label">On-Time</div>
                <div class="metric-value">$on_time_pct</div>
            </div>
            <div class="metric warning">
                <div class="metric-label">Avg Delay</div>
                <div class="metric-value">$avg_delay<span style="font-size:0.4em">min</span></div>
            </div>
            <div class="metric warning">
                <div class="metric-label">Max Delay</div>
                <div class="metric-value">$max_delay<span style="font-size:0.4em">min</span></div>
            </div>
        </div>
        
        <h2>📈 Visual Analytics</h2>
        <div class="charts-grid">
            <div class="chart-container">
                <div class="chart-title">Average Delay by Route</div>
                <canvas id="delayChart"></canvas>
            </div>
            <div class="chart-container">
                <div class="chart-title">On-Time Performance by Route</div>
                <canvas id="ontimeChart"></canvas>
            </div>
            <div class="chart-container">
                <div class="chart-title">Delay Severity Distribution</div>
                <canvas id="severityChart"></canvas>
            </div>
        </div>
        
        <h2>📋 Detailed Delay Report</h2>
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Route</th>
                        <th>Vehicle</th>
                        <th>Stop</th>
                        <th>Scheduled</th>
                        <th>Actual</th>
                        <th>Delay (min)</th>
                        <th>Severity</th>
                    </tr>
                </thead>
                <tbody>
HTMLEOF2

    # Add table rows from delay data
    tail -n +2 "$delay_file" | while IFS=',' read -r timestamp route vehicle stop scheduled actual delay status severity; do
        local status_class="status-ontime"
        case "$severity" in
            CRITICAL) status_class="status-critical" ;;
            MAJOR) status_class="status-major" ;;
            MINOR) status_class="status-minor" ;;
            EARLY) status_class="status-early" ;;
        esac
        
        local delay_class="delay-positive"
        if (( delay < 0 )); then
            delay_class="delay-negative"
        fi
        
        echo "                    <tr>" >> "$output_file"
        echo "                        <td><strong>$route</strong></td>" >> "$output_file"
        echo "                        <td>$vehicle</td>" >> "$output_file"
        echo "                        <td>$stop</td>" >> "$output_file"
        echo "                        <td>$scheduled</td>" >> "$output_file"
        echo "                        <td>$actual</td>" >> "$output_file"
        echo "                        <td class=\"$delay_class\">$delay</td>" >> "$output_file"
        echo "                        <td><span class=\"$status_class\">$severity</span></td>" >> "$output_file"
        echo "                    </tr>" >> "$output_file"
    done
    
    # Add JavaScript for charts
    cat >> "$output_file" << HTMLEOF3
                </tbody>
            </table>
        </div>
        
        <div class="footer">
            <p><strong>Public Transport Delay Tracker</strong></p>
            <p>Generated automatically by the monitoring system</p>
        </div>
    </div>
    
    <script>
        // Chart colors
        const colors = {
            primary: 'rgba(102, 126, 234, 0.8)',
            success: 'rgba(56, 239, 125, 0.8)',
            warning: 'rgba(245, 87, 108, 0.8)',
            info: 'rgba(79, 172, 254, 0.8)',
            secondary: 'rgba(118, 75, 162, 0.8)'
        };
        
        // Route data
        const routes = '$routes'.split(',');
        const avgDelays = '$avg_delays'.split(',').map(Number);
        const ontimePercentages = '$ontime_pcts'.split(',').map(Number);
        
        // Chart 1: Average Delay by Route (Bar Chart)
        const ctx1 = document.getElementById('delayChart').getContext('2d');
        new Chart(ctx1, {
            type: 'bar',
            data: {
                labels: routes,
                datasets: [{
                    label: 'Average Delay (minutes)',
                    data: avgDelays,
                    backgroundColor: colors.warning,
                    borderColor: 'rgba(245, 87, 108, 1)',
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        display: true,
                        position: 'top'
                    },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                return context.parsed.y.toFixed(2) + ' minutes';
                            }
                        }
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Minutes'
                        }
                    }
                }
            }
        });
        
        // Chart 2: On-Time Performance by Route (Bar Chart)
        const ctx2 = document.getElementById('ontimeChart').getContext('2d');
        new Chart(ctx2, {
            type: 'bar',
            data: {
                labels: routes,
                datasets: [{
                    label: 'On-Time Performance (%)',
                    data: ontimePercentages,
                    backgroundColor: colors.success,
                    borderColor: 'rgba(56, 239, 125, 1)',
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        display: true,
                        position: 'top'
                    },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                return context.parsed.y.toFixed(2) + '%';
                            }
                        }
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        max: 100,
                        title: {
                            display: true,
                            text: 'Percentage'
                        }
                    }
                }
            }
        });
        
        // Chart 3: Severity Distribution (Doughnut Chart)
        const ctx3 = document.getElementById('severityChart').getContext('2d');
        new Chart(ctx3, {
            type: 'doughnut',
            data: {
                labels: ['On-Time', 'Minor Delay', 'Major Delay', 'Critical Delay'],
                datasets: [{
                    data: [$ontime_count, $minor_count, $major_count, $critical_count],
                    backgroundColor: [
                        'rgba(56, 239, 125, 0.8)',
                        'rgba(255, 193, 7, 0.8)',
                        'rgba(255, 152, 0, 0.8)',
                        'rgba(220, 53, 69, 0.8)'
                    ],
                    borderColor: [
                        'rgba(56, 239, 125, 1)',
                        'rgba(255, 193, 7, 1)',
                        'rgba(255, 152, 0, 1)',
                        'rgba(220, 53, 69, 1)'
                    ],
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        position: 'bottom'
                    },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                const label = context.label || '';
                                const value = context.parsed || 0;
                                const total = context.dataset.data.reduce((a, b) => a + b, 0);
                                const percentage = ((value / total) * 100).toFixed(1);
                                return label + ': ' + value + ' (' + percentage + '%)';
                            }
                        }
                    }
                }
            }
        });
    </script>
</body>
</html>
HTMLEOF3
    
    log_message "INFO" "HTML report with charts generated: $output_file"
    echo "$output_file"
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

    # Generate PDF report
    log_message "INFO" "Generating PDF report..."
    bash "$(dirname "$0")/generate_pdf.sh"
    pdf_status=$?
    
    if [[ $pdf_status -ne 0 ]]; then
        log_message "WARN" "PDF generation failed, but CSV and HTML are available"
    fi
       
    log_message "INFO" "========== Report Generation Complete =========="
    
    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi
 
