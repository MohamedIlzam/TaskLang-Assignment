/*
 * ============================================================================
 * TaskLang++ : A Domain-Specific Language for Task Scheduling and Automation
 * ============================================================================
 * SE2052 - Programming Paradigms | Y2 S2
 * 
 * This header defines the core data structures and function prototypes
 * used by both the lexer (lexer.l) and the parser (parser.y).
 * 
 * Author: Mohamed Ilzam
 * ============================================================================
 */

#ifndef TASKLANG_H
#define TASKLANG_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ── Constants ──────────────────────────────────────────────────────────── */
#define MAX_TASKS     100    /* Maximum number of tasks in a program       */
#define MAX_NAME_LEN   64   /* Maximum length of a task identifier        */
#define MAX_CMD_LEN   256   /* Maximum length of a command/script string  */

/* ── Task Data Structure ────────────────────────────────────────────────── 
 * Each parsed TASK block is stored as one Task struct in the task_table.
 * Fields are populated by semantic actions in parser.y as the grammar
 * rules are reduced.
 */
typedef struct {
    char name[MAX_NAME_LEN];          /* Task identifier (e.g., "backupDB")     */
    char command[MAX_CMD_LEN];        /* Script/command to execute              */
    
    /* Scheduling fields */
    int  has_schedule;                /* 1 if EVERY...AT clause is present      */
    char schedule_freq[64];           /* e.g., "EVERY DAY", "EVERY WEEK ON MONDAY" */
    char schedule_time[6];            /* 24-hour time, e.g., "02:00"            */
    
    /* Dependency fields */
    int  has_dependency;              /* 1 if AFTER clause is present           */
    char depends_on[MAX_NAME_LEN];   /* Name of the dependency task            */
    
    /* Condition fields */
    int  has_condition;               /* 1 if IF clause is present              */
    char condition[16];              /* "success" or "failure"                  */
} Task;

/* ── Global Symbol Table ────────────────────────────────────────────────── */
extern Task task_table[MAX_TASKS];   /* Array storing all parsed tasks         */
extern int  task_count;              /* Number of tasks currently stored       */

/* ── Temporary Task (used during parsing) ───────────────────────────────── */
extern Task current_task;            /* Holds the task being currently parsed  */

/* ── Line Tracking ──────────────────────────────────────────────────────── */
extern int line_num;                 /* Current line number for error messages */

/* ── Function Prototypes ────────────────────────────────────────────────── */

/**
 * find_task - Search for a task by name in the task_table.
 * @param name: The task identifier to search for.
 * @return: Index of the task if found, -1 otherwise.
 */
int find_task(const char *name);

/**
 * add_task - Add a completed task to the task_table.
 * @param t: The Task struct to add.
 * Prints an error and exits if a duplicate task name is detected.
 */
void add_task(Task t);

/**
 * print_execution_summary - Print the formatted execution summary
 * of all parsed tasks, matching the expected output format.
 */
void print_execution_summary(void);

/**
 * check_circular_dependencies - Detect circular dependencies
 * among all tasks using DFS-based cycle detection.
 * @return: 0 if no cycles found, 1 if a circular dependency exists.
 */
int check_circular_dependencies(void);

/**
 * validate_dependencies - Check that all AFTER references point
 * to tasks that actually exist in the task_table.
 * @return: 0 if all dependencies are valid, 1 if an error is found.
 */
int validate_dependencies(void);

/**
 * init_current_task - Reset the current_task struct to default values.
 * Called at the start of parsing each new TASK block.
 */
void init_current_task(void);

#endif /* TASKLANG_H */
