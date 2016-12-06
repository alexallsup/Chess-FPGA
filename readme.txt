Authors: Alex Allsup and Kevin Wu

This is our final semester project for EE354 (Intro. to Digital Circuits) at University of Southern California in the fall of 2016.

It is a chess game for two players that can be played using the Nexys-3 FPGA board and a VGA monitor.
The game is played using the 4 directional buttons and the center button. During the game, one square will be highlighted with a blue border. This is the "cursor". Using the 4 directional buttons, the cursor can be moved around the screen. Pressing the center button while the cursor is over the active player's piece selects that piece to be moved. Moving the cursor to a different square and pressing the center button will move the piece to that square, if it is a valid and legal move. Attempting to make an invalid move deselects the piece, or selects a new piece if the cursor was on a piece of the active player.

The game respects which player's turn it is to move (ie White cannot move Black's piece during White's turn). It also respects the movement patterns of the different pieces (ie Bishops move diagonally, knights move in an L, etc). For complexity's sake, we were not able to implement castling, en passant capture for pawns, or determining if a move places the player in check (which would make the move illegal).

The pieces are displayed on the VGA monitor using a 7-bit RRR-GGG-BB color scheme and 8x8 pixel art for each piece.