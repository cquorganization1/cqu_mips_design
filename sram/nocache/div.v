`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/01/05 21:07:26
// Design Name: 
// Module Name: div
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


`include "define.vh"
module div(

input wire clk,
input wire rst,

input wire signed_div_i,//是否有符号除法 为1表示有符号除法
input wire[31:0] opdata1_i,//被除数
input wire[31:0] opdata2_i,//除数
input wire start_i,//是否开始除法运算
input wire annul_i,//是否取消除法运算，为1表示取消除法运算

output reg[63:0] result_o,//除法运算结果
output reg ready_o//除法运算结束
);
wire[32:0] div_temp;
reg[5:0] cnt;
reg[64:0] dividend;
reg[1:0] state;
reg[31:0] divisor;
reg[31:0] temp_op1;
reg[31:0] temp_op2;
/*dividend低32位保存的是被除数、中间结果，第k次迭代结束时dividend[k:0]保存的是当前得到的
中间结果，dividend[31:k+1]保存的是被除数中还没有参与运算的数据，dividend高32位是每次迭代
时的被减数，所以dividend[63:32]就是minuend,divisor就是除数n，此处进行的是minuend—n运算
结果保存在div_temp中*/
assign div_temp = {1'b0,dividend[63:32]} - {1'b0,divisor};//minuend-n
always @ (posedge clk) begin
	if(rst == `RstEnable) begin
		state <= `DivFree;
		ready_o <= `DivResultNotReady;//除法运算没有结束
		result_o <= {`ZeroWord,`ZeroWord};
	end else begin
		case(state)
			/**********************DivFree状态*************************
			分三种情况:
			(1)开始除法运算，但除数为0，那么进入DivByZero状态
			(2)开始除法运算，且除数不为0，那么进入DivOn状态，
			初始化cnt=0，如果是有符号除法，且被除数或者除数为负
			那么对被除数或者除数取补码。除数保存到divisor中，将
			被除数的最高位保存到dividend的第32位，准备进行第一次迭代
			(3)没有开始除法运算，保持ready_o为DivResultNotReady，保持
			result为0
			**********************************************************/
			`DivFree:begin
				if((start_i == `DivStart) && (annul_i == 1'b0)) begin
					if(opdata2_i == `ZeroWord) begin
						state <= `DivByZero;//除数为0
					end else begin //除数不为0的情况
						state <= `DivOn;//除数不为0 开始进行除法运算
						cnt <= 6'b000000;
						if(signed_div_i == 1'b1 && opdata1_i[31] == 1'b1) begin //有符号除法 被除数为负数
							temp_op1 = ~opdata1_i+1;//被除数取补码
						end else begin //有符号除法 被除数是正数
							temp_op1 = opdata1_i; //被除数不需要改动
						end
						if(signed_div_i == 1'b1 && opdata2_i[31] == 1'b1) begin //有符号除法  除数为负数
							temp_op2 = ~opdata2_i+1;
						end else begin //有符号除法 除数是正数
							temp_op2 = opdata2_i;
						end
						dividend <= {`ZeroWord,`ZeroWord};
						dividend[32:1] <= temp_op1;
						divisor <= temp_op2;//divisor保存除数
					end
				end else begin //没有开始除法运算
					ready_o <= `DivResultNotReady;
					result_o <= {`ZeroWord,`ZeroWord};
				end
			end
			/********************DivByZero状态***********************
			如果进入DivByZero状态，那么直接进入DivEnd状态，除法结束，
			且结果为0
			*********************************************************/
			`DivByZero:begin
				dividend <= {`ZeroWord,`ZeroWord};
				state <= `DivEnd;//状态转移到DivEnd
			end
			/*********************DivOn状态***************************
			分三种情况
			(1)如果输入信号annul_i为1，表示处理器取消除法运算，那么DIV
			模块直接回到DivFree状态
			(2)如果annul_i为0，且cnt不为32，那么表示试商法还没有结束，
			如果此时减法结果div_temp为负，那么此次迭代结果为0，如果减法
			结果div_temp为正，那么此次迭代结果为1，dividend的最低位保存
			每次的迭代结果。同时保持DivOn状态，cnt+1
			(3)如果annul_i为0，且cnt==32，表示试商法结束，如果是有符号
			除法，且被除数、除数一正一负，那么将试商法的结果取补码，得到
			最终的结果，此处的商、余数都要取补码。商保存在dividend的低32
			位，余数保存在dividend的高32位。同时进入DivEnd状态
			**********************************************************/
			`DivOn:begin
				if(annul_i == 1'b0) begin
					if(cnt != 6'b100000) begin
						if(div_temp[32] == 1'b1) begin
							/*如果div_temp[32]==1,表示(minuend-n)<0,将dividend
							向左移一位，这样就将被除数还没有参与运算的最高位加入到
							下一次迭代的被减数中，同时将0追加到中间结果*/
							dividend <= {dividend[63:0],1'b0};
						end else begin
							/*如果div_temp[32]==0,表示(minuend-n)>0,将减法的结果
							与被除数还没有参运算的最高位加入到下一次的迭代的被减
							数中，同时将1追加到中间结果*/
							dividend <= {div_temp[31:0],dividend[31:0],1'b1};
						end
						cnt <= cnt + 1;
					end else begin //试商法结束
						if((signed_div_i == 1'b1)&&((opdata1_i[31]^opdata2_i[31])==1'b1)) begin//有符号数除法 除数和被除数中有一个是负数
							dividend[31:0] <= (~dividend[31:0]+1);//取补码
						end
						if((signed_div_i == 1'b1)&&((opdata1_i[31]^dividend[64])==1'b1)) begin
							dividend[64:33] <= (~dividend[64:33]+1);
						end
						state <= `DivEnd;
						cnt <= 6'b000000;
					end
				end else begin
					state <= `DivFree;
				end
			end
			`DivEnd:begin
				result_o <= {dividend[64:33],dividend[31:0]};
				ready_o <= `DivResultReady;
				if(start_i == `DivStop)begin
					state <= `DivFree;
					ready_o <= `DivResultNotReady;
					result_o <= {`ZeroWord,`ZeroWord};
				end
			end
	endcase
	end
	end
endmodule
