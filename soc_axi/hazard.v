`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/21 21:30:02
// Design Name: 
// Module Name: hazard
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


module hazard(
    input i_stall,d_stall,
    input wire[4:0] rsE,rtE,writeregM,writeregW,writeregfinalE,rsD,rtD,
    input wire regwriteM,regwriteW,memtoregE,memtoregM,regwriteE,judgeM,divD,jumpD,jumptoregD,hiloweM,
    input wire[5:0] labelD,labelE,
    input wire divstartE,divdoneE,
    input wire cp0readE,cp0writeM,
    input wire[4:0] cp0addrE,cp0addrM,
    input wire[31:0] excepttypefinalM,
    output wire forwardAD,forwardBD,
    output wire[1:0] forwardAE,forwardBE,
    output wire hiforwardE,loforwardE,cp0forwardE,
    output wire stallF,stallD,stallE,stallM,stallW,flushF,flushD,flushE,flushM,flushW,all_stall
    );

    assign forwardAE=((rsE!=5'b0)&&(rsE==writeregM)&&regwriteM)?2'b10:
                    ((rsE!=5'b0)&&(rsE==writeregW)&&regwriteW)?2'b01:2'b00;
    assign forwardBE=((rtE!=5'b0)&&(rtE==writeregM)&&regwriteM)?2'b10:
                    ((rtE!=5'b0)&&(rtE==writeregW)&&regwriteW)?2'b01:2'b00;
    assign forwardAD=(rsD!=0)&(rsD==writeregM)&regwriteM;
    assign forwardBD=(rtD!=0)&(rtD==writeregM)&regwriteM;
    assign hiforwardE=(labelE==6'b101001)&hiloweM;
    assign loforwardE=(labelE==6'b101010)&hiloweM;
    assign cp0forwardE=cp0readE&cp0writeM&(cp0addrE==cp0addrM);
    
    wire lwstall;
    wire divstall;  //除法器还在计算
    wire jumpstall;  //寄存器值还在写入中
    wire exceptflush;  //异常处理需清空流水线

    assign lwstall=((rsD==writeregfinalE)|(rtD==writeregfinalE))&memtoregE;
    assign jumpstall=jumpD&jumptoregD&((regwriteE&(writeregfinalE==rsD))|(memtoregM&(writeregM==rsD)));
    assign divstall=divstartE&(~divdoneE)&(excepttypefinalM==32'h0);

    assign exceptflush=(excepttypefinalM!=32'h0);

    assign all_stall = i_stall | d_stall;
    assign stallF=(all_stall|lwstall|jumpstall|divstall)&(excepttypefinalM==32'h0);
    assign stallD=all_stall|lwstall|jumpstall|divstall;
    assign stallE=divstall|all_stall;
    assign stallM=all_stall;
    assign stallW=all_stall;  

    assign flushF=1'b0;
    assign flushD=(judgeM & ~all_stall)|exceptflush;
    assign flushE=(((judgeM&divstall==1'b0)|lwstall|jumpstall)&~all_stall)|exceptflush;
    assign flushM=exceptflush|(divstall& ~all_stall);
    assign flushW=exceptflush;
    
endmodule