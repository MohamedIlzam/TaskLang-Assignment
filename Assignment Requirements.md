# SE2052 – Programming Paradigms

# Y2 S2 – BSc (Hons) in Computer Science

**Take-Home Assignment**

**Duration: ~ 16 hours
Submission Deadline: 04 – 05 - 2026
Total Marks: 100**

**TaskLang++: A Domain-Specific Language for Task Scheduling and Automation**

Modern systems rely heavily on task scheduling and automation, from simple reminders to complex workflows (e.g., CI/CD
pipelines, cron jobs, smart assistants). General-purpose languages can express these, but they are often verbose and error-
prone. In this assignment, you will design a Domain-Specific Language (DSL) called TaskLang++ to define:

- Tasks
- Time-based scheduling
- Dependencies between tasks
- Conditional execution

You will formally define the syntax using BNF or EBNF and demonstrate how your DSL simplifies task specification. Then
implement a lexer using Lex or Flex and a parser using Yacc or Bison.

**Task 1: Domain Understanding & DSL Scope**

Define the **scope of your Task Scheduling DSL**.

- What types of tasks are supported? (e.g., email, backup, script execution)
- Scheduling mechanisms:
    o Time-based (daily, weekly, specific time)
    o Event-based (optional)


- Dependencies (e.g., task A must complete before task B)
- Constraints or assumptions
**Task 2: Language Design and Define the Formal Grammar**
Define the formal grammar for TaskLang++. Grammar needs to be unambiguous.

```
Your DSL should support at least:
```
- Task definition
- Scheduling (AT, EVERY, AFTER, etc.)
- Dependencies (BEFORE, AFTER, DEPENDS ON)
- Optional conditions (IF)

Following are some tokens that can be used in TaskLang++

```
{
  "tasklang_tokens": [
    {
      "token_name": "TASK",
      "lexeme": "TASK",
      "description": "Begins a task definition"
    },
    {
      "token_name": "RUN",
      "lexeme": "RUN",
      "description": "Specifies command execution"
    },
    {
      "token_name": "EVERY",
      "lexeme": "EVERY",
      "description": "Recurring schedule keyword"
    },
    {
      "token_name": "DAY",
      "lexeme": "DAY",
      "description": "Used with EVERY"
    },
    {
      "token_name": "AT",
      "lexeme": "AT",
      "description": "Time-based execution"
    },
    {
      "token_name": "AFTER",
      "lexeme": "AFTER",
      "description": "Dependency specification"
    },
    {
      "token_name": "IF",
      "lexeme": "IF",
      "description": "Conditional execution"
    },
    {
      "token_name": "SUCCESS",
      "lexeme": "success",
      "description": "Condition keyword"
    }
  ]
}
```
Task 3: Implement lexer and parser.
Task 4 : Validate the parser. Test your implementation using both valid and invalid programs with appropriate output messages
(successful parsing or failures)
```

Example TaskLang++ codes could be as below:
1. Simple Daily Recurring TaskThis example defines a basic recurring schedule for a single script.  Code snippetTASK dailyReport {
    RUN "report.py"
    EVERY DAY AT 06:00
}
2. Multi-step Workflow with ConditionsThis example demonstrates how to chain tasks using dependencies (AFTER) and status conditions (IF success).  Code snippetTASK backupDB {
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

You need to cover different scenarios of task combinations such as routine tasks such as daily schedules, tasks with conditions,
task dependencies, how to deal with circular dependencies (if any), etc..

1. A simple daily recurring scheduled task:
2. Multi-step workflow chained with conditions:


**Expected Output**
Parsing TaskLang++ input...

--- EXECUTION START ---
Executing Task: dailyReport
  Script: "report.py"
  Schedule: EVERY DAY AT 06:00

--- EXECUTION COMPLETE ---

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
Schedule: AT 03:00

--- EXECUTION COMPLETE ---


**Deliverables:**

**Report (PDF)**

1. Domain & DSL Design (scope of your Task Scheduling DSL as indicated in task 1)
2. Final Grammar (EBNF + BNF as indicated in task 2). Clearly defined terminals and non-terminals.
3. Sample Programs
4. Reflection

**Code Submission (as a zip file need to be uploaded separately)**

- lexer.l
- parser.y
- Makefile or compile instructions
- Sample input files


**Marking Rubric**

{
  "marking_rubric": [
    {
      "component": "DSL Design (10 marks)[cite: 1, 2]",
      "excellent_a": "Clear, realistic, well-justified DSL.[cite: 1, 2] Clear, realistic task scheduling domain;[cite: 1, 2] well-justified need for DSL;[cite: 1, 2] expressive and consistent syntax design[cite: 1, 2]",
      "good_b": "Reasonable design, minor issues, minor inconsistencies or limited justification[cite: 1, 2]",
      "satisfactory_c": "Basic domain; limited features; syntax somewhat unclear[cite: 1, 2]",
      "poor_df": "Unclear or weak design, poor syntax[cite: 1, 2]"
    },
    {
      "component": "Grammar (20 marks)[cite: 1, 2]",
      "excellent_a": "Fully correct, well-structured inconsistent grammar.[cite: 1, 2] Covers all constructs (tasks, scheduling, dependencies, conditions),[cite: 1, 2] use EBNF features,[cite: 1, 2] proper naming, etc..[cite: 1, 2]",
      "good_b": "Minor errors, mostly correct and covered[cite: 1, 2]",
      "satisfactory_c": "Several inconsistencies, limited coverage[cite: 1, 2]",
      "poor_df": "Incorrect/incomplete[cite: 1, 2]"
    },
    {
      "component": "Lexer (15 marks)[cite: 1, 2]",
      "excellent_a": "Accurate tokens, strong regex,[cite: 1, 2] correct prioritization of keywords and identifiers,[cite: 1, 2] proper handling of white spaces,[cite: 1, 2] Meaningful lexical error reporting[cite: 1, 2]",
      "good_b": "Mostly correct[cite: 1, 2]",
      "satisfactory_c": "Some issues[cite: 1, 2]",
      "poor_df": "Incorrect/missing[cite: 1, 2]"
    },
    {
      "component": "Parser (20 marks)[cite: 1, 2]",
      "excellent_a": "Correct parsing, no conflicts,[cite: 1, 2] Correct mapping from BNF to Yacc,[cite: 1, 2] accepts valid programs,[cite: 1, 2] rejects invalid ones,[cite: 1, 2] Optional Constructs Handling,[cite: 1, 2] minimal conflicts, clear rules[cite: 1, 2]",
      "good_b": "Minor issues[cite: 1, 2]",
      "satisfactory_c": "Some conflicts/errors[cite: 1, 2]",
      "poor_df": "Fails to parse[cite: 1, 2]"
    },
    {
      "component": "Integration and execution (10 marks)[cite: 1, 2]",
      "excellent_a": "Seamless lexer-parser, Seamless integration;[cite: 1, 2] tokens correctly passed;[cite: 1, 2] no runtime issues,[cite: 1, 2] Correct execution + dependencies[cite: 1, 2]",
      "good_b": "Minor issues, Basic execution works[cite: 1, 2]",
      "satisfactory_c": "Partial integration and limited simulation[cite: 1, 2]",
      "poor_df": "No meaningful execution logic[cite: 1, 2]"
    },
    {
      "component": "Testing (15 marks)[cite: 1, 2]",
      "excellent_a": "Comprehensive tests covering all syntax errors,[cite: 1, 2] semantic errors covering all possible scenarios including edge cases,[cite: 1, 2] uses test automation[cite: 1, 2]",
      "good_b": "Good coverage[cite: 1, 2]",
      "satisfactory_c": "Basic tests[cite: 1, 2]",
      "poor_df": "No testing[cite: 1, 2]"
    },
    {
      "component": "Reflection (10 marks)[cite: 1, 2]",
      "excellent_a": "Insightful and critical.[cite: 1, 2] Insightful discussion of challenges, trade-offs, improvements[cite: 1, 2]",
      "good_b": "Reasonable reflection[cite: 1, 2]",
      "satisfactory_c": "Basic reflection[cite: 1, 2]",
      "poor_df": "Missing/weak or superficial[cite: 1, 2]"
    }
  ]
}

