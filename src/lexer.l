/*
 * ============================================================================
 * TaskLang++ Lexer (Flex)
 * ============================================================================
 * SE2052 - Programming Paradigms | Y2 S2
 *
 * This lexer tokenizes TaskLang++ source files. It recognizes:
 *   - Keywords: TASK, RUN, EVERY, DAY, WEEK, ON, AT, AFTER, IF
 *   - Conditions: success, failure
 *   - Day names: MONDAY through SUNDAY
 *   - Identifiers: alphanumeric task names
 *   - String literals: double-quoted command strings
 *   - Time literals: HH:MM format (24-hour)
 *   - Symbols: { }
 *   - Comments: // single-line comments (ignored)
 *
 * Keywords appear BEFORE the IDENTIFIER rule to ensure correct
 * prioritization (Flex matches rules in order of appearance).
 *
 * Author: Mohamed Ilzam
 * ============================================================================
 */

%{
#include "parser.tab.h"
#include "tasklang.h"
#include <string.h>

/* Line number tracking for error reporting */
int line_num = 1;
%}

/* ── Flex Options ─────────────────────────────────────────────────────── */
%option noyywrap
%option nounput
%option noinput

%%

 /* ═══════════════════════════════════════════════════════════════════════
  *  SECTION 1: Whitespace & Comments (ignored, but track line numbers)
  * ═══════════════════════════════════════════════════════════════════════ */

[ \t]+          { /* Ignore spaces and tabs */ }
\n              { line_num++; }
\/\/[^\n]*      { /* Ignore single-line comments */ }

 /* ═══════════════════════════════════════════════════════════════════════
  *  SECTION 2: Keywords (MUST appear before IDENTIFIER rule)
  * ═══════════════════════════════════════════════════════════════════════ */

"TASK"          { return TASK; }
"RUN"           { return RUN; }
"EVERY"         { return EVERY; }
"DAY"           { return DAY; }
"WEEK"          { return WEEK; }
"ON"            { return ON; }
"AT"            { return AT; }
"AFTER"         { return AFTER; }
"IF"            { return IF_COND; }

 /* ═══════════════════════════════════════════════════════════════════════
  *  SECTION 3: Condition Keywords (lowercase as per spec)
  * ═══════════════════════════════════════════════════════════════════════ */

"success"       { yylval.sval = strdup(yytext); return SUCCESS; }
"failure"       { yylval.sval = strdup(yytext); return FAILURE; }

 /* ═══════════════════════════════════════════════════════════════════════
  *  SECTION 4: Day-of-Week Keywords
  * ═══════════════════════════════════════════════════════════════════════ */

"MONDAY"        { yylval.sval = strdup(yytext); return DAY_NAME; }
"TUESDAY"       { yylval.sval = strdup(yytext); return DAY_NAME; }
"WEDNESDAY"     { yylval.sval = strdup(yytext); return DAY_NAME; }
"THURSDAY"      { yylval.sval = strdup(yytext); return DAY_NAME; }
"FRIDAY"        { yylval.sval = strdup(yytext); return DAY_NAME; }
"SATURDAY"      { yylval.sval = strdup(yytext); return DAY_NAME; }
"SUNDAY"        { yylval.sval = strdup(yytext); return DAY_NAME; }

 /* ═══════════════════════════════════════════════════════════════════════
  *  SECTION 5: Literals
  * ═══════════════════════════════════════════════════════════════════════ */

 /* Time literal: exactly HH:MM in 24-hour format */
[0-9]{2}:[0-9]{2}   { yylval.sval = strdup(yytext); return TIME; }

 /* String literal: double-quoted, no escapes needed for this DSL */
\"[^\"]*\"      { yylval.sval = strdup(yytext); return STRING; }

 /* ═══════════════════════════════════════════════════════════════════════
  *  SECTION 6: Identifiers (AFTER all keywords)
  * ═══════════════════════════════════════════════════════════════════════ */

[a-zA-Z_][a-zA-Z0-9_]*  { yylval.sval = strdup(yytext); return IDENTIFIER; }

 /* ═══════════════════════════════════════════════════════════════════════
  *  SECTION 7: Symbols
  * ═══════════════════════════════════════════════════════════════════════ */

"{"             { return LBRACE; }
"}"             { return RBRACE; }

 /* ═══════════════════════════════════════════════════════════════════════
  *  SECTION 8: Catch-All Error Rule
  *  Any character not matched above is reported as a lexical error.
  * ═══════════════════════════════════════════════════════════════════════ */

.               { 
                    fprintf(stderr, "Lexical Error at line %d: Unknown character '%c'\n", 
                            line_num, yytext[0]);
                    return yytext[0];  /* Return to parser — causes syntax error */
                }

%%
