#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

int printf(const char *fmt, ...) {
  panic("Not implemented");
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
}


int sprintf(char* out, const char *fmt, ...)   /* '...' is C syntax for a variadic function */
 {
	 	 out[0] = '\0';
		 va_list ap;
		 int d;
		 char c;
		 char *s;
		 char tmp[128];

		 va_start(ap, fmt);
		 while (*fmt){
				if(*fmt == '%'){
					fmt++;
				 switch (*fmt) {
				 case 's':              /* string */
						 s = va_arg(ap, char *);
						 strcat(out, s);
						 break;
				 case 'd':              /* int */
						 d = va_arg(ap, int);
						 strcat(out, itos(tmp, d));
						 break;
				 case 'c':              /* char */
						 /* need a cast here since va_arg only
								takes fully promoted types */
						 c = (char) va_arg(ap, int);
						 strcat(out, ctos(tmp, c));
						 break;
				 default:
						panic("NOT IMPLEMENT");
						return -1;
				 }
				}else{
					strcat(out, ctos(tmp, *fmt));
				}
				fmt++;
		 }
		 va_end(ap);
		return strlen(out);
 }

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
