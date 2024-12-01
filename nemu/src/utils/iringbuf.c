#include<utils.h>

#ifdef CONFIG_IRINGBUF
	IRingBuf iring_buf = { .index = 0 };

void IRF_Write(char* s){
	strcpy(iring_buf.ring_buf[iring_buf.index++], s);
	if(iring_buf.index == RING_LEN)
		iring_buf.index = 0;
}

void IRF_Log(){
	log_write("IRING BUFFER OUT: \n");
	for(int i = 0; i < RING_LEN; i++) {
		log_write("%s", iring_buf.ring_buf[i]); 
		if(i == (iring_buf.index + RING_LEN - 1)%RING_LEN)
			log_write("<----end at here");
		log_write("\n");
	}
}

#endif


