module WBU(
  input valid_in_lsu,
  
  input [7:0]  opcode,

  input [31:0] pc,
  input [31:0] aluout,
  input [31:0] csr_out,
  input [31:0] rdata_w,
  input gpr_wen,
  input rd,

  input csr_wen,
  input [11:0] csr_waddr,
  input [31:0] csr_wdata,

  output [31:0] dnpc,

  output gpr_wen_buf,
  output [4:0] rd_buf,
  output [31:0] gpr_wdata,

  output csr_wen_buf,
  output [11:0] csr_addr_buf,
  output [31:0] csr_wdata_buf,

  output valid_out_wbu
);

assign valid_out_wbu = valid_in_lsu;

wire [31:0] snpc;
assign snpc = pc + 4;

wire jen;
wire [1:0] dnpc_select;
assign jen = (opcode === 7'b1101111 | opcode === 7'b1100111); // jal and jalr
assign dnpc_select = {is_ecall|is_mret, ben|jen};

MuxKeyWithDefault #(4, 2, 32) dnpcMKWD(dnpc, dnpc_select, 32'b0, {
	2'b00, snpc,
	2'b01, aluout,
	2'b10, csr_out,
	2'b11, csr_out
});

MuxKeyWithDefault #(4, 7, 32) gpr_wdataMKWD(gpr_wdata, opcode, aluout, {
	7'b1101111, snpc,     //jal 
	7'b1100111, snpc,     //jalr 
  7'b0000011, rdata_w,  // lw, lh, lb, ...
  7'b1110011, csr_out  // csr..

  // unspecify opcode lead to default -- aluout
  // ( the inst with wen)
});

endmodule

