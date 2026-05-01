// Test 3: Weekly Scheduled Tasks
// Tests: EVERY WEEK ON <day_name> AT with multiple days

TASK weeklyMeeting {
    RUN "setup_meeting.sh"
    EVERY WEEK ON MONDAY AT 09:00
}

TASK fridayReport {
    RUN "generate_report.py"
    EVERY WEEK ON FRIDAY AT 17:00
}
