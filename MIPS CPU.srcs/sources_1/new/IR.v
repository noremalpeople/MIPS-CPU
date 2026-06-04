`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: IR
// Description: 指令寄存器 (Instruction Register)
//              在时钟下降沿，当 IRWr 为高时锁存新指令
//////////////////////////////////////////////////////////////////////////////////

module IR(
    input             clk,         // 时钟
    input             IRWr,        // 写使能
    input      [31:0] next_inst,   // 新指令输入
    output reg [31:0] cur_inst     // 当前锁存的指令
);

    always @(negedge clk) begin
        if (IRWr)
            cur_inst <= next_inst;
    end

endmodule
