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
	
	


all:
	@echo "Write this Makefile by your self."

sim: $(BIN)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	$^
 
include ../Makefile
