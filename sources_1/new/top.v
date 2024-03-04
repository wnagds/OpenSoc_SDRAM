`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/26 17:44:17
// Design Name: 
// Module Name: top
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


module top(
   input  sclk                 ,
   input  reset                ,
   //串口接口
   output RS232_tx             ,
   input rs232_rx             ,
   //SDRAM
   output sdram_clk            ,
   output sdram_cke            ,
     
   output sdram_cs             ,
   output sdram_cas            ,
   output sdram_ras            ,
   output sdram_we             ,
   
   output [1:0]sdram_bank      ,
   output [11:0]sdram_addr     ,
   output [1:0]sdram_dqm       ,
   output [15:0]sdram_dq        
   
    );           
        
//***************命令解析模块的接口******************** 
    wire            sdram_wr_trig   ;
    wire            sdram_rd_trig   ;
//***************写fifo的接口********************   
//    wire            wr_trig         ; 
    wire            wfifo_rd_en     ;
    wire [7:0]      wfifo_rd_data   ;
    wire            wfifo_wr_en     ;
    wire [7:0]      wfifo_wr_data   ;
//***************读fifo接口*********************
//    wire            rd_trig         ; 
    wire            rfifo_wr_en     ;
    wire [7:0]      rfifo_wr_data   ;
    wire            rfifo_rd_en     ;
    wire [7:0]      rfifo_rd_data   ;
    wire            rfifo_empty     ;
    wire [3:0]      data_count;
//***************串口发送******************
    wire            outflag_tx      ;
    wire            tx_trig         ;
    assign          tx_trig = (rfifo_empty == 0)&&(outflag_tx == 0)&&(rfifo_wr_en == 0);
//***************串口接收*******************
    wire [7:0]      rx_data         ;
    wire            rx_flag         ;
    
    
    
    
    uart_tx uart_tx_inst(
    .sclk                 (sclk)     ,
    .reset                (reset)     ,
    //发送串口                           ,
    
    .tx_trig              (tx_trig)     ,
    .RS232_tx             (RS232_tx)     ,
    .outflag_tx           (outflag_tx),
     //rfifo的读端口                  ,
    .rfifo_empty          (rfifo_empty)     , 
    .rfifo_rd_en          (rfifo_rd_en),
    .tx_data              (rfifo_rd_data)     
    );
  
    uart_rx uart_rx_inst(
    .sclk(sclk),
    .reset(reset),
    .rs232_rx(rs232_rx),
    
    .rx_data(rx_data),
    .po_flag(rx_flag)
    );
    
    fifo_16x8 wfifo_inst
    (
        .clk        (sclk),
        .wr_en      (wfifo_wr_en),
        .din        (wfifo_wr_data),
        
        .rd_en      (wfifo_rd_en),
        .dout       (wfifo_rd_data),
        .full       (),
        .empty      ()
    );
    fifo_16x8 rfifo_inst    
    ( 
        .clk        (sclk),
        .din        (rfifo_wr_data),
        .wr_en      (rfifo_wr_en),
        
        .rd_en      (rfifo_rd_en),
        .dout       (rfifo_rd_data),
        .full       (),
        .empty      (rfifo_empty),
        .data_count (data_count)
    );
    cmd_decode cmd_decode_inst(
        .sclk                  (sclk            ),
        .reset                 (reset           ),
        .uart_flag             (rx_flag         ),
        .uart_data             (rx_data         ),
        
        .wr_trig               (sdram_wr_trig   ),
        .rd_trig               (sdram_rd_trig   ),
        .wfifo_wr_en           (wfifo_wr_en     ),
        .wfifo_data            (wfifo_wr_data      )
    );
    
    
    sdram_top sdram_top_inst(
        //input Interface
        .sclk       (sclk),
        .reset      (reset),
 //**************与命令解析模块的接口******************
       .wr_trig         (sdram_wr_trig),
       .rd_trig         (sdram_rd_trig),

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
       .sdram_dq   (sdram_dq),
//*************input/output data*******************
        //写fifo接口
       .wfifo_rd_en     (wfifo_rd_en),
       .wfifo_rd_data   (wfifo_rd_data),
       //读fifo接口
       .rfifo_wr_en     (rfifo_wr_en),
       .rfifo_wr_data   (rfifo_wr_data)
    );
endmodule
