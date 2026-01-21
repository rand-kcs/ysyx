#include <am.h>
#include <npc.h>
#include <riscv/riscv.h>


uint64_t boot_time = 0;
uint64_t current_time = 0;
void __am_timer_init() {
  uint32_t* p = (uint32_t*) &boot_time;
  *p = inl(RTC_ADDR);
  *(p+1) = inl(RTC_ADDR + 4);

}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uint32_t* p = (uint32_t*) &current_time;
  *p = inl(RTC_ADDR);
  *(p+1) = inl(RTC_ADDR + 4);

  uptime->us = (current_time - boot_time)/2;
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}
