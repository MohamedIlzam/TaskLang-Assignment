// Invalid Test: Dependency on a task that doesn't exist
TASK sendReport {
    RUN "report.py"
    AFTER nonExistentTask
    IF success
}
