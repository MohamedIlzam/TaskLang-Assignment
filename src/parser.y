/*
 * ============================================================================
 * TaskLang++ Parser (Bison)
 * ============================================================================
 * SE2052 - Programming Paradigms | Y2 S2
 *
 * This parser implements the formal grammar for TaskLang++.
 * It performs:
 *   1. Syntactic analysis   - Validates program structure via BNF rules
 *   2. Semantic actions      - Populates a symbol table (task_table) 
 *   3. Semantic validation   - Checks for duplicates, unknown deps, cycles
 *   4. Execution simulation  - Prints formatted execution summary
 *
 * Grammar (BNF):
 *   program          -> task_list
 *   task_list        -> task_definition | task_list task_definition
 *   task_definition  -> TASK IDENTIFIER '{' task_body '}'
 *   task_body        -> run_stmt opt_schedule opt_dependency
 *   run_stmt         -> RUN STRING
 *   opt_schedule     -> schedule_clause | (empty)
 *   schedule_clause  -> EVERY frequency AT TIME
 *   frequency        -> DAY | WEEK ON day_name
 *   day_name         -> MONDAY | TUESDAY | ... | SUNDAY
 *   opt_dependency   -> dependency_clause | (empty)
 *   dependency_clause-> AFTER IDENTIFIER opt_condition
 *   opt_condition    -> IF condition | (empty)
 *   condition        -> SUCCESS | FAILURE
 *
 * Author: Mohamed Ilzam
 * ============================================================================
 */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tasklang.h"

/* ── External references from Lexer ─────────────────────────────────── */
extern int yylex(void);
extern int line_num;
extern FILE *yyin;

/* ── Error reporting function ───────────────────────────────────────── */
void yyerror(const char *s);

/* ── Global Symbol Table ────────────────────────────────────────────── */
Task task_table[MAX_TASKS];
int  task_count = 0;

/* ── Temporary task being parsed ────────────────────────────────────── */
Task current_task;

%}

/* ── Enable verbose error messages for better debugging ─────────────── */
%define parse.error verbose

/* ── Semantic value types ───────────────────────────────────────────── */
%union {
    char *sval;    /* String values: identifiers, strings, time, day names */
}

/* ── Token declarations ─────────────────────────────────────────────── */
%token TASK RUN EVERY DAY WEEK ON AT AFTER IF_COND
%token LBRACE RBRACE

%token <sval> IDENTIFIER
%token <sval> STRING
%token <sval> TIME
%token <sval> DAY_NAME
%token <sval> SUCCESS
%token <sval> FAILURE

/* ── Start symbol ───────────────────────────────────────────────────── */
%start program

%%

/* ═══════════════════════════════════════════════════════════════════════
 *  GRAMMAR RULES WITH SEMANTIC ACTIONS
 * ═══════════════════════════════════════════════════════════════════════ */

program:
    task_list
    {
        /* ── Semantic Validation ──────────────────────────────────── */
        
        /* Check that all dependencies reference existing tasks */
        if (validate_dependencies() != 0) {
            exit(1);
        }
        
        /* Check for circular dependencies */
        if (check_circular_dependencies() != 0) {
            exit(1);
        }
        
        /* ── Print Execution Summary ─────────────────────────────── */
        print_execution_summary();
    }
    ;

task_list:
    task_definition
    | task_list task_definition
    ;

task_definition:
    TASK IDENTIFIER LBRACE
    {
        /* Initialize a fresh temporary task and set its name */
        init_current_task();
        strncpy(current_task.name, $2, MAX_NAME_LEN - 1);
        current_task.name[MAX_NAME_LEN - 1] = '\0';
        free($2);
    }
    task_body RBRACE
    {
        /* Task block fully parsed — add to the symbol table */
        add_task(current_task);
    }
    ;

task_body:
    run_stmt opt_schedule opt_dependency
    ;

/* ─── RUN statement ─────────────────────────────────────────────────── */

run_stmt:
    RUN STRING
    {
        strncpy(current_task.command, $2, MAX_CMD_LEN - 1);
        current_task.command[MAX_CMD_LEN - 1] = '\0';
        free($2);
    }
    ;

/* ─── Optional SCHEDULE clause ──────────────────────────────────────── */

opt_schedule:
    schedule_clause
    | /* empty */
    ;

schedule_clause:
    EVERY frequency AT TIME
    {
        current_task.has_schedule = 1;
        strncpy(current_task.schedule_time, $4, 5);
        current_task.schedule_time[5] = '\0';
        free($4);
    }
    ;

frequency:
    DAY
    {
        strcpy(current_task.schedule_freq, "EVERY DAY");
    }
    | WEEK ON DAY_NAME
    {
        sprintf(current_task.schedule_freq, "EVERY WEEK ON %s", $3);
        free($3);
    }
    ;

/* ─── Optional DEPENDENCY clause ────────────────────────────────────── */

opt_dependency:
    dependency_clause
    | /* empty */
    ;

dependency_clause:
    AFTER IDENTIFIER opt_condition
    {
        current_task.has_dependency = 1;
        strncpy(current_task.depends_on, $2, MAX_NAME_LEN - 1);
        current_task.depends_on[MAX_NAME_LEN - 1] = '\0';
        free($2);
    }
    ;

/* ─── Optional CONDITION clause ─────────────────────────────────────── */

opt_condition:
    IF_COND condition
    | /* empty */
    ;

condition:
    SUCCESS
    {
        current_task.has_condition = 1;
        strcpy(current_task.condition, "success");
        free($1);
    }
    | FAILURE
    {
        current_task.has_condition = 1;
        strcpy(current_task.condition, "failure");
        free($1);
    }
    ;

%%

/* ═══════════════════════════════════════════════════════════════════════
 *  SUPPORTING FUNCTIONS
 * ═══════════════════════════════════════════════════════════════════════ */

/**
 * yyerror - Called by Bison on parse errors.
 * Prints the line number and error message to stderr.
 */
void yyerror(const char *s) {
    fprintf(stderr, "Syntax Error at line %d: %s\n", line_num, s);
}

/**
 * init_current_task - Reset all fields of the temporary task struct.
 */
void init_current_task(void) {
    memset(&current_task, 0, sizeof(Task));
}

/**
 * find_task - Search for a task by name in the symbol table.
 * @return Index if found, -1 otherwise.
 */
int find_task(const char *name) {
    for (int i = 0; i < task_count; i++) {
        if (strcmp(task_table[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}

/**
 * add_task - Add a task to the symbol table.
 * Rejects duplicate task names with a semantic error.
 */
void add_task(Task t) {
    /* Check for duplicate task names */
    if (find_task(t.name) != -1) {
        fprintf(stderr, "Semantic Error at line %d: Task '%s' is already defined.\n", 
                line_num, t.name);
        exit(1);
    }
    
    /* Check table capacity */
    if (task_count >= MAX_TASKS) {
        fprintf(stderr, "Error: Maximum number of tasks (%d) exceeded.\n", MAX_TASKS);
        exit(1);
    }
    
    task_table[task_count++] = t;
}

/**
 * validate_dependencies - Verify all AFTER references point to defined tasks.
 * Also checks that IF conditions don't appear without AFTER.
 * @return 0 on success, 1 on error.
 */
int validate_dependencies(void) {
    for (int i = 0; i < task_count; i++) {
        /* Check: IF without AFTER */
        if (task_table[i].has_condition && !task_table[i].has_dependency) {
            fprintf(stderr, 
                "Semantic Error: Task '%s' has a condition (IF) without a dependency (AFTER).\n",
                task_table[i].name);
            return 1;
        }
        
        /* Check: AFTER references an undefined task */
        if (task_table[i].has_dependency) {
            if (find_task(task_table[i].depends_on) == -1) {
                fprintf(stderr, 
                    "Semantic Error: Task '%s' depends on undefined task '%s'.\n",
                    task_table[i].name, task_table[i].depends_on);
                return 1;
            }
        }
    }
    return 0;
}

/**
 * check_circular_dependencies - Detect cycles using DFS-based traversal.
 *
 * For each task that has a dependency, we follow the dependency chain.
 * If we revisit a task we've already seen in the current chain, 
 * there's a circular dependency.
 *
 * @return 0 if no cycles, 1 if a cycle is detected.
 */
int check_circular_dependencies(void) {
    for (int i = 0; i < task_count; i++) {
        if (!task_table[i].has_dependency) continue;
        
        /* visited array to track the chain for this starting task */
        int visited[MAX_TASKS] = {0};
        visited[i] = 1;
        
        int current = i;
        while (task_table[current].has_dependency) {
            int next = find_task(task_table[current].depends_on);
            if (next == -1) break;  /* Already caught by validate_dependencies */
            
            if (visited[next]) {
                fprintf(stderr, 
                    "Semantic Error: Circular dependency detected — task '%s' is part of a dependency cycle.\n",
                    task_table[i].name);
                return 1;
            }
            
            visited[next] = 1;
            current = next;
        }
    }
    return 0;
}

/**
 * print_execution_summary - Output the formatted execution plan
 * matching the expected output format from the assignment.
 */
void print_execution_summary(void) {
    printf("--- EXECUTION START ---\n\n");
    
    for (int i = 0; i < task_count; i++) {
        printf("Executing Task: %s\n", task_table[i].name);
        printf("  Script: %s\n", task_table[i].command);
        
        /* Schedule line */
        if (task_table[i].has_schedule) {
            printf("  Schedule: %s AT %s\n", 
                   task_table[i].schedule_freq, 
                   task_table[i].schedule_time);
        } else {
            printf("  Schedule:\n");
        }
        
        /* Dependency line */
        if (task_table[i].has_dependency) {
            printf("  Depends on: %s\n", task_table[i].depends_on);
        }
        
        /* Condition line */
        if (task_table[i].has_condition) {
            printf("  Condition: %s\n", task_table[i].condition);
        }
        
        printf("\n");
    }
    
    printf("--- EXECUTION COMPLETE ---\n");
}

/* ═══════════════════════════════════════════════════════════════════════
 *  MAIN ENTRY POINT
 * ═══════════════════════════════════════════════════════════════════════ */

int main(int argc, char **argv) {
    /* If a filename argument is provided, read from that file */
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr, "Error: Cannot open file '%s'\n", argv[1]);
            return 1;
        }
    }
    /* Otherwise, read from stdin */

    /* Print header before parsing begins */
    printf("Parsing TaskLang++ input...\n\n");
    fflush(stdout);   /* Flush before errors may appear on stderr */

    int result = yyparse();
    
    if (yyin && yyin != stdin) {
        fclose(yyin);
    }
    
    return result;
}
