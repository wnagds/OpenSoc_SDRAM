`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/26 22:57:38
// Design Name: 
// Module Name: sdram_top_tb
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


module sdram_top_tb(
    
    );
    reg sclk;
    reg reset;
    wire sdram_clk;
    wire sdram_cke;
    wire sdram_cs;
    wire sdram_cas;
    wire sdram_ras;
    wire sdram_we;
//`   wire [1:0]sdram_bank;
    wire [1:0]sdram_bank;
    wire [11:0]sdram_addr;
    wire [1:0]sdram_dqm;  
    wire [15:0]sdram_dq;  
    wire wfifo_rd_en;
    reg wr_trig;
    reg rd_trig;
    reg [7:0]wfifo_rd_data;
    reg [7:0] wfifo_rd_data_r[3:0];
    reg [1:0]bits_cnt;
    reg [1:0]bits_cnt_r;    
    always @(posedge sclk or negedge reset)
    begin
        if(!reset)
            bits_cnt <= 0;
        else if(wfifo_rd_en)
            bits_cnt <= bits_cnt + 1;
    end
    always @(posedge sclk or negedge reset)
    begin
        if(!reset)
            bits_cnt_r <= 0;
        else if(wfifo_rd_en)
            bits_cnt_r <= bits_cnt;
    end
    initial begin
        wfifo_rd_data_r[0] <= 8'h11;
        wfifo_rd_data_r[1] <= 8'h22;
        wfifo_rd_data_r[2] <= 8'h33;
        wfifo_rd_data_r[3] <= 8'h44;
    end
    always @(*)
    begin
        wfifo_rd_data = wfifo_rd_data_r[bits_cnt_r];
    end
    initial sclk=1;
    always #10 sclk=!sclk;
    initial begin
        reset =0;
        #201;
        reset=1;
    end
    initial begin
        wr_trig <=  0;
        rd_trig <=  0;
        #300_500;
        wr_trig <= 1;
        #20;
        wr_trig <=0;
        #40_000;
        #3000_000;
        rd_trig <= 1;
        #20;
        rd_trig <= 0;
        #300_000;
        rd_trig <= 1;
        #20;
        rd_trig <= 0;
        #300_000;
        $stop;
    end
    
    
    sdram_top sdram_top_inst(
    //input Interface
    .sclk       (sclk),
    .reset      (reset),
//********output SDRAM_Interface ********************
    .sdram_clk  (sdram_clk),
    .sdram_cke  (sdram_cke),
    
    .sdram_cs   (sdram_cs),
    .sdram_cas  (sdram_cas),
    .sdram_ras  (sdram_ras),
    .sdram_we   (sdram_we),
    
    .sdram_bank (sdram_bank),
    .sdram_addr (sdram_addr),
    .sdram_dqm  (sdram_dqm),
//*************************************************
//*************input/output data*******************

    .sdram_dq   (sdram_dq),
    //Ð´fifoµÄ½Ó¿Ú
    .wr_trig    (wr_trig),
    .rd_trig    (rd_trig),
    .wfifo_rd_en     (wfifo_rd_en),
    .wfifo_rd_data   (wfifo_rd_data),
    
    .rfifo_wr_en     (),
    .rfifo_wr_data   ()
    
    );
    sdram_model_plus sdram_model_plus_inst(
        .Dq(sdram_dq),
        .Addr(sdram_addr),
        .Ba(sdram_bank),  
        .Clk(sdram_clk), 
        .Cke(sdram_cke), 
        .Cs_n(sdram_cs),
        .Ras_n(sdram_ras),
        .Cas_n(sdram_cas),
        .We_n(sdram_we),
        .Dqm(sdram_dqm),
        .Debug(1'b1)
        );
        defparam    sdram_model_plus_inst.addr_bits=12;
        defparam    sdram_model_plus_inst.data_bits=16;
        defparam    sdram_model_plus_inst.col_bits=9;
        defparam    sdram_model_plus_inst.mem_sizes=2*1024*1024;
endmodule
