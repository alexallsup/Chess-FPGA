`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// VGA verilog template
// Author:  Da Cheng
//////////////////////////////////////////////////////////////////////////////////
module vga_demo(ClkPort, vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b, Sw0, Sw1, btnU, btnD,
	St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar,
	An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7);
	input ClkPort, Sw0, btnU, btnD, Sw0, Sw1;
	output St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar;
	output vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b;
	output An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp;
	output LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	reg vga_r, vga_g, vga_b;
	
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/*  LOCAL SIGNALS */
	wire	reset, start, ClkPort, board_clk, clk, button_clk;
	
	BUF BUF1 (board_clk, ClkPort); 	
	BUF BUF2 (reset, Sw0);
	BUF BUF3 (start, Sw1);
	
	reg [27:0]	DIV_CLK;
	always @ (posedge board_clk, posedge reset)  
	begin : CLOCK_DIVIDER
      if (reset)
			DIV_CLK <= 0;
      else
			DIV_CLK <= DIV_CLK + 1'b1;
	end	

	assign	button_clk = DIV_CLK[18];
	assign	clk = DIV_CLK[1];
	assign 	{St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar} = {5'b11111};
	
	wire inDisplayArea;
	wire [9:0] CounterX;
	wire [9:0] CounterY;

	hvsync_generator syncgen(.clk(clk), .reset(reset),.vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));
	
	/////////////////////////////////////////////////////////////////
	///////////////		VGA control starts here		/////////////////
	/////////////////////////////////////////////////////////////////
	reg [9:0] position;
	//reg [64:0] pieces;
	
	reg [8:0] selectedTile = 50;
	reg pawnArt [7:0][0:7] = {
	8'b01111110,
	8'b01111110,
	8'b00111100,
	8'b00011000,
	8'b00011000,
	8'b00011000,
	8'b00111100,
	8'b00011000};
	
	//00011000
	//00111000
	//01111110
	//01111110
	//00111100
	//00011000
	//00111100
	//01111110
	reg bishopArt [7:0][0:7] = {
	8'b01111110,
	8'b00111100,
	8'b00011000,
	8'b00111100,
	8'b01111110,
	8'b01111110,
	8'b00011100,
	8'b00011000};
	
	//00010000
	//00111000
	//01111110
	//11111110
	//11011100
	//00011100
	//00111110
	//01111111
	//reg [63:0] knightArt = 64'b0001000000111000011111101111111011011100000111000011111001111111;
	//reg [63:0] knightArt = 64'b1111111001111100001110000011101101111111011111100001110000001000;

	//01011010
	//01011010
	//01111110
	//01111110
	//00111100
	//00111100
	//01111110
	//01111110
	//reg [63:0] rookArt = 64'b0101101001011010011111100111111000111100001111000111111001111110;
	//reg [63:0] rookArt = 64'b0111111001111110001111000011110001111110011111100101101001011010;

	//00000000
	//10011001
	//10011001
	//11011011
	//11111111
	//11111111
	//11111111
	//01111110
	//reg [63:0] queenArt = 0000000010011001100110011101101111111111111111111111111101111110;
	//reg [63:0] queenArt = 64'b0111111011111111111111111111111111011011100110011001100100000000;
	
	//00000000
	//00011000
	//00011000
	//01111110
	//01111110
	//00011000
	//00011000
	//00011000
	//reg [63:0] kingArt = 0000000000011000000110000111111001111110000110000001100000011000
	//reg [63:0] kingArt = 64'b0001100000011000000110000111111001111110000110000001100000000000;
	
//	reg
//	
//	00011000
//	00111100
//	00011000
//	00111100
//	00111100
//	00011000
	
	/*always @(posedge DIV_CLK[21])
		begin
			if(reset)
				position<=240;
			else if(btnD && ~btnU)
				position<=position+2;
			else if(btnU && ~btnD)
				position<=position-2;	
		end*/
		
	reg R = 0;
	reg G = 0;
	reg B = 0;

	always @(CounterX or CounterY)
	begin
		R <= 0;
		G <= 1;
		B <= 0;
		if (CounterY >= 40 && CounterY < 440) 
		begin
			if (CounterX >= 120 && CounterX < 520)
			begin
				/*if ((((CounterY+10)/50) == (selectedTile / 8) + 1) && (((CounterX+30)/50) == (selectedTile % 8) + 3) && 
						(((CounterY+10) % 50 < 2) || ((CounterY+10) % 50 > 47) || ((CounterX+30) % 50 < 2) || ((CounterX+30) % 50 > 47)))
				begin
					R <= 1;
					G <= 0;
					B <= 0;
				end*/
				if ((((CounterY+10)/50) == (selectedTile / 8) + 1) && (((CounterX+30)/50) == (selectedTile % 8) + 3))
				begin
					if (((CounterY+10) % 50 >= 5) && ((CounterY+10) % 50 < 45) && ((CounterX+30) % 50 >= 5) && ((CounterX+30) % 50 < 45))
					//(bishopArt[((((CounterY+5)%50)/5) * 8) + (((CounterX+25)%50)/5)] == 1))
						begin
							if (pawnArt[(((CounterY+5)%50)/5)][(((CounterX+25)%50)/5)] == 1)
							begin
								R <= 1;
								G <= 0;
								B <= 0;
							end
							else
							begin
								R <= ((((CounterY+10)/50) + (CounterX+30)/50) %  2 == 0);
								G <= ((((CounterY+10)/50) + (CounterX+30)/50) %  2 == 0);
								B <= ((((CounterY+10)/50) + (CounterX+30)/50) %  2 == 0);
							end
						end
					else
						begin
							R <= ((((CounterY+10)/50) + (CounterX+30)/50) %  2 == 0);
							G <= ((((CounterY+10)/50) + (CounterX+30)/50) %  2 == 0);
							B <= ((((CounterY+10)/50) + (CounterX+30)/50) %  2 == 0);
						end
				end
				else
				begin
						R <= ((((CounterY+10)/50) + (CounterX+30)/50) %  2 == 0);
						G <= ((((CounterY+10)/50) + (CounterX+30)/50) %  2 == 0);
						B <= ((((CounterY+10)/50) + (CounterX+30)/50) %  2 == 0);
				end
			end
			else
			begin
				R <= 0;
				G <= 0;
				B <= 0;
			end
		end
		else
		begin
			R <= 0;
			G <= 0;
			B <= 0;
		end
	end
	
	
   //wire R = ((CounterY >= 40 && CounterY < 440) && (CounterX >= 120 && CounterX < 520) && ((((CounterY+10)/50) + (CounterX+30)/50) %  2 == 0));
	//wire G = ((CounterY >= 40 && CounterY < 440) && (CounterX >= 120 && CounterX < 520) && ((((CounterY+10)/50) + (CounterX+30)/50) %  2 == 0));
   //wire B = ((CounterY >= 40 && CounterY < 440) && (CounterX >= 120 && CounterX < 520) && ((((CounterY+10)/50) + (CounterX+30)/50) %  2 == 0));

	//wire G = ((CounterY >= 40 && CounterY < 440) && (CounterX >= 120 && CounterX < 520) && ((((CounterY-40)/50) + ((CounterX-120)/50)) %  2 == 0));
   //wire B = ((CounterY >= 40 && CounterY < 440) && (CounterX >= 120 && CounterX < 520) && ((((CounterY-40)/50) + ((CounterX-120)/50)) %  2 == 0));

   //wire G = ((CounterY >= 40 && CounterY <= 440) && (CounterX >= 120 && CounterX <= 520) && ((((CounterY-40)/50) + ((CounterX-120)/50)) %  2 == 0));
   //wire B = ((CounterY >= 40 && CounterY <= 440) && (CounterX >= 120 && CounterX <= 520) && ((((CounterY-40)/50) + ((CounterX-120)/50)) %  2 == 0));
	/*if (piece[CounterY/60 * 8 + CounterX/60] == 1) {
		R = 1;
		B = 2;
		G = 3;
	}*/

	always @(posedge clk)
	begin
		vga_r <= R & inDisplayArea;
		vga_g <= G & inDisplayArea;
		vga_b <= B & inDisplayArea;
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  VGA control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	`define QI 			2'b00
	`define QGAME_1 	2'b01
	`define QGAME_2 	2'b10
	`define QDONE 		2'b11
	
	reg [3:0] p2_score;
	reg [3:0] p1_score;
	reg [1:0] state;
	wire LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	
	assign LD0 = (p1_score == 4'b1010);
	assign LD1 = (p2_score == 4'b1010);
	
	assign LD2 = start;
	assign LD4 = reset;
	
	assign LD3 = (state == `QI);
	assign LD5 = (state == `QGAME_1);	
	assign LD6 = (state == `QGAME_2);
	assign LD7 = (state == `QDONE);
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control ends here 	 	////////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	reg 	[3:0]	SSD;
	wire 	[3:0]	SSD0, SSD1, SSD2, SSD3;
	wire 	[1:0] ssdscan_clk;
	
	assign SSD3 = 4'b1111;
	assign SSD2 = 4'b1111;
	assign SSD1 = 4'b1111;
	assign SSD0 = position[3:0];
	
	// need a scan clk for the seven segment display 
	// 191Hz (50MHz / 2^18) works well
	assign ssdscan_clk = DIV_CLK[19:18];	
	assign An0	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An1	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An2	= !( (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An3	= !( (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
			2'b00:
					SSD = SSD0;
			2'b01:
					SSD = SSD1;
			2'b10:
					SSD = SSD2;
			2'b11:
					SSD = SSD3;
		endcase 
	end	

	// and finally convert SSD_num to ssd
	reg [6:0]  SSD_CATHODES;
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES, 1'b1};
	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD)		
			4'b1111: SSD_CATHODES = 7'b1111111 ; //Nothing 
			4'b0000: SSD_CATHODES = 7'b0000001 ; //0
			4'b0001: SSD_CATHODES = 7'b1001111 ; //1
			4'b0010: SSD_CATHODES = 7'b0010010 ; //2
			4'b0011: SSD_CATHODES = 7'b0000110 ; //3
			4'b0100: SSD_CATHODES = 7'b1001100 ; //4
			4'b0101: SSD_CATHODES = 7'b0100100 ; //5
			4'b0110: SSD_CATHODES = 7'b0100000 ; //6
			4'b0111: SSD_CATHODES = 7'b0001111 ; //7
			4'b1000: SSD_CATHODES = 7'b0000000 ; //8
			4'b1001: SSD_CATHODES = 7'b0000100 ; //9
			4'b1010: SSD_CATHODES = 7'b0001000 ; //10 or A
			default: SSD_CATHODES = 7'bXXXXXXX ; // default is not needed as we covered all cases
		endcase
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
endmodule
