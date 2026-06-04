`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: ROM
// Description: 指令存储器 (只读存储器)
//              从 inst.txt 文件加载指令，按字节编址，大端序
// Size: 512 字节
//////////////////////////////////////////////////////////////////////////////////

module ROM(
    input             IsRd,      // 读使能
    input      [31:0] addr,      // 读地址
    output reg [31:0] DataOut    // 读出的 32 位指令
);

    reg [7:0] rom [511:0];  // 512 字节存储空间

    // 从文件加载指令 (使用相对路径)
    initial begin
        $readmemh("inst.txt", rom);
    end

    // 读操作 (大端序)
    always @(*) begin
        if (IsRd)
            DataOut = {rom[addr], rom[addr+1], rom[addr+2], rom[addr+3]};
        else
            DataOut = 32'bz;
    end

endmodule
