/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

int DecodeCoolString(char* raw, char* buffer);

/*
 *  Add Your own definitions here
 */
%}

/*
 * Define names for regular expressions here.
 */
CLASS           [cC][lL][aA][sS][sS]
ELSE            [eE][lL][sS][eE]
FI              [fF][iI]
IF              [iI][fF]
IN              [iI][nN]
INHERITS        [iI][nN][hH][eE][rR][iI][tT][sS]
LET             [lL][eE][tT]
LOOP            [lL][oO][oO][pP]
POOL            [pP][oO][oP][lL]
THEN            [tT][hH][eE][nN]
WHILE           [wW][hH][iI][lL][eE]
CASE            [cC][aA][sS][eE]
ESAC            [eE][sS][aA][cC]
OF              [oO][fF]
NEW             [nN][eE][wW]
ISVOID          [iI][sS][vV][oO][iI][dD]
TRUE            t[rR][uU][eE]
FALSE           f[aA][lL][sS][eE]
NOT             [nN][oO][tT]
DARROW         	=>
ONE_LINE_STR    ([^"\\]|\\['"?\\btnf])*
STR_CONST       \"({ONE_LINE_STR}\\\n)*{ONE_LINE_STR}\"
INT_CONST       [0-9]+
TYPEID          ([A-Z])([_a-zA-Z0-9])*|SELF_TYPE
OBJECTID        ([a-z])([_a-zA-Z0-9])*|self
LE              <=
ASSIGN          <-
WHITE_SPACE     [ \n\f\r\t\v]+

%x COMMENT
%%

 /*
  *  Nested comments
  */


 /*
  *  The multiple-character operators.
  */
"(*"          {
  BEGIN(COMMENT);
}
<COMMENT>[^*]
<COMMENT>"*"+[^)]*
<COMMENT>"*)" {
  BEGIN(INITIAL);
}
{CLASS}       { return (CLASS); }
{ELSE}        { return (ELSE);  }
{FI}          { return (FI);  }
{IF}          { return (IF);  }
{IN}          { return (IN);  }
{INHERITS}    { return (INHERITS);  }
{LET}         { return (LET); }
{LOOP}        { return (LOOP);  }
{POOL}        { return (POOL);  }
{THEN}        { return (THEN);  }
{WHILE}       { return (WHILE); }
{CASE}        { return (CASE);  }
{ESAC}        { return (ESAC);  }
{OF}          { return (OF);    }
{NEW}         { return (NEW); }
{ISVOID}      { return (ISVOID);  }
{TRUE}        {
  cool_yylval.boolean = 1;
  return (BOOL_CONST);
}
{FALSE}       {
  cool_yylval.boolean = 0;
  return (BOOL_CONST);
}
{NOT}         { return (NOT);  }
{DARROW}      { return (DARROW); }
{STR_CONST}   {
  int r = DecodeCoolString(yytext, string_buf);
  if (r == ERROR) {
    cool_yylval.error_msg = strdup(string_buf); 
  } else {
    cool_yylval.symbol = stringtable.add_string(string_buf);
  }
  return r;
}
{INT_CONST}   {
  cool_yylval.symbol = inttable.add_string(yytext);
  return (INT_CONST);
}
{TYPEID}      {
  cool_yylval.symbol = idtable.add_string(yytext);
  return (TYPEID);
}
{OBJECTID}    {
  cool_yylval.symbol = idtable.add_string(yytext); 
  return (OBJECTID);
} 
{LE}          { return (LE);  }
{ASSIGN}      { return (ASSIGN);  }
{WHITE_SPACE}
";"           { return ';'; }
"{"           { return '{'; }
"}"           { return '}'; }
","           { return ','; }
":"           { return ':'; }
"("           { return '('; }
")"           { return ')'; }
"."           { return '.'; }
"+"           { return '+'; }
"-"           { return '-'; }
"*"           { return '*'; }
"/"           { return '/'; }
"~"           { return '~'; }
"<"           { return '<'; }
"="           { return '='; }
.             {
  cool_yylval.error_msg = strdup(yytext);
  return ERROR;
}
 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */


%%

int DecodeCoolString(char* raw, char* buffer) {
  int it = 1; 
  int bit = 0;
  while (true) {
    if (raw[it] == '"') {
      buffer[bit] = '\0';
      return STR_CONST;
    }
    if (raw[it] == '\n') {
      sprintf(buffer, "String contains non-escaped new line: %s", raw);
      return ERROR;
    }
    if (raw[it] != '\\') {
      buffer[bit++] = raw[it];
      it += 1;
      continue;
    }
    if (raw[it+1] == 'b') {
      buffer[bit++] = '\b';
    } else if (raw[it+1] == 't') {
      buffer[bit++] = '\t';
    } else if (raw[it+1] == 'n') {
      buffer[bit++] = '\n';
    } else if (raw[it+1] == 'f') {
      buffer[bit++] = '\f';
    } else if (raw[it+1] == '\n') {
      // Do nothing
    } else {
      buffer[bit++] = raw[it+1];
    }
    it += 2;
  }
}
