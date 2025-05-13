-- This is a modified version of flappy_bird_base.vhd that adds score incrementing
-- and modularizes the design into bird_controller and pipe_controller components.

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

    SIGNAL bird_y : INTEGER;
    SIGNAL bird_velocity : INTEGER;

    SIGNAL pipe_x : INTEGER;
    SIGNAL pipe_gap_y : INTEGER;

    SIGNAL pipe_speed : INTEGER := 1;
    CONSTANT bird_x : INTEGER := 100;
    CONSTANT PIPE_INIT_X1 : INTEGER := 640;
    CONSTANT PIPE_INIT_X2 : INTEGER := 640 + 160;
    CONSTANT PIPE_INIT_X3 : INTEGER := 640 + 2 * 160;
    CONSTANT PIPE_INIT_X4 : INTEGER := 640 + 3 * 160;

    SIGNAL vsync_internal : STD_LOGIC;

    SIGNAL score : INTEGER RANGE 0 TO 999 := 0;
    SIGNAL score_enable : STD_LOGIC;
    SIGNAL pipe2_x, pipe2_gap_y : INTEGER;
    SIGNAL score_enable2 : STD_LOGIC;
    SIGNAL pipe3_x, pipe3_gap_y : INTEGER;
    SIGNAL pipe4_x, pipe4_gap_y : INTEGER;
    SIGNAL score_enable3 : STD_LOGIC;
    SIGNAL score_enable4 : STD_LOGIC;

    COMPONENT bird_controller
        PORT (
            clk           : IN STD_LOGIC;
            reset         : IN STD_LOGIC;
            flap_button   : IN STD_LOGIC;
            bird_y        : OUT INTEGER;
            bird_velocity : OUT INTEGER
        );
    END COMPONENT;

    COMPONENT pipe_controller
        PORT (
            clk            : IN STD_LOGIC;
            reset          : IN STD_LOGIC;
            bird_x         : IN INTEGER;
            bird_y         : IN INTEGER;
            pipe_speed     : IN INTEGER;
            pipe_init_x    : IN INTEGER;
            pipe_x_out     : OUT INTEGER;
            pipe_gap_y_out : OUT INTEGER;
            score_trigger  : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT char_rom
        PORT (
            character_address : IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
            font_row          : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            font_col          : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            clock             : IN  STD_LOGIC;
            rom_mux_output    : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL char_pixel : STD_LOGIC;
    SIGNAL char_code  : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL digit_index : INTEGER range 0 to 2;
    SIGNAL score_ascii : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

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

    bird_inst : ENTITY work.bird_controller
        PORT MAP(
            clk => vsync_internal,
            reset => NOT RESET_N,
            flap_button => left_button,
            bird_y => bird_y,
            bird_velocity => bird_velocity
        );

    -- Pipe 1
    pipe1_inst : ENTITY work.pipe_controller
        PORT MAP(
            clk => vsync_internal,
            reset => NOT RESET_N,
            bird_x => bird_x,
            bird_y => bird_y,
            pipe_speed => pipe_speed,
            pipe_init_x => PIPE_INIT_X1,
            pipe_x_out => pipe_x,
            pipe_gap_y_out => pipe_gap_y,
            score_trigger => score_enable
        );

    -- Pipe 2

    pipe2_inst : ENTITY work.pipe_controller
        PORT MAP(
            clk => vsync_internal,
            reset => NOT RESET_N,
            bird_x => bird_x,
            bird_y => bird_y,
            pipe_speed => pipe_speed,
            pipe_init_x => PIPE_INIT_X2,
            pipe_x_out => pipe2_x,
            pipe_gap_y_out => pipe2_gap_y,
            score_trigger => score_enable2
        );

    -- Pipe 3
    pipe3_inst : ENTITY work.pipe_controller
        PORT MAP(
            clk => vsync_internal,
            reset => NOT RESET_N,
            bird_x => bird_x,
            bird_y => bird_y,
            pipe_speed => pipe_speed,
            pipe_init_x => PIPE_INIT_X3,
            pipe_x_out => pipe3_x,
            pipe_gap_y_out => pipe3_gap_y,
            score_trigger => score_enable3
        );

    -- Pipe 4
    pipe4_inst : ENTITY work.pipe_controller
        PORT MAP(
            clk => vsync_internal,
            reset => NOT RESET_N,
            bird_x => bird_x,
            bird_y => bird_y,
            pipe_speed => pipe_speed,
            pipe_init_x => PIPE_INIT_X4,
            pipe_x_out => pipe4_x,
            pipe_gap_y_out => pipe4_gap_y,
            score_trigger => score_enable4
        );

    digit_index <= to_integer(unsigned(pixel_column(8 DOWNTO 7)));

    PROCESS(score, digit_index)
        VARIABLE digit : INTEGER;
    BEGIN
        CASE digit_index IS
            WHEN 0 => digit := (score / 100) MOD 10;
            WHEN 1 => digit := (score / 10) MOD 10;
            WHEN OTHERS => digit := score MOD 10;
        END CASE;
        score_ascii <= std_logic_vector(to_unsigned(48 + digit, 8));
        char_code <= score_ascii(5 DOWNTO 0);
    END PROCESS;

    score_rom : char_rom
        PORT MAP (
            character_address => char_code,
            font_row => pixel_row(5 DOWNTO 3),
            font_col => pixel_column(5 DOWNTO 3),
            clock => clk_25,
            rom_mux_output => char_pixel
        );

    score_process : PROCESS (vsync_internal)
    BEGIN
        IF rising_edge(vsync_internal) THEN
            IF RESET_N = '0' THEN
                score <= 0;
            ELSIF score_enable = '1' OR score_enable2 = '1' OR score_enable3 = '1' OR score_enable4 = '1' THEN
                score <= score + 1;
            END IF;
        END IF;
    END PROCESS;

    draw_logic : PROCESS (pixel_row, pixel_column)
        VARIABLE size : INTEGER := 6;
    BEGIN
        red <= '0'; green <= '0'; blue <= '0';

        IF (to_integer(unsigned(pixel_column)) >= pipe_x AND
            to_integer(unsigned(pixel_column)) < pipe_x + 20 AND
            (to_integer(unsigned(pixel_row)) < pipe_gap_y OR to_integer(unsigned(pixel_row)) > pipe_gap_y + 100)) OR
           (to_integer(unsigned(pixel_column)) >= pipe2_x AND
            to_integer(unsigned(pixel_column)) < pipe2_x + 20 AND
            (to_integer(unsigned(pixel_row)) < pipe2_gap_y OR to_integer(unsigned(pixel_row)) > pipe2_gap_y + 100)) OR
           (to_integer(unsigned(pixel_column)) >= pipe3_x AND
            to_integer(unsigned(pixel_column)) < pipe3_x + 20 AND
            (to_integer(unsigned(pixel_row)) < pipe3_gap_y OR to_integer(unsigned(pixel_row)) > pipe3_gap_y + 100)) OR
           (to_integer(unsigned(pixel_column)) >= pipe4_x AND
            to_integer(unsigned(pixel_column)) < pipe4_x + 20 AND
            (to_integer(unsigned(pixel_row)) < pipe4_gap_y OR to_integer(unsigned(pixel_row)) > pipe4_gap_y + 100)) THEN
            red <= '0'; green <= '1'; blue <= '0';
        END IF;

        IF ABS(to_integer(unsigned(pixel_column)) - bird_x) < size AND
           ABS(to_integer(unsigned(pixel_row)) - bird_y) < size THEN
            red <= '1'; green <= '1'; blue <= '0';
        END IF;

        IF to_integer(unsigned(pixel_row)) < 16 AND
           to_integer(unsigned(pixel_column)) >= 272 AND
           to_integer(unsigned(pixel_column)) < 368 THEN
            IF char_pixel = '1' THEN
                red <= '1'; green <= '1'; blue <= '1';
            END IF;
        END IF;
    END PROCESS;

    VGA_R(2 DOWNTO 0) <= (OTHERS => '0');
    VGA_G(2 DOWNTO 0) <= (OTHERS => '0');
    VGA_B(2 DOWNTO 0) <= (OTHERS => '0');

END top;
