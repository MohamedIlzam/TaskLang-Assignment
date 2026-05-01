// Test 5: All Features Combined
// Tests: Daily, weekly, dependency-only, IF success, IF failure, comments

// Database maintenance pipeline
TASK backupDB {
    RUN "backup_database.sh"
    EVERY DAY AT 02:00
}

// Send email report after successful backup
TASK emailReport {
    RUN "send_email.py"
    AFTER backupDB
    IF success
}

// Alert on backup failure
TASK alertOnFailure {
    RUN "alert_admin.sh"
    AFTER backupDB
    IF failure
}

// Weekly cleanup of old logs
TASK cleanupLogs {
    RUN "cleanup_old_logs.sh"
    EVERY WEEK ON WEDNESDAY AT 04:00
}

// Saturday system health check
TASK healthCheck {
    RUN "system_health.py"
    EVERY WEEK ON SATURDAY AT 08:00
}

// Deploy only after health check passes
TASK deployUpdate {
    RUN "deploy.sh"
    AFTER healthCheck
    IF success
}
