// Invalid Test: Duplicate task names
TASK backupDB {
    RUN "backup1.sh"
    EVERY DAY AT 02:00
}

TASK backupDB {
    RUN "backup2.sh"
    EVERY DAY AT 03:00
}
