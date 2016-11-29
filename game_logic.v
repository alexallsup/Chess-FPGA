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
    selected_addr,
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
output reg[5:0] selected_addr;
output reg hilite_selected_square;

// wires for the contents of the board input
wire[3:0] cursor_contents, selected_contents;
assign cursor_contents = board[cursor_addr]; // contents of the cursor square
assign selected_contents = board[selected_addr]; // contents of the selected square

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

reg move_is_legal; // signal will be generated in combinational logic

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
        selected_addr <= 6'bXXXXXX;
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
                    && cursor_contents[2:0] != PIECE_NONE) // TODO verify addressing
                        state <= PIECE_MOVE;
                // else we remain in this state

                // RTL operations
                if (BtnC 
                    && cursor_contents[3] == player_to_move
                    && cursor_contents[2:0] != PIECE_NONE) // TODO verify addressing
                begin
                    selected_addr <= cursor_addr;
                    hilite_selected_square <= 1;
                end
            end

            PIECE_MOVE:
            begin
                // State Transitions
                if (BtnC) begin
                    if (cursor_contents[3] != player_to_move
                        || cursor_contents[2:0] == PIECE_NONE)
                        state <= WRITE_NEW_PIECE; // either the other color pieces or an empty square
                    // if the player clicked their own piece, we remain here and select that piece
                end
                // else remain in this state 

                // RTL operations
                if (BtnC) begin
                    if (selected_contents[2:0] == PIECE_KING)
                    begin
                        // see if we want to castle 
                        if (selected_contents[3] == COLOR_WHITE
                            && white_can_castle_short
                            && selected_addr == 6'b111_100 // king is on home
                            && cursor_addr == 6'b111_110 // target castle square
                            && board[6'b111_101][2:0] == PIECE_NONE // no obstructions
                            && board[6'b111_110][2:0] == PIECE_NONE
                            && board[6'b111_111] == {COLOR_WHITE, PIECE_ROOK}
                            && player_to_move == COLOR_WHITE) begin
                                // WHITE CASTLES SHORT
                                castle_state <= WRITE_KING;
                                board_out_addr <= 6'b111_110;
                                board_out_piece <= {COLOR_WHITE, PIECE_KING};
                                board_change_enable <= 1;
                            end

                        else if(selected_contents[3] == COLOR_WHITE
                            && white_can_castle_long
                            && selected_addr == 6'b111_100 // king is on home
                            && cursor_addr == 6'b111_010 // target castle square
                            && board[6'b111_001][2:0] == PIECE_NONE
                            && board[6'b111_010][2:0] == PIECE_NONE // no obstructions
                            && board[6'b111_011][2:0] == PIECE_NONE
                            && board[6'b111_000] == {COLOR_WHITE, PIECE_ROOK}
                            && player_to_move == COLOR_WHITE) begin
                                // WHITE CASTLES LONG
                                castle_state <= WRITE_KING;
                                board_out_addr <= 6'b111_010;
                                board_out_piece <= {COLOR_WHITE, PIECE_KING};
                                board_change_enable <= 1;
                            end

                        else if (selected_contents[3] == COLOR_BLACK
                            && black_can_castle_short
                            && selected_addr == 6'b000_100 // king is on home
                            && cursor_addr == 6'b000_110 // target castle square
                            && board[6'b000_101][2:0] == PIECE_NONE // no obstructions
                            && board[6'b000_110][2:0] == PIECE_NONE
                            && board[6'b000_111] == {COLOR_BLACK, PIECE_ROOK}
                            && player_to_move == COLOR_BLACK) begin
                                // BLACK CASTLES SHORT
                                castle_state <= WRITE_KING;
                                board_out_addr <= 6'b000_110;
                                board_out_piece <= {COLOR_BLACK, PIECE_KING};
                                board_change_enable <= 1;
                            end

                        else if(selected_contents[3] == COLOR_WHITE
                            && black_can_castle_long
                            && selected_addr == 6'b000_100 // king is on home
                            && cursor_addr == 6'b000_010 // target castle square
                            && board[6'b000_001][2:0] == PIECE_NONE
                            && board[6'b000_010][2:0] == PIECE_NONE // no obstructions
                            && board[6'b000_011][2:0] == PIECE_NONE
                            && board[6'b000_000] == {COLOR_WHITE, PIECE_ROOK}
                            && player_to_move == COLOR_WHITE) begin
                                // BLACK CASTLES LONG
                                castle_state <= WRITE_KING;
                                board_out_addr <= 6'b000_010;
                                board_out_piece <= {COLOR_BLACK, PIECE_KING};
                                board_change_enable <= 1;
                            end
                        else if(move_is_legal)
                            // for normal king move
                            // state going to WRITE_NEW_PIECE  
                            board_out_addr <= cursor_contents;
                            board_out_piece <= selected_contents;
                            board_change_enable <= 1;

                            // revoke castle rights:
                            if(selected_contents[3] == COLOR_WHITE) begin
                                white_can_castle_short <= 0;
                                white_can_castle_long  <= 0;
                            end
                            else if(selected_contents[3] == COLOR_BLACK) begin
                                black_can_castle_short <= 0;
                                black_can_castle_long  <= 0;
                            end
                        end
                    end
                    else if (   (cursor_contents[3] != player_to_move
                                || cursor_contents[2:0] == PIECE_NONE)
                            && move_is_legal)
                    begin
                        // they clicked either an empty space of the other color piece
                        // going to WRITE_NEW_PIECE
                        board_out_addr <= cursor_contents;
                        board_out_piece <= selected_contents;
                        board_change_enable <= 1;

                        // revoke castle rights if rook move (king move handled in the other if branch)
                        if     (selected_addr == 6'b111_000) white_can_castle_long <= 0;
                        else if(selected_addr == 6'b111_111) white_can_castle_short <= 0;
                        else if(selected_addr == 6'b000_000) black_can_castle_long <= 0;
                        else if(selected_addr == 6'b000_111) black_can_castle_short <= 0;
                    end
                    else if (cursor_contents[3] == player_to_move
                        || cursor_contents[2:0] == PIECE_NONE)
                    begin
                        // they clicked their own piece
                        selected_addr <= cursor_addr;
                    end
                
            end

            WRITE_NEW_PIECE:
            begin
                // State Transitions
                state <= ERASE_OLD_PIECE;

                // RTL operations
                // going to ERASE_OLD_PIECE
                board_change_enable <= 1; // already done but it doesn't hurt here
                board_out_addr <= selected_addr;
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
                case (castle_state)
                WRITE_KING: 
                begin
                    // king being written in last step; erase king next
                    board_out_addr <= selected_addr;
                    board_out_piece <= {COLOR_WHITE, PIECE_NONE};
                    board_change_enable <= 1;

                    castle_state <= ERASE_KING;
                end

                ERASE_KING:
                begin
                    // king being erased by last step; write rook next
                    board_change_enable <= 1;
                    castle_state <= WRITE_ROOK;

                    if(cursor_addr == 6'b111_110) begin // white short
                        board_out_addr <= 6'b111_101;
                        board_out_piece <= {COLOR_WHITE, PIECE_ROOK};
                    end
                    else if(cursor_addr == 6'b111_010) begin // white long
                        board_out_addr <= 6'b111_011;
                        board_out_piece <= {COLOR_WHITE, PIECE_ROOK};
                    end
                    else if(cursor_addr == 6'b000_110) begin // black short
                        board_out_addr <= 6'b000_101;
                        board_out_piece <= {COLOR_BLACK, PIECE_ROOK};
                    end
                    else if(cursor_addr == 6'b000_010) begin // black long
                        board_out_addr <= 6'b000_011;
                        board_out_piece <= {COLOR_BLACK, PIECE_ROOK};
                    end
                end

                WRITE_ROOK:
                begin
                    // rook being written by last step; erase rook next
                    board_out_piece <= {COLOR_WHITE, PIECE_NONE};
                    board_change_enable <= 1;
                    castle_state <= ERASE_ROOK;

                    if     (cursor_addr == 6'b111_110) board_out_addr <= 6'b111_111; // white short
                    else if(cursor_addr == 6'b111_010) board_out_addr <= 6'b111_000; // white long
                    else if(cursor_addr == 6'b000_110) board_out_addr <= 6'b000_111; // black short
                    else if(cursor_addr == 6'b000_010) board_out_addr <= 6'b000_011; // black long
                end

                ERASE_ROOK:
                begin
                    // done with castle operation, setup next move
                    player_to_move <= ~player_to_move;
                    state <= PIECE_SEL;
                    board_change_enable <= 0;
                    hilite_selected_square <= 0;

                    if (player_to_move == COLOR_WHITE) begin
                        white_can_castle_long <= 0;
                        white_can_castle_short <= 0;
                    end
                    else begin
                        black_can_castle_short <= 0;
                        black_can_castle_long <= 0;
                    end
                end
                endcase
            end
			endcase
	 
		 /* Cursor Movement Controls */
		 if (BtnL && cursor_addr[2:0] != 3'b000) cursor_addr <= cursor_addr - 6'b000_001;
		 else if (BtnR && cursor_addr[2:0] != 3'b111) cursor_addr <= cursor_addr + 6'b000_001;
		 else if (BtnU && cursor_addr[5:3] != 3'b000) cursor_addr <= cursor_addr - 6'b001_000;
		 else if (BtnD && cursor_addr[5:3] != 3'b111) cursor_addr <= cursor_addr + 6'b001_000;
    end
end

/* Combinational logic to determine if the selected piece can move as desired */
// really only valid when in PIECE_MOVE state
// selected_contents is the piece we're trying to move
// selected_addr is the old location
// cursor_addr is the destination square
wire[3:0] h_delta;
wire[3:0] v_delta;
assign h_delta = cursor_addr[2:0] - selected_addr[2:0]; // + means moving right
assign v_delta = cursor_addr[5:3] - selected_addr[5:3]; // + means moving down (black forward)

always @(*) begin
    if(selected_contents[2:0] == PIECE_PAWN)
        begin
            if (player_to_move == COLOR_WHITE) begin // pawn moves forward (decreasing MSB)
                if (v_delta == -2 // skip forward by 2?
                    && h_delta == 0 // not moving diagonally?
                    && selected_addr[5:3] == 3'b110 // moving from home row?
                    && cursor_contents[2:0] == PIECE_NONE // no piece at dest?
                    && board[selected_addr + 6'b001_000][2:0] == PIECE_NONE) // no piece in way? 
                    move_is_legal = 1; // moving from home row by 2
                else if(v_delta == -1 // move forward by 1?
                    && h_delta == 0
                    && cursor_contents[2:0] == PIECE_NONE)
                    move_is_legal = 1;
                else if(v_delta == -1
                    && (h_delta==-1 || h_delta==1) // moving diagonally by 1?
                    && cursor_contents[3] == COLOR_BLACK // capturing opponent?
                    && cursor_contents[2:0] != PIECE_NONE) // capturing something?
                    move_is_legal = 1;
                else move_is_legal = 0;
                // TODO implement en passant
            end
            else if (player_to_move == COLOR_BLACK) begin
                if (v_delta == 2 // skip forward by 2?
                    && h_delta == 0 // not moving diagonally?
                    && selected_addr[5:3] == 3'b110 // moving from home row?
                    && cursor_contents[2:0] == PIECE_NONE // no piece at dest?
                    && board[selected_addr + 6'b001_000][2:0] == PIECE_NONE) // no piece in way? 
                    move_is_legal = 1; // moving from home row by 2
                else if(v_delta == 1 // move forward by 1?
                    && h_delta == 0
                    && cursor_contents[2:0] == PIECE_NONE)
                    move_is_legal = 1;
                else if(v_delta == 1
                    && (h_delta==-1 || h_delta==1) // moving diagonally by 1?
                    && cursor_contents[3] == COLOR_BLACK // capturing opponent?
                    && cursor_contents[2:0] != PIECE_NONE) // capturing something?
                    move_is_legal = 1;
                else move_is_legal = 0;
                // TODO implement en passant
            end
        end

    if(selected_contents[2:0] == PIECE_ROOK)
        begin
            move_is_legal = (h_delta==0 || v_delta==0);
            // well that was easy
        end

    if(selected_contents[2:0] == PIECE_QUEEN)
        begin
            move_is_legal =
                (  h_delta==0 || v_delta==0  // "rook" move
                || h_delta == v_delta       // "bishop" move pt1
                || h_delta == v_delta*-1);  // "bishop" move pt2
        end

    if(selected_contents[2:0] == PIECE_KING)
        begin
            move_is_legal =
                (  h_delta <= 1
                && h_delta >= -1
                && v_delta <= 1
                && v_delta >= -1);
        end

     if(selected_contents[2:0] == PIECE_BISHOP)
        begin
            move_is_legal =
                (  h_delta == v_delta       
                || h_delta == v_delta*-1);
        end

     if(selected_contents[2:0] == PIECE_KNIGHT)
        begin
            // must move "L" shape (2 in one dir and 1 in the other)
            move_is_legal =
                (   ( h_delta==-2 || h_delta==2) && (v_delta==-1 || v_delta==1 )
                ||  ( v_delta==-2 || v_delta==2) && (h_delta==-1 || h_delta==1 ));
        end
     
	  else move_is_legal = 0;
end

endmodule
