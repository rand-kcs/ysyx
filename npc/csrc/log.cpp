//extern uint64_t g_nr_guest_inst;
#include <cstdio>
#include "utils.h"

FILE *log_fp = NULL;

void init_log(const char *log_file) {
  log_fp = stdout;
  if (log_file != NULL) {
    FILE *fp = fopen(log_file, "w");
    Assert(fp, "Can not open '%s'", log_file);
    log_fp = fp;
  }
  Log("Log is written to %s", log_file ? log_file : "stdout\n");
}

extern "C" bool log_enable() {
		return true;
}
