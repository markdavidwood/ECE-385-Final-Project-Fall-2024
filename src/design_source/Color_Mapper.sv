module color_mapper (
    input  logic [9:0] DrawX,
    input  logic [9:0] DrawY,
    input  logic [9:0] snakeX [0:127],
    input  logic [9:0] snakeY [0:127],
    input  logic [7:0] snake_length,
    input  logic [9:0] foodX,
    input  logic [9:0] foodY,
    input  logic       game_over,
    input  logic [15:0] score,          // Added score input
    output logic [3:0] Red,
    output logic [3:0] Green,
    output logic [3:0] Blue
);

    // Existing signals
    logic snake_on;
    logic food_on;
    logic checkerboard;
    logic [10:0] addr_reg; // Updated to 11 bits to match font_rom's address width
    parameter BORDER_WIDTH = 10; // Define border width

    // Instantiate font_rom
    wire [7:0] font_data;
    font_rom font_inst (
        .addr(addr_reg),
        .data(font_data)
    );

    // Extract individual digits from the score
    wire [3:0] digit0 = score % 10;
    wire [3:0] digit1 = (score / 10) % 10;
    wire [3:0] digit2 = (score / 100) % 10;
    wire [3:0] digit3 = (score / 1000) % 10;

    // Define score position
    parameter SCORE_X = 600;
    parameter SCORE_Y = 20;
    parameter CHAR_WIDTH = 8;
    parameter CHAR_HEIGHT = 16;

    // Determine which digit to display based on DrawX and DrawY
    logic [3:0] current_digit;
    logic [3:0] bit_row;
    logic [3:0] bit_col;
    logic pixel_on;

    always_comb begin
        if (DrawX >= SCORE_X && DrawX < SCORE_X + (CHAR_WIDTH * 4) && DrawY >= SCORE_Y && DrawY < SCORE_Y + CHAR_HEIGHT) begin
            bit_col = (DrawX - SCORE_X) % CHAR_WIDTH;
            bit_row = (DrawY - SCORE_Y) % CHAR_HEIGHT;
            if (DrawX < SCORE_X + CHAR_WIDTH) begin
                current_digit = digit3;
            end else if (DrawX < SCORE_X + 2*CHAR_WIDTH) begin
                current_digit = digit2;
            end else if (DrawX < SCORE_X + 3*CHAR_WIDTH) begin
                current_digit = digit1;
            end else begin
                current_digit = digit0;
            end
            // Add base offset for digits ('0' is typically at 0x30 in ASCII)
            addr_reg = (11'h30 + current_digit) * 16 + bit_row;
            pixel_on = font_data[7 - bit_col];  
        end else begin
            pixel_on = 1'b0;
        end
    end

    // Snake rendering
    always_comb begin
        snake_on = 1'b0;
        for (int i = 0; i < snake_length; i++) begin
            if ((DrawX >= snakeX[i]) && (DrawX < snakeX[i] + 10) &&
                (DrawY >= snakeY[i]) && (DrawY < snakeY[i] + 10)) begin
                snake_on = 1'b1;
            end
        end
    end

    // Food rendering
    always_comb begin
        if ((DrawX >= foodX) && (DrawX < foodX + 10) &&
            (DrawY >= foodY) && (DrawY < foodY + 10)) begin
            food_on = 1'b1;
        end else begin
            food_on = 1'b0;
        end
    end

    // Checkerboard pattern
    always_comb begin
        checkerboard = ((DrawX / 10) + (DrawY / 10)) % 2;
    end

    // Border detection
    logic border;
    always_comb begin
        border = (DrawX < BORDER_WIDTH) || (DrawX >= (640 - BORDER_WIDTH)) ||
                 (DrawY < BORDER_WIDTH) || (DrawY >= (480 - BORDER_WIDTH));
    end

    // Color assignment
    always_comb begin
        if (game_over) begin
            // Game Over screen: Red background
            Red   = 4'hF;
            Green = 4'h0;
            Blue  = 4'h0;
        end else if (border) begin
            // Border color: White
            Red   = 4'hF;
            Green = 4'hF;
            Blue  = 4'hF;
        end else if (pixel_on) begin
            // Score digits color: White
            Red   = 4'hF;
            Green = 4'hF;
            Blue  = 4'hF;
        end else if (snake_on) begin
            // Snake color: Blue
            Red   = 4'h0;
            Green = 4'h0;
            Blue  = 4'hF;
        end else if (food_on) begin
            // Food color: Yellow
            Red   = 4'hF;
            Green = 4'hF;
            Blue  = 4'h0;
        end else begin
            // Background checkerboard: Dark Green and Light Green
            if (checkerboard) begin
                Red   = 4'h0;
                Green = 4'h8; // Light Green
                Blue  = 4'h0;
            end else begin
                Red   = 4'h0;
                Green = 4'h7; // Dark Green
                Blue  = 4'h0;
            end
        end
    end

endmodule