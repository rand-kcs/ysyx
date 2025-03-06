#include "mem.h"
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cassert>
#include <getopt.h>
#include "utils.h"
#include "macro.h"


#ifndef RESET_VECTOR
#define RESET_VECTOR 0x80000000
#endif

//extern uint32_t *pmem;
void init_log(const char*);
void init_sdb();

static char* log_file = NULL;
static char *img_file = NULL;
static char *ref_so_file = NULL;
static int difftest_port = 1234;

void init_difftest(char *ref_so_file, long img_size, int port);
void init_disasm(const char *triple);

static long load_img() {
  if (img_file == NULL) {
    Log("No image is given. Use the default build-in image.\n");
    load_default_img();
    return 4096; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  Assert(fp, "Can not open '%s'", img_file);

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

  Log("The image is %s, size = %ld\n", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(guest_to_host(RESET_VECTOR), size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return size;
}

static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"batch"    , no_argument      , NULL, 'b'},
    {"log"      , required_argument, NULL, 'l'},
    {"diff"     , required_argument, NULL, 'd'},
    {"port"     , required_argument, NULL, 'p'},
    {"elf"      , required_argument, NULL, 'e'},
    {"help"     , no_argument      , NULL, 'h'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-bhl:d:p:e:", table, NULL)) != -1) {
    switch (o) {
			/*
      case 'b': sdb_set_batch_mode(); break;
      case 'p': sscanf(optarg, "%d", &difftest_port); break;
			case 'e': elf_file = optarg; break;
			*/
      case 'l': log_file = optarg; break;
      case 'd': ref_so_file = optarg; break;
      case 1: img_file = optarg; return 0;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\t-l,--log=FILE           output log to FILE\n");
        printf("\t-d,--diff=REF_SO        run DiffTest with reference REF_SO\n");
				/*
        printf("\t-b,--batch              run with batch mode\n");
        printf("\t-p,--port=PORT          run DiffTest with port PORT\n");
        printf("\t-e,--elf=FILE           enable function trace WHEN CONFIG_FTRACE ON\n");
        printf("\n");
				*/
				assert(0);
    }
  }
  return 0;
}

void init_monitor(int argc, char **argv) {
  /* Perform some global initialization. */

  /* Parse arguments. */
  parse_args(argc, argv);

	/* open log file */
	init_log(log_file);

  // Init ISA -- pc, default img set

  /* Load the image to memory. This will overwrite the built-in image. */
  long img_size = load_img();


  IFDEF(ITRACE, init_disasm(
                               "riscv32" "-pc-linux-gnu"
  ));

  #ifdef DIFFTEST
  /* Initialize differential testing. */
  init_difftest(ref_so_file, img_size, difftest_port);
  #endif

  init_sdb();
}
