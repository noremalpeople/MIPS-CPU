`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: InstSplit
// Description: 指令字段分割模块
//              将 32 位指令分解为各个字段
// MIPS Instruction Formats:
//   R-type: [op(6)][rs(5)][rt(5)][rd(5)][sa(5)][func(6)]
//   I-type: [op(6)][rs(5)][rt(5)][imm(16)]
//   J-type: [op(6)][addr(26)]
//////////////////////////////////////////////////////////////////////////////////

module InstSplit(
    input      [31:0] inst,    // 32 位指令
    output     [5:0]  op,      // 操作码 [31:26]
    output     [4:0]  rs,      // 源寄存器 1 [25:21]
    output     [4:0]  rt,      // 源寄存器 2 [20:16]
    output     [4:0]  rd,      // 目的寄存器 [15:11]
    output     [4:0]  sa,      // 移位量 [10:6]
    output     [5:0]  func,    // 功能码 [5:0]
    output     [15:0] imm16,   // 16 位立即数 [15:0]
    output     [25:0] addr     // 26 位跳转地址 [25:0]
);

    assign op    = inst[31:26];
    assign rs    = inst[25:21];
    assign rt    = inst[20:16];
    assign rd    = inst[15:11];
    assign sa    = inst[10:6];
    assign func  = inst[5:0];
    assign imm16 = inst[15:0];
    assign addr  = inst[25:0];

endmodule
