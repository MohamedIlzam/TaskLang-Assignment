// Invalid Test: Unknown characters in the source
TASK backupDB {
    RUN "backup.sh"
    EVERY DAY AT 02:00
    @#$
}
