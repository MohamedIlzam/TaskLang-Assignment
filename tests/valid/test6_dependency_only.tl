// Test 6: Task with Dependency Only (No Schedule)
// Tests: A task that only has AFTER, no EVERY...AT

TASK buildProject {
    RUN "make build"
    EVERY DAY AT 08:00
}

TASK runTests {
    RUN "make test"
    AFTER buildProject
    IF success
}
