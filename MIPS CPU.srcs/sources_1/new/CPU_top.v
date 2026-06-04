`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: CPU_top
// Description: N4 开发板顶层模块
//              将 MIPS CPU 适配到 N4 开发板，提供用户交互接口
// Board: N4 开发板 (Artix-7 xc7a100tcsg324-1)
//
// 功能说明:
//   - 时钟: 板载 100MHz 时钟，内部分频使用
//   - 复位: BTNU 按钮
//   - LED: 显示当前 PC 低 16 位
//   - 数码管: 显示寄存器值或 ALU 结果
//   - 开关: 选择显示内容
//   - 按钮: 控制 CPU 运行
//////////////////////////////////////////////////////////////////////////////////

module CPU_top(
    input         clk,          // 100MHz 时钟
    input         rst,          // 复位按钮 (BTNU)
    // LED 输出
    output [15:0] led,          // 16 个 LED 灯
    // 开关输入
    input  [15:0] sw,           // 16 个拨动开关
    // 按钮输入
    input         btnl,         // 左按钮
    input         btnc,         // 中按钮
    input         btnr,         // 右按钮
    input         btnd,         // 下按钮
    // 七段数码管输出
    output [6:0]  seg,          // 段选信号 (a-g)
    output        dp,           // 小数点
    output [7:0]  an            // 位选信号
);

    //=========================================
    // 时钟分频
    //=========================================
    reg [25:0] clk_div;
    reg cpu_clk;

    always @(posedge clk) begin
        if (rst) begin
            clk_div <= 0;
            cpu_clk <= 0;
        end else begin
            clk_div <= clk_div + 1;
            if (clk_div == 26'd49_999_999) begin  // 1Hz (1秒)
                cpu_clk <= ~cpu_clk;
                clk_div <= 0;
            end
        end
    end

    //=========================================
    // CPU 实例化
    //=========================================
    wire [31:0] curPC, nextPC, inst, IRinst;
    wire [5:0]  op, func;
    wire [4:0]  rs, rt, rd;
    wire [31:0] DB, dataDB;
    wire [31:0] A, dataA, B, dataB;
    wire [31:0] result, dataResult;
    wire [1:0]  PCSource, RegDst;
    wire        ZeroFlag, PCWr, IsRd;
    wire        RegWr, ALUSrcA, ALUSrcB;
    wire [3:0]  ALUop;
    wire        MemRd, MemWr, DBDataSrc, WrRegDSrc;
    wire [31:0] Rw, extend;
    wire [2:0]  cur_state;

    CPU_main cpu(
        .clk(cpu_clk),
        .rst(rst),
        .curPC(curPC),
        .nextPC(nextPC),
        .inst(inst),
        .IRinst(IRinst),
        .op(op),
        .func(func),
        .rs(rs),
        .rt(rt),
        .rd(rd),
        .DB(DB),
        .dataDB(dataDB),
        .A(A),
        .dataA(dataA),
        .B(B),
        .dataB(dataB),
        .result(result),
        .dataResult(dataResult),
        .PCSource(PCSource),
        .ZeroFlag(ZeroFlag),
        .PCWr(PCWr),
        .IsRd(IsRd),
        .RegDst(RegDst),
        .RegWr(RegWr),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ALUop(ALUop),
        .MemRd(MemRd),
        .MemWr(MemWr),
        .DBDataSrc(DBDataSrc),
        .WrRegDSrc(WrRegDSrc),
        .Rw(Rw),
        .extend(extend),
        .cur_state(cur_state)
    );

    //=========================================
    // LED 显示 - 当前 PC 低 16 位
    //=========================================
    assign led = curPC[15:0];

    //=========================================
    // 数码管显示 - 根据开关选择显示内容
    //=========================================
    reg [31:0] display_data;

    always @(*) begin
        case (sw[3:0])
            4'h0: display_data = curPC;       // 当前 PC
            4'h1: display_data = nextPC;      // 下一 PC
            4'h2: display_data = inst;        // 当前指令
            4'h3: display_data = IRinst;      // IR 中的指令
            4'h4: display_data = A;           // 寄存器 A
            4'h5: display_data = B;           // 寄存器 B
            4'h6: display_data = result;      // ALU 结果
            4'h7: display_data = DB;          // 数据总线
            4'h8: display_data = extend;      // 扩展后的立即数
            4'h9: display_data = {29'd0, cur_state};  // 状态机状态
            4'hA: display_data = {26'd0, op, func};   // 操作码和功能码
            4'hB: display_data = {27'd0, rs, rt, rd}; // 寄存器地址
            4'hC: display_data = {28'd0, ALUop, ZeroFlag, PCWr, RegWr}; // 控制信号
            default: display_data = curPC;
        endcase
    end

    //=========================================
    // 七段数码管扫描显示
    //=========================================
    reg [2:0] scan_cnt;
    reg [16:0] scan_div;

    always @(posedge clk) begin
        if (rst) begin
            scan_cnt <= 0;
            scan_div <= 0;
        end else begin
            scan_div <= scan_div + 1;
            if (scan_div == 17'd99_999) begin
                scan_cnt <= scan_cnt + 1;
                scan_div <= 0;
            end
        end
    end

    reg [3:0] hex_data;
    reg [7:0] an_reg;

    always @(*) begin
        case (scan_cnt)
            3'd0: begin hex_data = display_data[3:0];   an_reg = 8'b11111110; end
            3'd1: begin hex_data = display_data[7:4];   an_reg = 8'b11111101; end
            3'd2: begin hex_data = display_data[11:8];  an_reg = 8'b11111011; end
            3'd3: begin hex_data = display_data[15:12]; an_reg = 8'b11110111; end
            3'd4: begin hex_data = display_data[19:16]; an_reg = 8'b11101111; end
            3'd5: begin hex_data = display_data[23:20]; an_reg = 8'b11011111; end
            3'd6: begin hex_data = display_data[27:24]; an_reg = 8'b10111111; end
            3'd7: begin hex_data = display_data[31:28]; an_reg = 8'b01111111; end
            default: begin hex_data = 4'h0; an_reg = 8'b11111111; end
        endcase
    end

    assign an = an_reg;
    assign dp = 1'b1;  // 小数点默认关闭

    // 七段译码器
    reg [6:0] seg_reg;
    always @(*) begin
        case (hex_data)
            4'h0: seg_reg = 7'b1000000;
            4'h1: seg_reg = 7'b1111001;
            4'h2: seg_reg = 7'b0100100;
            4'h3: seg_reg = 7'b0110000;
            4'h4: seg_reg = 7'b0011001;
            4'h5: seg_reg = 7'b0010010;
            4'h6: seg_reg = 7'b0000010;
            4'h7: seg_reg = 7'b1111000;
            4'h8: seg_reg = 7'b0000000;
            4'h9: seg_reg = 7'b0010000;
            4'hA: seg_reg = 7'b0001000;
            4'hB: seg_reg = 7'b0000011;
            4'hC: seg_reg = 7'b1000110;
            4'hD: seg_reg = 7'b0100001;
            4'hE: seg_reg = 7'b0000110;
            4'hF: seg_reg = 7'b0001110;
            default: seg_reg = 7'b1111111;
        endcase
    end

    assign seg = seg_reg;

endmodule
