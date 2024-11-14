module tetris_top (
    input logic clk,
    input logic reset_rtl_0,

    // USB Signals
    input logic [0:0] gpio_usb_int_tri_i,
    output logic gpio_usb_rst_tri_o,
    input logic usb_spi_miso,
    output logic usb_spi_mosi,
    output logic usb_spi_sclk,
    output logic usb_spi_ss,

    // UART Signals
    input  logic uart_rtl_0_rxd,
    output logic uart_rtl_0_txd,

    // HDMI
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0] hdmi_tmds_data_n,
    output logic [2:0] hdmi_tmds_data_p

    // Maybe hex displays? Later...


);
    logic [9:0] drawX, drawY;
    logic [31:0] keycode0_gpio, keycode1_gpio;
    logic clk_25MHz, clk_125MHz;
    logic locked;

    logic hsync, vsync, vde;
    logic [3:0] red, green, blue;  // 4 bits per color channel
    logic reset_ah;  // Active high reset

    assign reset_ah = reset_rtl_0;




    // Game variables and logic -------------------------------------
    logic [2:0] board [29:0][9:0];  // 30 rows of 10 blocks (10 buffer rows)
    piece_t current_piece, next_piece;
    



    //clock wizard configured with a 1x and 5x clock for HDMI
    clk_wiz_0 clk_wiz_inst (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(reset_ah),
        .locked(locked),
        .clk_in1(clk)
    );

    // vga controller
    vga_controller vga_controller_inst (
        .pixel_clk(clk_25MHz),
        .reset(reset_ah),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );

    // Real Digital VGA to HDMI Converter
    hdmi_tx_0 hdmi_tx_0_inst (
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        .rst(reset_ah),
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),

        //Aux data unused
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),

        // Differential outputs
        .TMDS_CLK_P (hdmi_tmds_clk_p),
        .TMDS_CLK_N (hdmi_tmds_clk_n),
        .TMDS_DATA_P(hdmi_tmds_data_p),
        .TMDS_DATA_N(hdmi_tmds_data_n)
    );

    /*
    clk_100MHz,
    gpio_usb_int_tri_i,
    gpio_usb_keycode_0_tri_o,
    gpio_usb_keycode_1_tri_o,
    gpio_usb_rst_tri_o,
    reset_rtl_0,
    uart_rtl_0_rxd,
    uart_rtl_0_txd,
    usb_spi_miso,
    usb_spi_mosi,
    usb_spi_sclk,
    usb_spi_ss
    */

    // block design with microblaze
    mb_block_tetris mb_block_tetris (
        .clk_100MHz(clk),
        .gpio_usb_int_tri_i(gpio_usb_int_tri_i),
        .gpio_usb_keycode_0_tri_o(keycode0_gpio),
        .gpio_usb_keycode_1_tri_o(keycode1_gpio),
        .gpio_usb_rst_tri_o(gpio_usb_rst_tri_o),
        .reset_rtl_0(~reset_ah),
        .uart_rtl_0_rxd(uart_rtl_0_rxd),
        .uart_rtl_0_txd(uart_rtl_0_txd),
        .usb_spi_miso(usb_spi_miso),
        .usb_spi_mosi(usb_spi_mosi),
        .usb_spi_sclk(usb_spi_sclk),
        .usb_spi_ss(usb_spi_ss)
    );


    // Interfaces we will need for the top level
    /*
        Block Design:
            - Microblaze
            # I/O
            # Usb signals
            - gpio_usb_int_tri_i (tri-state interrupt)
            - gpio_usb_keycode_0_tri_o (keycode 0)
            - gpio_usb_keycode_1_tri_o (keycode 1)
            - gpio_usb_rst_tri_o (reset)
            # Reset signals
            - reset_rtl_0 (active low) (all other modules are active high)
            # UART
            - uart_rtl_0_rxd (receive data)
            - uart_rtl_0_txd (transmit data)
            # USB SPI MISO/MOSI
            - usb_spi_miso (master in slave out)
            - usb_spi_mosi (master out slave in)
            - usb_spi_sclk (serial clock)
            - usb_spi_ss (slave select)

        Clocking Wizard (100 MHz)
            - clk_out1(25 MHz)
            - clk_out2(125 MHz)
            - reset (active high)
            - locked
            - clk_in1 (100 MHz)

        VGA Controller
            - pixel_clk (25 Mhz)
            - reset (active high)
            - hs (horizontal sync pulse)
            - vs (vertical sync pulse)
            - active_nblank (High = active, low = blanking interval) (vde)
            - drawX (horizontal coordinate)
            - drawY (vertical coordinate)

        VGA to HDMI converter
            - pix_clk (25 MHz)
            - pix_clkx5 (125 MHz)
            - pix_clk_locked (locked)
            - rst (active high)
            - red (4 bit)
            - green (4 bit)
            - blue (4 bit)
            - hsync (horizontal sync pulse)
            - vsync (vertical sync pulse)
            - vde (vertical display enable)
            # Differential outputs
            - TMDS_CLK_P 
            - TMDS_CLK_N
            - TMDS_DATA_P
            - TMDS_DATA_N

        # HARDWARE LOGIC (underlying implementation of graphics)

        We will need some sort of memory to store the game state
        # Thoughts on memory
            - Could use BRAM 
                - Have to deal with delays for read operations
                - Do we really have enough information to warrant BRAM?
            - Could use registers
                - Would be faster
                - Takes up more system resources
        
            - How much data do we need to store?
                - Blocks
                    - 20 rows of 10 blocks each (Visible)
                    - 4 rows of "buffer" blocks (Invisible)
                        - Buffer rows are for loading the next block
                    - Block types
                        - i-piece (4 blocks tall) (cyan)
                        - o-piece (2x2) (yellow)
                        - t-piece (2 blocks tall, 3 blocks wide, T shape) (purple)
                        - s-piece (2 blocks tall, 3 blocks wide, S shape) (green)
                        - z-piece (2 blocks tall, 3 blocks wide, Z shape) (red)
                        - j-piece (3 blocks tall, 2 blocks wide, J shape) (blue)
                        - l-piece (3 blocks tall, 2 blocks wide, L shape) (orange)
                - Colors
                    - 7 colors in classic Tetris
                    - 1 color for empty space
                    - 1 color for block borders
                    - 7 colors for background/miscellaneous
                        - Scorekeeping
                        - Level
                        - Points
                        - Gradient?
                    - 16 colors total (4 bits)
                        - Assign a color to each combination of 4'b0000-4'b1111
                - Score (24 bits) (might need more)
                - Lines cleared (8 bits)
                    - Level is inferred from this (1 level per 10 lines)
                    - Current level is used to determine speed of block falling
                    - Current level is used to determine points per line cleared
                        - 1 line = 100 x level
                        - 2 lines = 300 x level
                        - 3 lines = 500 x level
                        - 4 lines = 800 x level
                - Next block type (3 bits)
                - Current block type (3 bits)
                - Current block rotation (2 bits)
                - Current block position (4 bits for 0-9, 5 bits for 0-19)

                - Static information about piece orientation based on shape type and rotation
                    - Each block needs a definition of its shape for each rotation
                    - Encode each piece as 4 coordinates relative to the center of the piece
                    - Each of the 4 coordinates has 3 bits for x and 3 bits for y
                    - 24 bits per block x 7 blocks = 168 bits
                - Rotation information can be computed mathematically, no extra bits
                    - swap and/or negate x and y coordinates
                    - functions exist in sv for this! rotate_x and rotate_y
                - 953 bits total

            # we can just store all of this in registers. 

            # we should use structs to store piece information

            # blocks need to rotate ONCE on a button press even when held
                - Posedge detector needed for keycodes used.  

            # Keycodes to use
                - left arrow - move left
                - right arrow - move right
                - down arrow - move down
                - space - slam block down
                - a - rotate CCW
                - d - rotate CW

            # Game state logic
                - Game state is updated every frame
                - Game states:
                    - Title screen
                    - Game over screen
                    - Playing

            # Piece struct
                - x
                - y
                - rotation
                - type
                

            # functions
            generate_new_piece();

            check_collision(piece, movex, movey, newrotation);

            move_left(piece);
            move_right(piece);
            move_down(piece);
            slam_down(piece);
            rotate_cw(piece);
            rotate_ccw(piece);

            clear_lines();

    */









endmodule
