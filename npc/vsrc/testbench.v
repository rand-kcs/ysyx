module testbench(
		input a,
		input b,
		output f
);

switch s1(a,b,f);


initial begin
	$display("[%0t] Tracing to logs/vlt_dump.fst", $time);
	$dumpfile("logs/vlt_dump.fst");
	$dumpvars();
	#50 $finish;

end

endmodule
