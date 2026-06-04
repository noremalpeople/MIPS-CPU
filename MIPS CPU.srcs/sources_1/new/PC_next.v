`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: PC_next
// Description: 下一 PC 值计算模块
//              根据 PCSource 选择下一 PC 的来源
// PCSource:
//   00 - PC + 4 (顺序执行)
//   01 - PC + 4 + offset (条件分支)
//   10 - rs (寄存器跳转 JR)
//   11 - {PC+4[31:28], addr, 00} (无条件跳转 J/JAL)
//////////////////////////////////////////////////////////////////////////////////

module PC_next(
    input             rst,
    input      [31:0] cur_PC,     // 当前 PC
    input      [1:0]  PCSource,   // PC 来源选择
    input      [31:0] imm16,      // 扩展后的分支偏移量
    input      [31:0] rs,         // 寄存器 rs 的值 (用于 JR)
    input      [25:0] addr,       // 跳转地址 (用于 J/JAL)
    output reg [31:0] next_PC     // 计算出的下一 PC 值
);

    wire [31:0] PC_plus4;
    assign PC_plus4 = cur_PC + 4;

    always @(*) begin
        if (rst)
            next_PC = 32'd0;
        else begin
            case (PCSource)
                2'b00: next_PC = PC_plus4;                          // 顺序执行
                2'b01: next_PC = PC_plus4 + {imm16[29:0], 2'b00};  // 分支跳转
                2'b10: next_PC = rs;                                // 寄存器跳转
                2'b11: next_PC = {PC_plus4[31:28], addr, 2'b00};   // 直接跳转
                default: next_PC = PC_plus4;
            endcase
        end
    end

endmodule
