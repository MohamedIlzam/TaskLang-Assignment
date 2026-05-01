// Invalid Test: Misspelled keyword (TAKS instead of TASK)
TAKS backupDB {
    RUN "backup.sh"
    EVERY DAY AT 02:00
}
