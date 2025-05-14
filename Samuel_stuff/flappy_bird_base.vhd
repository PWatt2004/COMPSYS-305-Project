-- flappy_bird_base.vhd (refactored to use a single multi-pipe controller)
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

    COMPONENT char_rom
        PORT (
            character_address : IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
            font_row          : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            font_col          : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            clock             : IN  STD_LOGIC;
            rom_mux_output    : OUT STD_LOGIC
        );
    END COMPONENT;

    TYPE INTEGER_VECTOR IS ARRAY (NATURAL RANGE <>) OF INTEGER;

    SIGNAL clk_25 : STD_LOGIC;
    SIGNAL red, green, blue : STD_LOGIC;
    SIGNAL pixel_row, pixel_column : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL mouse_row, mouse_col : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL left_button, right_button : STD_LOGIC;
    SIGNAL text_pixel : STD_LOGIC;

    SIGNAL bird_y : INTEGER;
    SIGNAL bird_velocity : INTEGER;

    SIGNAL pipe_hit : STD_LOGIC;
    SIGNAL pipe_x_array : INTEGER_VECTOR(0 TO 3);
    SIGNAL pipe_x_out : STD_LOGIC_VECTOR(39 DOWNTO 0);
    SIGNAL pipe_y_out : STD_LOGIC_VECTOR(39 DOWNTO 0);
    SIGNAL pipe_y_array : INTEGER_VECTOR(0 TO 3);

    CONSTANT bird_x : INTEGER := 100;
    SIGNAL vsync_internal : STD_LOGIC;

    SIGNAL score : INTEGER RANGE 0 TO 999 := 0;
    SIGNAL char_pixel : STD_LOGIC;
    SIGNAL char_code  : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL digit_index : INTEGER range 0 to 2;
    SIGNAL score_ascii : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');

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

    pipe_ctrl_inst : ENTITY work.pipe_controller
        PORT MAP(
            clk => vsync_internal,
            reset => NOT RESET_N,
            bird_x => bird_x,
            bird_y => bird_y,
            pipe_hit => pipe_hit,
            pipe_x_out => pipe_x_out,
            pipe_y_out => pipe_y_out
        );

    -- Decode pipe_x_out to pipe_x_array
    pipe_x_array(0) <= to_integer(unsigned(pipe_x_out(9 downto 0)));
    pipe_x_array(1) <= to_integer(unsigned(pipe_x_out(19 downto 10)));
    pipe_x_array(2) <= to_integer(unsigned(pipe_x_out(29 downto 20)));
    pipe_x_array(3) <= to_integer(unsigned(pipe_x_out(39 downto 30)));

    -- Decode pipe_y_out to pipe_y_array
    pipe_y_array(0) <= to_integer(unsigned(pipe_y_out(9 downto 0)));
    pipe_y_array(1) <= to_integer(unsigned(pipe_y_out(19 downto 10)));
    pipe_y_array(2) <= to_integer(unsigned(pipe_y_out(29 downto 20)));
    pipe_y_array(3) <= to_integer(unsigned(pipe_y_out(39 downto 30)));

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
            ELSIF pipe_hit = '1' THEN
                score <= score + 1;
            END IF;
        END IF;
    END PROCESS;

    draw_logic : PROCESS (pixel_row, pixel_column)
        VARIABLE size : INTEGER := 6;
    BEGIN
        red <= '0'; green <= '0'; blue <= '0';

        FOR i IN 0 TO 3 LOOP
            IF (to_integer(unsigned(pixel_column)) >= pipe_x_array(i) AND
                to_integer(unsigned(pixel_column)) < pipe_x_array(i) + 20 AND
                (to_integer(unsigned(pixel_row)) < 200 OR to_integer(unsigned(pixel_row)) > 300)) THEN
                red <= '0'; green <= '1'; blue <= '0';
            END IF;
        END LOOP;

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
