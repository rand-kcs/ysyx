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
#include "mem.h"
#include "cpu.h"
#include "utils.h"
#include "macro.h"

#define NR_WP 32

#define MAX_EXPR_SIZE 128

word_t expr(char *e, bool *success);

typedef struct watchpoint {
  int NO;
  struct watchpoint *next;
	
  /* TODO: Add more members if necessary */
	char wp_expr[MAX_EXPR_SIZE];
	uint32_t pre_value;

} WP;

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
  int i;
  for (i = 0; i < NR_WP; i ++) {
    wp_pool[i].NO = i;
    wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
  }

  head = NULL;
  free_ = wp_pool;
}

/* TODO: Implement the functionality of watchpoint */

void new_wp(char* e) {
	Assert(free_, "WatchPoints number out of range!\n");
	
	bool success;
	uint32_t e_value = expr(e, &success);
	if(!success) {
		Log("Watchpoint exprssion: '%s' non-valid!\n", e);
		return;
	}

	WP* p = free_;
	free_ = free_->next;

	WP* q = head;
	p->next = q;
	strncpy(p->wp_expr, e, MAX_EXPR_SIZE-1);
	p->pre_value = e_value;
	head = p;
}


void free_wp(int NO) {
	//TODO: find wp in Head and delete it;
	WP* p = head;
	if(!p) {
		Log("Watchpoint NOT using!\n");
	}
	WP* q = head->next;

	while(q) {
		if(q->NO == NO)		
			break;
		p = q;
		q = q->next;
	}
	if(!q) {
		Log("WatchPoint with NO: %d not exist!\n", NO);
		return;
	}
		
	p->next = q->next;		
	WP* u = free_;
	q->next = u;
	free_ = q;		
	Log("Free WP indexd:%d Successfully!\n", NO);
}

bool WP_trigger(){
	bool ret = false;
	WP *p = head;
	while(p) {
		bool success;
		uint32_t cur_value = expr(p->wp_expr, &success);
		if(cur_value != p->pre_value){
				ret = true;
				Log("Watchpoint Trigger:\nExprssion: %s\nPrevious Value: %u\nChanged To: %u\n", p->wp_expr, p->pre_value, cur_value);
				p->pre_value = cur_value;
		}
		p = p->next;
	}
	return ret;

}

void info_wp() {
	WP* p = head;
	printf("NO:\t\tEXPR:\t\tVALUE:\t\t\n");
	while(p) {
		printf("%d\t\t%s\t\t%u\n", p->NO, p->wp_expr, p->pre_value);
		p = p->next;
	}
}
