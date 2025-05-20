-- flappy_bird_base.vhd (updated to use display_text with char_rom)
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
<<<<<<< Updated upstream
        VGA_VS : OUT STD_LOGIC
=======
        VGA_VS : OUT STD_LOGIC;
        LEDR : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        SW : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        HEX2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
=======

    COMPONENT fsm
        PORT (
<<<<<<< Updated upstream
            pixel_row     : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            pixel_column  : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            bg_red        : OUT STD_LOGIC;
            bg_green      : OUT STD_LOGIC;
            bg_blue       : OUT STD_LOGIC
        );
    END COMPONENT;

	component display_text
		 port (
			  clk               : in  std_logic;
			  pixel_row         : in  std_logic_vector(9 downto 0);
			  pixel_column      : in  std_logic_vector(9 downto 0);
			  score             : in  std_logic_vector(11 downto 0);
			  health_percentage : in  std_logic_vector(11 downto 0);
			  text_rgb          : out std_logic_vector(11 downto 0);
			  text_on           : out std_logic
		 );
	end component;
>>>>>>> Stashed changes
=======
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            key0 : IN STD_LOGIC;
            key1 : IN STD_LOGIC;
            click : IN STD_LOGIC;
            pipe_hit : IN STD_LOGIC;
            life_zero : IN STD_LOGIC;
            game_active : OUT STD_LOGIC;
            show_mode_text : OUT STD_LOGIC;
            game_over_flag : OUT STD_LOGIC;
            mode_select : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT display_text
        PORT (
            clk : IN STD_LOGIC;
            pixel_row : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            pixel_column : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            score : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
            health_percentage : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
            text_rgb : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
            text_on : OUT STD_LOGIC;
            title_on : IN STD_LOGIC;
            score_on : IN STD_LOGIC;
            hp_on : IN STD_LOGIC;
            mode_select : IN STD_LOGIC;
            mode_on : IN STD_LOGIC
        );
    END COMPONENT;
>>>>>>> Stashed changes

    TYPE INTEGER_VECTOR IS ARRAY (NATURAL RANGE <>) OF INTEGER;

    SIGNAL clk_25 : STD_LOGIC;
    SIGNAL red, green, blue : STD_LOGIC;
    SIGNAL pixel_row, pixel_column : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL mouse_row, mouse_col : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL left_button, right_button : STD_LOGIC;

    SIGNAL bird_y : INTEGER;
    SIGNAL bird_velocity : INTEGER;

    SIGNAL pipe_hit : STD_LOGIC;
    SIGNAL pipe_x_array : INTEGER_VECTOR(0 TO 3);
    SIGNAL pipe_x_out : STD_LOGIC_VECTOR(39 DOWNTO 0);
    SIGNAL pipe_y_out : STD_LOGIC_VECTOR(39 DOWNTO 0);
    SIGNAL pipe_y_array : INTEGER_VECTOR(0 TO 3);

<<<<<<< Updated upstream
    CONSTANT bird_x : INTEGER := 100;
    SIGNAL vsync_internal : STD_LOGIC;

    

	signal text_on_signal : std_logic;
	signal text_rgb_signal : std_logic_vector(11 downto 0);
	signal score : std_logic_vector(11 downto 0) := (others => '0');
	signal health_percentage : std_logic_vector(11 downto 0) := (others => '0');

BEGIN

=======
    SIGNAL vsync_internal : STD_LOGIC;
    SIGNAL bg_red, bg_green, bg_blue : STD_LOGIC;

    SIGNAL score : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '0');
    SIGNAL health_percentage : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '1');

    SIGNAL text_rgb_signal : STD_LOGIC_VECTOR(11 DOWNTO 0);
    SIGNAL text_on_signal : STD_LOGIC;

    SIGNAL game_active : STD_LOGIC;
    SIGNAL show_mode_text : STD_LOGIC;
    SIGNAL game_over_flag : STD_LOGIC;
    SIGNAL mode_select_sig : STD_LOGIC;

    SIGNAL blink_counter : INTEGER := 0;
    SIGNAL blink_flag : STD_LOGIC := '0';

    CONSTANT bird_x : INTEGER := 100;
    SIGNAL number : INTEGER := 590;
    SIGNAL hundreds, tens, ones : STD_LOGIC_VECTOR(3 DOWNTO 0);

BEGIN

    -- Blink effect toggler
    blink_process : PROCESS (CLOCK_50)
    BEGIN
        IF rising_edge(CLOCK_50) THEN
            IF blink_counter < 25000000 THEN  -- ~0.5s at 50MHz
                blink_counter <= blink_counter + 1;
            ELSE
                blink_counter <= 0;
                blink_flag <= NOT blink_flag;
            END IF;
        END IF;
    END PROCESS;

    -- 7-segment displays
    hundred_display : ENTITY work.BCD_to_SevenSeg PORT MAP(BCD_digit => hundreds, SevenSeg_out => HEX2);
    ten_display     : ENTITY work.BCD_to_SevenSeg PORT MAP(BCD_digit => tens, SevenSeg_out => HEX1);
    one_display     : ENTITY work.BCD_to_SevenSeg PORT MAP(BCD_digit => ones, SevenSeg_out => HEX0);

    digit_split : PROCESS (number)
        VARIABLE temp : INTEGER;
    BEGIN
        temp := number;
        hundreds <= STD_LOGIC_VECTOR(to_unsigned((temp / 100) MOD 10, 4));
        tens     <= STD_LOGIC_VECTOR(to_unsigned((temp / 10) MOD 10, 4));
        ones     <= STD_LOGIC_VECTOR(to_unsigned(temp MOD 10, 4));
    END PROCESS;

    LEDR(0) <= left_button;
>>>>>>> Stashed changes
    VGA_VS <= vsync_internal;

    clk_divider : PROCESS (CLOCK_50)
        VARIABLE counter : STD_LOGIC := '0';
    BEGIN
        IF rising_edge(CLOCK_50) THEN
            counter := NOT counter;
            clk_25 <= counter;
        END IF;
    END PROCESS;

    vga_inst : ENTITY work.vga_sync PORT MAP(
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

    mouse_inst : ENTITY work.mouse PORT MAP(
        clock_25Mhz => clk_25,
        reset => NOT RESET_N,
        mouse_data => PS2_DAT,
        mouse_clk => PS2_CLK,
        left_button => left_button,
        right_button => right_button,
        mouse_cursor_row => mouse_row,
        mouse_cursor_column => mouse_col
    );

<<<<<<< Updated upstream
    bird_inst : ENTITY work.bird_controller
        PORT MAP(
            clk => vsync_internal,
            reset => NOT RESET_N,
            flap_button => left_button,
            bird_y => bird_y,
            bird_velocity => bird_velocity
        );

<<<<<<< Updated upstream
=======
    background_inst : ENTITY work.background
        PORT MAP(
            pixel_row    => pixel_row,
            pixel_column => pixel_column,
            bg_red       => bg_red,
            bg_green     => bg_green,
            bg_blue      => bg_blue
        );

>>>>>>> Stashed changes
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

		display_text_inst : entity work.display_text
			 port map (
				  clk               => clk_25,
				  pixel_row         => pixel_row,
				  pixel_column      => pixel_column,
				  score             => score,              -- std_logic_vector(11 downto 0)
				  health_percentage => health_percentage, -- std_logic_vector(11 downto 0)
				  text_rgb          => text_rgb_signal,
				  text_on           => text_on_signal
			 );
		 
    pipe_x_array(0) <= to_integer(unsigned(pipe_x_out(9 downto 0)));
    pipe_x_array(1) <= to_integer(unsigned(pipe_x_out(19 downto 10)));
    pipe_x_array(2) <= to_integer(unsigned(pipe_x_out(29 downto 20)));
    pipe_x_array(3) <= to_integer(unsigned(pipe_x_out(39 downto 30)));

    pipe_y_array(0) <= to_integer(unsigned(pipe_y_out(9 downto 0)));
    pipe_y_array(1) <= to_integer(unsigned(pipe_y_out(19 downto 10)));
    pipe_y_array(2) <= to_integer(unsigned(pipe_y_out(29 downto 20)));
    pipe_y_array(3) <= to_integer(unsigned(pipe_y_out(39 downto 30)));
=======
    bird_inst : ENTITY work.bird_controller PORT MAP(
        clk => vsync_internal,
        reset => NOT RESET_N,
        flap_button => left_button,
        bird_y => bird_y,
        bird_velocity => bird_velocity,
        bird_altitude => number
    );

    background_inst : ENTITY work.background PORT MAP(
        clk => clk_25,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        bg_red => bg_red,
        bg_green => bg_green,
        bg_blue => bg_blue
    );

    pipe_ctrl_inst : ENTITY work.pipe_controller PORT MAP(
        clk => vsync_internal,
        reset => NOT RESET_N,
        bird_x => bird_x,
        bird_y => bird_y,
        pipe_hit => pipe_hit,
        pipe_x_out => pipe_x_out,
        pipe_y_out => pipe_y_out
    );

    fsm_inst : ENTITY work.fsm PORT MAP(
        clk => vsync_internal,
        reset => NOT RESET_N,
        key0 => SW(0),
        key1 => SW(1),
        click => left_button,
        pipe_hit => pipe_hit,
        life_zero => '0',
        game_active => game_active,
        show_mode_text => show_mode_text,
        game_over_flag => game_over_flag,
        mode_select => mode_select_sig
    );

    display_text_inst : ENTITY work.display_text PORT MAP(
        clk => clk_25,
        pixel_row => pixel_row,
        pixel_column => pixel_column,
        score => score,
        health_percentage => health_percentage,
        text_rgb => text_rgb_signal,
        text_on => text_on_signal,
        title_on => show_mode_text,
        score_on => SW(2),
        hp_on => SW(3),
        mode_select => mode_select_sig,
        mode_on => show_mode_text
    );

    pipe_x_array(0) <= to_integer(unsigned(pipe_x_out(9 DOWNTO 0)));
    pipe_x_array(1) <= to_integer(unsigned(pipe_x_out(19 DOWNTO 10)));
    pipe_x_array(2) <= to_integer(unsigned(pipe_x_out(29 DOWNTO 20)));
    pipe_x_array(3) <= to_integer(unsigned(pipe_x_out(39 DOWNTO 30)));

    pipe_y_array(0) <= to_integer(unsigned(pipe_y_out(9 DOWNTO 0)));
    pipe_y_array(1) <= to_integer(unsigned(pipe_y_out(19 DOWNTO 10)));
    pipe_y_array(2) <= to_integer(unsigned(pipe_y_out(29 DOWNTO 20)));
    pipe_y_array(3) <= to_integer(unsigned(pipe_y_out(39 DOWNTO 30)));
>>>>>>> Stashed changes

    draw_logic : PROCESS (pixel_row, pixel_column)
        VARIABLE size : INTEGER := 6;
    BEGIN
        red <= '0'; green <= '0'; blue <= '0';

        FOR i IN 0 TO 3 LOOP
            IF (to_integer(unsigned(pixel_column)) >= pipe_x_array(i) AND
<<<<<<< Updated upstream
            to_integer(unsigned(pixel_column)) < pipe_x_array(i) + 20 AND
            (to_integer(unsigned(pixel_row)) < pipe_y_array(i) OR to_integer(unsigned(pixel_row)) > pipe_y_array(i) + 100)) THEN
=======
                to_integer(unsigned(pixel_column)) < pipe_x_array(i) + 20 AND
                (to_integer(unsigned(pixel_row)) < pipe_y_array(i) OR
                 to_integer(unsigned(pixel_row)) > pipe_y_array(i) + 100)) THEN
>>>>>>> Stashed changes
                red <= '0'; green <= '1'; blue <= '0';
            END IF;
        END LOOP;

        IF ABS(to_integer(unsigned(pixel_column)) - bird_x) < size AND
           ABS(to_integer(unsigned(pixel_row)) - bird_y) < size THEN
            red <= '1'; green <= '1'; blue <= '0';
        END IF;

        IF text_on_signal = '1' AND blink_flag = '1' THEN
            red <= text_rgb_signal(11);
            green <= text_rgb_signal(5);
            blue <= text_rgb_signal(0);
        END IF;
    END PROCESS;

    VGA_R(2 DOWNTO 0) <= (OTHERS => '0');
    VGA_G(2 DOWNTO 0) <= (OTHERS => '0');
    VGA_B(2 DOWNTO 0) <= (OTHERS => '0');

END top;
