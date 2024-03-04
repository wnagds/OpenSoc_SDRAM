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


module sdram_read(
  input                sclk,
  input                reset,
  //仲裁接口
  input                rd_req,
  input                rd_en,
  output    reg       flag_rd_end,
  input               ref_req,
  //与sdram的接口
  output reg  [3:0]    rd_cmd,
  output reg  [11:0]   rd_addr,
  output      [1:0]    bank_addr ,
  input       [15:0]   sdram_rd_data,
  //其他
  input                rd_trig,
  //读fifo接口
  output               rfifo_wr_en,
  output      [7:0]    rfifo_wr_data
);

    //定义状态
    localparam  S_IDLE  =   5'b0_0001;
    localparam  S_REQ   =   5'b0_0010;
    localparam  S_ACT   =   5'b0_0100;
    localparam  S_RD    =   5'b0_1000;
    localparam  S_PRE   =   5'b1_0000;
    //SDRAM命令
    localparam  CMD_NOP     =   4'b0111;
    localparam  CMD_PRE     =   4'b0010;
    localparam  CMD_AREF    =   4'b0001;
    localparam  CMD_ACT     =   4'b0011;
    localparam  CMD_RD      =   4'b0101;    
    reg                 flag_rd;
    reg [4:0]            state;
    //---------------------------------//
    reg                 flag_act_end;
    reg                 flag_pre_end;
    reg                 sd_row_end;
    reg [1:0]           burst_cnt;
    reg [1:0]           burst_cnt_t;
    reg                 rd_data_end;
    //-----------------------------------
    reg [3:0]           act_cnt;
    reg [3:0]           break_cnt;
    reg [6:0]           col_cnt;
    //--------------------------------------
    reg [11:0]          row_addr;
    wire[8:0]           col_addr;
//    reg                 ref_req_r;
    reg         [3:0]   rfifo_wr_en_r;
    always@(posedge sclk or negedge reset)
    begin
        if(!reset)
            rfifo_wr_en_r <=0;
        else begin
            rfifo_wr_en_r[0]<=(state == S_RD);
            rfifo_wr_en_r[1]<= rfifo_wr_en_r[0];
            rfifo_wr_en_r[2]<= rfifo_wr_en_r[1];
            rfifo_wr_en_r[3]<= rfifo_wr_en_r[2];
        end
    end
    
   
//   always@(posedge sclk or negedge reset)
//   begin
//        if(!reset)
//            ref_req_r <= 0;
//        else if(ref_req == 1 && ref_req_r == 0)
//            ref_req_r <= 1;
//   end
   always@(posedge sclk or negedge reset) 
   begin
        if(!reset)
            flag_rd <= 0;
        else if(rd_trig == 1'b1 && flag_rd == 1'b0)
            flag_rd <= 1'b1;
        else if(rd_data_end == 1'b1) 
            flag_rd <= 0;
   end
   always @(posedge sclk or negedge reset)
   begin
       if(!reset)
           burst_cnt <=  0;
       else if(state == S_RD)
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
                if(rd_trig == 1'b1)
                    state <= S_REQ;
                else 
                    state <=S_IDLE;
            S_REQ:  //10
                if(rd_en==1'b1)
                    state <= S_ACT;
                else 
                    state <= S_REQ;
            S_ACT://100
                if(flag_act_end==1'b1)   
                    state <= S_RD;
                 else 
                    state <= S_ACT;
            S_RD:   //01000
                if(rd_data_end == 1'b1)
                    state <= S_PRE;
                else if(ref_req == 1'b1 && burst_cnt_t == 'd2 && flag_rd == 1'b1)
                    state <= S_PRE;
                else if(sd_row_end == 1'b1 && flag_rd == 1'b1)
                    state <= S_PRE;
            S_PRE://10000
                if(ref_req==1'b1 && flag_rd == 1'b1)
                    state <= S_REQ; 
                else if(flag_pre_end == 1'b1 && flag_rd == 1'b1)
                    state <= S_ACT;
                else if(flag_rd == 0)
                    state <= S_IDLE;
            default: 
                    state <= S_IDLE;
        endcase
    end
    //wr_req
    assign rd_req = state[1];
    always @(posedge sclk or negedge reset)
    begin
        if(!reset)
            rd_cmd <= CMD_NOP;
        else case(state)
            S_ACT:
                if(act_cnt==0)
                    rd_cmd <= CMD_ACT;
                else 
                    rd_cmd <= CMD_NOP;
            S_RD:
                if(burst_cnt == 0)
                    rd_cmd <= CMD_RD;
                else    
                    rd_cmd <= CMD_NOP;
            S_PRE:
                if(break_cnt == 0)
                    rd_cmd<=CMD_PRE;
                else
                    rd_cmd <= CMD_NOP;
            default:
                    rd_cmd <=CMD_NOP;
        endcase
    end
    always @(*) begin
        case(state)
            S_ACT:
                if(act_cnt == 0)
                    rd_addr = row_addr;
            S_RD:
                rd_addr =  {3'b000,col_addr};
            S_PRE:
                if(break_cnt == 0)
                    rd_addr =  {12'b0100_0000_0000};
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
            flag_rd_end <= 0;
        else if(state == S_PRE && ref_req == 1 ||
                state == S_PRE && flag_rd == 0)
            flag_rd_end <= 1;
        else 
            flag_rd_end <= 0;
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
            rd_data_end <= 0;
        else if(row_addr == 0 && burst_cnt_t == 1)
            rd_data_end <= 1;
        else 
            rd_data_end <=0;
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
    
//    always @(*)
//    begin
//        case(burst_cnt_t)
//            0:  rd_data <=  'd3;
//            1:  rd_data <=  'd5;
//            2:  rd_data <=  'd7;
//            3:  rd_data <=  'd9;
//        endcase
//    end
    assign col_addr      =   {col_cnt,burst_cnt_t};
   assign bank_addr     =   2'b00;
   assign rfifo_wr_data =   sdram_rd_data[7:0];
   assign rfifo_wr_en   =   rfifo_wr_en_r[2];
endmodule
