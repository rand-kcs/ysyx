#include<utils.h>

#ifdef CONFIG_IRINGBUF
	IRingBuf iring_buf = { .index = 0 };

void IRF_Write(char* s){
	strcpy(iring_buf.ring_buf[iring_buf.index++], s);
	if(iring_buf.index == RING_LEN)
		iring_buf.index = 0;
}

void IRF_Log(){
	log_write("\n\nLast %d Inst Executed:\n", RING_LEN);
  int end  = iring_buf.index;
	for(int i = 0; i < RING_LEN; i++) {
    printf("Str: %s, Len: %ld", iring_buf.ring_buf[end],strlen(iring_buf.ring_buf[end]));
    if(strlen(iring_buf.ring_buf[end]) > 0) {
      log_write("%s", iring_buf.ring_buf[end]); 
      log_write("\n");
    }
    end = (end+1) % RING_LEN;
	}
}

#endif


