module CSRs #(ADDR_WIDTH = 1, DATA_WIDTH = 1) (
  input clk,
  input [DATA_WIDTH-1:0] wdata,
  input [ADDR_WIDTH-1:0] addr,
  input wen,

  output [DATA_WIDTH-1:0] data
);
// word_t mcause, mstatus, mepc;
// word_t mtvec;
/*
    case 0x300:
      return &(cpu.mstatus);
    case 0x305:
      return &(cpu.mtvec);
    case 0x341:
      return &(cpu.mepc);
    case 0x342:
      return &(cpu.mcause);
*/

reg [DATA_WIDTH-1:0] mcause;
reg [DATA_WIDTH-1:0] mstatus;
reg [DATA_WIDTH-1:0] mepc;
reg [DATA_WIDTH-1:0] mtvec;

always@(posedge clk) begin
  if(wen) begin
    case(addr)
      12'h300: mstatus <= wdata; 
      12'h305: mtvec <= wdata; 
      12'h341: mepc <= wdata; 
      12'h342: mcause <= wdata;
      default: 
    endcase
  end
end

MuxKeyWithDefault #(4, 12, 32) data_Mux(data, addr, 32'b0, {
  {12'h300} , mstatus,
  {12'h305} , mtvec ,
  {12'h341} , mepc ,
  {12'h342} , mcause 
});

endmodule
