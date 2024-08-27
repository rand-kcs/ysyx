

sim: encode42.v sim_main.cpp
	verilator --cc --exe --build -j 0 -Wall --trace-fst $^
	obj_dir/Vencode42
