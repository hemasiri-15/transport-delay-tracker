#!/bin/bash
# Check cron job status

echo "========================================"
echo "   📅 CRON JOB STATUS"
echo "========================================"
echo ""

echo "Active Cron Jobs:"
echo "-----------------"
crontab -l 2>/dev/null | grep -A 1 "Transport Delay Tracker" || echo "No cron jobs found"

echo ""
echo "Recent Cron Executions:"
echo "-----------------------"
if [[ -f "logs/cron/cron.log" ]]; then
    echo "Last 10 executions:"
    grep "Starting Transport Delay Tracker Pipeline" logs/cron/cron.log | tail -10
    echo ""
    echo "Log size: $(du -h logs/cron/cron.log | cut -f1)"
else
    echo "No cron logs found"
fi

echo ""
echo "Next Scheduled Run:"
echo "-------------------"
# This is an approximation based on current time
echo "Check: crontab -l"

echo ""
echo "========================================"
