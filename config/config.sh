#!/bin/bash
# Configuration file for Transport Delay Tracker

# Project paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="$PROJECT_ROOT/data"
TIMETABLE_DIR="$DATA_DIR/timetables"
LIVE_FEED_DIR="$DATA_DIR/live_feeds"
PROCESSED_DIR="$DATA_DIR/processed"
REPORTS_DIR="$PROJECT_ROOT/reports"
LOGS_DIR="$PROJECT_ROOT/logs"

# API Configuration (example - replace with real API)
API_ENDPOINT="https://api.example-transit.com/v1/delays"
API_KEY="your_api_key_here"  # Replace with actual key

# Delay thresholds (in minutes)
MINOR_DELAY=5
MAJOR_DELAY=15
CRITICAL_DELAY=30

# Email configuration
ALERT_EMAIL="your-email@example.com"
SMTP_SERVER="smtp.gmail.com"
EMAIL_FROM="transit-alerts@example.com"

# Report settings
REPORT_TITLE="Public Transport Delay Report"
ON_TIME_THRESHOLD=5  # Vehicles delayed less than this are "on-time"

# Date format
DATE_FORMAT="%Y-%m-%d"
TIME_FORMAT="%H:%M:%S"
DATETIME_FORMAT="%Y-%m-%d %H:%M:%S"

# Log rotation (days to keep)
LOG_RETENTION_DAYS=30
