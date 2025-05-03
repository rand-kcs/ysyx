module CSRs #(ADDR_WIDTH = 1, DATA_WIDTH = 1) (
  input clk,
  input rst,
  input valid_wbu,
  input [ADDR_WIDTH-1:0] waddr,
  input [DATA_WIDTH-1:0] wdata,
  //wen only stands for csrxx inst;
  input wen,
  input is_ecall,
  input is_mret,
  input [DATA_WIDTH-1:0] pc,

  input [ADDR_WIDTH-1:0] raddr,
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

wire [DATA_WIDTH-1:0] csr_data;

always@(posedge clk) begin
  if (rst) mstatus <= 32'h1800;
  if(valid_wbu) begin
    if(is_ecall) begin
      mepc <= pc;
      mcause  <= 32'hb;
    end
    if(wen) begin
      case(waddr)
        12'h300: mstatus <= wdata; 
        12'h305: mtvec <= wdata; 
        12'h341: mepc <= wdata; 
        12'h342: mcause <= wdata;
        default: ;
      endcase
    end
  end
end


MuxKeyWithDefault #(4, 12, 32) csr_data_Mux(csr_data, raddr, 32'b0, {
  {12'h300} , mstatus,
  {12'h305} , mtvec ,
  {12'h341} , mepc ,
  {12'h342} , mcause 
});

wire [2:0] select;
assign select = {1'b0, is_ecall, is_mret};

MuxKeyWithDefault #(2, 3, 32) data_Mux(data, select, csr_data, {
  {3'b010}, mtvec,
  {3'b001}, mepc
});


endmodule
