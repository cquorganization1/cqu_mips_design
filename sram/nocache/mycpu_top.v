`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/08 21:13:10
// Design Name: 
// Module Name: mycpu_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mycpu_top(
    input clk,
    input resetn,  //low active
    input [5:0] ext_int,

    //cpu inst sram
    output        inst_sram_en   ,
    output [3 :0] inst_sram_wen  ,
    output [31:0] inst_sram_addr ,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata,
    //cpu data sram
    output        data_sram_en   ,
    output [3 :0] data_sram_wen  ,
    output [31:0] data_sram_addr ,
    output [31:0] data_sram_wdata,
    input  [31:0] data_sram_rdata,
    //debug
    output [31:0] debug_wb_pc,      
    output [3:0]  debug_wb_rf_wen,  
    output [4:0]  debug_wb_rf_wnum, 
    output [31:0] debug_wb_rf_wdata
    );

    wire [31:0] pc;
	wire [31:0] instr;
	wire [3:0] memwrite;
	wire [31:0] aluout, writedata, readdata;
    wire[31:0] db_pc,db_result;
    wire db_regwrite;
    wire [4:0] db_writereg;
    mips mips(
        .clk(~clk),
        .rst(~resetn),
        //instr
        // .inst_en(inst_en),
        .pcfinalF(pc),                    //pcF
        .instrF(instr),              //instrF
        //data
        // .data_en(data_en),
        .memwritefinalM(memwrite),
        .aluoutaddrM(aluout),
        .writedatafinalM(writedata),
        .readdataM(readdata),
        .pcW(db_pc),
        .regwriteW(db_regwrite),
        .writeregW(db_writereg),
        .resultW(db_result),
        .ext_int(ext_int)
    );

    assign inst_sram_en = 1'b1;     //如果有inst_en，就用inst_en
    assign inst_sram_wen = 4'b0;
    assign inst_sram_addr = pc;
    assign inst_sram_wdata = 32'b0;
    assign instr = inst_sram_rdata;

    assign data_sram_en = 1'b1;     //如果有data_en，就用data_en
    assign data_sram_wen = memwrite;
    assign data_sram_addr = aluout;
    assign data_sram_wdata = writedata;
    assign readdata = data_sram_rdata;

    assign debug_wb_pc=db_pc;
    assign debug_wb_rf_wen={4{db_regwrite}};
    assign debug_wb_rf_wnum=db_writereg;
    assign debug_wb_rf_wdata=db_result;
endmodule
