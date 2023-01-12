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
	output wire[31:0] aluoutaddrM ,   //读/写地址
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
	assign debug_wb_pc = pcM;
	assign debug_wb_rf_wen = {4{regwriteM & ~stallW & ~excepttypefinalM}};
	assign debug_wb_rf_wnum = writeregM;
	assign debug_wb_rf_wdata = resultM;

	//F阶段变量
	wire stallF,flushF;
	wire [31:0] pcF,pcplus4F,pc_preF,pc_inF,pc_rightF,pc_memoryF,pc_finalF,exceptpcF;
	wire isindelayslotF;

	//D阶段变量
	wire [31:0] pcplus4D,instrD,pcD;
	wire [31:0] pcjumpD,pcjumptempD,pcbranchD,pcjumpfinalD;
	wire [4:0] rsD,rtD,rdD,saD;
	wire flushD,stallD,pred_takeD,forwardaD,forwardbD; 
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srcbD,srcafinalD,srcbfinalD;
	wire regwriteD,alusrcD,regdstD,branchD,jumpD,jumptoregD,unsignD;
	wire [3:0] memwriteD,memtoregD;
	wire [5:0] labelD;
	wire isindelayslotD,cp0writeD,cp0readD;
	wire [4:0] cp0addrD;
	wire [31:0] excepttypeD,badaddriD,excepttypefinalD;
	wire divsignedD,divstartD;
	
	//E阶段变量
	wire [1:0] forwardaE,forwardbE;
	wire [4:0] rsE,rtE,rdE,saE;
	wire [4:0] writeregE,writeregfinalE;
	wire [31:0] signimmE,pcE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] pcplus4E,pcbranchE;
	wire [31:0] aluoutE;
	wire regwriteE,alusrcE,regdstE,branchE,pred_takeE,overflowE,divsignedE,divstartE;
	wire flushE,stallE;
	wire [3:0] memwriteE,memtoregE;
	wire [5:0] labelE;
	wire hiloweE,reg31writeE;
	wire [31:0] hi_iE,lo_iE,hi_oE,lo_oE,hi_ofinalE,lo_ofinalE;
	wire [63:0] divresE;
	wire [1:0] lbshiftE;
	wire isindelayslotE,cp0writeE,cp0readE;
	wire [4:0] cp0addrE;
	wire [31:0] readcp0dataE,readcp0datafinalE,excepttypeE,excepttypefinalE,badaddriE,epcE,statusE,causeE;
	wire hiforwardE,loforwardE,cp0forwardE;

	//M阶段变量
	wire regwriteM,judgeM,needbranchM,branchM,pred_takeM,stallM,flushM;
	wire [4:0] writeregM;
	wire [31:0] readdatafinalM,writedataM,pcM,pcplus4M,pcbranchM,aluoutM,resultM;
	wire [31:0] hi_iM,lo_iM;
	wire [5:0] labelM;
	wire [3:0] memtoregM,memwriteM,memwritecheckM;
	wire [1:0] lbshiftM;
	wire isindelayslotM,cp0writeM,hiloweM;
	wire [4:0] cp0addrM,rsM,rtM;
	wire [31:0] excepttypeM,badaddriM,badaddrifinalM,
				excepttypenextM,excepttypenextnextM,excepttypefinalM,dataaddrM;
	wire loadexceptM,storeexceptM;
	wire [31:0] branchsrcaM,branchsrcbM;
	wire [31:0] epcM,statusM,causeM;

	//W阶段变量
	wire [31:0] aluoutW,readdataW,resultW;
	wire [3:0] memtoregW;
	wire stallW,flushW,regwriteW;
	wire[31:0] pcW;
	wire [4:0] writeregW;

	//译码模块（部分译码在E和M阶段）
	decoder decoder(
		instrD,
		memwriteD,memtoregD,branchD,alusrcD,regdstD,regwriteD,jumpD,jumptoregD,
		labelD,
		divstartD,
		isindelayslotF,cp0writeD,cp0readD,
		excepttypeD
	);

	//冒险模块
	hazard hazard(
		i_stall,d_stall,rsE,rtE,writeregM,writeregW,writeregfinalE,rsD,rtD,
		regwriteM,regwriteW,memtoregE[0],memtoregM[0],regwriteE,judgeM,divD,jumpD,jumptoregD,hiloweM,
		labelD,labelE,
		divstartE,divdoneE,
		cp0readE,cp0writeM,cp0addrE,cp0addrM,excepttypefinalM,
		forwardaD,forwardbD,
		forwardaE,forwardbE,
		hiforwardE,loforwardE,cp0forwardE,
		stallF,stallD,stallE,stallM,stallW,flushF,flushD,flushE,flushM,flushW,all_stall
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
		.clk(clk),.rst(rst),
		.we_i(cp0writeM),.waddr_i(cp0addrM),.raddr_i(cp0addrE),.data_i(aluoutM),
		.int_i(ext_int),
		.excepttype_i(excepttypefinalM),.current_inst_addr_i(pcM),
		.is_in_delayslot_i(isindelayslotM),.bad_addr_i(badaddrifinalM),
		.data_o(readcp0dataE),.epc_o(epcE),.status_o(statusE),.cause_o(causeE)
	);

	regfile regfile(clk,rst,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD,
					rsM,rtM,branchsrcaM,branchsrcbM);

	hilo_reg hilo_reg(clk,rst,hiloweM,hi_iM,lo_iM,hi_oE,lo_oE);

	//mmu
	mmu mmu(
		pcF,pcfinalF,
		aluoutM,aluoutaddrM
	);



	//F阶段连线
	mux2#(32) mux2F1(pcplus4F,pcbranchD,pred_takeD,pc_preF);  //预测分支跳转
	mux2#(32) mux2F2(pc_preF,pcjumpfinalD,jumpD,pc_inF);  //直接跳转
	mux2#(32) mux2F3(pc_inF,pc_memoryF,judgeM,pc_rightF);  //预测错误
	//异常处理下一条指令
	mux2#(32) mux2F4(32'hbfc00380,epcM,excepttypefinalM==32'h0000000e,exceptpcF);
	mux2#(32) mux2F5(pc_rightF,exceptpcF,excepttypefinalM!=0,pc_finalF);
	pc pc(clk,rst,~stallF,flushF,pc_finalF,pcF);
	adder adder1(pcF,32'h4,pcplus4F);

	//FD
	flopenrc #(32) r1D(clk,rst,~stallD,flushD,pcplus4F,pcplus4D);
	flopenrc #(32) r2D(clk,rst,~stallD,flushD,instrF,instrD);
	flopenrc #(1) r3D(clk,rst,~stallD,flushD,isindelayslotF,isindelayslotD);
	flopenrc #(32) r4D(clk,rst,~stallD,flushD,pcF,pcD);

	//D阶段连线
	assign unsignD=instrD[29]&instrD[28];  //无符号扩展的指令op:0011xx
	dataext dataext(instrD[15:0],unsignD,signimmD);
	sl2 immsh(signimmD,signimmshD);
	sl2 jumpsh(.a({{6{1'b0}},instrD[25:0]}),.y(pcjumptempD));
	adder adder2(pcplus4D,signimmshD,pcbranchD);

	assign divsignedD=(labelD==6'b001011);
	
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign saD = instrD[10:6];
	assign pcjumpD={pcplus4D[31:28],pcjumptempD[27:0]};

	assign jumptoregD=~instrD[27];
	mux2#(32) jumpmuxD(pcjumpD,srcafinalD,jumptoregD,pcjumpfinalD);  //是否跳转到寄存器的值

	assign cp0addrD = instrD[15:11];

	//D阶段数据前推
	mux2#(32) muxD3(srcaD,aluoutM,forwardaD,srcafinalD);
	mux2#(32) muxD4(srcbD,aluoutM,forwardbD,srcbfinalD);

	//取值异常
	mux2#(32) muxD1(excepttypeD,32'h00000004,pcD[1]|pcD[0],excepttypefinalD);
	mux2#(32) muxD2(32'b0,pcD,pcD[1]|pcD[0],badaddriD);

	//DE
	flopenrc #(32) r1E(clk,rst,~stallE,flushE,srcafinalD,srcaE);
	flopenrc #(32) r2E(clk,rst,~stallE,flushE,srcbfinalD,srcbE);
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
	flopenrc #(32) r17E(clk,rst,~stallE,flushE,pcbranchD,pcbranchE);
	flopenrc #(1) r18E(clk,rst,~stallE,flushE,isindelayslotD,isindelayslotE);
	flopenrc #(5) r19E(clk,rst,~stallE,flushE,cp0addrD,cp0addrE);
	flopenrc #(1) r20E(clk,rst,~stallE,flushE,cp0writeD,cp0writeE);
	flopenrc #(1) r21E(clk,rst,~stallE,flushE,cp0readD,cp0readE);
	flopenrc #(32) r22E(clk,rst,~stallE,flushE,excepttypefinalD,excepttypeE);
	flopenrc #(32) r23E(clk,rst,~stallE,flushE,badaddriD,badaddriE);
	flopenrc #(32) r24E(clk,rst,~stallE,flushE,pcD,pcE);
	flopenrc #(1) r26E(clk,rst,~stallE,flushE,divsignedD,divsignedE);
	flopenrc #(1) r27E(clk,rst,~stallE,flushE,divstartD,divstartE);

	//E阶段连线
	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E);
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);
	mux2 #(5) wrmux(rtE,rdE,regdstE,writeregE);
	mux2 #(5) mux2E2(writeregE,5'b11111,reg31writeE,writeregfinalE);  //是否写入31号寄存器
	mux2 #(32) mux2E3(excepttypeE,32'h0000000c,overflowE,excepttypefinalE);  //溢出异常
	//数据前推
	mux2 #(32) mux2E4(hi_oE,hi_iM,hiforwardE,hi_ofinalE);
	mux2 #(32) mux2E5(lo_oE,lo_iM,loforwardE,lo_ofinalE);
	mux2 #(32) mux2E6(readcp0dataE,aluoutM,cp0forwardE,readcp0datafinalE);

	div div(
		clk,rst,
		divsignedE,
		srca2E,srcb3E,
		divstartE,(excepttypefinalM!=0),
		divresE,divdoneE
	);

	ALU ALU(
		srca2E,srcb3E,saE,pcplus4E,
		hi_ofinalE,lo_ofinalE,divresE,
		labelE,
		readcp0datafinalE,
		aluoutE,
		hi_iE,lo_iE,
		hiloweE,reg31writeE,
		lbshiftE,
		overflowE
	);

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
	flopenrc #(32) r11M(clk,rst,~stallM,flushM,pcbranchE,pcbranchM);
	flopenrc #(2) r12M(clk,rst,~stallM,flushM,lbshiftE,lbshiftM);
	flopenrc #(1) r13M(clk,rst,~stallM,flushM,isindelayslotE,isindelayslotM);
	flopenrc #(5) r14M(clk,rst,~stallM,flushM,cp0addrE,cp0addrM);
	flopenrc #(1) r15M(clk,rst,~stallM,flushM,cp0writeE,cp0writeM);
	flopenrc #(32) r16M(clk,rst,~stallM,flushM,excepttypefinalE,excepttypeM);
	flopenrc #(32) r17M(clk,rst,~stallM,flushM,badaddriE,badaddriM);
	flopenrc #(32) r18M(clk,rst,~stallM,flushM,pcE,pcM);
	flopenrc #(5) r19M(clk,rst,~stallM,flushM,rsE,rsM);
	flopenrc #(5) r20M(clk,rst,~stallM,flushM,rtE,rtM);
	flopenrc #(32) r21M(clk,rst,~stallM,flushM,hi_iE,hi_iM);
	flopenrc #(32) r22M(clk,rst,~stallM,flushM,lo_iE,lo_iM);
	flopenrc #(1) r23M(clk,rst,~stallM,flushM,hiloweE,hiloweM);
	flopenrc #(32) r24M(clk,rst,~stallM,flushM,epcE,epcM);
	flopenrc #(32) r25M(clk,rst,~stallM,flushM,statusE,statusM);
	flopenrc #(32) r26M(clk,rst,~stallM,flushM,causeE,causeM);

	//M阶段连线
	mux2 #(32) mux2M1(pcplus4M+32'h4,pcbranchM,(needbranchM&branchM),pc_memoryF);

	load load(readdataM,memtoregM,lbshiftM,readdatafinalM);
	save save(writedataM,memwriteM,lbshiftM,writedatafinalM,memwritecheckM);
	//异常地址不进行写入
	mux2 #(4) mux2M5(memwritecheckM,4'b0000,excepttypefinalM==32'h00000005,memwritefinalM);

	branchdecide branchdecide(labelM,branchsrcaM,branchsrcbM,needbranchM);
	assign judgeM = branchM&(needbranchM^pred_takeM); //1:不同，代表预测错误

	assign dataaddrM=aluoutM|lbshiftM;  //原始数据地址（可能触发异常）
	assign loadexceptM=(((memtoregM==4'b1011|memtoregM==4'b0011)&(lbshiftM==2'b01|lbshiftM==2'b11))
						|(memtoregM==4'b1111&lbshiftM!=2'b00));
	assign storeexceptM=((memwriteM==4'b0011&(lbshiftM==2'b01|lbshiftM==2'b11))
						|(memwriteM==4'b1111&lbshiftM!=2'b00));
	
	mux2#(32) mux2M2(badaddriM,dataaddrM,loadexceptM|storeexceptM,badaddrifinalM);  //数据地址是否错误
	mux2#(32) mux2M3(excepttypeM,32'h00000004,loadexceptM,excepttypenextM);  //load异常
	mux2#(32) mux2M4(excepttypenextM,32'h00000005,storeexceptM,excepttypenextnextM);  //store异常
	mux2#(32) mux2M6(excepttypenextnextM,32'h00000001,(((causeM[15:8]&statusM[15:8])!=8'b0))
					&(statusM[1]==1'b0)&(statusM[0]==1'b1),excepttypefinalM);  //中断

	mux2 #(32) resmux1(aluoutM,readdatafinalM,memtoregM[0],resultM);

	//MW
	flopenrc #(32) r1W(clk,rst,~stallW,flushW,aluoutM,aluoutW);
	flopenrc #(32) r2W(clk,rst,~stallW,flushW,readdatafinalM,readdataW);
	flopenrc #(5) r3W(clk,rst,~stallW,flushW,writeregM,writeregW);
	flopenrc #(1) r4W(clk,rst,~stallW,flushW,regwriteM,regwriteW);
	flopenrc #(4) r5W(clk,rst,~stallW,flushW,memtoregM,memtoregW);
	flopenrc #(32) r6W(clk,rst,~stallW,flushW,pcM,pcW);

	//W阶段连线
	mux2 #(32) resmux2(aluoutW,readdataW,memtoregW[0],resultW);

	
endmodule