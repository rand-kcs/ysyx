TOPNAME = ysyxSoCFull
BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
NXDC_FILES = constr/top.nxdc

BIN = $(BUILD_DIR)/$(TOPNAME)
$(shell mkdir -p $(BUILD_DIR))

# --- 1. NVBoard 规则 ---
include $(NVBOARD_HOME)/scripts/nvboard.mk

# --- 2. 约束文件与自动绑定 ---
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# --- 3. 源文件收集 (VSRC & CXXSRC) ---
VSRC = $(shell find -name "*.v")
VSRC += $(shell find $(YSYX_HOME)/ysyxSoC/perip -name "*.v")

CSRCS = $(abspath ./csrc/main.cpp)
CXXSRC = $(shell find ./csrc -name "*.cpp")
CXXSRC += $(shell find ./csrc -name "*.c")
CXXSRC += $(SRC_AUTO_BIND)

# --- 4. 包含路径 (Include Paths) ---
INC_PATH = $(YSYX_HOME)/ysyxSoC/perip/uart16550/rtl
INC_PATH += $(YSYX_HOME)/ysyxSoC/perip/spi/rtl
INC_PATH += $(NVBOARD_HOME)/usr/include  # 【修复1】移除了错误的 usr/ 目录

# 统一生成 -I 参数
INCFLAGS = $(addprefix -I, $(INC_PATH))

# --- 5. 编译参数与链接参数 ---
VERILATOR = verilator
VERILATOR_FLAGS = -MMD --build -cc -O3 --x-assign fast --x-initial fast --noassert
VERILATOR_FLAGS += -Wall --timescale "1ns/1ns" --no-timing

# 警告抑制逻辑
SUPPRESS_PIN_WARN ?= 0
ifeq ($(SUPPRESS_PIN_WARN),1)
    VERILATOR_FLAGS += -Wno-PINCONNECTEMPTY -Wno-PINMISSING -Wno-CASEINCOMPLETE -Wno-DECLFILENAME -Wno-ASSIGNDLY -Wno-DEFPARAM -Wno-UNUSEDPARAM -Wno-SYNCASYNCNET  
    $(info # PINCONNECTEMPTY warnings are SUPPRESSED)
else
    $(info # PINCONNECTEMPTY warnings are ENABLED)
endif

# 波形追踪
WAVETRACE = 0
ifeq ($(WAVETRACE), 1)
    VERILATOR_FLAGS += --trace-fst
endif

# C++ 编译参数 (CFLAGS)
# 【修复2】去掉了危险的 foreach，统一整合成一个变量
MYCXXFLAGS = $(shell llvm-config --cxxflags) -fPIE -g -fpermissive
MYCXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""
MYCXXFLAGS += $(shell sdl2-config --cflags)
# 链接参数 (LDFLAGS)
# 【修复3】加入了 $(NVBOARD_ARCHIVE)，否则链接时会报错找不到 nvboard 函数

MYLDFLAGS = -lreadline $(shell llvm-config --libs) $(NVBOARD_ARCHIVE)
MYLDFLAGS += $(LDFLAGS)

# --- 6. 运行所需变量 ---
TOP_PATH = $(YSYX_HOME)/ysyxSoC/build
MROM ?= ../mykernel/build/char-test.bin
FLASH ?= ../mykernel/build/char-test.bin
LOGFILE ?= $(BUILD_DIR)/npc-log.txt

ARGS ?=
ifeq ($(BATCH),1)
	ARGS += -b
endif

# --- 7. 目标规则 (Targets) ---
all:
	@echo "Write this Makefile by your self."

sim: $(BIN)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$^

run: $(SRC_AUTO_BIND)
	$(VERILATOR) --public --cc --exe --build --prefix VDUT -j 0 \
		$(VERILATOR_FLAGS) \
		$(INCFLAGS) \
		-CFLAGS "$(MYCXXFLAGS)" \
		-LDFLAGS "$(MYLDFLAGS)" \
		$(CXXSRC) $(TOP_PATH)/$(TOPNAME).v $(VSRC) \
		--Mdir build/ --top-module $(TOPNAME)
	./build/VDUT $(ARGS) --log=$(LOGFILE) --diff=ref/riscv32-nemu-interpreter-so --flash=$(FLASH) 

debug:
	$(VERILATOR) --public --cc --exe --build --prefix VDUT -j 0 \
		$(VERILATOR_FLAGS) \
		$(INCFLAGS) \
		-CFLAGS "$(MYCXXFLAGS) -O0" \
		-LDFLAGS "$(MYLDFLAGS) -g" \
		$(CXXSRC) $(TOP_PATH)/$(TOPNAME).v $(VSRC) \
		--Mdir build/ --top-module $(TOPNAME)
	gdb --args ./build/VDUT --flash=$(FLASH) 

clean:
	rm -rf build/

include ../Makefile
