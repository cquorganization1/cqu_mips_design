`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 10:58:03
// Design Name: 
// Module Name: mips
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


module mips(
	input wire clk,rst,
	input wire[5:0] ext_int,

	// //inst
    // output wire [31:0] pcF,
    // // output wire [31:0] pc_next,
    // output wire inst_enF,
    // input wire [31:0] instrF,
    // input wire i_stall,
    // // output wire stallF,

	//inst
	output wire[31:0] pcfinalF,
	output wire inst_enF,//1.缺失使能信号
	input wire[31:0] instrF,
	input wire i_stall,//2.缺失暂停信号

	//data
    // output wire mem_enM,                    
    // output wire [31:0] mem_addrM,   //读/写地址
    // input wire [31:0] mem_rdataM,   //读数据
    // output wire [3:0] mem_wenM,     //写使能
    // output wire [31:0] mem_wdataM,  //写数据
    // input wire d_stall,
    // // output wire [31:0] mem_addrE,
    // // output wire mem_read_enE,
    // // output wire mem_write_enE,
    // // output wire stallM,

    // output wire longest_stall,

	//data
	output wire mem_enM,//1.缺失存储器读写使能
	output wire[31:0] aluoutfinalM ,   //读/写地址
	input wire[31:0] readdataM,       //读数据
	output wire[3:0] memwritefinalM,  //写使能
	output wire[31:0] writedatafinalM,//写数据
	input wire d_stall,   //2.缺失存储器暂停信号
	output wire all_stall,

	//debug
	output wire [31:0]  debug_wb_pc,      
    output wire [3:0]   debug_wb_rf_wen,
    output wire [4:0]   debug_wb_rf_wnum, 
    output wire [31:0]  debug_wb_rf_wdata
    );
	
	// inst和data部分信号赋值
	assign inst_enF = 1'b1;
	assign mem_enM = 1'b1;
	
	//debug信号赋值
	assign debug_wb_pc = pcW;
	assign debug_wb_rf_wen = {4{regwriteW & ~stallW}};
	assign debug_wb_rf_wnum = writeregW;
	assign debug_wb_rf_wdata = resultW;


	//F阶段变量
	wire stallF;
	wire [31:0] pcF,pcplus4F,pc_preF,pc_inF,pc_rightF,pc_memoryF;
	wire isindelayslotF;

	//D阶段变量
	wire [31:0] pcplus4D,instrD,pcD;
	wire [31:0] pcjumpD,pcjumptempD,pcbranchD,pcjumpfinalD;
	wire [4:0] rsD,rtD,rdD,saD;
	wire flushD,stallD,pred_takeD; 
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srcbD;
	wire regwriteD,alusrcD,regdstD,branchD,jumpD,jumptoregD,unsignD;
	wire [3:0] memwriteD,memtoregD;
	wire [5:0] labelD;
	wire [31:0] hi_oD,lo_oD;
	wire isindelayslotD,cp0writeD,cp0readD;
	wire [4:0] cp0addrD;
	wire [31:0] excepttypeD,badaddriD,excepttypefinalD;
	
	//E阶段变量
	wire [1:0] forwardaE,forwardbE;
	wire [4:0] rsE,rtE,rdE,saE;
	wire [4:0] writeregE,writeregfinalE;
	wire [31:0] signimmE,pcE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] pcplus4E,pcbranchE;
	wire [31:0] aluoutE;
	wire regwriteE,alusrcE,regdstE,branchE,needbranchE,pred_takeE,overflowE;
	wire flushE,stallE;
	wire [3:0] memwriteE,memtoregE;
	wire [5:0] labelE;
	wire hiloweE,reg31writeE,divsignedE,divstartE,divdoneE;
	wire [31:0] hi_iE,lo_iE,hi_oE,lo_oE;
	wire [63:0] divresE;
	wire [1:0] lbshiftE;
	wire isindelayslotE,cp0writeE,cp0readE;
	wire [4:0] cp0addrE;
	wire [31:0] readcp0dataE;
	wire [31:0] excepttypeE,excepttypefinalE,badaddriE;

	//M阶段变量
	wire regwriteM,judgeM,needbranchM,branchM,pred_takeM;
	wire [4:0] writeregM;
	wire [31:0] readdatafinalM,writedataM,pcM,pcplus4M,pcbranchM,aluoutM;
	wire [5:0] labelM;
	wire [3:0] memtoregM,memwriteM;
	wire [1:0] lbshiftM;
	wire isindelayslotM,cp0writeM;
	wire [4:0] cp0addrM;
	wire [31:0] excepttypeM,badaddriM,badaddrifinalM,
				excepttypenextM,excepttypefinalM,dataaddrM;
	wire loadexceptM,storeexceptM;
	wire flushM,stallM;


	//W阶段变量
	wire [31:0] pcW,aluoutW,readdataW;
	wire [3:0] memtoregW;
	wire flushW,stallW,regwriteW;
	wire [4:0]  writeregW; 
	wire [31:0]  resultW;

	//译码模块（部分译码在ALU模块）
	decoder decoder(
		instrD,
		memwriteD,memtoregD,branchD,alusrcD,regdstD,regwriteD,jumpD,jumptoregD,
		labelD,
		isindelayslotF,cp0writeD,cp0readE,
		excepttypeD
	);

	//冒险模块
	hazard hazard(
		i_stall,d_stall,
		rsE,rtE,writeregM,writeregW,writeregfinalE,rsD,rtD,
		regwriteM,regwriteW,memtoregE[0],memtoregM[0],regwriteE,judgeM,hiloweE,jumpD,jumptoregD,
		labelD,
		divstartE,divdoneE,
		cp0readE,cp0writeM,cp0addrE,cp0addrM,
		forwardaE,forwardbE,
		stallF,stallD,stallE,stallM,stallW,flushD,flushE,
		all_stall
	);

	//分支预测模块
	branch_predict_compete branch_predict_compete(
		clk,rst,
		flushD,stallD,
		pcF,pcM,
		branchM,needbranchM,
		branchD,pred_takeD
	);

	//CP0寄存器  E阶段读 M阶段写
	cp0_reg cp0_reg(
		clk,rst,
		cp0writeM,cp0addrM,cp0addrE,writedataM,
		ext_int,
		excepttypefinalM,pcM,isindelayslotM,badaddrifinalM,
		readcp0dataE
	);

	//mmu
	mmu mmu(
		pcF,pcfinalF,
		aluoutM,aluoutfinalM
	);

	//F阶段连线
	mux2#(32) mux2F1(pcplus4F,pcbranchD,pred_takeD,pc_preF);
	mux2#(32) mux2F2(pc_preF,pcjumpfinalD,jumpD,pc_inF);
	mux2#(32) mux2F3(pc_inF,pc_memoryF,judgeM,pc_rightF);
	pc pc(clk,rst,~stallF,pc_rightF,pcF);
	adder adder1(pcF,32'h4,pcplus4F);

	//FD
	flopenrc #(32) r1D(clk,rst,~stallD,flushD,pcplus4F,pcplus4D);
	flopenrc #(32) r2D(clk,rst,~stallD,flushD,instrF,instrD);
	flopenrc #(1) r3D(clk,rst,~stallD,flushD,isindelayslotF,isindelayslotD);
	flopenrc #(32) r4D(clk,rst,~stallD,flushD,pcF,pcD);

	//D阶段连线
	regfile regfile(clk,rst,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);
	hilo_reg hilo_reg(clk,rst,hiloweE,hi_iE,lo_iE,hi_oD,lo_oD);

	assign unsignD=instrD[29]&instrD[28];  //无符号扩展的指令op:0011xx
	dataext dataext(instrD[15:0],unsignD,signimmD);
	sl2 immsh(signimmD,signimmshD);
	sl2 jumpsh(.a({{6{1'b0}},instrD[25:0]}),.y(pcjumptempD));
	adder adder2(pcplus4D,signimmshD,pcbranchD);

	
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign saD = instrD[10:6];
	assign pcjumpD={pcplus4D[31:28],pcjumptempD[27:0]};

	assign jumptoregD=~instrD[27];
	mux2#(32) jumpmuxD(pcjumpD,srcaD,jumptoregD,pcjumpfinalD);  //是否跳转到寄存器的值

	assign cp0addrD = instrD[15:11];

	//取值异常
	mux2#(32) muxD1(excepttypeD,32'h00000004,pcD[1]|pcD[0],excepttypefinalD);
	mux2#(32) muxD2(32'b0,pcD,pcD[1]|pcD[0],badaddriD);

	//DE
	flopenrc #(32) r1E(clk,rst,~stallE,flushE,srcaD,srcaE);
	flopenrc #(32) r2E(clk,rst,~stallE,flushE,srcbD,srcbE);
	flopenrc #(32) r3E(clk,rst,~stallE,flushE,signimmD,signimmE);
	flopenrc #(5) r4E(clk,rst,~stallE,flushE,rsD,rsE);
	flopenrc #(5) r5E(clk,rst,~stallE,flushE,rtD,rtE);
	flopenrc #(5) r6E(clk,rst,~stallE,flushE,rdD,rdE);
	flopenrc #(5) r7E(clk,rst,~stallE,flushE,saD,saE);
	flopenrc #(32) r8E(clk,rst,~stallE,flushE,pcplus4D,pcplus4E);
	flopenrc #(1) r9E(clk,rst,~stallE,flushE,pred_takeD,pred_takeE);
	flopenrc #(1) r10E(clk,rst,~stallE,flushE,regwriteD,regwriteE);
	flopenrc #(4) r11E(clk,rst,~stallE,flushE,memtoregD,memtoregE);
	flopenrc #(4) r12E(clk,rst,~stallE,flushE,memwriteD,memwriteE);
	flopenrc #(6) r13E(clk,rst,~stallE,flushE,labelD,labelE);
	flopenrc #(1) r14E(clk,rst,~stallE,flushE,alusrcD,alusrcE);
	flopenrc #(1) r15E(clk,rst,~stallE,flushE,regdstD,regdstE);
	flopenrc #(1) r16E(clk,rst,~stallE,flushE,branchD,branchE);
	flopenrc #(32) r17E(clk,rst,~stallE,flushE,hi_oD,hi_oE);
	flopenrc #(32) r18E(clk,rst,~stallE,flushE,lo_oD,lo_oE);
	flopenrc #(32) r19E(clk,rst,~stallE,flushE,pcbranchD,pcbranchE);
	flopenrc #(1) r20E(clk,rst,~stallE,flushE,isindelayslotD,isindelayslotE);
	flopenrc #(5) r21E(clk,rst,~stallE,flushE,cp0addrD,cp0addrE);
	flopenrc #(1) r22E(clk,rst,~stallE,flushE,cp0writeD,cp0writeE);
	flopenrc #(1) r23E(clk,rst,~stallE,flushE,cp0readD,cp0readE);
	flopenrc #(32) r24E(clk,rst,~stallE,flushE,excepttypefinalD,excepttypeE);
	flopenrc #(32) r25E(clk,rst,~stallE,flushE,badaddriD,badaddriE);
	flopenrc #(32) r26E(clk,rst,~stallE,flushE,pcD,pcE);

	//E阶段连线
	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E);
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);
	mux2 #(5) wrmux(rtE,rdE,regdstE,writeregE);
	mux2 #(5) mux2E2(writeregE,5'b11111,reg31writeE,writeregfinalE);  //是否写入31号寄存器
	mux2 #(32) mux2E3(excepttypeE,32'h0000000c,overflowE,excepttypefinalE);  //溢出异常

	div div(
		clk,rst,
		divsignedE,
		srca2E,srcb3E,
		divstartE,1'b0,
		divresE,divdoneE
	);

	ALU ALU(
		srca2E,srcb3E,saE,pcplus4E,
		hi_oE,lo_oE,divresE,
		labelE,
		readcp0dataE,
		aluoutE,
		hi_iE,lo_iE,
		needbranchE,hiloweE,divsignedE,divstartE,reg31writeE,
		lbshiftE,
		overflowE
	);

	assign flushM = 1'b0;
	//EM
	flopenrc #(32) r1M(clk,rst,~stallM,flushM,srcb2E,writedataM);
	flopenrc #(32) r2M(clk,rst,~stallM,flushM,aluoutE,aluoutM);
	flopenrc #(5) r3M(clk,rst,~stallM,flushM,writeregfinalE,writeregM);
	flopenrc #(6) r4M(clk,rst,~stallM,flushM,labelE,labelM);
	flopenrc #(32) r5M(clk,rst,~stallM,flushM,pcplus4E,pcplus4M);
	flopenrc #(1) r6M(clk,rst,~stallM,flushM,regwriteE,regwriteM);
	flopenrc #(4) r7M(clk,rst,~stallM,flushM,memtoregE,memtoregM);
	flopenrc #(4) r8M(clk,rst,~stallM,flushM,memwriteE,memwriteM);
	flopenrc #(1) r9M(clk,rst,~stallM,flushM,branchE,branchM);
	flopenrc #(1) r10M(clk,rst,~stallM,flushM,pred_takeE,pred_takeM);
	flopenrc #(1) r11M(clk,rst,~stallM,flushM,needbranchE,needbranchM);
	flopenrc #(32) r12M(clk,rst,~stallM,flushM,pcbranchE,pcbranchM);
	flopenrc #(2) r13M(clk,rst,~stallM,flushM,lbshiftE,lbshiftM);
	flopenrc #(1) r14M(clk,rst,~stallM,flushM,isindelayslotE,isindelayslotM);
	flopenrc #(5) r15M(clk,rst,~stallM,flushM,cp0addrE,cp0addrM);
	flopenrc #(1) r16M(clk,rst,~stallM,flushM,cp0writeE,cp0writeM);
	flopenrc #(32) r17M(clk,rst,~stallM,flushM,excepttypefinalE,excepttypeM);
	flopenrc #(32) r18M(clk,rst,~stallM,flushM,badaddriE,badaddriM);
	flopenrc #(32) r19M(clk,rst,~stallM,flushM,pcE,pcM);

	
	//M阶段连线
	mux2#(32) mux2M1(pcplus4M+32'h4,pcbranchM,(needbranchM&branchM),pc_memoryF);
	load load(readdataM,memtoregM,lbshiftM,readdatafinalM);
	save save(writedataM,memwriteM,lbshiftM,writedatafinalM,memwritefinalM);
	assign judgeM = branchM&(needbranchM^pred_takeM); //1:不同，代表预测错误
	assign dataaddrM=aluoutM|lbshiftM;  //原始数据地址（可能触发异常）
	assign loadexceptM=(((memtoregM==4'b1011|memtoregM==4'b0011)&(lbshiftM==2'b01|lbshiftM==2'b11))
						|(memtoregM==4'b1111&lbshiftM!=2'b00));
	assign storeexceptM=((memwriteM==4'b0011&(lbshiftM==2'b01|lbshiftM==2'b11))
						|(memwriteM==4'b1111&lbshiftM!=2'b00));
	
	mux2#(32) mux2M2(badaddriM,dataaddrM,loadexceptM|storeexceptM,badaddrifinalM);  //数据地址是否错误
	mux2#(32) mux2M3(excepttypeM,32'h00000004,loadexceptM,excepttypenextM);  //load异常
	mux2#(32) mux2M4(excepttypenextM,32'h00000005,storeexceptM,excepttypefinalM);  //store异常

	assign flushW = 1'b0;
	//MW
	flopenrc #(32) r1W(clk,rst,~stallW,flushM,aluoutM,aluoutW);
	flopenrc #(32) r2W(clk,rst,~stallW,flushM,readdatafinalM,readdataW);
	flopenrc #(5) r3W(clk,rst,~stallW,flushM,writeregM,writeregW);
	flopenrc #(1) r4W(clk,rst,~stallW,flushM,regwriteM,regwriteW);
	flopenrc #(4) r5W(clk,rst,~stallW,flushM,memtoregM,memtoregW);
	flopenrc #(32) r6W(clk,rst,~stallW,flushM,pcM,pcW);

	//W阶段连线
	mux2 #(32) resmux(aluoutW,readdataW,memtoregW[0],resultW);

	
endmodule
