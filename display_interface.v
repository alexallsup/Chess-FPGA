`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Alex Allsup & Kevin Wu
// 
// Create Date:    17:41:01 11/09/2016 
// Design Name: 
// Module Name:    display_interface 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module display_interface(
    CLK, RESET,
	 HSYNC, VSYNC, R, G, B,
	 BOARD, 
	 CURSOR_ADDR, SELECT_ADDR, SELECT_EN
    );
	 
input wire CLK, RESET;

output reg HSYNC, VSYNC;
output reg [2:0] R;
output reg [2:0] G;
output reg [1:0] B;

input wire [5:0] CURSOR_ADDR;
input wire [5:0] SELECT_ADDR;
input wire SELECT_EN;

// BOARD is the incoming 64 bus from the top's board reg
// board will be re-vectored into a 64x4 for ease of use
input wire [255:0] BOARD;
wire[3:0] board[63:0];
genvar i;
generate for (i=0; i<64; i=i+1) begin: REWIRE_BOARD
	assign board[i] = BOARD[i*4+3 : i*4];
end
endgenerate

always @(posedge RESET) begin
	// need to give some dummy vals for now
	/*if (board[6'b000_101] == 3'b101) begin
	R <= 3'b000;
	G <= 3'b000;
	B <= 2'b00;*/
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
	if (CURSOR_ADDR > 0) HSYNC <= 0;
	if (SELECT_ADDR > 0) VSYNC <= 0;
	else if (SELECT_EN) VSYNC <= 1;
	else if (CLK) VSYNC <= 0;
end

endmodule
