#include <am.h>
#include <nemu.h>
#include <stdio.h>

#define SYNC_ADDR (VGACTL_ADDR + 4)

void __am_gpu_init() {
//   int data = inl(VGACTL_ADDR);
//   int height = data & 0xffff;
//   int width = (data >> 16) & 0xffff;
// int i;
// int w = width;  // TODO: get the correct width
// int h = height;  // TODO: get the correct height
// uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;
// for (i = 0; i < w * h; i ++) fb[i] = i;
// outl(SYNC_ADDR, 1);
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  int data = inl(VGACTL_ADDR);
  int height = data & 0xffff;
  int width = (data >> 16) & 0xffff;
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = width, .height = height, 
    .vmemsz = 0
  };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  if (ctl->sync) {
    outl(SYNC_ADDR, 1);
  }

  int cnt = 0;
  uint32_t *px = (uint32_t*)ctl->pixels;
  //int width = inw(VGACTL_ADDR + 2);

  int data = inl(VGACTL_ADDR);
  int width = (data >> 16) & 0xffff;
  for(int j= 0; j < ctl->h; j++)
    for(int i = 0; i < ctl->w; i++){
      outl(FB_ADDR + (ctl->y + j)*width*4 + (ctl->x + i)*4 , px[cnt++]);
    }
  //printf("drawing at height: %d, width: %d\n", (ctl->y), (ctl->x));
  
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
