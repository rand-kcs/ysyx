all:
	@echo "Write this Makefile by your self."

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@echo "Write this Makefile by your self."
	@echo
	@echo "-- VERILATE-----------------"
	verilator -cc --exe --build -Wall --trace-fst --timing  vsrc/testbench.v vsrc/switch.v csrc/sim_main.cpp

	@echo
	@echo "-- RUN--------------------"
	@rm -rf logs
	@mkdir -p logs
	obj_dir/Vtestbench +trace

	@echo
	@echo "-- DONE ------------------"
	@echo "Waveforms dumped in logs/"
	@echo
 
include ../Makefile
