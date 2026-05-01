// Invalid Test: Missing closing brace
TASK backupDB {
    RUN "backup.sh"
    EVERY DAY AT 02:00

