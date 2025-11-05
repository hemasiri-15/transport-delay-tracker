#!/bin/bash
# Script to calculate delays and flag problematic vehicles

# Source utilities
source "$(dirname "$0")/../utils/helpers.sh"

# Function to calculate all delays
calculate_all_delays() {
    local live_data="$PROCESSED_DIR/live_data_parsed.txt"
    local output_file="$PROCESSED_DIR/delays_calculated_$(get_today).csv"
    
    log_message "INFO" "Calculating delays"
    
    if ! validate_file "$live_data"; then
        log_message "ERROR" "Live data file not found"
        return 1
    fi
    
    # Create CSV header
    echo "timestamp,route_id,vehicle_id,stop_name,scheduled_time,actual_time,delay_minutes,status,severity" > "$output_file"
    
    local timestamp=$(date +"$DATETIME_FORMAT")
    
    # Process each line
    while IFS='|' read -r route_id vehicle_id stop_name scheduled_time actual_time status; do
        # Calculate delay
        local delay_min=$(calculate_delay_minutes "$scheduled_time" "$actual_time")
        
        # Determine severity
        local severity="ON_TIME"
        if (( delay_min >= CRITICAL_DELAY )); then
            severity="CRITICAL"
        elif (( delay_min >= MAJOR_DELAY )); then
            severity="MAJOR"
        elif (( delay_min >= MINOR_DELAY )); then
            severity="MINOR"
        elif (( delay_min < 0 )); then
            severity="EARLY"
        fi
        
        # Write to CSV
        echo "$timestamp,$route_id,$vehicle_id,$stop_name,$scheduled_time,$actual_time,$delay_min,$status,$severity" >> "$output_file"
        
        # Log critical delays
        if [[ "$severity" == "CRITICAL" ]]; then
            log_message "ALERT" "CRITICAL delay: $vehicle_id on $route_id ($delay_min minutes)"
        fi
        
    done < "$live_data"
    
    log_message "INFO" "Delay calculation complete. Results in $output_file"
    echo "$output_file"
}

# Function to get delay statistics
get_delay_statistics() {
    local delay_file="$1"
    
    if ! validate_file "$delay_file"; then
        return 1
    fi
    
    # Skip header
    local data=$(tail -n +2 "$delay_file")
    
    # Total vehicles
    local total_vehicles=$(echo "$data" | wc -l)
    
    # On-time vehicles (delay <= threshold)
    local on_time=$(echo "$data" | awk -F',' -v threshold="$ON_TIME_THRESHOLD" '$7 <= threshold' | wc -l)
    
    # Average delay
    local avg_delay=$(echo "$data" | awk -F',' '{sum+=$7; count++} END {if(count>0) printf "%.2f", sum/count; else print "0"}')
    
    # Max delay
    local max_delay=$(echo "$data" | awk -F',' '{if($7>max) max=$7} END {print max+0}')
    
    # On-time percentage
    local on_time_pct=$(awk "BEGIN {if($total_vehicles>0) printf \"%.2f\", ($on_time/$total_vehicles)*100; else print \"0\"}")
    
    # Output statistics
    cat > "$PROCESSED_DIR/statistics_$(get_today).txt" << EOF
Total Vehicles: $total_vehicles
On-Time Vehicles: $on_time
On-Time Percentage: $on_time_pct%
Average Delay: $avg_delay minutes
Maximum Delay: $max_delay minutes
EOF
    
    log_message "INFO" "Statistics calculated"
    
    # Return values for use in other scripts
    echo "$total_vehicles|$on_time|$on_time_pct|$avg_delay|$max_delay"
}

# Function to identify heavily delayed routes
identify_delayed_routes() {
    local delay_file="$1"
    local threshold="$MAJOR_DELAY"
    local output_file="$PROCESSED_DIR/heavily_delayed_$(get_today).txt"
    
    log_message "INFO" "Identifying heavily delayed routes (>$threshold minutes)"
    
    # Find vehicles with major delays
    echo "Route,Vehicle,Stop,Delay (min),Severity" > "$output_file"
    tail -n +2 "$delay_file" | awk -F',' -v threshold="$threshold" '$7 >= threshold {print $2","$3","$4","$7","$9}' >> "$output_file"
    
    local count=$(tail -n +2 "$output_file" | wc -l)
    log_message "INFO" "Found $count heavily delayed vehicles"
    
    echo "$output_file"
}

# Main execution
main() {
    log_message "INFO" "========== Starting Delay Calculation =========="
    
    # Calculate delays
    delay_file=$(calculate_all_delays)
    
    if [[ -z "$delay_file" ]]; then
        log_message "ERROR" "Delay calculation failed"
        exit 1
    fi
    
    # Get statistics
    stats=$(get_delay_statistics "$delay_file")
    
    # Identify problem routes
    problem_file=$(identify_delayed_routes "$delay_file")
    
    log_message "INFO" "========== Delay Calculation Complete =========="
    log_message "INFO" "Delay file: $delay_file"
    log_message "INFO" "Problem routes: $problem_file"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi
