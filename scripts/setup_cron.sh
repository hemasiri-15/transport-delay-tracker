#!/bin/bash
# Script to set up cron jobs for automated execution

# Source utilities
source "$(dirname "$0")/../utils/helpers.sh"

echo "========================================"
echo "   ⏰ CRON JOB SETUP"
echo "========================================"
echo ""

# Get absolute path to project
PROJECT_PATH="$PROJECT_ROOT"
MAIN_SCRIPT="$PROJECT_PATH/scripts/main.sh"

# Check if main script exists
if [[ ! -f "$MAIN_SCRIPT" ]]; then
    echo "❌ Error: Main script not found at $MAIN_SCRIPT"
    exit 1
fi

echo "Project path: $PROJECT_PATH"
echo "Main script: $MAIN_SCRIPT"
echo ""

# Show current crontab
echo "Current cron jobs:"
echo "-------------------"
crontab -l 2>/dev/null || echo "No cron jobs found"
echo ""

# Cron job options
cat << 'EOF'
Available scheduling options:
========================================

1. Every hour (on the hour)
   - Runs: 00:00, 01:00, 02:00, etc.
   - Good for: Real-time monitoring

2. Every 30 minutes
   - Runs: 00:00, 00:30, 01:00, 01:30, etc.
   - Good for: Frequent updates

3. Every day at 8:00 AM
   - Runs: Once daily at 08:00
   - Good for: Daily summary reports

4. Every weekday at 8:00 AM
   - Runs: Monday-Friday at 08:00
   - Good for: Business day monitoring

5. Custom schedule
   - Enter your own cron expression

6. Remove all Transport Tracker cron jobs

7. Exit without changes

EOF

read -p "Select option (1-7): " choice

case $choice in
    1)
        CRON_SCHEDULE="0 * * * *"
        DESCRIPTION="Every hour"
        ;;
    2)
        CRON_SCHEDULE="*/30 * * * *"
        DESCRIPTION="Every 30 minutes"
        ;;
    3)
        CRON_SCHEDULE="0 8 * * *"
        DESCRIPTION="Daily at 8:00 AM"
        ;;
    4)
        CRON_SCHEDULE="0 8 * * 1-5"
        DESCRIPTION="Weekdays at 8:00 AM"
        ;;
    5)
        echo ""
        echo "Cron format: minute hour day month weekday"
        echo "Example: 0 8 * * * = Every day at 8:00 AM"
        read -p "Enter cron schedule: " CRON_SCHEDULE
        DESCRIPTION="Custom schedule"
        ;;
    6)
        echo ""
        echo "Removing Transport Tracker cron jobs..."
        crontab -l 2>/dev/null | grep -v "transport-delay-tracker" | crontab -
        echo "✅ Cron jobs removed"
        exit 0
        ;;
    7)
        echo "Exiting without changes"
        exit 0
        ;;
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac

# Create log directory for cron output
CRON_LOG_DIR="$PROJECT_PATH/logs/cron"
mkdir -p "$CRON_LOG_DIR"

# Build cron command
CRON_COMMAND="cd $PROJECT_PATH && bash $MAIN_SCRIPT >> $CRON_LOG_DIR/cron.log 2>&1"

# Add cron job
echo ""
echo "Adding cron job..."
echo "-------------------"
echo "Schedule: $DESCRIPTION ($CRON_SCHEDULE)"
echo "Command: $CRON_COMMAND"
echo ""

# Backup current crontab
crontab -l 2>/dev/null > /tmp/crontab_backup.txt

# Add new job
(crontab -l 2>/dev/null | grep -v "transport-delay-tracker"; echo "# Transport Delay Tracker - $DESCRIPTION"; echo "$CRON_SCHEDULE $CRON_COMMAND") | crontab -

if [[ $? -eq 0 ]]; then
    echo "✅ Cron job added successfully!"
    echo ""
    echo "Your pipeline will now run: $DESCRIPTION"
    echo "Logs will be saved to: $CRON_LOG_DIR/cron.log"
    echo ""
    echo "View cron jobs: crontab -l"
    echo "View cron logs: tail -f $CRON_LOG_DIR/cron.log"
    echo "Remove cron job: bash scripts/setup_cron.sh (option 6)"
else
    echo "❌ Failed to add cron job"
    echo "Restoring backup..."
    crontab /tmp/crontab_backup.txt 2>/dev/null
    exit 1
fi

echo ""
echo "========================================"
echo "   ✅ AUTOMATION SETUP COMPLETE"
echo "========================================"
