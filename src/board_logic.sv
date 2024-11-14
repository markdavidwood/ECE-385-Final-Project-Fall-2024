
/*

Purely combinational logic to generate the next board state based on the 
current board state. Uses the board_in input to generate the board_out output.

Uses information about where the current piece is, and what its type and rotation
are to generate the next board state. 

*/

module board_logic
  import tetris_package::*;
(
    input  board_t board_in,
    output board_t board_out,

    input piece_t current_piece
);
    /*
        Multiple cases must be dealt with to generate the next board state:
        

    */

endmodule
