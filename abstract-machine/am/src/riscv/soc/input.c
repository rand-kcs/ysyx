#include <am.h>
#include <riscv/riscv.h>
#include <soc.h>
#include <stdio.h>

// 256 大小的映射表，将物理 PS/2 扫描码映射为 AM 虚拟键码
static const int ps2_map[256] = {
  [0x1C] = AM_KEY_A, [0x32] = AM_KEY_B, [0x21] = AM_KEY_C, [0x23] = AM_KEY_D,
  [0x24] = AM_KEY_E, [0x2b] = AM_KEY_F, [0x34] = AM_KEY_G, [0x33] = AM_KEY_H,
  [0x43] = AM_KEY_I, [0x3b] = AM_KEY_J, [0x42] = AM_KEY_K, [0x4b] = AM_KEY_L,
  [0x3a] = AM_KEY_M, [0x31] = AM_KEY_N, [0x44] = AM_KEY_O, [0x4d] = AM_KEY_P,
  [0x15] = AM_KEY_Q, [0x2d] = AM_KEY_R, [0x1b] = AM_KEY_S, [0x2c] = AM_KEY_T,
  [0x3c] = AM_KEY_U, [0x2a] = AM_KEY_V, [0x1d] = AM_KEY_W, [0x22] = AM_KEY_X,
  [0x35] = AM_KEY_Y, [0x1a] = AM_KEY_Z,
  
  [0x45] = AM_KEY_0, [0x16] = AM_KEY_1, [0x1e] = AM_KEY_2, [0x26] = AM_KEY_3,
  [0x25] = AM_KEY_4, [0x2e] = AM_KEY_5, [0x36] = AM_KEY_6, [0x3d] = AM_KEY_7,
  [0x3e] = AM_KEY_8, [0x46] = AM_KEY_9,

  [0x29] = AM_KEY_SPACE, [0x5a] = AM_KEY_RETURN, [0x66] = AM_KEY_BACKSPACE,
  [0x76] = AM_KEY_ESCAPE, [0x0d] = AM_KEY_TAB,
  // 扩展按键（如方向键、F1-F12等）可以根据你的需要继续在这里补充
};

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  // 静态变量，用来记住上一次是不是收到了断码 0xF0
    static int is_keyup = 0; 
    
    // 1. 从你的硬件 APB 读一个 32 位的数据，但只有低 8 位有效
    int code = inl(KBD_ADDR) & 0xFF; 
    // 2. 如果硬件返回 0，说明没按键，直接退出
    if (code == 0) {
        kbd->keycode = AM_KEY_NONE;
        return;
    }

    // 3. 状态机：如果收到 0xF0，说明下一个进来的码是松开操作
    if (code == 0xF0) {
        is_keyup = 1;
        kbd->keycode = AM_KEY_NONE; // 本次还没有键码，直接返回
        return;
    }

    // 4. 到这里，说明收到了真实的扫描码（比如 0x1C）
    // 通过软件查表，把 PS/2 扫描码转换成 AM 框架认识的宏
    kbd->keycode = ps2_map[code];
    
    // 5. 根据之前的状态，决定是按下还是松开
    kbd->keydown = is_keyup ? 0 : 1;

    // 6. 状态机复位，准备迎接下一次按键
    is_keyup = 0;
    printf("get code: %x\n", code);
}
