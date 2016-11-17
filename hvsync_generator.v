///////////////////
// File Name:   VGA Tutorial
// Author   :   Da Cheng
// Course   :   EE201 
///////////////////
// timing diagram for the horizontal synch signal (HS)
// 0                       655    752           800 (pixels)
// -------------------------|______|-----------------
// timing diagram for the vertical synch signal (VS)
// 0                                 490    491  525 (lines)
// -----------------------------------|______|-------

module hvsync_generator(clk, reset,vga_h_sync, vga_v_sync, inDisplayArea, CounterX, CounterY);
input clk;
input reset;
output vga_h_sync, vga_v_sync;
output inDisplayArea;
output [9:0] CounterX;
output [9:0] CounterY;

//////////////////////////////////////////////////
reg [9:0] CounterX;
reg [9:0] CounterY;
reg vga_HS, vga_VS;
reg inDisplayArea;
//increment column counter
always @(posedge clk)
begin
   if(reset)
      CounterX <= 0;
   else if(CounterX==10'h320)
	   CounterX <= 0;
   else
	   CounterX <= CounterX +1;
end
//increment row counter
always @(posedge clk)
begin
   if(reset)
      CounterY<=0; 
   else if(CounterY==10'h209)    //521
      CounterY<=0;
   else if(CounterX==10'h320)    //800
      CounterY <= CounterY + 1;
end
//generate synchronization signal for both vertical and horizontal
always @(posedge clk)
begin
	vga_HS <= (CounterX>655 && CounterX<752); 	// change these values to move the display horizontally
	vga_VS <= (CounterY==490 ||CounterY==491); 	// change these values to move the display vertically
end 


always @(posedge clk)
   if(reset)
      inDisplayArea<=0;
   else
	   inDisplayArea <= (CounterX<640) && (CounterY<480);
	
assign vga_h_sync = ~vga_HS;
assign vga_v_sync = ~vga_VS;

endmodule
