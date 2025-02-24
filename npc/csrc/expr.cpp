/***************************************************************************************
* Copyright (c) 2014-2022 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/


/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>
#include <string.h>
#include <stdlib.h>
#include "mem.h"
#include "utils.h"
#include "macro.h"
#include "cpu.h"
#define MIN_PRIOR 0

enum {
  TK_NOTYPE = 256, TK_EQ,
	TK_DEC, TK_HEX,TK_NEG,
	TK_REF, TK_REG, TK_RNAME,
	TK_GEQ, TK_LEQ, TK_GTER,
	TK_LESS, TK_LAND, TK_LOR,
	TK_BAND, TK_BOR, 
  /* TODO: Add more token types */

};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */

  {" +", TK_NOTYPE},    // spaces
  {"\\+", '+'},         // plus
  {"-", '-'},         // minus
  {"\\*", '*'},         // multi
  {"/", '/'},         // divide
  {"\\(", '('},         // left bracket
  {"\\)", ')'},         // right bracket
  {"==", TK_EQ},        // equal
  {">=", TK_GEQ},        // Geater or equal
  {">", TK_GTER},        // greated
  {"<=", TK_LEQ},        // less or equl
  {"<", TK_LESS},        // less
  {"&&", TK_LAND},        // Logical AND
  {"\\|\\|", TK_LOR},        // Lorgical OR
  {"&", TK_BAND},        // Bitwise AND
  {"\\|", TK_BOR},        // Bitwise OR
	{"0x[0-9a-z]+[U]?", TK_HEX}, //hexdecimal
	{"[0-9]+[U]?", TK_DEC},  //decimal
	{"\\$", TK_REG}, //register fetch value indicator
	{"[a-z][a-z0-9]", TK_RNAME}, // now only to indicate REGISTER NAME
};

static struct prior {
	const int op;
	int prior_value;
} priors[] = {
	{'+', 4},
	{'-', 4},
	{'*', 3},
	{'/', 3},
	{TK_NEG,2},
	{TK_REF,2},
	{TK_GEQ,6},
	{TK_GTER,6},
	{TK_LEQ,6},
	{TK_LESS,6},
	{TK_EQ,7},
	{TK_BAND,8},
	{TK_LAND,11},
	{TK_LOR,12},
	{TK_BOR,10},
	{TK_REG,2},
};

static int check_prior(int op) {
	for(int i = 0; i < ARRLEN(priors); i++) 
		if(op == priors[i].op)
			return priors[i].prior_value;
	Assert(0, "Unmatch operator index: %d\n", op);
}

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
	
}

typedef struct token {
  int type;
  char str[32];
} Token;

static Token tokens[128] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;

  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

				#ifdef CONFIG_MATCH_OUT
        Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
            i, rules[i].regex, position, substr_len, substr_len, substr_start);
				#endif

        position += substr_len;

        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */

        switch (rules[i].token_type) {
					case TK_NOTYPE:
									break;
					case TK_HEX:
					case TK_DEC:	
					case TK_RNAME:
								strncpy(tokens[nr_token].str, substr_start, substr_len);
								tokens[nr_token].str[substr_len] = '\0';
          default: tokens[nr_token].type = rules[i].token_type;
									 nr_token++;
        }

        break;
      }
    }

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }
   for(int i = 0; i < nr_token; i++){
     if(tokens[i].type == '-' && (i-1 < 0 || (tokens[i-1].type != TK_DEC &&tokens[i-1].type != TK_HEX&&tokens[i-1].type != ')')))
       tokens[i].type = TK_NEG;
   }
	for(int i = 0; i < nr_token; i++){
     if(tokens[i].type == '*' && (i-1 < 0 || (tokens[i-1].type != TK_DEC &&tokens[i-1].type != TK_HEX&&tokens[i-1].type != ')')))
       tokens[i].type = TK_REF;
   }
  return true;
}

// for now, just check that the each parathesis match, 
// may extend to check the syntax error of the buf, like "1 ** 2" .etc
bool check_expr_valid() {
	int flag = 0;
	for(int i = 0; i < nr_token; i++) {
		if(tokens[i].type == '(') {
			flag++;	
		}else if(tokens[i].type == ')') {
			flag--;	
			if(flag < 0) {
				printf("Error: ) Unmatch\n");		
				return false;
			}
		}
	}
	if(flag != 0) {
		printf("Error: ( Unmatch\n");		
		return false;
	}
#ifdef CONFIG_EXPR_EVAL
	printf("----Valid----\n");
#endif
	return true;
}

bool check_parentheses(int p, int q) {
	if(!(tokens[p].type == '(' && tokens[q].type == ')')){
		return false;		
	} 
	int flag = 0;
	for(int i = p + 1; i <= q-1; i++) {
		if(tokens[i].type == '(') {
			flag++;	
		}else if(tokens[i].type == ')') {
			flag--;	
			if(flag < 0) {
				return false;
			}
		}
	}
	if(flag > 0) {
		return false;
	}
	return true;

}

int find_main_operator(int p, int q) {
	int op_pos = 0, op_prior = MIN_PRIOR;
	int cur_prior;
  int flag;
	for(int i = p; i <= q; i++) {
		switch (tokens[i].type){
		case '(':
      {
				flag = 1; int j;
				for(j = i+1; ; j++) {
					 if(tokens[j].type =='(')	
							flag++;
					else if(tokens[j].type==')') {
							flag--;
							if(flag == 0)
								break;
					}
				}
				i = j;
				break;
      }
		case TK_HEX:
		case TK_DEC:
		case TK_RNAME:	
				break;
		default:
				cur_prior = check_prior(tokens[i].type);
					if(cur_prior >= op_prior){
						op_pos = i;	
						op_prior = cur_prior;
					}
					break;
		}
	}
	return op_pos;
}


uint32_t eval(int p, int q, bool* success) {
  if (p > q) {
    /* Bad expression */
		Assert(0, "Bad Expression with p:%d and q:%d\n", p, q);
  }
  else if (p == q) {
    /* Single token.
     * For now this token should be a number.
     * Return the value of the number.
     */
			if(tokens[p].type == TK_DEC) {
				 return strtol(tokens[p].str, NULL, 10);
			}else if(tokens[p].type == TK_HEX) {
				 return strtol(tokens[p].str, NULL, 16);
			}else {
				printf("Error! p==q but not a Number.\n");
				return 0;
			}
  }
  else if (check_parentheses(p, q) == true) {
    /* The expression is surrounded by a matched pair of parentheses.
     * If that is the case, just throw away the parentheses.
     */
    return eval(p + 1, q - 1, success);
  }
  else {
    int op = find_main_operator(p,q);
		int op_type = tokens[op].type;
		if(op_type == TK_NEG) {
			return -eval(op+1, q, success);
		}else if(op_type == TK_REG) {
			Assert(tokens[op+1].type == TK_RNAME, "$ Unmatch");
			uint32_t ret_val = isa_reg_str2val(tokens[op+1].str, success);
			if(!(*success)){
				Log("%s: Can't find Register with name: %s\n", ANSI_FMT("ERROR", ANSI_FG_RED), tokens[op+1].str);
				return 0;
			}
			return ret_val;
		}else if(op_type == TK_REF) {
			uint32_t val1 = eval(op + 1, q, success);
			return pmem_read(val1);
		}else{
   		 uint32_t val1 = eval(p, op - 1, success);
   		 uint32_t val2 = eval(op + 1, q, success);

   		 switch (op_type) {
   		   case '+': return val1 + val2;
   		   case '-': return val1 - val2;/* ... */
   		   case '*': return val1 * val2;/* ... */
   		   case '/': return val1 / val2;/* ... */
   		   case TK_EQ: return val1 == val2;/* ... */
   		   case TK_GEQ: return val1 >= val2;/* ... */
   		   case TK_LEQ: return val1 <= val2;/* ... */
   		   case TK_GTER: return val1 > val2;/* ... */
   		   case TK_LESS: return val1 < val2;/* ... */
   		   case TK_LAND: return val1 && val2;/* ... */
   		   case TK_LOR: return val1 || val2;/* ... */
   		   case TK_BAND: return val1 & val2;/* ... */
   		   case TK_BOR: return val1 | val2;/* ... */
   		   default:
						Assert(0, "Operator Type Not Found!\n");
   		 }
		}
  }
}

word_t expr(char *e, bool *success) {
	*success = true;
  if (!make_token(e)) {
    *success = false;
    return 0;
  }
	if(!check_expr_valid()) {
		*success = false;
		return 0;	
	}

  /* TODO: Insert codes to evaluate the expression. */
  //TODO();
	return eval(0, nr_token-1, success);

}
