LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY flappy_bird_base IS
    PORT (
        CLOCK_50 : IN STD_LOGIC;
        RESET_N : IN STD_LOGIC;
        PS2_CLK : INOUT STD_LOGIC;
        PS2_DAT : INOUT STD_LOGIC;
        VGA_R : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        VGA_G : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        VGA_B : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        VGA_HS : OUT STD_LOGIC;
        VGA_VS : OUT STD_LOGIC
    );
END flappy_bird_base;

ARCHITECTURE top OF flappy_bird_base IS

    SIGNAL clk_25 : STD_LOGIC;
    SIGNAL red, green, blue : STD_LOGIC;
    SIGNAL pixel_row, pixel_column : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL mouse_row, mouse_col : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL left_button, right_button : STD_LOGIC;
    SIGNAL text_pixel : STD_LOGIC;

    SIGNAL bird_y : INTEGER := 240;
    SIGNAL bird_velocity : INTEGER := 0;

    --click to rise stuff
    SIGNAL vsync_internal : STD_LOGIC;

    --pipes and screen stuff
    SIGNAL pipe_x : INTEGER := 640; -- Pipe horizontal position (starts off screen)
    SIGNAL pipe_gap_y : INTEGER := 200; -- Y position of the vertical gap in the pipe
    SIGNAL pipe_speed : INTEGER := 1; -- Speed per frame (pixels)
BEGIN

    VGA_VS <= vsync_internal;

    -- Divide 50MHz clock to 25MHz for VGA
    clk_divider : PROCESS (CLOCK_50)
        VARIABLE counter : STD_LOGIC := '0';
    BEGIN
        IF rising_edge(CLOCK_50) THEN
            counter := NOT counter;
            clk_25 <= counter;
        END IF;
    END PROCESS;

    -- Instantiate VGA sync generator
    vga_inst : ENTITY work.vga_sync
        PORT MAP(
            clock_25Mhz => clk_25,
            red => red,
            green => green,
            blue => blue,
            red_out => VGA_R(3),
            green_out => VGA_G(3),
            blue_out => VGA_B(3),
            horiz_sync_out => VGA_HS,
            vert_sync_out => vsync_internal,
            pixel_row => pixel_row,
            pixel_column => pixel_column
        );

    -- Instantiate mouse controller
    mouse_inst : ENTITY work.mouse
        PORT MAP(
            clock_25Mhz => clk_25,
            reset => NOT RESET_N,
            mouse_data => PS2_DAT,
            mouse_clk => PS2_CLK,
            left_button => left_button,
            right_button => right_button,
            mouse_cursor_row => mouse_row,
            mouse_cursor_column => mouse_col
        );

    -- Bird movement logic
    PROCESS (vsync_internal)
        VARIABLE temp_velocity : INTEGER;
        VARIABLE temp_y : INTEGER;
    BEGIN
        IF rising_edge(vsync_internal) THEN
            temp_velocity := bird_velocity;
            temp_y := bird_y;

            -- Apply gravity
            temp_velocity := temp_velocity + 1;

            -- Jump if left button is pressed
            IF left_button = '1' THEN
                temp_velocity := - 6;
            END IF;

            -- Apply velocity to position
            temp_y := temp_y + temp_velocity;

            -- Clamp to screen
            IF temp_y < 0 THEN
                temp_y := 0;
            END IF;
            IF temp_y > 480 THEN
                temp_y := 480;
            END IF;

            -- Assign final values back to signals
            bird_velocity <= temp_velocity;
            bird_y <= temp_y;

            --pipe moving logic?
            -- Move pipe left
            pipe_x <= pipe_x - pipe_speed;

            -- Reset pipe if it goes off screen
            IF pipe_x <- 20 THEN
                pipe_x <= 640;
                pipe_gap_y <= (bird_y * 37 + 113) MOD 300 + 60; -- random-looking height
            END IF;

        END IF;

    END PROCESS;
    draw_logic : PROCESS (pixel_row, pixel_column)
        VARIABLE bird_x : INTEGER := 100;
        VARIABLE size : INTEGER := 6;
        CONSTANT pipe_width : INTEGER := 20;
        CONSTANT gap_size : INTEGER := 100;
    BEGIN
        -- Default background color (black)
        red <= '0';
        green <= '0';
        blue <= '0';

        -- Pipe logic first (so bird can be drawn on top if overlapping)
        IF to_integer(unsigned(pixel_column)) >= pipe_x AND
            to_integer(unsigned(pixel_column)) < pipe_x + pipe_width THEN
            IF to_integer(unsigned(pixel_row)) < pipe_gap_y OR
                to_integer(unsigned(pixel_row)) > pipe_gap_y + gap_size THEN
                red <= '0';
                green <= '1';
                blue <= '0'; -- Green pipe
            END IF;
        END IF;

        -- Bird logic (can override pipe if overlapping)
        IF ABS(to_integer(unsigned(pixel_column)) - bird_x) < size AND
            ABS(to_integer(unsigned(pixel_row)) - bird_y) < size THEN
            red <= '1';
            green <= '1';
            blue <= '0'; -- Yellow bird
        END IF;
    END PROCESS;
    -- Connect lower bits of color to 0
    VGA_R(2 DOWNTO 0) <= (OTHERS => '0');
    VGA_G(2 DOWNTO 0) <= (OTHERS => '0');
    VGA_B(2 DOWNTO 0) <= (OTHERS => '0');

END top;