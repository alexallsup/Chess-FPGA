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
	 board_change_en_wire,
    BtnL, // All button inputs shall have been debounced & made a single clk pulse outside this module
    BtnU,
    BtnR,
    BtnD,
    BtnC,
    cursor_addr,
    selected_addr,
    hilite_selected_square,
	 state, move_is_legal, is_in_initial_state
    );

/* Inputs */
input wire CLK, RESET;
input wire BtnL, BtnU, BtnR, BtnD, BtnC;

input wire [255:0] board_input;

wire [3:0] board[63:0];

genvar i;
generate for (i=0; i<64; i=i+1) begin: BOARD
	assign board[i] = board_input[i*4+3 : i*4];
end
endgenerate

/* Outputs */ 
// outputs for communicating with the board register in top
output reg[5:0] board_out_addr;
output reg[3:0] board_out_piece;
reg board_change_enable; // signal the board reg in top to write the new piece to the addr
output wire board_change_en_wire;
assign board_change_en_wire = board_change_enable;

// outputs for communicating with the VGA module
output reg[5:0] cursor_addr;
output reg[5:0] selected_addr;
output wire hilite_selected_square;

output wire is_in_initial_state;
assign is_in_initial_state = (state == INITIAL);

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

output reg move_is_legal; // signal will be generated in combinational logic

/* State Machine Definition */
// use encoded-assignment
localparam INITIAL = 3'b000,
    PIECE_SEL = 3'b001, PIECE_MOVE= 3'b010,
    WRITE_NEW_PIECE = 3'b011, ERASE_OLD_PIECE = 3'b100;
output reg[2:0] state;
assign hilite_selected_square = (state == PIECE_MOVE);

/* State Machine NSL and OFL */
always @ (posedge CLK, posedge RESET) begin
    if (RESET) begin
        // initialization code here
        state <= INITIAL;
        castle_state <= WRITE_KING;
        player_to_move <= COLOR_WHITE;
        
        cursor_addr <= 6'b110_100; // white's king pawn, most common starting move
        selected_addr <= 6'bXXXXXX;

        board_out_addr <= 6'b000000;
        board_out_piece <= 4'b0000;
        board_change_enable <= 0;
	
    end
    else begin
        // State machine code from here
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
                    && cursor_contents[2:0] != PIECE_NONE) 
						  begin
                        state <= PIECE_MOVE;
								selected_addr <= cursor_addr;
						  end
                // else we remain in this state
            end

            PIECE_MOVE:
            begin
                // RTL operations
                if (BtnC) begin
                    if (      (cursor_contents[3] != player_to_move
                            || cursor_contents[2:0] == PIECE_NONE)
                            && move_is_legal)
                    begin
                        // they clicked either an empty space or the other color piece & legally
								state <= WRITE_NEW_PIECE; 
                        board_out_addr <= cursor_addr;
                        board_out_piece <= selected_contents;
                        board_change_enable <= 1;
                    end
                    else if (cursor_contents[3] == player_to_move
                        && cursor_contents[2:0] != PIECE_NONE)
                    begin
                        // they clicked their own piece
                        selected_addr <= cursor_addr;
                    end
						  else begin
								state <= PIECE_SEL;
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

			endcase
	 
		 /* Cursor Movement Controls */
		 if      (BtnL && cursor_addr[2:0] != 3'b000) cursor_addr <= cursor_addr - 6'b000_001;
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
reg[3:0] h_delta;
reg[3:0] v_delta;

// cursor addr and selected addr are 6 bit numbers. 5:3 reps the row, 2:0 reps the col
always @(*) begin
	if (cursor_addr[2:0] >= selected_addr[2:0]) h_delta = cursor_addr[2:0] - selected_addr[2:0];
	else													  h_delta = selected_addr[2:0] - cursor_addr[2:0];
	
	if (cursor_addr[5:3] >= selected_addr[5:3]) v_delta = cursor_addr[5:3] - selected_addr[5:3];
	else													  v_delta = selected_addr[5:3] - cursor_addr[5:3];
end

// Logic to generate the move_is_legal signal
always @(*) begin
    if(selected_contents[2:0] == PIECE_PAWN)
        begin
            if (player_to_move == COLOR_WHITE) begin // pawn moves forward (decreasing MSB)
                if (v_delta == 2 // skip forward by 2?
                    && h_delta == 0 // not moving diagonally?
                    && selected_addr[5:3] == 3'b110 // moving from home row?
                    && cursor_contents[2:0] == PIECE_NONE // no piece at dest?
                    && board[selected_addr - 6'b001_000][2:0] == PIECE_NONE // no piece in way?
						  && cursor_addr[5:3] < selected_addr[5:3] )
                    move_is_legal = 1; // moving from home row by 2
                else if(v_delta == 1 // move forward by 1?
                    && h_delta == 0
                    && cursor_contents[2:0] == PIECE_NONE
						  && cursor_addr[5:3] < selected_addr[5:3] )
                    move_is_legal = 1;
                else if(v_delta == 1
                    && (h_delta == 1) // moving diagonally by 1?
                    && cursor_contents[3] == COLOR_BLACK // capturing opponent?
                    && cursor_contents[2:0] != PIECE_NONE // capturing something?
						  && cursor_addr[5:3] < selected_addr[5:3] )
                    move_is_legal = 1;
                else move_is_legal = 0;
            end
            else if (player_to_move == COLOR_BLACK) begin
                if (v_delta == 2 // skip forward by 2?
                    && h_delta == 0 // not moving diagonally?
                    && selected_addr[5:3] == 3'b001 // moving from home row?
                    && cursor_contents[2:0] == PIECE_NONE // no piece at dest?
                    && board[selected_addr + 6'b001_000][2:0] == PIECE_NONE // no piece in way? 
						  && cursor_addr[5:3] > selected_addr[5:3] )
                    move_is_legal = 1; // moving from home row by 2
                else if(v_delta == 1 // move forward by 1?
                    && h_delta == 0
                    && cursor_contents[2:0] == PIECE_NONE
						  && cursor_addr[5:3] > selected_addr[5:3] )
                    move_is_legal = 1;
                else if(v_delta == 1
                    && (h_delta==1) // moving diagonally by 1?
                    && cursor_contents[3] == COLOR_WHITE // capturing opponent?
                    && cursor_contents[2:0] != PIECE_NONE // capturing something?
						  && cursor_addr[5:3] > selected_addr[5:3] )
                    move_is_legal = 1;
                else move_is_legal = 0;
                // TODO implement en passant
            end
        end

    else if(selected_contents[2:0] == PIECE_ROOK)
        begin
            move_is_legal = (h_delta==0 || v_delta==0);
            // well that was easy
        end

    else if(selected_contents[2:0] == PIECE_QUEEN)
        begin
            move_is_legal =
                (  h_delta==0 || v_delta==0  // "rook" move
                || h_delta == v_delta );     // "bishop" move
        end

    else if(selected_contents[2:0] == PIECE_KING)
        begin
            move_is_legal =
                ( h_delta == 0 || h_delta == 1)
				 && ( v_delta == 0 || v_delta == 1);
        end

    else if(selected_contents[2:0] == PIECE_BISHOP)
        begin
            move_is_legal =
                (  h_delta == v_delta );
        end

    else if(selected_contents[2:0] == PIECE_KNIGHT)
        begin
            // must move "L" shape (2 in one dir and 1 in the other)
            move_is_legal =
                (   h_delta==2 && v_delta==1 
                ||  v_delta==2 && h_delta==1 );
        end
     
	 else move_is_legal = 0;
end 

endmodule
