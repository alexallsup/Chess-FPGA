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
      ClkPort, // ClkPort will be the board's 100MHz clk
		BtnL, BtnU, BtnD, BtnR, BtnC,
		Sw0, // For reset   
		vga_hsync, vga_vsync, 
		vga_r0, vga_r1, vga_r2,
		vga_g0, vga_g1, vga_g2,
		vga_b0, vga_b1,
		Ld0, Ld1, Ld2, Ld3, Ld4
    );
	 
/*  INPUTS */
// Clock & Reset I/O
input		Sw0;	
input		BtnL, BtnU, BtnD, BtnR, BtnC;	
wire Reset;
assign Reset = Sw0;

/* OUTPUTS */
output wire	MemOE, MemWR, RamCS, FlashCS, QuadSpiFlashCS; // just to disable them all
	assign MemOE = 0;
	assign MemWR = 0;
	assign RamCS = 0;
	assign FlashCS = 0;
	assign QuadSpiFlashCS = 0;
output wire vga_hsync, vga_vsync; 
output wire vga_r0, vga_r1, vga_r2;
output wire vga_g0, vga_g1, vga_g2;
output wire vga_b0, vga_b1;
output wire Ld0, Ld1, Ld2, Ld3, Ld4;

// connect the vga color buses to the top design's outputs
wire[2:0] vga_r;
wire[2:0] vga_g;
wire[1:0] vga_b;
assign vga_r0 = vga_r[2]; assign vga_r1 = vga_r[1]; assign vga_r2 = vga_r[0];
assign vga_g0 = vga_g[2]; assign vga_g1 = vga_g[1]; assign vga_g2 = vga_b[0];
assign vga_b0 = vga_b[1]; assign vga_b1 = vga_b[0];


/* Clocking */
input ClkPort;
reg[26:0] DIV_CLK;
wire full_clock;
BUFGP CLK_BUF(full_clock, ClkPort);

always @(posedge full_clock, posedge Reset)
begin
	if (Reset) DIV_CLK <= 0;
	else DIV_CLK <= DIV_CLK + 1'b1;
end

wire game_logic_clk, vga_clk, debounce_clk;
assign game_logic_clk = DIV_CLK[11]; // 24.4 kHz 
assign vga_clk = DIV_CLK[1]; // 25MHz for pixel freq
assign debounce_clk = DIV_CLK[11]; // 24.4 kHz; needs to match game_logic for the single clock pulses

/* Init debouncer */
wire BtnC_pulse, BtnU_pulse, BtnR_pulse, BtnL_pulse, BtnD_pulse;
input_debounce L_debounce(
	.CLK(debounce_clk), .RESET(Reset),
	.Btn(BtnL), .Btn_pulse(BtnL_pulse));
input_debounce R_debounce(
	.CLK(debounce_clk), .RESET(Reset),
	.Btn(BtnR), .Btn_pulse(BtnR_pulse));
input_debounce U_debounce(
	.CLK(debounce_clk), .RESET(Reset),
	.Btn(BtnU), .Btn_pulse(BtnU_pulse));
input_debounce D_debounce(
	.CLK(debounce_clk), .RESET(Reset),
	.Btn(BtnD), .Btn_pulse(BtnD_pulse));
input_debounce C_debounce(
	.CLK(debounce_clk), .RESET(Reset),
	.Btn(BtnC), .Btn_pulse(BtnC_pulse));

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
wire [255:0] passable_board;

genvar i;
generate for (i=0; i<64; i=i+1) begin: BOARD
	assign passable_board[i*4+3 : i*4] = board[i];
end
endgenerate

always @(posedge game_logic_clk)
begin 
	if (~Reset) begin if (board_change_enable) board[board_change_addr] <= board_change_piece; end
	else begin
	board[6'b111_000] <= { COLOR_WHITE, PIECE_ROOK };
	board[6'b111_001] <= { COLOR_WHITE, PIECE_KNIGHT };
	board[6'b111_010] <= { COLOR_WHITE, PIECE_BISHOP };
	board[6'b111_011] <= { COLOR_WHITE, PIECE_QUEEN };
	board[6'b111_100] <= { COLOR_WHITE, PIECE_KING };
	board[6'b111_101] <= { COLOR_WHITE, PIECE_BISHOP };
	board[6'b111_110] <= { COLOR_WHITE, PIECE_KNIGHT };
	board[6'b111_111] <= { COLOR_WHITE, PIECE_ROOK };
	
	board[6'b110_000] <= { COLOR_WHITE, PIECE_PAWN };
	board[6'b110_001] <= { COLOR_WHITE, PIECE_PAWN };
	board[6'b110_010] <= { COLOR_WHITE, PIECE_PAWN };
	board[6'b110_011] <= { COLOR_WHITE, PIECE_PAWN };
	board[6'b110_100] <= { COLOR_WHITE, PIECE_PAWN };
	board[6'b110_101] <= { COLOR_WHITE, PIECE_PAWN };
	board[6'b110_110] <= { COLOR_WHITE, PIECE_PAWN };
	board[6'b110_111] <= { COLOR_WHITE, PIECE_PAWN };
	
	board[6'b101_000] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b101_001] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b101_010] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b101_011] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b101_100] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b101_101] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b101_110] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b101_111] <= { COLOR_WHITE, PIECE_NONE };
	
	board[6'b100_000] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b100_001] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b100_010] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b100_011] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b100_100] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b100_101] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b100_110] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b100_111] <= { COLOR_WHITE, PIECE_NONE };
	
	board[6'b011_000] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b011_001] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b011_010] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b011_011] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b011_100] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b011_101] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b011_110] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b011_111] <= { COLOR_WHITE, PIECE_NONE };
	
	board[6'b010_000] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b010_001] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b010_010] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b010_011] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b010_100] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b010_101] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b010_110] <= { COLOR_WHITE, PIECE_NONE };
	board[6'b010_111] <= { COLOR_WHITE, PIECE_NONE };
	
	board[6'b001_000] <= { COLOR_BLACK, PIECE_PAWN };
	board[6'b001_001] <= { COLOR_BLACK, PIECE_PAWN };
	board[6'b001_010] <= { COLOR_BLACK, PIECE_PAWN };
	board[6'b001_011] <= { COLOR_BLACK, PIECE_PAWN };
	board[6'b001_100] <= { COLOR_BLACK, PIECE_PAWN };
	board[6'b001_101] <= { COLOR_BLACK, PIECE_PAWN };
	board[6'b001_110] <= { COLOR_BLACK, PIECE_PAWN };
	board[6'b001_111] <= { COLOR_BLACK, PIECE_PAWN };
	
	board[6'b000_000] <= { COLOR_BLACK, PIECE_ROOK };
	board[6'b000_001] <= { COLOR_BLACK, PIECE_KNIGHT };
	board[6'b000_010] <= { COLOR_BLACK, PIECE_BISHOP };
	board[6'b000_011] <= { COLOR_BLACK, PIECE_QUEEN };
	board[6'b000_100] <= { COLOR_BLACK, PIECE_KING };
	board[6'b000_101] <= { COLOR_BLACK, PIECE_BISHOP };
	board[6'b000_110] <= { COLOR_BLACK, PIECE_KNIGHT };
	board[6'b000_111] <= { COLOR_BLACK, PIECE_ROOK };
	end
end

/* Init game logic module and its output wires */
wire[5:0] board_change_addr;
wire[3:0] board_change_piece;
wire board_change_enable;
wire[5:0] cursor_addr;
wire[5:0] selected_piece_addr;
wire hilite_selected_square;

wire[3:0] logic_state;
assign { Ld3, Ld2, Ld1, Ld0 } = logic_state;

game_logic logic_module(
	.CLK(game_logic_clk), 
	.RESET(Reset),
	.board_input(passable_board),

	.board_out_addr(board_change_addr),
	.board_out_piece(board_change_piece),
	.board_change_enable(board_change_enable),
	.cursor_addr(cursor_addr),
	.selected_addr(selected_piece_addr),
	.hilite_selected_square(hilite_selected_square),

	.BtnU(BtnU_pulse), .BtnL(BtnL_pulse), .BtnC(BtnC_pulse),
	.BtnR(BtnR_pulse), .BtnD(BtnD_pulse),
	.state(logic_state), .move_is_legal(Ld4)
	);


/* Init VGA interface */
display_interface display_interface(
	.CLK(vga_clk), // 25 MHz
	.RESET(Reset),
	.HSYNC(vga_hsync), // direct outputs to VGA monitor
	.VSYNC(vga_vsync),
	.R(vga_r),
	.G(vga_g),
	.B(vga_b),
	.BOARD(passable_board), // the 64x4 array for the board contents
	.CURSOR_ADDR(cursor_addr), // 6 bit address showing what square to hilite
	.SELECT_ADDR(selected_piece_addr), // 6b address showing the address of which piece is selected
	.SELECT_EN(hilite_selected_square)); // binary flag to show a selected piece
	
endmodule
