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

endmodule
