////////////////////
//VGA tutorial 
//Author: Da Cheng
//EE201 Fall 2010
////////////////////

`timescale 1ns / 1ps

module hvsync_tb();

// Inputs
   reg reset_tb;
   reg clk_tb;
   reg [11:0]Clk_cnt;
// Output
	
	wire vga_h_sync_tb;
	wire vga_v_sync_tb;
	wire inDisplayArea_tb;
	wire [9:0]   CounterX_tb;
	wire [8:0]   CounterY_tb;
	

// Instantiate the UUT
hvsync_generator UUT (
      .clk(clk_tb), 
      .reset(reset_tb),
      .vga_h_sync(vga_h_sync_tb),
      .vga_v_sync(vga_v_sync_tb),
      .inDisplayArea(inDisplayArea_tb),
      .CounterX(CounterX_tb),
      .CounterY(CounterY_tb)
   );

//CLK_GENERATOR
always
  begin  : CLK_GENERATOR
       #20 clk_tb = ~clk_tb;
end

//CLK_COUNTER
initial
  begin  : CLK_COUNTER
    Clk_cnt = 0;
    forever
       begin
	      @(posedge clk_tb) Clk_cnt = Clk_cnt + 1;
       end 
  end
  
// APPLYING STIMULUS
initial
begin
   clk_tb=0;
	reset_tb=1;
	#45;
	reset_tb=0;
	
	end
endmodule
