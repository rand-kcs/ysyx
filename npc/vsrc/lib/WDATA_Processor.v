// 极简版本 (Advanced)
module WDATA_Processor (
    input  wire [31:0] wdata_origin,
    input  wire [2:0]  func3,
    input  wire [1:0]  addr_offset,
    output reg  [31:0] wdata,
    output reg  [3:0]  wstrb
);

    always @(*) begin
        wdata = 32'b0;
        wstrb = 4'b0;
        
        case (func3)
            3'b000: begin // SB
                wdata = {24'b0, wdata_origin[7:0]} << (addr_offset * 8);
                wstrb = 4'b0001 << addr_offset;
            end
            3'b001: begin // SH
                wdata = {16'b0, wdata_origin[15:0]} << (addr_offset[1] * 16);
                wstrb = 4'b0011 << (addr_offset[1] * 2);
            end
            3'b010: begin // SW
                wdata = wdata_origin;
                wstrb = 4'b1111;
            end
            default: ; 
        endcase
    end
endmodule
