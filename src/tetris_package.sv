package tetris_package;

    // Define Useful Constants
    parameter int BOARD_WIDTH = 10;
    parameter int BOARD_HEIGHT = 30;
    parameter int BUFFER_ROWS = 10;

    // Define board cell type
    typedef logic [2:0] cell_t;  // 3 bits for 7 colors and 1 bit for empty (8)

    // Define board type
    typedef cell_t board_t[BOARD_HEIGHT][BOARD_WIDTH];

    // Define piece types as enumerated type for clarity in coding
    typedef enum logic [2:0] {
        I_PIECE = 3'd1,
        O_PIECE = 3'd2,
        T_PIECE = 3'd3,
        S_PIECE = 3'd4,
        Z_PIECE = 3'd5,
        J_PIECE = 3'd6,
        L_PIECE = 3'd7,
        EMPTY   = 3'd0
    } piece_type_t;


    // Piece struct
    typedef struct packed {
        logic [3:0]  x;
        logic [4:0]  y;
        piece_type_t piece_type;
        logic [1:0]  rotation;
    } piece_t;



    // Define piece rotation as enumerated type for clarity in coding
    // Defined as CCW rotations
    typedef enum logic [1:0] {
        ROT_0   = 2'd0,
        ROT_90  = 2'd1,
        ROT_180 = 2'd2,
        ROT_270 = 2'd3
    } piece_rotation_t;

    // Define a struct for a single block coordinate
    typedef struct packed {
        logic signed [2:0] x;
        logic signed [2:0] y;
    } block_pos_t;

    // Define an array of 4 block positions for a piece
    typedef block_pos_t [3:0] piece_blocks_t;

    // Define the piece data as a parameter array
    parameter logic signed [2:0] PIECE_DATA[7][4][2] = '{
        // Each piece is defined as 4 (x,y) coordinates
        // relative to the center of the piece. 
        // The center of the piece (0,0) is always the first coordinate.
        // The other 3 coordinates are relative to the center.
        // The coordinates are signed to allow for negative values.
        // The coordinates are 3 bits wide to allow for a range of -4 to 4.

        '{  // I_PIECE
            '{-3'sd1, 3'sd0},  // center
            '{3'sd0, 3'sd0},
            '{3'sd1, 3'sd0},
            '{3'sd2, 3'sd0}
        },

        '{  // O_PIECE
            '{3'sd0, 3'sd0},  // center
            '{3'sd0, 3'sd1},
            '{3'sd1, 3'sd0},
            '{3'sd1, 3'sd1}
        },

        '{  // T_PIECE
            '{3'sd0, 3'sd0},  // center
            '{3'sd0, 3'sd1},
            '{-3'sd1, 3'sd0},
            '{3'sd1, 3'sd0}
        },

        '{  // S_PIECE
            '{3'sd0, 3'sd0},  // center
            '{3'sd1, 3'sd0},
            '{-3'sd1, -3'sd1},
            '{3'sd0, -3'sd1}
        },

        '{  // Z_PIECE
            '{3'sd0, 3'sd0},  // center
            '{-3'sd1, 3'sd0},
            '{3'sd0, -3'sd1},
            '{3'sd1, -3'sd1}
        },

        '{  // J_PIECE
            '{3'sd0, 3'sd0},  // center
            '{3'sd1, 3'sd0},
            '{-3'sd1, 3'sd1},
            '{-3'sd1, 3'sd0}
        },

        '{  // L_PIECE
            '{3'sd0, 3'sd0},  // center
            '{3'sd1, 3'sd0},
            '{3'sd1, 3'sd1},
            '{-3'sd1, 3'sd0}
        }

    };

    // Split rotation into simple operations
    function automatic block_pos_t rotate_single_block(input logic signed [2:0] x, y,
                                                       input logic [1:0] rotation);
        block_pos_t rotated;
        case (rotation)
            ROT_0: begin
                rotated = '{x: x, y: y};
            end
            ROT_90: begin
                rotated = '{x: -y, y: x};
            end
            ROT_180: begin
                rotated = '{x: -x, y: -y};
            end
            ROT_270: begin
                rotated = '{x: y, y: -x};
            end
        endcase
        return rotated;
    endfunction

    // Split collision check into smaller checks
    function automatic logic check_wall_collision(input logic signed [4:0] x, y);
        return (x < 0) || (x >= BOARD_WIDTH) || (y >= BOARD_HEIGHT);
    endfunction

    // Simplified get_rotated_coords
    function automatic piece_blocks_t get_rotated_relative_coords(input piece_t piece);
        piece_blocks_t blocks;
        for (int i = 0; i < 4; i++) begin
            blocks[i] = rotate_single_block(
                PIECE_DATA[piece.piece_type][i][0],
                PIECE_DATA[piece.piece_type][i][1],
                piece.rotation
            );
        end
        return blocks;
    endfunction

    // Simplified get_absolute_coords
    function automatic piece_blocks_t get_absolute_coords(input piece_t piece);
        piece_blocks_t rotated_blocks = get_rotated_relative_coords(piece);
        piece_blocks_t abs_blocks;

        for (int i = 0; i < 4; i++) begin
            abs_blocks[i].x = piece.x + rotated_blocks[i].x;
            abs_blocks[i].y = piece.y + rotated_blocks[i].y;
        end

        return abs_blocks;
    endfunction

    // Function to check a single block for collision
    function automatic logic check_block_collision(input board_t board, input logic signed [4:0] x,
                                                   y);
        return (board[y][x] != 3'b000);
    endfunction

    // Main collision check uses helper functions
    function automatic logic check_collision(input board_t board, input piece_t piece);
        piece_blocks_t abs_blocks = get_absolute_coords(piece);
        for (int i = 0; i < 4; i++) begin
            if (check_wall_collision(
                    abs_blocks[i].x, abs_blocks[i].y
                ) || check_block_collision(
                    board, abs_blocks[i].x, abs_blocks[i].y
                )) begin
                return 1;
            end
        end
        return 0;
    endfunction


        // These below functions should be in modules, not in the package
        // This is because they are actual pipelining. 

    // // Function to lock a piece in place on the board
    // function automatic board_t lock_piece(input board_t board, input piece_t piece);
    //     board_t new_board = board;
    //     piece_blocks_t abs_blocks = get_absolute_coords(piece);

    //     // Lock all 4 blocks of the piece
    //     for (int i = 0; i < 4; i++) begin
    //         // Lock block in place using absolute coordinates
    //         new_board[abs_blocks[i].y][abs_blocks[i].x] = piece.piece_type;
    //     end

    //     return new_board;
    // endfunction

    // function automatic logic [BOARD_HEIGHT-1:0] get_complete_lines(input board_t board);
    //     logic [BOARD_HEIGHT-1:0] complete_lines = 0;
    //     logic                    complete;

    //     for (int i = 0; i < BOARD_HEIGHT; i++) begin
    //         complete = 1;
    //         for (int j = 0; j < BOARD_WIDTH; j++) begin
    //             if (board[i][j] == 3'b000) begin
    //                 complete = 0;
    //                 break;
    //             end
    //         end

    //         complete_lines[i] = complete;
    //     end

    //     return complete_lines;

    // endfunction

    // // Function to clear lines from the board
    // function automatic board_t clear_lines(input board_t board, input logic [BOARD_HEIGHT-1:0] lines_to_clear);

    // endfunction



endpackage
