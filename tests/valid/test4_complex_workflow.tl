// Test 4: Complex Workflow with Multiple Dependencies
// Tests: Chained dependencies, mixed schedules, IF failure

TASK fetchData {
    RUN "fetch_data.sh"
    EVERY DAY AT 01:00
}

TASK processData {
    RUN "process.py"
    AFTER fetchData
    IF success
}

TASK generateReport {
    RUN "report_gen.sh"
    AFTER processData
    IF success
}

TASK notifyAdmin {
    RUN "notify_failure.sh"
    AFTER fetchData
    IF failure
}

TASK archiveLogs {
    RUN "archive_logs.sh"
    EVERY WEEK ON SATURDAY AT 23:00
}
