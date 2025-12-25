#include "utils.h"

//#ifdef 
RingBuf iring_buf = { .index = 0 };
RingBuf mring_buf = { .index = 0 };

void RF_Write(RingBuf* rb, char* s){
	strcpy(rb->ring_buf[rb->index++], s);
	if(rb->index == RING_LEN)
		rb->index = 0;
}

void IRF_Log(){
	log_write("\n\nLast %d Inst Executed:\n", RING_LEN);
  int end  = iring_buf.index;
	for(int i = 0; i < RING_LEN; i++) {
    //printf("Str: %s, Len: %ld", iring_buf.ring_buf[end],strlen(iring_buf.ring_buf[end]));
    if(strlen(iring_buf.ring_buf[end]) > 0) {
      log_write("%s", iring_buf.ring_buf[end]); 
    }
    end = (end+1) % RING_LEN;
	}
}

void MRF_Log(){
	log_write("\n\nLast %d Memory option:\n", RING_LEN);
  int end  = mring_buf.index;
	for(int i = 0; i < RING_LEN; i++) {
    //printf("Str: %s, Len: %ld", mring_buf.ring_buf[end],strlen(mring_buf.ring_buf[end]));
    if(strlen(mring_buf.ring_buf[end]) > 0) {
      log_write("%s", mring_buf.ring_buf[end]); 
    }
    end = (end+1) % RING_LEN;
	}
}

//#endif

