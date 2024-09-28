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

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <string.h>

// this should be enough
static char buf[65536] = {};
static char code_buf[65536 + 128] = {}; // a little larger than `buf`
static char *code_format =
"#include <stdio.h>\n"
"int main() { "
"  unsigned result = %s; "
"  printf(\"%%u\", result); "
"  return 0; "
"}";
static int buf_index = 0;

static uint32_t choose(int up) {
	return (uint32_t) rand() % up;
}
// TODO: HEX? DEC? Negetive?
static void gen_num() {
	uint32_t rand_gen = choose(10000)	;
	char str[10];
	//char u_symbol[20] = "(unsigned)";
	sprintf(str, "%u", rand_gen);
	strcat(str, "U");
	buf[buf_index] = '\0';
	//strcat(buf, u_symbol);
	//buf_index += strlen(u_symbol);
	strcat(buf, str);
	buf_index += strlen(str);
}

static void gen_rand_op() {
	switch(choose(4)) {
		case 0: buf[buf_index++] = '+'; break;
		case 1: buf[buf_index++] = '-';break;
		case 2: buf[buf_index++] = '*';break;
		default: buf[buf_index++] = '/';break;
	}
}

static const int MAX_LEVEL = 7;
static const int MIN_LEVEL = 2;

static void gen_rand_expr(int level) {
	uint32_t rand_space = choose(3)	;
	for(int i = 0; i < rand_space; i++)
		buf[buf_index++] =' ';
	
	if(level > MAX_LEVEL) {
		gen_num(); return;
	}
 
  if(level < MIN_LEVEL) {
		 gen_rand_expr(level+1); gen_rand_op(); gen_rand_expr(level+1);
		 return ;
	}

	switch(choose(3)) {
		case 0 : gen_num(); break;
		case 1 : buf[buf_index++] = '('; gen_rand_expr(level+1); buf[buf_index++]=')';break;
		default: gen_rand_expr(level+1); gen_rand_op(); gen_rand_expr(level+1);break;
	}
}

static void gen_rand_expr_main() {
	buf_index = 0;
	gen_rand_expr(0);
	buf[buf_index] = '\0';
}

int main(int argc, char *argv[]) {
  int seed = time(0);
  srand(seed);
  int loop = 1;
  if (argc > 1) {
    sscanf(argv[1], "%d", &loop);
  }
  int i;
  for (i = 0; i < loop; i ++) {
    gen_rand_expr_main();

    sprintf(code_buf, code_format, buf);

    FILE *fp = fopen("/tmp/.code.c", "w");
    assert(fp != NULL);
    fputs(code_buf, fp);
    fclose(fp);

    int ret = system("gcc /tmp/.code.c -o /tmp/.expr");
		//printf("System Call Return Value: %d\n", ret);
    if (ret != 0) continue;

    fp = popen("/tmp/.expr", "r");
    assert(fp != NULL);

    int result;
    ret = fscanf(fp, "%d", &result);
		if(ret != 1) continue;
		//printf("RETVALE: %d \n", ret);
    pclose(fp);

    printf("%u %s\n", result, buf);
  }
  return 0;
}
