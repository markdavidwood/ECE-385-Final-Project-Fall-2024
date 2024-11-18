module color_mapper (
    input  logic [9:0] DrawX,
    input  logic [9:0] DrawY,
    input  logic [9:0] snakeX [0:127],
    input  logic [9:0] snakeY [0:127],
    input  logic [7:0] snake_length,
    input  logic [9:0] foodX,
    input  logic [9:0] foodY,
    input  logic       game_over,     // New input
    output logic [3:0] Red,
    output logic [3:0] Green,
    output logic [3:0] Blue
);
    
    logic snake_on;
    logic food_on;
    logic checkerboard;
    
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

    // Color assignment
    always_comb begin
        if (game_over) begin
            // Game Over screen: Red background
            Red   = 4'hF;
            Green = 4'h0;
            Blue  = 4'h0;
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
                Green = 4'h4; // Dark Green
                Blue  = 4'h0;
            end
        end
    end

endmodule