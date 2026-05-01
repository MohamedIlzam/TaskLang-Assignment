# ============================================================================
# TaskLang++ Build System
# ============================================================================
# SE2052 - Programming Paradigms | Y2 S2
#
# Usage:
#   make          - Build the tasklang compiler
#   make test     - Run all tests
#   make clean    - Remove generated files
#
# Requirements: flex, bison, gcc
# ============================================================================

CC      = gcc
LEX     = flex
YACC    = bison
CFLAGS  = -Wall -g
SRCDIR  = src

# Output binary
TARGET  = tasklang

# Generated files
PARSER_C     = $(SRCDIR)/parser.tab.c
PARSER_H     = $(SRCDIR)/parser.tab.h
PARSER_OUT   = $(SRCDIR)/parser.output
LEXER_C      = $(SRCDIR)/lex.yy.c

# ── Build Rules ─────────────────────────────────────────────────────────

all: $(TARGET)

# Step 1: Generate parser C code + header from Bison grammar
$(PARSER_C) $(PARSER_H): $(SRCDIR)/parser.y $(SRCDIR)/tasklang.h
	$(YACC) -d -v -o $(PARSER_C) $(SRCDIR)/parser.y

# Step 2: Generate lexer C code from Flex specification
$(LEXER_C): $(SRCDIR)/lexer.l $(PARSER_H) $(SRCDIR)/tasklang.h
	$(LEX) -o $(LEXER_C) $(SRCDIR)/lexer.l

# Step 3: Compile everything into the final binary
$(TARGET): $(LEXER_C) $(PARSER_C)
	$(CC) $(CFLAGS) -o $(TARGET) $(LEXER_C) $(PARSER_C)

# ── Test Runner ─────────────────────────────────────────────────────────

test: $(TARGET)
	@bash tests/run_tests.sh

# ── Cleanup ─────────────────────────────────────────────────────────────

clean:
	rm -f $(LEXER_C) $(PARSER_C) $(PARSER_H) $(PARSER_OUT) $(TARGET)

.PHONY: all test clean
