// Test 1: Simple Daily Recurring Task
// Tests: TASK, RUN, EVERY DAY AT, basic structure

TASK dailyReport {
    RUN "report.py"
    EVERY DAY AT 06:00
}
