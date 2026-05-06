# TaskLang++: A Domain-Specific Language for Task Scheduling and Automation

**SE2052 – Programming Paradigms | Y2 S2 – BSc (Hons) in Computer Science**
**Author:** Mohamed Ilzam
**Date:** May 2026

---

## Table of Contents

1. Domain Understanding & DSL Design
2. Language Design & Formal Grammar
3. Implementation Details
4. Sample Programs & Output
5. Testing & Validation
6. Reflection

---

## 1. Domain Understanding & DSL Design

### 1.1 Problem Domain

Modern computing systems depend heavily on automated task scheduling. From daily database backups and log rotation to multi-step CI/CD pipelines and cron jobs, the need to define, schedule, and chain tasks is universal. However, existing solutions have significant usability problems:

- **Cron syntax** is cryptic and error-prone. The expression `0 2 * * 0` means "every Sunday at 02:00," but this is unintuitive and difficult to maintain.
- **General-purpose languages** (Python, Bash) require verbose boilerplate code for scheduling logic, dependency management, and conditional execution.
- **GUI-based schedulers** (Windows Task Scheduler) lack composability and version control.

### 1.2 Justification for a DSL

TaskLang++ addresses these problems by providing a **declarative, human-readable** syntax that maps directly to scheduling intent. A comparison illustrates the advantage:

| Approach | Syntax for "Run backup.sh every day at 02:00" |
|---|---|
| Cron | `0 2 * * * /usr/bin/backup.sh` |
| Bash script | `while true; do if [ $(date +%H:%M) = "02:00" ]; then ./backup.sh; fi; sleep 60; done` |
| **TaskLang++** | `TASK backupDB { RUN "backup.sh" EVERY DAY AT 02:00 }` |

TaskLang++ is **self-documenting**: anyone can read a `.tl` file and immediately understand what tasks run, when they run, and how they depend on each other — without consulting documentation.

### 1.3 Supported Features

| Feature | Syntax | Description |
|---|---|---|
| Task Definition | `TASK name { ... }` | Defines a named, reusable task unit |
| Command Execution | `RUN "script.sh"` | Specifies the shell command or script to execute |
| Daily Scheduling | `EVERY DAY AT HH:MM` | Recurring execution every day at a specific time |
| Weekly Scheduling | `EVERY WEEK ON DAY AT HH:MM` | Recurring execution on a specific weekday |
| Task Dependencies | `AFTER taskName` | Task executes only after the named task completes |
| Conditional Execution | `IF success` / `IF failure` | Task executes only if the dependency succeeded or failed |
| Single-line Comments | `// comment text` | Documentation within source files |

### 1.4 Constraints and Assumptions

1. **Unique task names** — Each task must have a distinct identifier within a program.
2. **Single dependency** — A task may depend on at most one other task (simplifies the dependency graph to a forest of chains).
3. **24-hour time format** — Times are specified as `HH:MM` in 24-hour notation.
4. **Commands are opaque strings** — The DSL does not interpret or validate command contents; it treats them as literal strings to be passed to a shell.
5. **Static analysis** — All validation (duplicate names, undefined dependencies, circular dependencies) is performed at parse time, not at runtime.
6. **No circular dependencies** — Detected and rejected with a clear error message.

---

## 2. Language Design & Formal Grammar

### 2.1 EBNF Grammar

The following Extended Backus-Naur Form defines the complete syntax of TaskLang++. Non-terminals are in *italics*, terminals are in **bold** or quoted.

```
program           = task_definition { task_definition } ;

task_definition   = "TASK" IDENTIFIER "{" task_body "}" ;

task_body         = run_statement [ schedule_clause ] [ dependency_clause ] ;

run_statement     = "RUN" STRING ;

schedule_clause   = "EVERY" frequency "AT" TIME ;

frequency         = "DAY"
                  | "WEEK" "ON" day_name ;

day_name          = "MONDAY" | "TUESDAY" | "WEDNESDAY" | "THURSDAY"
                  | "FRIDAY" | "SATURDAY" | "SUNDAY" ;

dependency_clause = "AFTER" IDENTIFIER [ condition_clause ] ;

condition_clause  = "IF" condition ;

condition         = "success" | "failure" ;
```

**Terminal Definitions:**

```
IDENTIFIER  = letter { letter | digit | "_" } ;
STRING      = '"' { character } '"' ;
TIME        = digit digit ":" digit digit ;
letter      = "a" | ... | "z" | "A" | ... | "Z" ;
digit       = "0" | "1" | ... | "9" ;
character   = (* any printable character except double-quote *) ;
```

### 2.2 BNF Grammar (Yacc-Compatible)

The following BNF is the direct mapping used in the Bison parser file (`parser.y`):

```
<program>           ::= <task_list>

<task_list>         ::= <task_definition>
                      | <task_list> <task_definition>

<task_definition>   ::= TASK IDENTIFIER LBRACE <task_body> RBRACE

<task_body>         ::= <run_stmt> <opt_schedule> <opt_dependency>

<run_stmt>          ::= RUN STRING

<opt_schedule>      ::= <schedule_clause>
                      | ε

<schedule_clause>   ::= EVERY <frequency> AT TIME

<frequency>         ::= DAY
                      | WEEK ON <day_name>

<day_name>          ::= MONDAY | TUESDAY | WEDNESDAY | THURSDAY
                      | FRIDAY | SATURDAY | SUNDAY

<opt_dependency>    ::= <dependency_clause>
                      | ε

<dependency_clause> ::= AFTER IDENTIFIER <opt_condition>

<opt_condition>     ::= IF_COND <condition>
                      | ε

<condition>         ::= SUCCESS
                      | FAILURE
```

Where ε represents the empty production.

### 2.3 Terminals and Non-Terminals

**Non-Terminals (12):**
`program`, `task_list`, `task_definition`, `task_body`, `run_stmt`, `opt_schedule`, `schedule_clause`, `frequency`, `day_name`, `opt_dependency`, `dependency_clause`, `opt_condition`, `condition`

**Terminal Tokens (20):**

| Token | Lexeme(s) | Category |
|---|---|---|
| TASK | `TASK` | Keyword |
| RUN | `RUN` | Keyword |
| EVERY | `EVERY` | Keyword |
| DAY | `DAY` | Keyword |
| WEEK | `WEEK` | Keyword |
| ON | `ON` | Keyword |
| AT | `AT` | Keyword |
| AFTER | `AFTER` | Keyword |
| IF_COND | `IF` | Keyword |
| SUCCESS | `success` | Condition |
| FAILURE | `failure` | Condition |
| DAY_NAME | `MONDAY`...`SUNDAY` | Day literal |
| IDENTIFIER | `[a-zA-Z_][a-zA-Z0-9_]*` | Task name |
| STRING | `"[^"]*"` | Command string |
| TIME | `[0-9]{2}:[0-9]{2}` | Time literal |
| LBRACE | `{` | Delimiter |
| RBRACE | `}` | Delimiter |

### 2.4 Grammar Properties

The grammar is **unambiguous** because:

1. **Unique leading keywords** — Every construct begins with a distinct keyword (`TASK`, `RUN`, `EVERY`, `AFTER`, `IF`), so the parser can always determine which production to apply by looking at the next token.
2. **Fixed clause ordering** — Within a task body, the order is strictly `RUN` → optional `EVERY...AT` → optional `AFTER`. This eliminates any ambiguity about which clause is being parsed.
3. **Explicit empty alternatives** — Optional clauses use `| ε` productions rather than Kleene-star operators, which prevents shift/reduce conflicts in LALR(1) parsing.

Bison confirms zero shift/reduce and zero reduce/reduce conflicts in the generated `parser.output` file.

---

## 3. Implementation Details

### 3.1 Architecture Overview

```
  Source File (.tl)
        │
        ▼
  ┌──────────┐    tokens    ┌──────────┐    Task structs    ┌───────────────┐
  │  Lexer   │ ──────────►  │  Parser  │ ────────────────►  │  Execution    │
  │ (Flex)   │              │ (Bison)  │                    │  Summary      │
  │ lexer.l  │              │ parser.y │                    │  + Validation │
  └──────────┘              └──────────┘                    └───────────────┘
                                 │
                                 ▼
                          ┌──────────────┐
                          │ Symbol Table │
                          │ task_table[] │
                          └──────────────┘
```

### 3.2 Data Structure — Task Symbol Table

Defined in `tasklang.h`:

```c
typedef struct {
    char name[64];           // Task identifier
    char command[256];       // Script/command to execute
    int  has_schedule;       // 1 if EVERY...AT is present
    char schedule_freq[64];  // "EVERY DAY" or "EVERY WEEK ON MONDAY"
    char schedule_time[6];   // "02:00"
    int  has_dependency;     // 1 if AFTER is present
    char depends_on[64];     // Dependency task name
    int  has_condition;      // 1 if IF is present
    char condition[16];      // "success" or "failure"
} Task;

Task task_table[100];  // Global symbol table
int  task_count = 0;   // Number of stored tasks
```

### 3.3 Lexer Implementation (`lexer.l`)

**Key design decisions:**

1. **Keyword priority** — All keyword rules (`"TASK"`, `"RUN"`, etc.) appear *before* the `IDENTIFIER` rule. Flex matches rules in order of appearance, so this ensures `TASK` is recognized as the `TASK` token rather than as an identifier.

2. **Line number tracking** — A global `line_num` counter is incremented on every `\n`, enabling precise error locations.

3. **Cross-platform whitespace** — The whitespace rule `[ \t\r]+` ignores spaces, tabs, and carriage returns, ensuring compatibility with both Windows (CRLF) and Unix (LF) line endings.

4. **Comment support** — The rule `\/\/[^\n]*` silently ignores single-line comments, adding documentation capability to the DSL.

5. **Catch-all error rule** — Any unrecognized character triggers a lexical error with the line number and the offending character. The character is then returned to the parser, which generates a syntax error — ensuring invalid input is always rejected.

### 3.4 Parser Implementation (`parser.y`)

**Key design decisions:**

1. **Mid-rule actions** — When `TASK IDENTIFIER LBRACE` is matched, a mid-rule action initializes a fresh `current_task` struct and copies the task name. This allows subsequent rules (RUN, EVERY, AFTER) to populate the same struct incrementally.

2. **Optional clauses via empty productions** — `opt_schedule`, `opt_dependency`, and `opt_condition` each have an explicit `| /* empty */` alternative, allowing tasks with any combination of features.

3. **Verbose error messages** — `%define parse.error verbose` enables Bison to generate descriptive error messages like `"unexpected EVERY, expecting RUN"` instead of the generic `"syntax error"`.

4. **Semantic validation after parsing** — Once all tasks are stored in `task_table`, the `program` rule's action calls `validate_dependencies()` and `check_circular_dependencies()` before printing the execution summary.

### 3.5 Semantic Validation

Four types of semantic errors are detected:

| Error Type | Detection Method | Example Message |
|---|---|---|
| Duplicate task name | Linear search of `task_table` on `add_task()` | `Semantic Error at line 10: Task 'backupDB' is already defined.` |
| Undefined dependency | Search for `depends_on` name in `task_table` | `Semantic Error: Task 'X' depends on undefined task 'Y'.` |
| Circular dependency | DFS-based chain traversal with visited array | `Semantic Error: Circular dependency detected — task 'X' is part of a dependency cycle.` |
| Condition without dependency | Check `has_condition && !has_dependency` | `Semantic Error: Task 'X' has a condition (IF) without a dependency (AFTER).` |

**Circular Dependency Algorithm:**

For each task with a dependency, we follow the chain of AFTER references. A `visited[]` array tracks which tasks have been seen in the current chain. If we encounter a task already marked as visited, a cycle exists.

```
function check_circular(task_table):
    for each task T in task_table:
        if T has no dependency: skip
        mark T as visited
        current = T
        while current has a dependency:
            next = find_task(current.depends_on)
            if next is visited: CYCLE DETECTED
            mark next as visited
            current = next
```

This algorithm runs in O(n²) worst case, which is efficient for the expected number of tasks (< 100).

---

## 4. Sample Programs & Output

### 4.1 Simple Daily Recurring Task

**Input (test1_simple_daily.tl):**
```
TASK dailyReport {
    RUN "report.py"
    EVERY DAY AT 06:00
}
```

**Output:**
```
Parsing TaskLang++ input...

--- EXECUTION START ---

Executing Task: dailyReport
Script: "report.py"
Schedule: EVERY DAY AT 06:00

--- EXECUTION COMPLETE ---
```

### 4.2 Multi-Step Workflow with Conditions

**Input (test2_multi_step.tl):**
```
TASK backupDB {
    RUN "backup.sh"
    EVERY DAY AT 02:00
}

TASK sendReport {
    RUN "report.py"
    AFTER backupDB
    IF success
}

TASK cleanup {
    RUN "cleanup.sh"
    EVERY WEEK ON SUNDAY AT 03:00
}
```

**Output:**
```
Parsing TaskLang++ input...

--- EXECUTION START ---

Executing Task: backupDB
Script: "backup.sh"
Schedule: EVERY DAY AT 02:00

Executing Task: sendReport
Script: "report.py"
Schedule:
Depends on: backupDB
Condition: success

Executing Task: cleanup
Script: "cleanup.sh"
Schedule: EVERY WEEK ON SUNDAY AT 03:00

--- EXECUTION COMPLETE ---
```

### 4.3 Complex Workflow with Chained Dependencies

**Input (test4_complex_workflow.tl):**
```
TASK fetchData {
    RUN "fetch_data.sh"
    EVERY DAY AT 01:00
}

TASK processData {
    RUN "process.py"
    AFTER fetchData
    IF success
}

TASK generateReport {
    RUN "report_gen.sh"
    AFTER processData
    IF success
}

TASK notifyAdmin {
    RUN "notify_failure.sh"
    AFTER fetchData
    IF failure
}

TASK archiveLogs {
    RUN "archive_logs.sh"
    EVERY WEEK ON SATURDAY AT 23:00
}
```

**Output:**
```
Parsing TaskLang++ input...

--- EXECUTION START ---

Executing Task: fetchData
Script: "fetch_data.sh"
Schedule: EVERY DAY AT 01:00

Executing Task: processData
Script: "process.py"
Schedule:
Depends on: fetchData
Condition: success

Executing Task: generateReport
Script: "report_gen.sh"
Schedule:
Depends on: processData
Condition: success

Executing Task: notifyAdmin
Script: "notify_failure.sh"
Schedule:
Depends on: fetchData
Condition: failure

Executing Task: archiveLogs
Script: "archive_logs.sh"
Schedule: EVERY WEEK ON SATURDAY AT 23:00

--- EXECUTION COMPLETE ---
```

### 4.4 Error Handling Examples

**Missing closing brace:**
```
Parsing TaskLang++ input...

Syntax Error at line 6: syntax error, unexpected end of file, expecting RBRACE
```

**Missing RUN statement:**
```
Parsing TaskLang++ input...

Syntax Error at line 3: syntax error, unexpected EVERY, expecting RUN
```

**Misspelled keyword (TAKS instead of TASK):**
```
Parsing TaskLang++ input...

Syntax Error at line 2: syntax error, unexpected IDENTIFIER, expecting TASK
```

**Circular dependency (A → C → B → A):**
```
Parsing TaskLang++ input...

Semantic Error: Circular dependency detected — task 'taskA' is part of a dependency cycle.
```

**Undefined dependency:**
```
Parsing TaskLang++ input...

Semantic Error: Task 'sendReport' depends on undefined task 'nonExistentTask'.
```

**Duplicate task name:**
```
Parsing TaskLang++ input...

Semantic Error at line 10: Task 'backupDB' is already defined.
```

**Unknown characters (@#$):**
```
Parsing TaskLang++ input...

Lexical Error at line 5: Unknown character '@'
Syntax Error at line 5: syntax error, unexpected invalid token, expecting RBRACE
```

---

## 5. Testing & Validation

### 5.1 Test Suite Overview

A comprehensive automated test suite validates both correct and incorrect inputs. The test runner (`tests/run_tests.sh`) executes all test files and reports pass/fail status.

### 5.2 Valid Test Cases

| # | File | Features Tested |
|---|---|---|
| 1 | `test1_simple_daily.tl` | Single task, `EVERY DAY AT` |
| 2 | `test2_multi_step.tl` | 3 tasks, `AFTER`, `IF success`, `EVERY WEEK ON` |
| 3 | `test3_weekly_schedule.tl` | Multiple weekly schedules (MONDAY, FRIDAY) |
| 4 | `test4_complex_workflow.tl` | 5 tasks, chained deps, `IF failure`, mixed schedules |
| 5 | `test5_all_features.tl` | 6 tasks: all features combined with comments |
| 6 | `test6_dependency_only.tl` | Task with `AFTER` only, no schedule |

### 5.3 Invalid Test Cases

| # | File | Error Type | Expected Behaviour |
|---|---|---|---|
| 1 | `test_missing_brace.tl` | Syntax | Rejected — missing `}` |
| 2 | `test_missing_run.tl` | Syntax | Rejected — no RUN statement |
| 3 | `test_misspelled_keyword.tl` | Syntax | Rejected — `TAKS` not recognized |
| 4 | `test_circular_dependency.tl` | Semantic | Rejected — A→C→B→A cycle |
| 5 | `test_duplicate_task.tl` | Semantic | Rejected — duplicate name |
| 6 | `test_unknown_dependency.tl` | Semantic | Rejected — undefined task |
| 7 | `test_unknown_char.tl` | Lexical | Rejected — `@#$` characters |
| 8 | `test_empty_file.tl` | Syntax | Rejected — no task definitions |

### 5.4 Automated Test Results

```
============================================
  TaskLang++ Automated Test Suite
============================================

--- Valid Test Cases (expect PASS) ---

  test1_simple_daily.tl                   PASS ✓
  test2_multi_step.tl                     PASS ✓
  test3_weekly_schedule.tl                PASS ✓
  test4_complex_workflow.tl               PASS ✓
  test5_all_features.tl                   PASS ✓
  test6_dependency_only.tl                PASS ✓

--- Invalid Test Cases (expect FAIL) ---

  test_circular_dependency.tl             PASS ✓ (correctly rejected)
  test_duplicate_task.tl                  PASS ✓ (correctly rejected)
  test_empty_file.tl                      PASS ✓ (correctly rejected)
  test_missing_brace.tl                   PASS ✓ (correctly rejected)
  test_missing_run.tl                     PASS ✓ (correctly rejected)
  test_misspelled_keyword.tl              PASS ✓ (correctly rejected)
  test_unknown_char.tl                    PASS ✓ (correctly rejected)
  test_unknown_dependency.tl              PASS ✓ (correctly rejected)

============================================
  RESULTS: 14/14 passed, 0 failed
============================================
  All tests passed! ✓
```

---

## 6. Reflection

### 6.1 Design Trade-Offs

**Simplicity vs. Expressiveness.** The most significant design decision was limiting each task to a single dependency (`AFTER taskName`) rather than supporting multiple dependencies (`AFTER [taskA, taskB]`). This kept the grammar simple and unambiguous — a single LALR(1) lookahead is sufficient — but it means complex dependency graphs must be expressed as linear chains. In practice, most real-world task pipelines are linear (A → B → C), so this trade-off is acceptable for the intended domain.

**Static vs. Dynamic Validation.** All semantic checks (duplicate names, undefined dependencies, circular dependencies) are performed at parse time rather than at execution time. This is a "fail-fast" approach: the user gets immediate feedback about errors before any task would execute. The alternative — runtime validation — would be more flexible (e.g., allowing forward references where a task is defined after it's referenced), but would provide a worse user experience for a DSL that emphasizes correctness.

**Fixed Clause Ordering.** The grammar enforces that `RUN` must come before `EVERY`, which must come before `AFTER`. This eliminates grammatical ambiguity at the cost of some flexibility. An alternative would be to allow clauses in any order, but this would require either a more complex grammar (increasing the risk of shift/reduce conflicts) or post-parse validation (adding complexity to the semantic layer).

### 6.2 Challenges Encountered

**Keyword-Identifier Conflict.** The most subtle implementation challenge was ensuring that keywords like `TASK`, `AFTER`, and `DAY` are not consumed as generic identifiers. In Flex, rules are matched in the order they appear, so placing keyword rules *before* the `IDENTIFIER` rule resolves this. However, this also means a task cannot be named `TASK` or `RUN`, which is a reasonable restriction for a DSL.

**Windows/Linux Compatibility.** Developing on Windows while targeting Flex/Bison (which are Unix-native tools) required careful handling of line endings. Windows uses CRLF (`\r\n`) while Unix uses LF (`\n`). The `\r` character was not initially handled by the lexer, causing "Unknown character" errors when files created on Windows were processed in WSL. The fix was adding `\r` to the whitespace rule: `[ \t\r]+`.

**Circular Dependency Detection.** Implementing cycle detection required choosing between a simple chain-following algorithm and a full graph-based approach (e.g., Tarjan's algorithm). Since each task has at most one dependency, the dependency structure is a forest of chains rather than a general directed graph. A simple visited-array traversal was sufficient and more readable than a full DFS/SCC algorithm.

**Output Buffering.** The "Parsing TaskLang++ input..." header (printed to `stdout`) and error messages (printed to `stderr`) appeared in incorrect order due to different buffering modes. Adding `fflush(stdout)` before `yyparse()` ensured the header always appears first.

### 6.3 Potential Improvements

1. **Multiple Dependencies.** Support `AFTER [taskA, taskB]` with AND/OR semantics — "run after both complete" vs. "run after either completes." This would require extending the grammar and using an adjacency list rather than a single `depends_on` field.

2. **Variables and Parameters.** Add `SET var = value` syntax to allow parameterized commands, e.g., `RUN "backup.sh ${DB_NAME}"`. This would require a symbol table for variables and string interpolation in the execution layer.

3. **Error Recovery.** Currently, the parser stops at the first error. Using Bison's `error` token, the parser could skip to the next `}` and continue parsing subsequent tasks, reporting all errors in a single pass.

4. **Time Validation.** The lexer currently accepts any `[0-9]{2}:[0-9]{2}` pattern, including invalid times like `25:99`. Adding semantic validation for valid hours (00–23) and minutes (00–59) would improve robustness.

5. **Topological Execution Order.** The current output lists tasks in declaration order. A topological sort of the dependency graph would present them in a valid execution order, which is more useful for the user.

---

## Appendix: Build and Run Instructions

**Prerequisites:** `flex`, `bison`, `gcc`, `make` (available on Ubuntu/WSL)

```bash
# Build
make clean && make

# Run a TaskLang++ program
./tasklang tests/valid/test2_multi_step.tl

# Run automated test suite
bash tests/run_tests.sh
```

**File Structure:**
```
TaskLang-/
├── src/
│   ├── tasklang.h      # Data structures and function prototypes
│   ├── lexer.l         # Flex lexer specification
│   └── parser.y        # Bison parser with semantic actions
├── tests/
│   ├── valid/          # 6 valid test programs
│   ├── invalid/        # 8 invalid test programs
│   └── run_tests.sh    # Automated test runner
├── Makefile            # Build automation
└── report/
    └── report.pdf      # This document
```
