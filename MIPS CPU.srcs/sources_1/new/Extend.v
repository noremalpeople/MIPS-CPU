`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: Extend
// Description: 立即数扩展模块
//              将 16 位立即数扩展为 32 位
// ExtType:
//   0 - 零扩展 (Zero Extension)
//   1 - 符号扩展 (Sign Extension)
//////////////////////////////////////////////////////////////////////////////////

module Extend(
    input      [15:0] imm16,    // 16 位立即数
    input             ExtType,  // 扩展类型
    output     [31:0] imm32     // 32 位扩展结果
);

    assign imm32 = (ExtType && imm16[15]) ?
                   {16'hFFFF, imm16} :    // 符号扩展
                   {16'h0000, imm16};     // 零扩展

endmodule
