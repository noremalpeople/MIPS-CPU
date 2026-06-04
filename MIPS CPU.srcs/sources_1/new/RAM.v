`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: RAM
// Description: 数据存储器 (随机存取存储器)
//              支持读写操作，按字节编址
// Size: 128 字节
//////////////////////////////////////////////////////////////////////////////////

module RAM(
    input             MemRd,      // 读使能
    input             MemWr,      // 写使能
    input      [31:0] addr,       // 地址
    input      [31:0] data_in,    // 写入数据
    output reg [31:0] data_out,   // 读出数据
    input             DBDataSrc,  // 数据总线来源选择
    output reg [31:0] DB          // 数据总线输出
);

    reg [7:0] ram [127:0];  // 128 字节存储空间

    // 初始化 RAM 为 0
    integer i;
    initial begin
        for (i = 0; i < 128; i = i + 1)
            ram[i] = 8'd0;
    end

    // 读操作
    always @(*) begin
        if (MemRd)
            data_out = {ram[addr+3], ram[addr+2], ram[addr+1], ram[addr]};
        else
            data_out = 32'bz;
        // 数据总线选择
        DB = (DBDataSrc == 1'b1) ? data_out : addr;
    end

    // 写操作
    always @(*) begin
        if (MemWr)
            {ram[addr+3], ram[addr+2], ram[addr+1], ram[addr]} = data_in;
    end

endmodule
