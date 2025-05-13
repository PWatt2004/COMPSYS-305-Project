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

    SIGNAL vsync_internal : STD_LOGIC;

    CONSTANT pipe_spacing : integer := 240;
    CONSTANT pipe_width   : integer := 20;
    CONSTANT gap_size     : integer := 100;

    SIGNAL pipe_x : INTEGER := 640;
    SIGNAL pipe_gap_y : INTEGER := 200;

    SIGNAL pipe2_x : INTEGER := 640 + pipe_spacing;
    SIGNAL pipe2_gap_y : INTEGER := 180;

    SIGNAL pipe3_x : INTEGER := 640 + 2 * pipe_spacing;
    SIGNAL pipe3_gap_y : INTEGER := 150;

    SIGNAL pipe_speed : INTEGER := 1;

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

            pipe_x <= pipe_x - pipe_speed;
            IF pipe_x < -pipe_width THEN
                pipe_x <= pipe3_x + pipe_spacing;
                pipe_gap_y <= (bird_y * 37 + 113) MOD 300 + 60;
            END IF;

            pipe2_x <= pipe2_x - pipe_speed;
            IF pipe2_x < -pipe_width THEN
                pipe2_x <= pipe_x + pipe_spacing;
                pipe2_gap_y <= (bird_y * 53 + 71) MOD 300 + 60;
            END IF;

            pipe3_x <= pipe3_x - pipe_speed;
            IF pipe3_x < -pipe_width THEN
                pipe3_x <= pipe2_x + pipe_spacing;
                pipe3_gap_y <= (bird_y * 97 + 83) MOD 300 + 60;
            END IF;
        END IF;
    END PROCESS;

    draw_logic : PROCESS (pixel_row, pixel_column)
        VARIABLE bird_x : INTEGER := 100;
        VARIABLE size : INTEGER := 6;
    BEGIN
        red <= '0'; green <= '0'; blue <= '0';

        IF to_integer(unsigned(pixel_column)) >= pipe_x AND
           to_integer(unsigned(pixel_column)) < pipe_x + pipe_width THEN
            IF to_integer(unsigned(pixel_row)) < pipe_gap_y OR
               to_integer(unsigned(pixel_row)) > pipe_gap_y + gap_size THEN
                red <= '0'; green <= '1'; blue <= '0';
            END IF;
        END IF;

        IF to_integer(unsigned(pixel_column)) >= pipe2_x AND
           to_integer(unsigned(pixel_column)) < pipe2_x + pipe_width THEN
            IF to_integer(unsigned(pixel_row)) < pipe2_gap_y OR
               to_integer(unsigned(pixel_row)) > pipe2_gap_y + gap_size THEN
                red <= '0'; green <= '1'; blue <= '0';
            END IF;
        END IF;

        IF to_integer(unsigned(pixel_column)) >= pipe3_x AND
           to_integer(unsigned(pixel_column)) < pipe3_x + pipe_width THEN
            IF to_integer(unsigned(pixel_row)) < pipe3_gap_y OR
               to_integer(unsigned(pixel_row)) > pipe3_gap_y + gap_size THEN
                red <= '0'; green <= '1'; blue <= '0';
            END IF;
        END IF;

        IF ABS(to_integer(unsigned(pixel_column)) - bird_x) < size AND
           ABS(to_integer(unsigned(pixel_row)) - bird_y) < size THEN
            red <= '1'; green <= '1'; blue <= '0';
        END IF;
    END PROCESS;

    VGA_R(2 DOWNTO 0) <= (OTHERS => '0');
    VGA_G(2 DOWNTO 0) <= (OTHERS => '0');
    VGA_B(2 DOWNTO 0) <= (OTHERS => '0');

END top;
