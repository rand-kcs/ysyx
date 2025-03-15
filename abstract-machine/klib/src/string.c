#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
		size_t len = 0;
		while(s && s[len]){
			len++;
		}
		return len;
}

char *strcpy(char *dst, const char *src) {
		size_t lens = strlen(src);
		for(size_t i = 0; i <= lens; i++)
			dst[i] = src[i];
		return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  panic("Not implemented");
}

char *strcat(char *dst, const char *src) {
	size_t lend = strlen(dst)	;
	strcpy(dst + lend, src);
	return dst;
}

int strcmp(const char *s1, const char *s2) {
	size_t len1 = strlen(s1), len2 = strlen(s2);
	for(size_t i = 0; i < len1 && i < len2; i++){
		if(s1[i] < s2[i]) 
			return -1;
		else if(s1[i] > s2[i])
			return 1;
	}
	if(len1 == len2)
		return 0;
	else if(len1 < len2)
		return -1;
	else 
		return 1;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  panic("Not implemented");
}

void *memset(void *s, int c, size_t n) {
	char* ts = (char*) s;
	for(size_t i = 0; i < n; i++)	
			ts[i] = c;
	return s;
}

void *memmove(void *dst, const void *src, size_t n) {
  panic("Not implemented");
}

void *memcpy(void *out, const void *in, size_t n) {
  char *dest = (char*)out;     // 转换为 char* 指针
  const char *src = (const char*)in;
  for(size_t i = 0; i < n; i++)
    dest[i] = src[i];

  return out;
}

int memcmp(const void *s1, const void *s2, size_t n) {
	unsigned char *ts1 = (unsigned char *)s1;
	unsigned char *ts2 = (unsigned char *)s2;
	for(size_t i = 0; i < n; i++){
		if(ts1[i] < ts2[i])
			return -1;
		else if(ts1[i] > ts2[i])
			return 1;
	}
	return 0;

}

char* ctos(char* dst, char src){
	dst[0] = src;
	dst[1] = '\0';
	return dst;
}


char* itos(char* dst, int src){
		int neg = src < 0 ? 1 : 0;
		if(neg) src = -src;
		char tmp[20];
		int index = 1;
		tmp[0] = src % 10 + '0';
		src/=10;
		while(src){
			tmp[index++] = '0' + src%10;
			src/=10;
		}
		tmp[index] = '\0';
	
		if(neg){
			index = 1;
			dst[0] = '-';
		}else{
			index=0;
		}
		
		int len = strlen(tmp);
		for(int i = 0; i < len; i++){
			dst[index++] = tmp[len - i - 1];
		}
		dst[index] = '\0';
		return dst;
}

// 将整数转换为十六进制字符串的函数
char* itohs(char* buffer, int value) {
    const char* hexDigits = "0123456789ABCDEF"; // 十六进制数字
    for (int i = 7; i >= 0; i--) { // 处理每一个四位的十六进制位
        buffer[i] = hexDigits[value & 0xF]; // 取出最低四位并找到对应的十六进制字符
        value >>= 4; // 将数值右移四位
    }
    buffer[8] = '\0'; // 添加字符串终止符
    return buffer;
}

#endif
