TOPNAME=top
BUILD_DIR=./build
OBJ_DIR=$(BUILD_DIR)/obj_dir
NXDC_FILES= constr/top.nxdc

VERILATOR= verilator
VERILATOR_CFLAGS += -MMD --build -cc -O3 --x-assign fast --x-initial fast --noassert

$(shell mkdir -p $(BUILD_DIR))

BIN = $(BUILD_DIR)/$(TOPNAME)

# constriant file
SRC_AUTO_BIND= $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

#rules for nvboard
include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""

VSRCS = ./vsrc/top.v ./vsrc/switch.v
CSRCS = $(abspath ./csrc/main.cpp)
CSRCS += $(SRC_AUTO_BIND)



$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS))  \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))
	
	
VSRC=$(shell find -name "*.v" | grep -v "$(TOPNAME).v")
CXXSRC=$(shell find ./csrc -name "*.cpp")
CXXSRC+=$(shell find ./csrc -name "*.c")
LDFLAGS= -lreadline 
 
# For disasm
LDFLAGS+= $(shell llvm-config --libs) 

NEW_LDFLAGS = $(foreach flag,$(LDFLAGS),-LDFLAGS $(flag))

all:
	@echo "Write this Makefile by your self."

sim: $(BIN)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$^

IMG:=
MYCXXFLAGS= $(shell llvm-config --cxxflags) -fPIE -g -fpermissive
NEW_CXXFLAGS= $(foreach flag,$(MYCXXFLAGS), -CFLAGS $(flag))

TRACEFLAG:=  

WAVETRACE=0
ifeq ($(WAVETRACE), 1)
	TRACEFLAG= --trace-fst
endif

# 默认值：显示所有警告（不抑制）
SUPPRESS_PIN_WARN ?= 0
VERILATOR_FLAGS = -Wall

# 根据 SUPPRESS_PIN_WARN 变量的值添加选项
ifeq ($(SUPPRESS_PIN_WARN),1)
    VERILATOR_FLAGS += -Wno-PINCONNECTEMPTY -Wno-PINMISSING -Wno-CASEINCOMPLETE
    $(info # PINCONNECTEMPTY warnings are SUPPRESSED)
else
    $(info # PINCONNECTEMPTY warnings are ENABLED)
endif

run:
	$(VERILATOR) --public --cc --exe --build -j 0 $(VERILATOR_FLAGS) -timing  $(TRACEFLAG) $(NEW_LDFLAGS) $(NEW_CXXFLAGS)  $(CXXSRC)  vsrc/$(TOPNAME).v $(VSRC) --Mdir build/ --top-module $(TOPNAME)
	./build/Vtop  --log=$(BUILD_DIR)/npc-log.txt --diff=ref/riscv32-nemu-interpreter-so $(ARGS) $(IMG) 
 
clean:
	rm -r build/
include ../Makefile
