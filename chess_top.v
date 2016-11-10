`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Alex Allsup & Kevin Wu
// 
// Create Date:    17:37:14 11/09/2016 
// Design Name: 
// Module Name:    chess_top 
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
module chess_top( MemOE, MemWR, RamCS, FlashCS, QuadSpiFlashCS, // Disable the three memory chips
      ClkPort, Reset,
		BtnL, BtnU, BtnD, BtnR, BtnC       
    );
	 
/*  INPUTS */
// Clock & Reset I/O
input		ClkPort, Reset;	
input		BtnL, BtnU, BtnD, BtnR, BtnC;	

/* OUTPUTS */
output 	MemOE, MemWR, RamCS, FlashCS, QuadSpiFlashCS; // just to disable them all
 
/* Piece Definitions */
localparam PIECE_NONE 	= 3'b000;
localparam PIECE_PAWN	= 3'b001;
localparam PIECE_KNIGHT	= 3'b010;
localparam PIECE_BISHOP	= 3'b011;
localparam PIECE_ROOK	= 3'b100;
localparam PIECE_QUEEN	= 3'b101;
localparam PIECE_KING	= 3'b110;

localparam COLOR_WHITE	= 0;
localparam COLOR_BLACK	= 1;

/* Setup Board */
reg [3:0] board[63:0];

initial
begin: INITIALIZE_BOARD
	board[6'b111_000] = { COLOR_WHITE, PIECE_ROOK };
	board[6'b111_001] = { COLOR_WHITE, PIECE_KNIGHT };
	board[6'b111_010] = { COLOR_WHITE, PIECE_BISHOP };
	board[6'b111_011] = { COLOR_WHITE, PIECE_QUEEN };
	board[6'b111_100] = { COLOR_WHITE, PIECE_KING };
	board[6'b111_101] = { COLOR_WHITE, PIECE_BISHOP };
	board[6'b111_110] = { COLOR_WHITE, PIECE_KNIGHT };
	board[6'b111_111] = { COLOR_WHITE, PIECE_ROOK };
	
	board[6'b110_000] = { COLOR_WHITE, PIECE_PAWN };
	board[6'b110_001] = { COLOR_WHITE, PIECE_PAWN };
	board[6'b110_010] = { COLOR_WHITE, PIECE_PAWN };
	board[6'b110_011] = { COLOR_WHITE, PIECE_PAWN };
	board[6'b110_100] = { COLOR_WHITE, PIECE_PAWN };
	board[6'b110_101] = { COLOR_WHITE, PIECE_PAWN };
	board[6'b110_110] = { COLOR_WHITE, PIECE_PAWN };
	board[6'b110_111] = { COLOR_WHITE, PIECE_PAWN };
	
	board[6'b101_000] = { COLOR_WHITE, PIECE_NONE };
	board[6'b101_001] = { COLOR_WHITE, PIECE_NONE };
	board[6'b101_010] = { COLOR_WHITE, PIECE_NONE };
	board[6'b101_011] = { COLOR_WHITE, PIECE_NONE };
	board[6'b101_100] = { COLOR_WHITE, PIECE_NONE };
	board[6'b101_101] = { COLOR_WHITE, PIECE_NONE };
	board[6'b101_110] = { COLOR_WHITE, PIECE_NONE };
	board[6'b101_111] = { COLOR_WHITE, PIECE_NONE };
	
	board[6'b100_000] = { COLOR_WHITE, PIECE_NONE };
	board[6'b100_001] = { COLOR_WHITE, PIECE_NONE };
	board[6'b100_010] = { COLOR_WHITE, PIECE_NONE };
	board[6'b100_011] = { COLOR_WHITE, PIECE_NONE };
	board[6'b100_100] = { COLOR_WHITE, PIECE_NONE };
	board[6'b100_101] = { COLOR_WHITE, PIECE_NONE };
	board[6'b100_110] = { COLOR_WHITE, PIECE_NONE };
	board[6'b100_111] = { COLOR_WHITE, PIECE_NONE };
	
	board[6'b011_000] = { COLOR_WHITE, PIECE_NONE };
	board[6'b011_001] = { COLOR_WHITE, PIECE_NONE };
	board[6'b011_010] = { COLOR_WHITE, PIECE_NONE };
	board[6'b011_011] = { COLOR_WHITE, PIECE_NONE };
	board[6'b011_100] = { COLOR_WHITE, PIECE_NONE };
	board[6'b011_101] = { COLOR_WHITE, PIECE_NONE };
	board[6'b011_110] = { COLOR_WHITE, PIECE_NONE };
	board[6'b011_111] = { COLOR_WHITE, PIECE_NONE };
	
	board[6'b010_000] = { COLOR_WHITE, PIECE_NONE };
	board[6'b010_001] = { COLOR_WHITE, PIECE_NONE };
	board[6'b010_010] = { COLOR_WHITE, PIECE_NONE };
	board[6'b010_011] = { COLOR_WHITE, PIECE_NONE };
	board[6'b010_100] = { COLOR_WHITE, PIECE_NONE };
	board[6'b010_101] = { COLOR_WHITE, PIECE_NONE };
	board[6'b010_110] = { COLOR_WHITE, PIECE_NONE };
	board[6'b010_111] = { COLOR_WHITE, PIECE_NONE };
	
	board[6'b001_000] = { COLOR_BLACK, PIECE_PAWN };
	board[6'b001_001] = { COLOR_BLACK, PIECE_PAWN };
	board[6'b001_010] = { COLOR_BLACK, PIECE_PAWN };
	board[6'b001_011] = { COLOR_BLACK, PIECE_PAWN };
	board[6'b001_100] = { COLOR_BLACK, PIECE_PAWN };
	board[6'b001_101] = { COLOR_BLACK, PIECE_PAWN };
	board[6'b001_110] = { COLOR_BLACK, PIECE_PAWN };
	board[6'b001_111] = { COLOR_BLACK, PIECE_PAWN };
	
	board[6'b000_000] = { COLOR_BLACK, PIECE_ROOK };
	board[6'b000_001] = { COLOR_BLACK, PIECE_KNIGHT };
	board[6'b000_010] = { COLOR_BLACK, PIECE_BISHOP };
	board[6'b000_011] = { COLOR_BLACK, PIECE_QUEEN };
	board[6'b000_100] = { COLOR_BLACK, PIECE_KING };
	board[6'b000_101] = { COLOR_BLACK, PIECE_BISHOP };
	board[6'b000_110] = { COLOR_BLACK, PIECE_KNIGHT };
	board[6'b000_111] = { COLOR_BLACK, PIECE_ROOK };
	
end


endmodule
