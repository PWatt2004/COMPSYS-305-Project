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

    CONSTANT PIPE_COUNT     : INTEGER := 4;
    CONSTANT PIPE_SPACING   : INTEGER := 160;
    CONSTANT PIPE_WIDTH     : INTEGER := 20;
    CONSTANT GAP_SIZE       : INTEGER := 100;
    CONSTANT SCREEN_WIDTH   : INTEGER := 640;

    SIGNAL clk_25 : STD_LOGIC;
    SIGNAL red, green, blue : STD_LOGIC;
    SIGNAL pixel_row, pixel_column : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL mouse_row, mouse_col : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL left_button, right_button : STD_LOGIC;
    SIGNAL vsync_internal : STD_LOGIC;

    SIGNAL bird_y : INTEGER := 240;
    SIGNAL bird_velocity : INTEGER := 0;

    TYPE pipe_array IS ARRAY(0 TO PIPE_COUNT - 1) OF INTEGER;
    SIGNAL pipe_x     : pipe_array := (others => SCREEN_WIDTH + 0 * PIPE_SPACING);
    SIGNAL pipe_gap_y : pipe_array := (others => 200);

    SIGNAL pipe_speed : INTEGER := 2;
    SIGNAL score      : INTEGER := 0;

BEGIN

    VGA_VS <= vsync_internal;

    clk_divider : PROCESS (CLOCK_50)
        VARIABLE counter : STD_LOGIC := '0';
    BEGIN
        IF rising_edge(CLOCK_50) THEN
            counter := NOT counter;
            clk_25 <= counter;
        END IF;
    END PROCESS;

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

    PROCESS (vsync_internal)
        VARIABLE temp_velocity : INTEGER;
        VARIABLE temp_y : INTEGER;
    BEGIN
        IF rising_edge(vsync_internal) THEN
            temp_velocity := bird_velocity;
            temp_y := bird_y;

            temp_velocity := temp_velocity + 1;

            IF left_button = '1' THEN
                temp_velocity := -6;
            END IF;

            temp_y := temp_y + temp_velocity;

            IF temp_y < 0 THEN temp_y := 0; END IF;
            IF temp_y > 480 THEN temp_y := 480; END IF;

            bird_velocity <= temp_velocity;
            bird_y <= temp_y;

            FOR i IN 0 TO PIPE_COUNT - 1 LOOP
                pipe_x(i) <= pipe_x(i) - pipe_speed;

                IF pipe_x(i) < -PIPE_WIDTH THEN
                    pipe_x(i) <= SCREEN_WIDTH + (PIPE_SPACING * (PIPE_COUNT - 1));
                    pipe_gap_y(i) <= (bird_y * (i+1) * 43 + 59) MOD 300 + 60;

                    -- Increase score when pipe wraps
                    score <= score + 1;
                END IF;
            END LOOP;
        END IF;
    END PROCESS;

    draw_logic : PROCESS (pixel_row, pixel_column)
        VARIABLE bird_x : INTEGER := 100;
        VARIABLE size   : INTEGER := 6;
        VARIABLE px_col, px_row : INTEGER;
    BEGIN
        red <= '0'; green <= '0'; blue <= '0';

        px_col := to_integer(unsigned(pixel_column));
        px_row := to_integer(unsigned(pixel_row));

        -- Pipe drawing
        FOR i IN 0 TO PIPE_COUNT - 1 LOOP
            IF px_col >= pipe_x(i) AND px_col < pipe_x(i) + PIPE_WIDTH THEN
                IF px_row < pipe_gap_y(i) OR px_row > pipe_gap_y(i) + GAP_SIZE THEN
                    red <= '0'; green <= '1'; blue <= '0';
                END IF;
            END IF;
        END LOOP;

        -- Bird drawing
        IF ABS(px_col - bird_x) < size AND ABS(px_row - bird_y) < size THEN
            red <= '1'; green <= '1'; blue <= '0';
        END IF;
    END PROCESS;

    VGA_R(2 DOWNTO 0) <= (OTHERS => '0');
    VGA_G(2 DOWNTO 0) <= (OTHERS => '0');
    VGA_B(2 DOWNTO 0) <= (OTHERS => '0');

END top;
