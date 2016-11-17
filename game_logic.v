`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Alex Allsup
// 
// Create Date:    17:40:01 11/09/2016 
// Design Name: 
// Module Name:    game_logic 
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
module game_logic(
    CLK, RESET,
    board_input,
    board_out_addr,
    board_out_piece,
    board_change_enable, // allow the board to update its value on next clock
    BtnL, // All button inputs shall have been debounced & made a single clk pulse outside this module
    BtnU,
    BtnR,
    BtnD,
    BtnC,
    cursor_addr,
    selected_piece_addr,
    hilite_selected_square
    );

/* Inputs */
input wire CLK, RESET;
input wire BtnL, BtnU, BtnR, BtnD, BtnC;

input wire [255:0] board_input;

wire[3:0] board[63:0];
genvar i;
generate for (i=0; i<64; i=i+1) begin: BOARD
	assign board[i] = board_input[i*4+3 : i*4];
end
endgenerate

/* Outputs */ 
// outputs for communicating with the board register in top
output reg[5:0] board_out_addr;
output reg[3:0] board_out_piece;
output reg board_change_enable; // signal the board reg in top to write the new piece to the addr

// outputs for communicating with the VGA module
output reg[5:0] cursor_addr;
output reg[5:0] selected_piece_addr;
output reg hilite_selected_square;

// wires for the contents of the board input
wire[3:0] cursor_contents, selected_contents;
assign cursor_contents = board_input[cursor_addr]; // contents of the cursor square
assign selected_contents = board_input[selected_piece_addr]; // contents of the selected square

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

/* DPU registers */
reg player_to_move;
reg white_can_castle_long, white_can_castle_short, // moving a rook or king removes castling rights
    black_can_castle_long, black_can_castle_short; // so we need flags to track it

/* State Machine Definition */
// we're gonna use encoded-assignment bc I can
localparam INITIAL = 3'b000,
    PIECE_SEL = 3'b001, PIECE_MOVE= 3'b010,
    WRITE_NEW_PIECE = 3'b011, ERASE_OLD_PIECE = 3'b100, CASTLE = 3'b101;
reg[2:0] state;

// need sub-state machine for castling since it moves two pieces & requires four ops
localparam WRITE_KING = 2'b00, ERASE_KING = 2'b01, WRITE_ROOK = 2'b10, ERASE_ROOK = 2'b11;
reg[1:0] castle_state;

/* State Machine NSL and OFL */
always @ (posedge CLK, posedge RESET) begin
    if (RESET) begin
        // initialization code here
        state <= INITIAL;
        castle_state <= 2'bXX;
        player_to_move <= COLOR_WHITE;
        white_can_castle_short <= 1;
        white_can_castle_long  <= 1;
        black_can_castle_short <= 1;
        black_can_castle_long  <= 1;
        
        cursor_addr <= 6'b110_100; // white's king pawn, most common starting move
        selected_piece_addr <= 6'bXXXXXX;
        hilite_selected_square <= 0;

        board_out_addr <= 6'bXXXXXX;
        board_out_piece <= 4'bXXXX;
        board_change_enable <= 0;
    end
    else begin
        case (state)
            INITIAL :
            begin
                // State Transitions
                state <= PIECE_SEL; // unconditional

                // RTL operations
            end

            PIECE_SEL:
            begin
                // State Transitions
                if (BtnC 
                    && cursor_contents[3] == player_to_move
                    && cursor_contents[2:0] != 3'b000) // TODO verify addressing
                        state <= PIECE_MOVE;
                // else we remain in this state

                // RTL operations
                if (BtnC 
                    && cursor_contents[3] == player_to_move
                    && cursor_contents[2:0] != 3'b000) // TODO verify addressing
                begin
                    selected_piece_addr <= cursor_addr;
                    hilite_selected_square <= 1;
                end
            end

            PIECE_MOVE:
            begin
                // State Transitions
                if (BtnC) begin
                    if (cursor_contents[3] != player_to_move
                        || cursor_contents[2:0] == 3'b000)
                        state <= WRITE_NEW_PIECE; // either the other color pieces or an empty square
                    // if the player clicked their own piece, we remain here and select that piece
                end
                // else remain in this state 

                // RTL operations
                if (BtnC) begin
                    if (cursor_contents[3] != player_to_move
                        || cursor_contents[2:0] == 3'b000)
                    begin
                        // they clicked either an empty space of the other color piece
                        // going to WRITE_NEW_PIECE
                        board_out_addr <= cursor_contents;
                        board_out_piece <= selected_contents;
                        board_change_enable <= 1;
                    end
                    else if (cursor_contents[3] == player_to_move
                        || cursor_contents[2:0] == 3'b000)
                    begin
                        // they clicked their own piece
                        selected_piece_addr <= cursor_addr;
                    end
                end
            end

            WRITE_NEW_PIECE:
            begin
                // State Transitions
                state <= ERASE_OLD_PIECE;

                // RTL operations
                // going to ERASE_OLD_PIECE
                board_change_enable <= 1; // already done but it doesn't hurt here
                board_out_addr <= selected_piece_addr;
                board_out_piece <= 4'b0000; // no piece
            end

            ERASE_OLD_PIECE:
            begin
                // State Transitions
                state <= PIECE_SEL;

                // RTL operations
                board_change_enable <= 0;
                board_out_addr <= 6'bXXXXXX;
                board_out_piece <= 4'bXXXX;

                player_to_move <= ~player_to_move;
            end

            CASTLE:
            begin
                // TODO implement castling.
                // this will be a sub-state machine to handle the four different states
            end
			endcase
	 
		 /* Cursor Movement Controls */
		 if (BtnL && cursor_addr[2:0] != 3'b000) cursor_addr <= cursor_addr - 6'b000_001;
		 else if (BtnR && cursor_addr[2:0] != 3'b111) cursor_addr <= cursor_addr + 6'b000_001;
		 else if (BtnU && cursor_addr[5:3] != 3'b000) cursor_addr <= cursor_addr - 6'b001_000;
		 else if (BtnD && cursor_addr[5:3] != 3'b111) cursor_addr <= cursor_addr + 6'b001_000;
    end
end


endmodule
