#!/bin/bash
# ============================================================================
# TaskLang++ Automated Test Suite
# ============================================================================
# SE2052 - Programming Paradigms | Y2 S2
#
# Runs all valid and invalid test cases and reports results.
# Valid tests are expected to pass (exit code 0).
# Invalid tests are expected to fail (exit code != 0).
# ============================================================================

PASS=0
FAIL=0
TOTAL=0
BINARY="./tasklang"

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

echo ""
echo "============================================"
echo "  TaskLang++ Automated Test Suite"
echo "============================================"
echo ""

# Check if binary exists
if [ ! -f "$BINARY" ]; then
    echo -e "${RED}Error: $BINARY not found. Run 'make' first.${NC}"
    exit 1
fi

# ── Valid Tests (expect exit code 0) ─────────────────────────────────────

echo -e "${YELLOW}--- Valid Test Cases (expect PASS) ---${NC}"
echo ""

for f in tests/valid/*.tl; do
    TOTAL=$((TOTAL + 1))
    testname=$(basename "$f")
    printf "  %-40s" "$testname"
    
    output=$($BINARY < "$f" 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}PASS ✓${NC}"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}FAIL ✗${NC}"
        echo "    Output: $output"
        FAIL=$((FAIL + 1))
    fi
done

echo ""

# ── Invalid Tests (expect exit code != 0) ────────────────────────────────

echo -e "${YELLOW}--- Invalid Test Cases (expect FAIL) ---${NC}"
echo ""

for f in tests/invalid/*.tl; do
    TOTAL=$((TOTAL + 1))
    testname=$(basename "$f")
    printf "  %-40s" "$testname"
    
    output=$($BINARY < "$f" 2>&1)
    exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        echo -e "${GREEN}PASS ✓ (correctly rejected)${NC}"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}FAIL ✗ (should have been rejected)${NC}"
        FAIL=$((FAIL + 1))
    fi
done

echo ""

# ── Summary ──────────────────────────────────────────────────────────────

echo "============================================"
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "============================================"

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}  All tests passed! ✓${NC}"
else
    echo -e "${RED}  Some tests failed. ✗${NC}"
fi

echo ""
exit $FAIL
