#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

// longest string one time is 128!
int printf(const char *fmt, ...) {
  char total[256];
	va_list ap;
	va_start(ap, fmt);

  int len = vsprintf(total, fmt, ap);
  for(char* p = total; *p; p++)
    putch(*p);
  va_end(ap);
  return len;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
     out[0] = '\0';
		 int d;
		 char c;
		 char *s;
		 char tmp[256];
     int width = -1;
		 while (*fmt){
				if(*fmt == '%'){
          width = -1;
					fmt++;
          if(*fmt == '0'){
            //todo: add padding;
            fmt++;
          }
          if(*fmt >= '1' && *fmt <='9'){
              width = *fmt - '0';
              fmt++;
          }

        
          switch (*fmt) {
          case 's':              /* string */
              s = va_arg(ap, char *);
              break;
          case 'd':              /* int */
              d = va_arg(ap, int);
              s = itos(tmp, d);
              break;
          case 'c':              /* char */
              /* need a cast here since va_arg only
                  takes fully promoted types */
              c = (char) va_arg(ap, int);
              s = ctos(tmp, c);
              break;
          case 'x':              /* char */
          case 'p':              /* char */
              /* need a cast here since va_arg only
                  takes fully promoted types */
              d = (uint32_t) va_arg(ap, int);
              s = itohs(tmp, d);
              break;
          case 'l':
            if(*(fmt+1) == 'd'){
              fmt++;
              d =  va_arg(ap, long int);
              s = itos(tmp, d);
              break;
            }
          default:
              printf("%s You havenot implement this placeholder, ah\n", fmt);
              panic("Error");
              return -1;
          }
          int len = strlen(s);
          if(width > 0){
            if(width > len){
              strcat(out, s);
            }else{
              strcat(out, s + (len - width));
            }
          }else{
            strcat(out, s);
          }
				}else{
					strcat(out, ctos(tmp, *fmt));
				}
				fmt++;
		 }
		return strlen(out);
}


// The longest zhanwei is 128!!
int sprintf(char* out, const char *fmt, ...)   /* '...' is C syntax for a variadic function */
 {
		 va_list ap;
		 va_start(ap, fmt);
     int len = vsprintf(out, fmt, ap);
		 va_end(ap);
		return len;
 }

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
