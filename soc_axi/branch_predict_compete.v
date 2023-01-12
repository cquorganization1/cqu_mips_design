module branch_predict_compete(
    input wire clk, rst,
    
    input wire flushD,  
    input wire stallD,

    input wire [31:0] pcF,
    input wire [31:0] pcM,

    input wire branchM,         // M阶段是否是分支指令
    input wire actual_takeM,    // 实际是否跳转

    input wire branchD,        // 译码阶段是否是跳转指令   //改动
    output wire pred_takeD      // 预测是否跳转
    );

    //得到局部预测和全局预测的结果
    wire local_predictF,global_predictF;
    reg local_predictD,global_predictD,local_predictE,global_predictE,local_predictM,global_predictM;
    branch_predict_local branch_predict_local(.clk(clk),.rst(rst),.flushD(flushD),.stallD(stallD),
    .pcF(pcF),.pcM(pcM),.branchM(branchM),
    .actual_takeM(actual_takeM),.branchD(branchD),.pred_takeD(local_predictF));
    branch_predict_global branch_predict_global(.clk(clk),.rst(rst),.flushD(flushD),.stallD(stallD),
    .pcF(pcF),.pcM(pcM),.branchM(branchM),
    .actual_takeM(actual_takeM),.branchD(branchD),.pred_takeD(global_predictF));

    //CPHT的状态
    parameter Saturated_p1 = 2'b00, Not_saturated_p1 = 2'b01, Saturated_p2 = 2'b11, Not_saturated_p2 = 2'b10;
    //表的定义
    wire pred_takeF_r;
    parameter CPHT_DEPTH=10;
    wire[CPHT_DEPTH-1:0] CPHT_INDEX;
    reg[CPHT_DEPTH-1:0] CPHT_INDEX_r;
    integer i;
    wire[CPHT_DEPTH-1:0] pc_hash;
    reg [1:0] CPHT [(1<<CPHT_DEPTH)-1:0];

    //预测逻辑
    // 对PC哈希
    assign pc_hash = pcF[31:22]^pcF[21:12]^pcF[11:2];
    assign CPHT_INDEX = pc_hash;
    mux2#(1) mux2(.s(CPHT[CPHT_INDEX][1]),.d0(global_predictF),.d1(local_predictF),.y(pred_takeF_r));


    always @(posedge clk) begin
        if (!rst) begin
            local_predictM=local_predictE;
            global_predictM=global_predictE;
            local_predictE=local_predictD;
            global_predictE=global_predictD;
            local_predictD=local_predictF;
            global_predictD=global_predictF;
            CPHT_INDEX_r=CPHT_INDEX;
        end
    end

    //CPHT初始化及更新
    wire[CPHT_DEPTH-1:0] pc_hash_M;
    wire[CPHT_DEPTH-1:0] update_CPHT_index;
    assign pc_hash_M = pcM[31:22]^pcM[21:12]^pcM[11:2];
    assign update_CPHT_index= pc_hash_M;
    wire global_wrong,local_wrong;  //两种方法是否预测错误
    assign global_wrong=global_predictM^actual_takeM;
    assign local_wrong=local_predictM^actual_takeM;

    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<CPHT_DEPTH); i=i+1) begin
                CPHT[i] <= Not_saturated_p1;
            end
        end
        else if (branchM) begin
            case(CPHT[update_CPHT_index])
                // 此处应该添加你的更新逻辑的代码
                Saturated_p1: begin
                    if (global_wrong&&!local_wrong) begin
                        CPHT[update_CPHT_index]=Not_saturated_p1;
                    end
                end
                Not_saturated_p1: begin
                    if (global_wrong&&!local_wrong) begin
                        CPHT[update_CPHT_index]=Not_saturated_p2;
                    end
                    else if (!global_wrong&&local_wrong)begin
                        CPHT[update_CPHT_index]=Saturated_p1;
                    end
                end
                Not_saturated_p2: begin
                    if (global_wrong&&!local_wrong) begin
                        CPHT[update_CPHT_index]=Saturated_p2;
                    end
                    else if (!global_wrong&&local_wrong) begin
                        CPHT[update_CPHT_index]=Not_saturated_p1;
                    end
                end
                Saturated_p2: begin
                    if (!global_wrong&&local_wrong) begin
                        CPHT[update_CPHT_index]=Not_saturated_p2;
                    end
                end
            endcase 
        end
    end

    // 译码阶段输出最终的预测结果
    assign pred_takeD = branchD & pred_takeF_r;

endmodule
