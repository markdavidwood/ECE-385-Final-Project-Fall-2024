module snake (
    input logic          Reset,
    input logic          clk,
    input logic  [7:0]   keycode,

    output logic [9:0]   snakeX [0:127],
    output logic [9:0]   snakeY [0:127],
    output logic [7:0]   snake_length,
    output logic [9:0]   foodX,
    output logic [9:0]   foodY,
    output logic         game_over,
    output logic [15:0]  score      // Added score output
);

// Parameters and constants
parameter [9:0] Snake_X_Center = 320;
parameter [9:0] Snake_Y_Center = 240;
parameter [9:0] Snake_X_Min    = 10;  // Updated to account for border
parameter [9:0] Snake_X_Max    = 630; // Adjusted to fit 10-pixel steps
parameter [9:0] Snake_Y_Min    = 10;  // Updated to account for border
parameter [9:0] Snake_Y_Max    = 470; // Adjusted to fit 10-pixel steps
parameter [9:0] Snake_Step     = 10;

// Directions
typedef enum logic [1:0] {
    UP    = 2'd0,
    DOWN  = 2'd1,
    LEFT  = 2'd2,
    RIGHT = 2'd3
} direction_t;

// Registers and wires
direction_t direction;
logic       move_enable;
logic [23:0] move_counter;
logic [15:0] lfsr;
logic [9:0]  rand_num_x, rand_num_y;
logic        snake_self_collision;
logic        started;       // Indicates if the game has started
logic        food_eaten;    // Flag to indicate food has been eaten

// Initialize registers
always_ff @(posedge clk or posedge Reset) begin
    if (Reset) begin
        snake_length <= 8'd4; // Initial length of the snake
        game_over    <= 1'b0;
        score        <= 16'd0; // Initialize score
        food_eaten   <= 1'b0;  // Initialize food_eaten flag
        // Initialize snake positions
        for (int i = 0; i < 128; i++) begin
            snakeX[i] <= Snake_X_Center - (i * Snake_Step);
            snakeY[i] <= Snake_Y_Center;
        end
        // Initialize food position
        foodX <= rand_num_x;
        foodY <= rand_num_y;
    end else if (move_enable && !game_over && started) begin
        // Shift body segments
        for (int i = 127; i > 0; i--) begin
            if (i < snake_length) begin
                snakeX[i] <= snakeX[i-1];
                snakeY[i] <= snakeY[i-1];
            end
        end

        // Update head position
        case (direction)
            UP:    snakeY[0] <= snakeY[0] - Snake_Step;
            DOWN:  snakeY[0] <= snakeY[0] + Snake_Step;
            LEFT:  snakeX[0] <= snakeX[0] - Snake_Step;
            RIGHT: snakeX[0] <= snakeX[0] + Snake_Step;
        endcase

        // Check for wall collisions
        if (snakeX[0] < Snake_X_Min || snakeX[0] > Snake_X_Max ||
            snakeY[0] < Snake_Y_Min || snakeY[0] > Snake_Y_Max) begin
            game_over <= 1'b1;
        end else begin
            // Check for self-collision
            snake_self_collision = 1'b0;
            for (int i = 1; i < snake_length; i++) begin
                if (snakeX[0] == snakeX[i] && snakeY[0] == snakeY[i]) begin
                    snake_self_collision = 1'b1;
                end
            end
            if (snake_self_collision) begin
                game_over <= 1'b1;
            end
        end

        // Check if snake eats the food
        if ((snakeX[0] == foodX) && (snakeY[0] == foodY) && !food_eaten) begin
            // Increase snake length
            if (snake_length < 128) begin
                snake_length <= snake_length + 1;
            end
            // Increment score
            score <= score + 16'd1;
            // Set food_eaten flag
            food_eaten <= 1'b1;
        end else if ((snakeX[0] != foodX) || (snakeY[0] != foodY)) begin
            // Reset food_eaten flag when not on food
            food_eaten <= 1'b0;
        end

        // Generate new food position if food was eaten
        if (food_eaten) begin
            foodX <= rand_num_x;
            foodY <= rand_num_y;
            food_eaten <= 1'b0; // Reset flag after repositioning food
        end
    end
end

// Clock divider to create a slower movement clock
always_ff @(posedge clk or posedge Reset) begin
    if (Reset) begin
        move_counter <= 24'd0;
        move_enable  <= 1'b0;
    end else begin
        if (move_counter == 24'd1_250_000) begin // Adjust value for desired speed
            move_counter <= 24'd0;
            move_enable  <= 1'b1;
        end else begin
            move_counter <= move_counter + 24'd1;
            move_enable  <= 1'b0;
        end
    end
end

// LFSR for pseudo-random number generation
logic feedback;
assign feedback = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];

// Update new_foodX and new_foodY after LFSR updates
always_ff @(posedge clk or posedge Reset) begin
    if (Reset) begin
        lfsr <= 16'hACE1; // Non-zero seed
    end else if (move_enable) begin
        lfsr <= {lfsr[14:0], feedback};
    end
end

// Generate random numbers for food position
always_comb begin
    rand_num_x = (lfsr[7:0] % ((Snake_X_Max - Snake_X_Min) / Snake_Step)) * Snake_Step + Snake_X_Min;
    rand_num_y = (lfsr[15:8] % ((Snake_Y_Max - Snake_Y_Min) / Snake_Step)) * Snake_Step + Snake_Y_Min;
end

// Direction control based on keycode
always_ff @(posedge clk or posedge Reset) begin
    if (Reset) begin
        direction <= RIGHT;
        started <= 1'b0;
    end else begin
        case (keycode)
            8'h1A: begin // 'W' key
                if (direction != DOWN) direction <= UP;
                started <= 1'b1;
            end
            8'h16: begin // 'S' key
                if (direction != UP) direction <= DOWN;
                started <= 1'b1;
            end
            8'h04: begin // 'A' key
                if (direction != RIGHT) direction <= LEFT;
                started <= 1'b1;
            end
            8'h07: begin // 'D' key
                if (direction != LEFT) direction <= RIGHT;
                started <= 1'b1;
            end
            default: direction <= direction;
        endcase
    end
end

endmodule