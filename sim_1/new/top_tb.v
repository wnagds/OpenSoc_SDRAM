`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/26 18:11:28
// Design Name: 
// Module Name: top_tb
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


module top_tb(

    );
    reg sclk;
    reg reset;
    reg rs232_rx;
    wire rs232_tx;
//*********************sdram******************************
   wire sdram_clk       ;
   wire sdram_cke       ;
   
   wire sdram_cs        ;
   wire sdram_cas       ;
   wire sdram_ras       ;
   wire sdram_we        ;
   
   wire [1:0]sdram_bank      ;
   wire [11:0]sdram_addr      ;
   wire [1:0]sdram_dqm       ;
   wire [15:0]sdram_dq        ;
    
    
    initial sclk=1;
        always #10 sclk=~sclk;
        initial begin
            reset=0;
            rs232_rx=1;
            #101;
            reset=1;
            tx_byte();
            #300000;
            $stop;
        end
        task tx_byte();
            repeat(2)begin
                tx_bit(8'h55);  //Ğ´ÃüÁî
                #3000;
                tx_bit(8'h12);
                #3000;
                tx_bit(8'h34);
                #3000;
                tx_bit(8'h56);
                #3000;
                tx_bit(8'h78);
                #3000;
                tx_bit(8'haa);  //¶ÁÃüÁî
                #3000;
            end
        endtask
        
    task tx_bit;
        input [7:0]data;
        begin
           rs232_rx=1;
           #20;
           rs232_rx=0;
           #8680;
           
           rs232_rx=data[0];
           #8680;
           rs232_rx=data[1];
           #8680;
           rs232_rx=data[2];
           #8680;   
           rs232_rx=data[3];
          #8680;
          rs232_rx=data[4];
          #8680;
          rs232_rx=data[5];
          #8680;      
          rs232_rx=data[6];
          #8680;
          rs232_rx=data[7];
          #8680;      
          
          rs232_rx=1;
          #8680;
        end
    endtask
    top top_inst(
        .sclk(sclk),
        .reset(reset),
        .RS232_tx(rs232_tx),
        .rs232_rx(rs232_rx),
        //SDRAM
       .sdram_clk        (sdram_clk)   ,
       .sdram_cke        (sdram_cke)   ,
                          
       .sdram_cs         (sdram_cs)   ,
       .sdram_cas        (sdram_cas)   ,
       .sdram_ras        (sdram_ras)   ,
       .sdram_we         (sdram_we)   ,
                           
       .sdram_bank       (sdram_bank)   ,
       .sdram_addr       (sdram_addr)   ,
       .sdram_dqm        (sdram_dqm)   ,
       .sdram_dq         (sdram_dq)
        
        
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
