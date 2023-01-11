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
    input wire i_stall,d_stall,
    input wire[4:0] rsE,rtE,writeregM,writeregW,writeregfinalE,rsD,rtD,
    input wire regwriteM,regwriteW,memtoregE,memtoregM,regwriteE,judgeM,hiloweE,jumpD,jumptoregD,
    input wire[5:0] labelD,
    input wire divstartE,divdoneE,
    input wire cp0readE,cp0writeM,
    input wire [4:0] cp0addrE,cp0addrM,
    output wire[1:0] forwardAE,forwardBE,
    output wire stallF,stallD,stallE,stallM,stallW,flushD,flushE,
    output wire all_stall
    );

    assign forwardAE=((rsE!=5'b0)&&(rsE==writeregM)&&regwriteM)?2'b10:
                    ((rsE!=5'b0)&&(rsE==writeregW)&&regwriteW)?2'b01:2'b00;
    assign forwardBE=((rtE!=5'b0)&&(rtE==writeregM)&&regwriteM)?2'b10:
                    ((rtE!=5'b0)&&(rtE==writeregW)&&regwriteW)?2'b01:2'b00;
    
    wire lwstall;
    //wire hilostall;  //HILO还在写入数值中
    wire divstall;  //等待除法器完成
    wire jumpstall;  //寄存器值还在写入中
    wire cp0stall;  //cp0寄存器值还在写入

    //assign branchstall=branchD&regwriteE&((writeregE==rsD)|(writeregE==rtD));
    assign lwstall=((rsD==writeregfinalE)|(rtD==writeregfinalE))&memtoregE;
    //assign hilostall=(labelD==6'b101001|labelD==6'b101010)&hiloweE;
    assign divstall=(divstartE==1'b1)&(divdoneE==1'b0);
    //D阶段不设置数据前推
    assign jumpstall=jumpD&jumptoregD&
    ((regwriteM&(writeregM==rsD))|(regwriteE&(writeregfinalE==rsD))|
    (memtoregM&(writeregM==rsD)));
    assign cp0stall=cp0readE&cp0writeM&(cp0addrE==cp0addrM);

    assign all_stall = i_stall | d_stall;
    assign stallF=lwstall|divstall|jumpstall|cp0stall|all_stall;
    assign stallD=lwstall|divstall|jumpstall|cp0stall|all_stall;
    assign stallE=divstall|all_stall;
    assign stallM = all_stall;
    assign stallW = all_stall;

    assign flushE=lwstall|judgeM;
    assign flushD=judgeM;
    
    
    // assign stallF = longest_stall | stall_ltypeD;
    // assign stallD = longest_stall | stall_ltypeD;
    // assign stallE = longest_stall;
    // assign stallM = longest_stall;
    // assign stallW = longest_stall;
endmodule
