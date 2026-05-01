// Invalid Test: Circular dependency chain (A depends on B, B depends on C, C depends on A)
TASK taskA {
    RUN "a.sh"
    AFTER taskC
}

TASK taskB {
    RUN "b.sh"
    AFTER taskA
}

TASK taskC {
    RUN "c.sh"
    AFTER taskB
}
