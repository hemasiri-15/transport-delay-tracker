#!/bin/bash
# Script to ingest timetable and live delay data

# Source utilities
source "$(dirname "$0")/../utils/helpers.sh"

# Function to read timetable CSV
read_timetable() {
    local timetable_file="$TIMETABLE_DIR/schedule.csv"
    
    log_message "INFO" "Reading timetable from $timetable_file"
    
    if ! validate_file "$timetable_file"; then
        log_message "ERROR" "Cannot read timetable file"
        return 1
    fi
    
    # Skip header and process each line
    tail -n +2 "$timetable_file" | while IFS=, read -r route_id vehicle_id stop_name scheduled_time direction; do
        echo "$route_id|$vehicle_id|$stop_name|$scheduled_time|$direction"
    done > "$PROCESSED_DIR/timetable_processed.txt"
    
    log_message "INFO" "Timetable processing complete"
    return 0
}

# Function to fetch live data from API (with curl)
fetch_live_data_from_api() {
    local output_file="$LIVE_FEED_DIR/live_data_$(get_timestamp).json"
    
    log_message "INFO" "Fetching live delay data from API"
    
    # Real API call (uncomment and modify for your actual API)
    # curl -s -X GET "$API_ENDPOINT" \
    #      -H "Authorization: Bearer $API_KEY" \
    #      -H "Content-Type: application/json" \
    #      -o "$output_file"
    
    # Check if curl succeeded
    # if [[ $? -ne 0 ]]; then
    #     log_message "ERROR" "Failed to fetch data from API"
    #     return 1
    # fi
    
    # For development/testing: Generate simulated data
    log_message "WARN" "Using simulated data (no real API configured)"
    generate_simulated_data "$output_file"
    
    log_message "INFO" "Live data saved to $output_file"
    
    # Return only the filename, not log messages
    echo "$output_file"
}

# Function to generate simulated live data for testing
generate_simulated_data() {
    local output_file="$1"
    
    # Generate realistic simulated delays
    cat > "$output_file" << 'EOF'
{
  "timestamp": "2025-11-02T08:17:00Z",
  "status": "success",
  "delays": [
    {
      "route_id": "Route_101",
      "vehicle_id": "BUS_001",
      "stop_name": "Central Station",
      "scheduled_time": "08:00:00",
      "actual_time": "08:00:00",
      "status": "on-time"
    },
    {
      "route_id": "Route_101",
      "vehicle_id": "BUS_001",
      "stop_name": "Market Square",
      "scheduled_time": "08:15:00",
      "actual_time": "08:17:00",
      "status": "delayed"
    },
    {
      "route_id": "Route_101",
      "vehicle_id": "BUS_001",
      "stop_name": "University",
      "scheduled_time": "08:30:00",
      "actual_time": "08:34:00",
      "status": "delayed"
    },
    {
      "route_id": "Route_101",
      "vehicle_id": "BUS_002",
      "stop_name": "Central Station",
      "scheduled_time": "08:30:00",
      "actual_time": "08:31:00",
      "status": "delayed"
    },
    {
      "route_id": "Route_101",
      "vehicle_id": "BUS_002",
      "stop_name": "Market Square",
      "scheduled_time": "08:45:00",
      "actual_time": "09:02:00",
      "status": "delayed"
    },
    {
      "route_id": "Route_101",
      "vehicle_id": "BUS_002",
      "stop_name": "University",
      "scheduled_time": "09:00:00",
      "actual_time": "09:19:00",
      "status": "delayed"
    },
    {
      "route_id": "Route_202",
      "vehicle_id": "TRAIN_001",
      "stop_name": "Downtown",
      "scheduled_time": "09:00:00",
      "actual_time": "09:00:00",
      "status": "on-time"
    },
    {
      "route_id": "Route_202",
      "vehicle_id": "TRAIN_001",
      "stop_name": "Suburbs",
      "scheduled_time": "09:25:00",
      "actual_time": "09:28:00",
      "status": "delayed"
    },
    {
      "route_id": "Route_202",
      "vehicle_id": "TRAIN_001",
      "stop_name": "Airport",
      "scheduled_time": "09:45:00",
      "actual_time": "09:50:00",
      "status": "delayed"
    },
    {
      "route_id": "Route_202",
      "vehicle_id": "TRAIN_002",
      "stop_name": "Downtown",
      "scheduled_time": "10:00:00",
      "actual_time": "09:58:00",
      "status": "on-time"
    },
    {
      "route_id": "Route_202",
      "vehicle_id": "TRAIN_002",
      "stop_name": "Suburbs",
      "scheduled_time": "10:25:00",
      "actual_time": "10:24:00",
      "status": "on-time"
    },
    {
      "route_id": "Route_202",
      "vehicle_id": "TRAIN_002",
      "stop_name": "Airport",
      "scheduled_time": "10:45:00",
      "actual_time": "10:45:00",
      "status": "on-time"
    },
    {
      "route_id": "Route_303",
      "vehicle_id": "BUS_003",
      "stop_name": "City Center",
      "scheduled_time": "07:30:00",
      "actual_time": "07:30:00",
      "status": "on-time"
    },
    {
      "route_id": "Route_303",
      "vehicle_id": "BUS_003",
      "stop_name": "Business Park",
      "scheduled_time": "07:50:00",
      "actual_time": "07:51:00",
      "status": "on-time"
    },
    {
      "route_id": "Route_303",
      "vehicle_id": "BUS_003",
      "stop_name": "Industrial Zone",
      "scheduled_time": "08:10:00",
      "actual_time": "08:12:00",
      "status": "delayed"
    }
  ]
}
EOF
    return 0
}

# Function to parse JSON live data using jq
parse_live_data() {
    local json_file="$1"
    local output_file="$PROCESSED_DIR/live_data_parsed.txt"
    
    log_message "INFO" "Parsing live data from $json_file"
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        log_message "ERROR" "jq is not installed. Please install it: sudo apt-get install jq"
        return 1
    fi
    
    # Validate JSON file
    if ! validate_file "$json_file"; then
        log_message "ERROR" "JSON file is invalid or empty"
        return 1
    fi
    
    # Parse JSON and create pipe-delimited output
    jq -r '.delays[] | "\(.route_id)|\(.vehicle_id)|\(.stop_name)|\(.scheduled_time)|\(.actual_time)|\(.status)"' \
        "$json_file" > "$output_file" 2>/dev/null
    
    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "Failed to parse JSON data"
        return 1
    fi
    
    local record_count=$(wc -l < "$output_file" 2>/dev/null)
    log_message "INFO" "Parsed $record_count records from live data"
    
    echo "$output_file"
}

# Function to parse JSON using awk (alternative if jq not available)
parse_live_data_with_awk() {
    local json_file="$1"
    local output_file="$PROCESSED_DIR/live_data_parsed.txt"
    
    log_message "WARN" "Using awk parser (jq not available)"
    
    # Simple JSON parsing with awk (works for simple structures)
    awk '
    /"route_id":/ { gsub(/[",]/, ""); route=$2 }
    /"vehicle_id":/ { gsub(/[",]/, ""); vehicle=$2 }
    /"stop_name":/ { gsub(/[",]/, ""); stop=$2; for(i=3;i<=NF;i++) stop=stop" "$i }
    /"scheduled_time":/ { gsub(/[",]/, ""); scheduled=$2 }
    /"actual_time":/ { gsub(/[",]/, ""); actual=$2 }
    /"status":/ { 
        gsub(/[",]/, ""); 
        status=$2; 
        print route"|"vehicle"|"stop"|"scheduled"|"actual"|"status 
    }
    ' "$json_file" > "$output_file" 2>/dev/null
    
    log_message "INFO" "Live data parsing complete (awk method)"
    echo "$output_file"
}

# Function to validate parsed data
validate_parsed_data() {
    local parsed_file="$1"
    
    if ! validate_file "$parsed_file"; then
        log_message "ERROR" "Parsed data file is invalid"
        return 1
    fi
    
    # Check for required fields
    local invalid_lines=0
    while IFS='|' read -r route vehicle stop scheduled actual status; do
        if [[ -z "$route" ]] || [[ -z "$vehicle" ]] || [[ -z "$scheduled" ]] || [[ -z "$actual" ]]; then
            ((invalid_lines++))
            log_message "WARN" "Invalid data line: $route|$vehicle|$stop|$scheduled|$actual|$status"
        fi
    done < "$parsed_file"
    
    if [[ $invalid_lines -gt 0 ]]; then
        log_message "WARN" "Found $invalid_lines invalid records in parsed data"
    else
        log_message "INFO" "All parsed data records are valid"
    fi
    
    return 0
}

# Function to clean old data files (keep last 7 days)
cleanup_old_data() {
    local retention_days=7
    
    log_message "INFO" "Cleaning up data files older than $retention_days days"
    
    # Clean old live feed files
    find "$LIVE_FEED_DIR" -name "*.json" -mtime +$retention_days -delete 2>/dev/null
    
    # Clean old processed files
    find "$PROCESSED_DIR" -name "*.txt" -mtime +$retention_days -delete 2>/dev/null
    find "$PROCESSED_DIR" -name "*.csv" -mtime +$retention_days -delete 2>/dev/null
    
    log_message "INFO" "Cleanup complete"
}

# Main execution function
main() {
    log_message "INFO" "========== Starting Data Ingestion =========="
    
    # Step 1: Read timetable
    log_message "INFO" "Step 1: Reading timetable"
    if ! read_timetable; then
        log_message "ERROR" "Timetable reading failed"
        exit 1
    fi
    
    # Step 2: Fetch live data
    log_message "INFO" "Step 2: Fetching live delay data"
    live_file=$(fetch_live_data_from_api)
    if [[ -z "$live_file" ]] || [[ ! -f "$live_file" ]]; then
        log_message "ERROR" "Failed to fetch live data"
        exit 1
    fi
    
    # Step 3: Parse live data
    log_message "INFO" "Step 3: Parsing live data"
    
    # Try jq first
    parsed_file=$(parse_live_data "$live_file")
    parse_status=$?
    
    # If jq parsing fails, try awk method
    if [[ $parse_status -ne 0 ]]; then
        log_message "WARN" "jq parsing failed, trying awk method"
        parsed_file=$(parse_live_data_with_awk "$live_file")
        parse_status=$?
    fi
    
    if [[ $parse_status -ne 0 ]] || [[ -z "$parsed_file" ]] || [[ ! -f "$parsed_file" ]]; then
        log_message "ERROR" "Failed to parse live data"
        exit 1
    fi
    
    # Step 4: Validate parsed data
    log_message "INFO" "Step 4: Validating parsed data"
    validate_parsed_data "$parsed_file"
    
    # Step 5: Cleanup old files
    log_message "INFO" "Step 5: Cleaning up old data files"
    cleanup_old_data
    
    log_message "INFO" "========== Data Ingestion Complete =========="
    log_message "INFO" "Parsed data available at: $parsed_file"
    
    return 0
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi
