module fsm_best_practice (
    input wire clk,
    input wire rst,
    input wire some_input,
    output reg some_output
);

// ========== 1. 状态定义与状态寄存器 ==========
// 使用独热码(one-hot)或二进制码(binary)，用parameter定义状态名
localparam [1:0] S_IDLE = 2'b00,
                 S_START = 2'b01,
                 S_WORK = 2'b10,
                 S_DONE = 2'b11;

reg [1:0] current_state, next_state; // 状态寄存器

// 时序逻辑部分：只在时钟沿更新状态
always @(posedge clk) begin
    if (rst) begin
        current_state <= S_IDLE; // 明确的复位状态
    end else begin
        current_state <= next_state; // 状态转移
    end
end

// ========== 2. 次态逻辑（组合逻辑） ==========
always @(*) begin
    // 默认值：防止生成锁存器，并指定一个安全状态（通常是保持）
    next_state = current_state;
    
    case (current_state)
        S_IDLE: begin
            if (some_input == 1'b1) begin
                next_state = S_START;
            end
        end
        S_START: begin
            next_state = S_WORK; // 无条件转移
        end
        S_WORK: begin
            if (some_input == 1'b0) begin
                next_state = S_DONE;
            end
        end
        S_DONE: begin
            next_state = S_IDLE;
        end
        // 良好的习惯：即使认为不可能，也加上default分支
        default: begin
            next_state = S_IDLE; // 异常时恢复到安全状态
        end
    endcase
end

// ========== 3. 输出逻辑 ==========
// 建议1：摩尔型输出（输出仅取决于当前状态）
always @(*) begin
    some_output = 1'b0; // 默认输出值
    case (current_state)
        S_WORK: some_output = 1'b1;
        S_DONE: some_output = 1'b1;
        // 其他状态默认输出0
    endcase
end


endmodule
