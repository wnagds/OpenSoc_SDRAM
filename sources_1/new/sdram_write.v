`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/28 16:31:55
// Design Name: 
// Module Name: sdram_write
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


module sdram_write(
    sclk,
    reset,
    //仲裁接口
    wr_req,
    wr_en,
    flag_wr_end,
    ref_req,
    //与sdram的接口
    wr_cmd,
    wr_addr,
    bank_addr,
    wr_data,
    //其他
    wr_trig,
    wfifo_rd_en,
    wfifo_rd_data
    );
    input sclk;
    input reset;
    
    //仲裁接口
    output wr_req;
    input wr_en;
    input ref_req;
    output flag_wr_end;
    //sdram接口
    output reg [3:0]    wr_cmd;
    output reg [11:0]   wr_addr;
    output [1:0]    bank_addr;
    output [15:0] wr_data;
    //其他
    input wr_trig;
    //写fifo接口
    output wfifo_rd_en;
    input  [7:0]wfifo_rd_data;
    //定义状态
    localparam  S_IDLE  =   5'b0_0001;
    localparam  S_REQ   =   5'b0_0010;
    localparam  S_ACT   =   5'b0_0100;
    localparam  S_WR    =   5'b0_1000;
    localparam  S_PRE   =   5'b1_0000;
    //SDRAM命令
    localparam  CMD_NOP     =   4'b0111;
    localparam  CMD_PRE     =   4'b0010;
    localparam  CMD_AREF    =   4'b0001;
    localparam  CMD_ACT     =   4'b0011;
    localparam  CMD_WR      =   4'b0100;    
    reg                 flag_wr;
    reg [4:0]            state;
    //---------------------------------//
    reg                 flag_act_end;
    reg                 flag_pre_end;
    reg                 flag_wr_end;
    reg                 sd_row_end;
    reg [1:0]           burst_cnt;
    reg [1:0]           burst_cnt_t;
    reg                 wr_data_end;
    //-----------------------------------
    reg [3:0]           act_cnt;
    reg [3:0]           break_cnt;
    reg [6:0]           col_cnt;
    //--------------------------------------
    reg [11:0]          row_addr;
    wire[8:0]           col_addr;
    reg                 ref_req_r;
   
   always@(posedge sclk or negedge reset)
   begin
        if(!reset)
            ref_req_r <= 0;
        else if(ref_req == 1 && ref_req_r == 0)
            ref_req_r <= 1;
   end
   always@(posedge sclk or negedge reset) 
   begin
        if(!reset)
            flag_wr <= 0;
        else if(wr_trig == 1'b1 && flag_wr == 1'b0)
            flag_wr <= 1'b1;
        else if(wr_data_end == 1'b1) 
            flag_wr <= 0;
   end
   always @(posedge sclk or negedge reset)
   begin
       if(!reset)
           burst_cnt <=  0;
       else if(state == S_WR)
           burst_cnt <= burst_cnt + 1;
       else 
           burst_cnt <=0;
   end
   always @(posedge sclk or negedge reset)
   begin
       if(!reset)
           burst_cnt_t<=0;
       else 
           burst_cnt_t <=burst_cnt;
   end
   //状态转移
   always@(posedge sclk or negedge reset)
   begin
        if(!reset)
            state <=S_IDLE;
        else case(state)
            S_IDLE://1
                if(wr_trig == 1'b1)
                    state <= S_REQ;
                else 
                    state <=S_IDLE;
            S_REQ:  //10
                if(wr_en==1'b1)
                    state <= S_ACT;
                else 
                    state <= S_REQ;
            S_ACT://100
                if(flag_act_end==1'b1)   
                    state <= S_WR;
                 else 
                    state <= S_ACT;
            S_WR:   //01000
                if(wr_data_end == 1'b1)
                    state <= S_PRE;
                else if(ref_req == 1'b1 && burst_cnt_t == 'd2 && flag_wr == 1'b1)
                    state <= S_PRE;
                else if(sd_row_end == 1'b1 && flag_wr == 1'b1)
                    state <= S_PRE;
            S_PRE://10000
                if(ref_req==1'b1 && flag_wr == 1'b1)
                    state <= S_REQ; 
                else if(flag_pre_end == 1'b1 && flag_wr == 1'b1)
                    state <= S_ACT;
                else if(flag_wr == 1'b0)
                    state <= S_IDLE;
            default: 
                    state <= S_IDLE;
        endcase
    end
    //wr_req
    assign wr_req = state[1];
    always @(posedge sclk or negedge reset)
    begin
        if(!reset)
            wr_cmd <= CMD_NOP;
        else case(state)
            S_ACT:
                if(act_cnt==0)
                    wr_cmd <= CMD_ACT;
                else 
                    wr_cmd <= CMD_NOP;
            S_WR:
                if(burst_cnt == 0)
                    wr_cmd <= CMD_WR;
                else    
                    wr_cmd <= CMD_NOP;
            S_PRE:
                if(break_cnt == 0)
                    wr_cmd<=CMD_PRE;
                else
                    wr_cmd <= CMD_NOP;
            default:
                    wr_cmd <=CMD_NOP;
        endcase
    end
    always @(*) begin
        case(state)
            S_ACT:
                if(act_cnt == 0)
                    wr_addr = row_addr;
                else 
                    wr_addr = 0;
            S_WR:
                wr_addr =  {3'b000,col_addr};
            S_PRE:
                if(break_cnt == 0)
                    wr_addr =  {12'b0100_0000_0000};
                else 
                    wr_addr = 0;
            default:
                    wr_addr = 0;
        endcase
    end
    always @(posedge sclk or negedge reset)
    begin
        if(!reset)
            flag_act_end <= 1'b0;
        else if(act_cnt >= 'd3)
            flag_act_end <= 1'b1;
        else 
            flag_act_end <= 1'b0;
    end
    always @(posedge sclk or negedge reset)
    begin
        if(!reset)
            act_cnt <= 0;
        else if(state ==  S_ACT)
            act_cnt <= act_cnt+1;
        else act_cnt <= 0;
        
    end
    always @(posedge sclk or negedge reset)
    begin
        if(!reset)
            flag_pre_end <= 0;
        else if(break_cnt == 'd3)
            flag_pre_end <= 1'b1;
        else 
            flag_pre_end <= 1'b0;
    end
    always @(posedge sclk or negedge reset)
    begin
        if(!reset)
            flag_wr_end <= 0;
        else if(state == S_PRE && ref_req == 1 ||
                state == S_PRE && flag_wr == 0)
            flag_wr_end <= 1;
        else 
            flag_wr_end <= 0;
    end
    
     always @(posedge sclk or negedge reset)
       begin
           if(!reset)
               break_cnt <= 0;
           else if(state ==  S_PRE )
               break_cnt <= break_cnt+1;
           else break_cnt <= 0;
       end
       
    always @(posedge sclk or negedge reset)
    begin
        if(!reset)
            wr_data_end <= 0;
        else if(row_addr == 0 && burst_cnt_t == 1)
            wr_data_end <= 1;
        else 
            wr_data_end <=0;
    end
   
    always @(posedge sclk or negedge reset)
    begin
        if(!reset)
            col_cnt <=  0;
        else if(col_addr >= 511)
            col_cnt <=0;
        else if(burst_cnt_t == 3)
            col_cnt <= col_cnt + 1 ;
    end
    always @(posedge sclk or negedge reset)
    begin
        if(!reset)
            row_addr <= 0;
        else if(col_addr>=511)
            row_addr <= row_addr +1;
    end
    always @(posedge sclk or negedge reset)
    begin
        if(!reset)
            sd_row_end<=0;
        else if(col_addr ==509)
            sd_row_end<=1;
        else sd_row_end<=0;
    end
    
assign col_addr      =   {col_cnt,burst_cnt_t};
//assign col_addr      =   'd0;               //只使用SDRAM前4个地址
assign bank_addr     =   2'b00;
assign wfifo_rd_en   =   state == S_WR;
assign wr_data       =   wfifo_rd_data;
    
endmodule
