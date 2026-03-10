// =========================================================================
// 模块名称: BPU (Branch Prediction Unit)
// 功能描述: 带有直接映射 BTB 和 2-bit 饱和计数器的分支预测器
// =========================================================================
module BPU #(
    parameter INDEX_WIDTH = 6,  // 索引位宽，6 bit 代表有 2^6 = 64 个表项
    parameter PC_WIDTH    = 32  // PC 位宽
)(
    input  wire clk,
    input  wire rst,

    // ==========================================
    // 1. IFU 预测端口 (读端口 - 纯组合逻辑)
    // ==========================================
    input  wire [PC_WIDTH-1:0] fetch_pc,       // 当前 IFU 正在取指的 PC
    output wire                predict_taken,  // 预测结果：1 为跳，0 为不跳
    output wire [PC_WIDTH-1:0] predict_target, // 预测的跳转目标地址

    // ==========================================
    // 2. EXU 更新端口 (写端口 - 时序逻辑)
    // ==========================================
    input  wire                update_en,      // EXU 确认这是一条分支/跳转指令
    input  wire [PC_WIDTH-1:0] update_pc,      // 该指令自身的 PC
    input  wire                update_taken,   // 真实结果：实际跳了吗？
    input  wire [PC_WIDTH-1:0] update_target   // 真实结果：实际跳去哪了？
);

// ========== 内部参数与结构定义 ==========
localparam ENTRY_NUM = 1 << INDEX_WIDTH;                    // 64 项
// Tag 位宽 = 总位宽 - Index位宽 - 低两位(对齐位)
localparam TAG_WIDTH = PC_WIDTH - INDEX_WIDTH - 2;          

// 2-bit 饱和计数器状态定义
localparam [1:0] SNT = 2'b00,  // Strongly Not Taken (强烈不跳)
                 WNT = 2'b01,  // Weakly Not Taken   (微弱不跳)
                 WT  = 2'b10,  // Weakly Taken       (微弱跳转)
                 ST  = 2'b11;  // Strongly Taken     (强烈跳转)

// BPU 表项数组 (BTB + BHT 融合)
reg                 valid_array   [0:ENTRY_NUM-1]; // 有效位
reg [TAG_WIDTH-1:0] tag_array     [0:ENTRY_NUM-1]; // 标签，用于校验是否是同一条指令
reg [1:0]           counter_array [0:ENTRY_NUM-1]; // 2-bit 饱和计数器
reg [PC_WIDTH-1:0]  target_array  [0:ENTRY_NUM-1]; // 预测的目标 PC


// ========== 1. 预测逻辑 (0 周期延迟的组合逻辑) ==========
// 截取取指 PC 的各个字段
wire [INDEX_WIDTH-1:0] fetch_idx = fetch_pc[INDEX_WIDTH+1 : 2];
wire [TAG_WIDTH-1:0]   fetch_tag = fetch_pc[PC_WIDTH-1 : INDEX_WIDTH+2];

// 判断是否命中 (有效且 Tag 匹配)
wire fetch_hit = valid_array[fetch_idx] && (tag_array[fetch_idx] == fetch_tag);

// 预测方向：如果命中，且计数器高位为 1 (即 WT(10) 或 ST(11))，则预测跳转
assign predict_taken  = fetch_hit && counter_array[fetch_idx][1];
// 预测目标：直接透传表里的目标地址
assign predict_target = target_array[fetch_idx];


// ========== 2. 更新逻辑 (时序逻辑) ==========
// 截取更新 PC 的各个字段
wire [INDEX_WIDTH-1:0] update_idx = update_pc[INDEX_WIDTH+1 : 2];
wire [TAG_WIDTH-1:0]   update_tag = update_pc[PC_WIDTH-1 : INDEX_WIDTH+2];

integer i;
always @(posedge clk) begin
    if (rst) begin
        // 复位时只需清空所有有效位即可
        for (i = 0; i < ENTRY_NUM; i = i + 1) begin
            valid_array[i] <= 1'b0;
        end
    end 
    else if (update_en) begin
        // 更新有效位、Tag 和目标地址 (无论如何都要把最新正确的地址写进去)
        valid_array[update_idx]  <= 1'b1;
        tag_array[update_idx]    <= update_tag;
        target_array[update_idx] <= update_target;

        // 如果是“新面孔”（之前没存过，或者发生了 Hash 冲突覆盖了别的指令）
        if (!valid_array[update_idx] || tag_array[update_idx] != update_tag) begin
            // 第一次见面，根据实际结果赋初值 (直接进入微弱状态，给下次留余地)
            counter_array[update_idx] <= update_taken ? WT : WNT;
        end 
        else begin
            // 是“老熟人”（Tag 匹配），根据 2-bit 状态机规则进行更新
            case (counter_array[update_idx])
                SNT (2'b00): counter_array[update_idx] <= update_taken ? WNT : SNT; // 00 -> 跳-> 01, 不跳-> 00
                WNT (2'b01): counter_array[update_idx] <= update_taken ? WT  : SNT; // 01 -> 跳-> 10, 不跳-> 00
                WT  (2'b10): counter_array[update_idx] <= update_taken ? ST  : WNT; // 10 -> 跳-> 11, 不跳-> 01
                ST  (2'b11): counter_array[update_idx] <= update_taken ? ST  : WT;  // 11 -> 跳-> 11, 不跳-> 10
            endcase
        end
    end
end

endmodule
