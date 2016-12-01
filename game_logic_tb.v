`timescale 1ns / 1ps

module game_logic_tb();

/* Clocking: CLK has period=20ns */
reg CLK;
always begin: GENERATE_CLK
	#10 CLK = ~CLK;
end

/* TB signals */
reg BtnC, BtnU, BtnR, BtnL, BtnD;
reg Reset;
wire[5:0] board_change_addr;
wire[3:0] board_change_piece;
wire board_change_enable;
wire[5:0] cursor_addr;
wire[5:0] selected_piece_addr;
wire hilite_selected_square;
reg [5:0] test_count;

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
always @(posedge CLK) begin: LOGIC_UPDATES_BOARD
	if (board_change_enable) board[board_change_addr] <= board_change_piece;
end

genvar i;
generate for (i=0; i<64; i=i+1) begin: BOARD
	assign passable_board[i*4+3 : i*4] = board[i];
end
endgenerate

// Init UUT (Game logic module)
game_logic game_logic(
	.CLK(CLK), 
	.RESET(Reset),
	.board_input(passable_board),

	.board_out_addr(board_change_addr),
	.board_out_piece(board_change_piece),
	.board_change_enable(board_change_enable),
	.cursor_addr(cursor_addr),
	//.selected_piece_addr(selected_piece_addr),
	.hilite_selected_square(hilite_selected_square),

	.BtnU(BtnU), .BtnL(BtnL), .BtnC(BtnC),
	.BtnR(BtnR), .BtnD(BtnD)
	);

/*task BLANK_BOARD;
	integer j;
	for (j=0; i < 64; j=j+1) begin
		board[i] = {COLOR_WHITE, PIECE_NONE};
	end
endtask

task DISPLAY_BOARD;
	reg r[3:0], c[3:0];
	for (r=0; r<8; r=r+1) begin
		for (c=0; c<8; c=c+1) begin
			case (board[{r[2:0], c[2:0]}]) 
				{COLOR_WHITE, PIECE_KING}: 		$write("K");
				{COLOR_WHITE, PIECE_QUEEN}: 	$write("Q");
				{COLOR_WHITE, PIECE_ROOK}: 		$write("R");
				{COLOR_WHITE, PIECE_KNIGHT}: 	$write("N");
				{COLOR_WHITE, PIECE_BISHOP}: 	$write("B");
				{COLOR_WHITE, PIECE_PAWN}: 		$write("P");
				{COLOR_WHITE, PIECE_NONE}: 		$write("O");
				{COLOR_BLACK, PIECE_KING}: 		$write("k");
				{COLOR_BLACK, PIECE_QUEEN}: 	$write("q");
				{COLOR_BLACK, PIECE_ROOK}: 		$write("r");
				{COLOR_BLACK, PIECE_KNIGHT}: 	$write("n");
				{COLOR_BLACK, PIECE_BISHOP}: 	$write("b");
				{COLOR_BLACK, PIECE_PAWN}: 		$write("p");
				{COLOR_BLACK, PIECE_NONE}: 		$write("O");
				default	:						$write("x");
			endcase
		end
		$write("\n");
	end
endtask

task LOAD_BOARD begin
	input[3:0] test_num; // 
	input_file = $fopen("test1.txt", "r");
	integer r1[3:0], c1[3:0];
	for (r1=0; r1<8; r1=r1+1) begin
		for (c1=0; c1<8; c1=c1+1) begin
			reg[3:0] char_in = $fgetc(input_file);
			case(char_in)
				"K": board[{r1[2:0], c1[2:0]}] 		<= {COLOR_WHITE, PIECE_QUEEN};
				"R": board[{r1[2:0], c1[2:0]}] 		<= {COLOR_WHITE, PIECE_ROOK};
				"N": board[{r1[2:0], c1[2:0]}] 		<= {COLOR_WHITE, PIECE_KNIGHT};
				"B": board[{r1[2:0], c1[2:0]}] 		<= {COLOR_WHITE, PIECE_BISHOP};
				"P": board[{r1[2:0], c1[2:0]}] 		<= {COLOR_WHITE, PIECE_PAWN};
				"O": board[{r1[2:0], c1[2:0]}] 		<= {COLOR_WHITE, PIECE_NONE};
				"k": board[{r1[2:0], c1[2:0]}] 		<= {COLOR_BLACK, PIECE_KING};
				"q": board[{r1[2:0], c1[2:0]}] 		<= {COLOR_BLACK, PIECE_QUEEN};
				"r": board[{r1[2:0], c1[2:0]}] 		<= {COLOR_BLACK, PIECE_ROOK};
				"n": board[{r1[2:0], c1[2:0]}] 		<= {COLOR_BLACK, PIECE_KNIGHT};
				"b": board[{r1[2:0], c1[2:0]}] 		<= {COLOR_BLACK, PIECE_BISHOP};
				"p": board[{r1[2:0], c1[2:0]}] 		<= {COLOR_BLACK, PIECE_PAWN};
				"x": board[{r1[2:0], c1[2:0]}] 		<= {COLOR_WHITE, PIECE_NONE};
				default : board[{r1[2:0], c1[2:0]}] <= {COLOR_WHITE, PIECE_NONE};
			endcase
		end
	end

	$fclose(input_file);
end
endtask

task BTNU_PRESS;
	BtnU = 1;
	#20;
	BtnU = 0;
	#20;
endtask

task BTNL_PRESS;
	BtnL = 1;
	#20;
	BtnL = 0;
	#20;
endtask

task BTND_PRESS;
	BtnD = 1;
	#20;
	BtnD = 0;
	#20;
endtask

task BTNR_PRESS;
	BtnR = 1;
	#20;
	BtnR = 0;
	#20;
endtask

task BTNC_PRESS;
	BtnC = 1;
	#20;
	BtnC = 0;
	#20;
endtask

*/

initial begin
	/* Initialize local signals and initial reset pulse */
	BtnC = 0;
	BtnU = 0;
	BtnR = 0;
	BtnL = 0;
	BtnD = 0;

	test_count = 0;

	CLK = 0;
	Reset = 1;
	#100;
	Reset = 0;
	#15; // 15 to get buttons slightly out of sync with clock

	// TEST ONE: verify button movement works as expected
	// logic cursor should be initialized at the e2 square, 6'b110_100
	/*test_count = test_count + 1;
	$display("Testing game cursor");
	BTND_PRESS; // e1
	BTND_PRESS; // should stay e1 w/o going down

	BTNL_PRESS; // d1
	BTNL_PRESS; // C1
	BTNL_PRESS; // B1
	BTNL_PRESS; // A1
	BTNL_PRESS; // should stay a1 w/o going left

	BTNU_PRESS; // A2
	BTNU_PRESS; // A3
	BTNU_PRESS; // A4
	BTNU_PRESS; // A5
	BTNU_PRESS; // A6
	BTNU_PRESS; // A7
	BTNU_PRESS; // A8
	BTNU_PRESS; // should stay a8 w/o going up
	
	BTNR_PRESS; // b8
	BTNR_PRESS; // c8
	BTNR_PRESS; // d8
	BTNR_PRESS; // e8
	BTNR_PRESS; // f8
	BTNR_PRESS; // g8
	BTNR_PRESS; // h8
	BTNR_PRESS; // should stay h8 w/o going right
	if(cursor_addr == 6'b000_111) $display("Cursor test pass!");
	else $display("Cursor test fail!");*/
	
	
end

endmodule