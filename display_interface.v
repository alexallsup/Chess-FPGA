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

reg [7:0] output_color;
output wire HSYNC, VSYNC;
output wire [2:0] R;
output wire [2:0] G;
output wire [1:0] B;
assign R = {
	output_color[7] & inDisplayArea,
	output_color[6] & inDisplayArea,
	output_color[5] & inDisplayArea
};
assign G = {
	output_color[4] & inDisplayArea,
	output_color[3] & inDisplayArea,
	output_color[2] & inDisplayArea
};
assign B = {
	output_color[1] & inDisplayArea,
	output_color[0] & inDisplayArea
};

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

// INIT the sync generator and its support wires
wire inDisplayArea;
wire [9:0] CounterX;
wire [9:0] CounterY;
hvsync_generator syncgen(.clk(CLK), .reset(RESET),
	.vga_h_sync(HSYNC), 
	.vga_v_sync(VSYNC), 
	.inDisplayArea(inDisplayArea), 
	.CounterX(CounterX), 
	.CounterY(CounterY));

/* Piece Definitions */
localparam PIECE_NONE   = 3'b000;
localparam PIECE_PAWN   = 3'b001;
localparam PIECE_KNIGHT = 3'b010;
localparam PIECE_BISHOP = 3'b011;
localparam PIECE_ROOK   = 3'b100;
localparam PIECE_QUEEN  = 3'b101;
localparam PIECE_KING   = 3'b110;

localparam COLOR_WHITE  = 0;
localparam COLOR_BLACK  = 1;

// ARTWORK
localparam pawnArt [0:7][0:7] = {
	8'b00000000,
	8'b00000000,
	8'b00000000,
	8'b00000000,
	8'b00011000,
	8'b00111100,
	8'b01111110,
	8'b01111110
};

localparam bishopArt [0:7][0:7] = {
	8'b00000000,
	8'b00011000,
	8'b00111100,
	8'b00111100,
	8'b00011000,
	8'b00011000,
	8'b00111100,
	8'b11100111
};

localparam knightArt [0:7][0:7] = { 
	8'b00011000,
	8'b01111100,
	8'b11111110,
	8'b11101111,
	8'b00000111,
	8'b00011111,
	8'b00111111,
	8'b01111110
};

localparam queenArt [0:7][0:7] = { 
	8'b00000000,
	8'b01010101,
	8'b01010101,
	8'b01010101,
	8'b01010101,
	8'b01111111,
	8'b01111111,
	8'b01111111
};

localparam kingArt [0:7][0:7] = { 
	8'b00011000,
	8'b01111110,
	8'b00011000,
	8'b00011000,
	8'b00111100,
	8'b01111110,
	8'b01111110,
	8'b00111100
};

localparam rookArt [0:7][0:7] = { 
	8'b00000000,
	8'b01011010,
	8'b01111110,
	8'b00111100,
	8'b00011000,
	8'b00011000,
	8'b00111100,
	8'b01111110
};

localparam RGB_OUTSIDE = 8'b000_000_00; 
localparam RGB_DARK_SQ = 8'b101_000_00; 
localparam RGB_LIGHT_SQ = 8'b111_110_10; 
localparam RGB_BLACK_PIECE = 8'b001_001_01; 
localparam RGB_WHITE_PIECE = 8'b111_111_11; // white
localparam RGB_CURSOR = 8'b000_000_11; // blue
localparam RGB_SELECTED = 8'b111_000_00; // not sure

// Drawing values for the board
reg [2:0] counter_row;
reg [2:0] counter_col;
reg [6:0] square_x; // coords of the counter within the board square
reg [6:0] square_y;
reg [4:0] art_x; // coords on 8x8 artwork grid within the square
reg [4:0] art_y; 
wire in_square_border;
wire in_board;
wire dark_square; // hi if cursor on dark square, lo if on light square

always @(CounterX) begin
	if 	  (CounterX <= 170) begin
		counter_col <= 0;
		square_x <= CounterX - 120;
	end
	else if (CounterX <= 220)  begin
		counter_col <= 1;
		square_x <= CounterX - 170;
	end
	else if (CounterX <= 270)  begin
		counter_col <= 2;
		square_x <= CounterX - 220;
	end
	else if (CounterX <= 320)  begin
		counter_col <= 3;
		square_x <= CounterX - 270;
	end
	else if (CounterX <= 370)  begin
		counter_col <= 4;
		square_x <= CounterX - 320;
	end
	else if (CounterX <= 420)  begin
		counter_col <= 5;
		square_x <= CounterX - 370;
	end
	else if (CounterX <= 470)  begin
		counter_col <= 6;
		square_x <= CounterX - 420;
	end
	else 							   begin
		counter_col <= 7;
		square_x <= CounterX - 470;
	end
end

always @(CounterY) begin
	if 	  (CounterY <=  90) begin counter_row <= 0; square_y <= CounterY - 40; end
	else if (CounterY <= 140) begin counter_row <= 1; square_y <= CounterY - 90; end
	else if (CounterY <= 190) begin counter_row <= 2; square_y <= CounterY - 140; end
	else if (CounterY <= 240) begin counter_row <= 3; square_y <= CounterY - 190; end
	else if (CounterY <= 290) begin counter_row <= 4; square_y <= CounterY - 240; end
	else if (CounterY <= 340) begin counter_row <= 5; square_y <= CounterY - 290; end
	else if (CounterY <= 390) begin counter_row <= 6; square_y <= CounterY - 340; end
	else 							  begin counter_row <= 7; square_y <= CounterY - 390; end
end

always @(square_x) begin
	if 	  (square_x <= 10) art_x <= 0;
	else if (square_x <= 15) art_x <= 1;
	else if (square_x <= 20) art_x <= 2;
	else if (square_x <= 25) art_x <= 3;
	else if (square_x <= 30) art_x <= 4;
	else if (square_x <= 35) art_x <= 5;
	else if (square_x <= 40) art_x <= 6;
	else 							 art_x <= 7;	
end
always @(square_y) begin
	if 	  (square_y <= 10) art_y <= 0;
	else if (square_y <= 15) art_y <= 1;
	else if (square_y <= 20) art_y <= 2;
	else if (square_y <= 25) art_y <= 3;
	else if (square_y <= 30) art_y <= 4;
	else if (square_y <= 35) art_y <= 5;
	else if (square_y <= 40) art_y <= 6;
	else 							 art_y <= 7;	
end
assign in_square_border = (   square_x <= 5 
									|| square_x >= 45
									||	square_y <= 5 
									|| square_y >= 45);
assign in_board = (CounterX >= 120 && CounterX < 520)
					 &&(CounterY >= 40  && CounterY < 440);
assign dark_square = counter_row[0] ^ counter_col[0]; // bit of a hack

// Set the pixel colors based on the Counter positions
always @(posedge CLK) begin
	if (!in_board) output_color <= RGB_OUTSIDE;
	else begin
		if (in_square_border) begin
			if (CURSOR_ADDR == { counter_row, counter_col }) 
				output_color <= RGB_CURSOR;
			else if (in_square_border && SELECT_ADDR == { counter_row, counter_col } && SELECT_EN)
				output_color <= RGB_SELECTED;
			else if (dark_square) 
				output_color <= RGB_DARK_SQ;
			else
				output_color <= RGB_LIGHT_SQ;
		end
		else begin
			// we are inside the drawable area of a square
			case (board[{counter_row, counter_col}][2:0])
				PIECE_NONE  : begin
					if (dark_square) 
						output_color <= RGB_DARK_SQ;
					else
						output_color <= RGB_LIGHT_SQ;
				end
				PIECE_PAWN  : begin
					if (pawnArt[art_y][art_x]) begin
						if(board[{counter_row, counter_col}][3] == COLOR_BLACK)
							output_color <= RGB_BLACK_PIECE;
						else
							output_color <= RGB_WHITE_PIECE;
					end
					else begin
						if (dark_square) 
							output_color <= RGB_DARK_SQ;
						else
							output_color <= RGB_LIGHT_SQ;
					end
				end
				PIECE_KNIGHT: begin
					if (knightArt[art_y][art_x]) begin
						if(board[{counter_row, counter_col}][3] == COLOR_BLACK)
							output_color <= RGB_BLACK_PIECE;
						else
							output_color <= RGB_WHITE_PIECE;
					end
					else begin
						if (dark_square) 
							output_color <= RGB_DARK_SQ;
						else
							output_color <= RGB_LIGHT_SQ;
					end
				end
				PIECE_BISHOP: begin
					if (bishopArt[art_y][art_x]) begin
						if(board[{counter_row, counter_col}][3] == COLOR_BLACK)
							output_color <= RGB_BLACK_PIECE;
						else
							output_color <= RGB_WHITE_PIECE;
					end
					else begin
						if (dark_square) 
							output_color <= RGB_DARK_SQ;
						else
							output_color <= RGB_LIGHT_SQ;
					end
				end
				PIECE_ROOK  : begin
					if (rookArt[art_y][art_x]) begin
						if(board[{counter_row, counter_col}][3] == COLOR_BLACK)
							output_color <= RGB_BLACK_PIECE;
						else
							output_color <= RGB_WHITE_PIECE;
					end
					else begin
						if (dark_square) 
							output_color <= RGB_DARK_SQ;
						else
							output_color <= RGB_LIGHT_SQ;
					end
				end
				PIECE_QUEEN : begin
					if (queenArt[art_y][art_x]) begin
						if(board[{counter_row, counter_col}][3] == COLOR_BLACK)
							output_color <= RGB_BLACK_PIECE;
						else
							output_color <= RGB_WHITE_PIECE;
					end
					else begin
						if (dark_square) 
							output_color <= RGB_DARK_SQ;
						else
							output_color <= RGB_LIGHT_SQ;
					end
				end
				PIECE_KING  : begin
					if (kingArt[art_y][art_x]) begin
						if(board[{counter_row, counter_col}][3] == COLOR_BLACK)
							output_color <= RGB_BLACK_PIECE;
						else
							output_color <= RGB_WHITE_PIECE;
					end
					else begin
						if (dark_square) 
							output_color <= RGB_DARK_SQ;
						else
							output_color <= RGB_LIGHT_SQ;
					end
				end
				default: output_color <= RGB_OUTSIDE;
			endcase
		end
	end
end

endmodule
