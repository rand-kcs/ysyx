#include <cstdlib>
#include <climits>
#include <readline/readline.h>
#include <readline/history.h>
#include "cpu.h"
#include "mem.h"
#include "utils.h"
#define ARRLEN(arr) (int)(sizeof(arr) / sizeof(arr[0]))

word_t expr(char *e, bool *success);


static int is_batch_mode = false;

void init_regex();
void init_wp_pool();
void new_wp(char*);
void free_wp(int);
void info_wp();


/* We use the `readline' library to provide more flexibility to read from stdin. */
static char* rl_gets() {
  static char *line_read = NULL;

  if (line_read) {
    free(line_read);
    line_read = NULL;
  }

  line_read = readline("(NPC) ");

  if (line_read && *line_read) {
    add_history(line_read);
  }

  return line_read;
}

static int cmd_c(char *args) {
  cpu_exec(UINT_MAX);
  return 0;
}

static int cmd_si(char *args);
static int cmd_q(char *args) {
	//npc_state.state = NPC_QUIT;
  return -1;
}

static int cmd_info(char *args);
static int cmd_x(char *args);
static int cmd_p(char *args);
static int cmd_w(char *args);

#if 0
static int cmd_help(char *args);



static int cmd_d(char *args);
#endif

static struct {
  const char *name;
  const char *description;
  int (*handler) (char *);
} cmd_table [] = {
  { "si", "Step N inst", cmd_si },
  { "c", "Continue the execution of the program", cmd_c },
  { "q", "Exit NPC", cmd_q },
  { "info", "Print info about SUBCMD", cmd_info},
  { "x", "Scan N * 4 bytes for the given address", cmd_x},
  { "p", "Print Value of the exprssion", cmd_p},
  //{ "help", "Display information about all supported commands", cmd_help },
  { "w", "Whenever the value of the EXPR changes, stop it.", cmd_w},
  //{ "d", "Delete the certain WP specified by INDEX", cmd_d},

  /* TODO: Add more commands */

};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
    }
  }
  else {
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(arg, cmd_table[i].name) == 0) {
        printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        return 0;
      }
    }
    printf("Unknown command '%s'\n", arg);
  }
  return 0;
}

static int cmd_x(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
	int N; paddr_t address;
  if (arg == NULL) {
    /* no argument given */
  	printf("Usage: x N addres\n");
		return 0;
  }
	N = strtol(arg, NULL, 10);
	if(N == 0) {
		printf("Unvalid N\n");
		return 0;
	}
	arg = strtok(NULL, " ");
	if(arg == NULL) {
  	printf("Usage: x N addres\n");
		return 0;
	}
	address = strtol(arg, NULL, 16);
	if(address == 0) {
		printf("Unvalid address\n");
		return 0;
	}

	for(int i = 0; i < N; i++) {
		printf("0x%08x\n", pmem_read_trace(address));
		address+=4;
	}
	return 0;
}

static int cmd_si(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  if (arg == NULL) {
    /* no argument given */
    cpu_exec(1);
  }
  else {
   	//char** endptr;
		int cnt = strtol(arg, NULL, 10);
		if(cnt == 0){
			printf("Unvalid count or zero provided: '%s'\n", arg);
		}else{
			cpu_exec(cnt);
		}
  }
  return 0;
}

static int cmd_info(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");

  if (arg == NULL) {
    /* no argument given */
    printf("Usage: -r -w\n");
  }
  else {
   	if(strcmp(arg, "r") == 0){
			print_reg_status();
		}else if(strcmp(arg, "w") == 0){
			//info_wp();
		}else{
    	printf("Unknown command '%s'\n", arg);
		}
  }
  return 0;
}

static int cmd_p(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");

  if (arg == NULL) {
    /* no argument given */
    printf("Usage: p <expr> \n");
  }
  else {
		bool success;	
		
		// Treat as a whole;
		char* cmd_expr = (char*)malloc(100 * sizeof(char));
		cmd_expr[0] = '\0';
		while(arg != NULL) {
			strcat(cmd_expr, arg);	
			arg = strtok(NULL, " ")	;
		}

		uint32_t ret_val = expr(cmd_expr, &success);
		free(cmd_expr);
		if(!success) {
			printf("Non-valid Expression: %s\n", arg);
			return 0;
		}
		arg = strtok(NULL, " ");
		printf("Hex: 0x%x\n", ret_val);
		printf("Dec: %u\n", ret_val);
  }
  return 0;
}


static int cmd_w(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("Usage: w <expr>\n");
    }
  }
  else {
		// Treat as a whole;
		char* cmd_expr = (char*)malloc(100 * sizeof(char));
		cmd_expr[0] = '\0';
		while(arg != NULL) {
			strcat(cmd_expr, arg);	
			arg = strtok(NULL, " ")	;
		}

		new_wp(cmd_expr);
		free(cmd_expr);
  }
  return 0;
}
#if 0

static int cmd_d(char *args) {
  /* extract the first argument */
  char *arg = strtok(NULL, " ");
  int i;

  if (arg == NULL) {
    /* no argument given */
    for (i = 0; i < NR_CMD; i ++) {
      printf("Usage: d <index>\n");
    }
  }
  else {
		char* endptr;
		int NO =strtol(args, &endptr, 10);
		if(endptr == arg)	{
			Log("Index Non-valid: %s. ",arg);
			return 0;
		}
		free_wp(NO);
  }
  return 0;
}
#endif

void sdb_set_batch_mode() {
  is_batch_mode = true;
}

void sdb_main_loop() {
  if (is_batch_mode) {
    cmd_c(NULL);
    return;
  }

  for (char *str; (str = rl_gets()) != NULL; ) {
    char *str_end = str + strlen(str);

    /* extract the first token as the command */
    char *cmd = strtok(str, " ");
    if (cmd == NULL) { continue; }

    /* treat the remaining string as the arguments,
     * which may need further parsing
     */
    char *args = cmd + strlen(cmd) + 1;
    if (args >= str_end) {
      args = NULL;
    }


    int i;
    for (i = 0; i < NR_CMD; i ++) {
      if (strcmp(cmd, cmd_table[i].name) == 0) {
        if (cmd_table[i].handler(args) < 0) { return; }
        break;
      }
    }

    if (i == NR_CMD) { printf("Unknown command '%s'\n", cmd); }
  }
}


void init_sdb() {
  /* Compile the regular expressions. */
  init_regex();

  /* Initialize the watchpoint pool. */
  init_wp_pool();
}
