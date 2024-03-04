`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/26 21:58:30
// Design Name: 
// Module Name: sdram_top
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


module sdram_top(
    //input Interface
    input               sclk,
    input               reset,
//************ SDRAM接口 ***********************
    output              sdram_clk,
    output              sdram_cke,
    //output cmd
    output              sdram_cs,
    output              sdram_cas,
    output              sdram_ras,
    output              sdram_we,
    //output addr
    output     [1:0]    sdram_bank,
    output reg [11:0]   sdram_addr,
    output     [1:0]    sdram_dqm,
    inout      [15:0]   sdram_dq,
//*************************************************
//*************input/output data*******************
    //写fifo的接口
    input           wr_trig,
    output          wfifo_rd_en,
    input   [7:0]   wfifo_rd_data,
    
    input           rd_trig,
    output          rfifo_wr_en,
    output  [7:0]   rfifo_wr_data
    );
    //仲裁模块参数定义
    //初始状态
    localparam      IDLE =           5'b0_0001;
    //仲裁状态
    localparam      ARBIT=           5'b0_0010;
    //刷新状态
    localparam      AREF=            5'b0_0100;
    //写状态
    localparam      WRITE=           5'b0_1000;
    //读状态
    localparam      READ=            5'b1_0000;
    //命令定义
    localparam      NOP=             4'b0111;
    
     reg [3:0]      sd_cmd;
    //init module
     wire           flag_init_end;
     wire [3:0]     init_cmd;
     wire [11:0]    init_addr;
     reg  [4:0]     state;
     //refresh  module
      wire          ref_req;
      reg           ref_en;
      wire          flag_ref_end;
      wire  [3:0]   ref_cmd;
      wire  [11:0]  ref_addr;
      //write module
      wire          wr_req;
      reg           wr_en;
      wire          flag_wr_end;
      wire [1:0]    wr_bank_addr;     
      wire [3:0]    wr_cmd;
      wire [11:0]   wr_addr;
      wire [15:0]   wr_data;
      //read module
      wire          rd_req;
      reg           rd_en;
      wire          flag_rd_end;
      wire [1:0]    rd_bank_addr;     
      wire [3:0]    rd_cmd;
      wire [11:0]   rd_addr;
      wire [15:0]   sdram_rd_data;   
    always@(posedge sclk or negedge reset)
    begin
        if(reset==1'b0)
            state   <=IDLE;
        else case(state)
            IDLE:begin
                if(flag_init_end==1'b1)
                    state<=ARBIT;
                else
                    state<=IDLE;
            end
            ARBIT:begin
                if(ref_en==1'b1)
                    state<=AREF;
                else if(wr_en == 1)
                    state <= WRITE;
                else if(rd_en == 1)
                    state <= READ;
                else state<=ARBIT;
            end
            AREF:begin          //100
                if(flag_ref_end==1'b1)
                    state<=ARBIT;
                else state<=AREF;
            end
            WRITE:          //1000
                if(flag_wr_end == 1'b1)
                    state <= ARBIT;
                else state <= WRITE;
            READ:           //10000
                if(flag_rd_end == 1'b1)
                    state <= ARBIT;
                else state <= READ;
            default:
                state<=IDLE;
       endcase             
    end
    //刷新使能
    always@(posedge sclk or negedge reset)
    begin
        if(!reset)
            ref_en<=0;
        else if(state == ARBIT&&ref_req==1'b1)
            ref_en<=1;
        else ref_en<=0;
    end
    
    //写使能
    always@(posedge sclk or negedge reset)
    begin
        if(!reset)
            wr_en   <= 0;
        else if(state == ARBIT && ref_req == 0 && wr_req == 1)
            wr_en   <= 1;
       else wr_en   <= 0;
    end
    //读使能 写操作优于读操作
    always@(posedge sclk or negedge reset)
    begin
        if(!reset)
            rd_en   <= 0;
        else if(state == ARBIT && ref_req == 0 && wr_req == 0 && rd_req == 1)
            rd_en   <= 1;
        else rd_en  <= 0;
    end
    
    always@(*)
    begin
        case(state)
            IDLE:begin
                sd_cmd         = init_cmd;
                sdram_addr     = init_addr;
            end
            AREF:begin
                sd_cmd         = ref_cmd;
                sdram_addr     = ref_addr;
            end
             WRITE:begin
               sd_cmd          = wr_cmd;
               sdram_addr      = wr_addr;
           end
            READ:begin
                sd_cmd         = rd_cmd;
                sdram_addr     = rd_addr;
            end
            default:begin 
                sd_cmd      = NOP;
                sdram_addr     = 0;
            end
        endcase
    end

    
    assign {sdram_cs,sdram_ras,sdram_cas,sdram_we}=sd_cmd;
    assign sdram_cke        =1'b1;
    assign sdram_dq       =   (state == WRITE) ? wr_data: 'bz;
    assign sdram_rd_data   =  sdram_dq;
    
    assign sdram_dqm=2'b00;
    assign sdram_clk =~sclk;
    assign sdram_bank = (state == WRITE) ? wr_bank_addr : rd_bank_addr;
    //地址
//    assign sdram_addr = (state == IDLE)?init_addr:ref_addr;
    //命令
//    assign {sdram_cs,sdram_ras,sdram_cas,sdram_we}=(state == IDLE)?init_cmd:ref_cmd;
    //数据屏蔽
    
    //sdram_bank_addr
    //例化 sdram初始化模块
    sdram_init sdram_init_inst(
        .sclk(sclk),
        .reset(reset),
        .cmd_reg(init_cmd),    
        .sdram_addr(init_addr),
        .flag_init_end(flag_init_end)
    );
    sdram_aref sdram_aref_inst(
        //系统信号
        .sclk                   (sclk),
        .reset                  (reset),
        //与仲裁机的接口
        .ref_en                 (ref_en),
        .ref_req                (ref_req),
        .flag_ref_end           (flag_ref_end),
        //其他接口
        .aref_cmd               (ref_cmd),
        .sdram_addr             (ref_addr),
        .flag_init_end          (flag_init_end)        
    );
    //写模块
    sdram_write sdram_write_inst(
        .sclk                   (sclk),
        .reset                  (reset),
        //仲裁接口
        .wr_req                 (wr_req),
        .wr_en                  (wr_en),
        .flag_wr_end            (flag_wr_end),
        .ref_req                (ref_req),
        //与sdram的接口
        .wr_cmd                 (wr_cmd),
        .wr_addr                (wr_addr),
        .bank_addr              (wr_bank_addr),
        .wr_data                (wr_data),
        //其他
        .wr_trig                (wr_trig),
        //写fifo的接口
        .wfifo_rd_en(wfifo_rd_en),
        .wfifo_rd_data(wfifo_rd_data)
        );
    sdram_read sdram_read_inst(
        .sclk                   (sclk),
        .reset                  (reset),
        //仲裁接口
        .rd_req                 (rd_req),
        .rd_en                  (rd_en),
        .flag_rd_end            (flag_rd_end),
        .ref_req                (ref_req),
        //与sdram的接口
        .rd_cmd                 (rd_cmd),
        .rd_addr                (rd_addr),
        .bank_addr              (rd_bank_addr),
        .sdram_rd_data          (sdram_rd_data),
        //其他
        .rd_trig                (rd_trig),
        .rfifo_wr_en            (rfifo_wr_en), 
        .rfifo_wr_data          (rfifo_wr_data)
    );
endmodule
