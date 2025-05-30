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
    VGA_VS : OUT STD_LOGIC;
    LEDR : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    SW : IN STD_LOGIC_VECTOR(9 DOWNTO 0);

    HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    HEX1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
    HEX2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)

  );
END ENTITY;

ARCHITECTURE top OF flappy_bird_base IS

  COMPONENT char_rom
    PORT (
      character_address : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
      font_row : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      font_col : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      clock : IN STD_LOGIC;
      rom_mux_output : OUT STD_LOGIC
    );
  END COMPONENT;

  COMPONENT background
    PORT (
      clk : IN STD_LOGIC;
      pixel_row : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
      pixel_column : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
      bg_red : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      bg_green : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      bg_blue : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
  END COMPONENT;

  COMPONENT display_text
    PORT (
      clk : IN STD_LOGIC;
      pixel_row : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
      pixel_column : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
      score : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
      text_rgb : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
      text_on : OUT STD_LOGIC
    );
  END COMPONENT;

  COMPONENT bird2_rom
    PORT (
      clk : IN STD_LOGIC;
      addr : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
      data : OUT STD_LOGIC_VECTOR(11 DOWNTO 0) -- RGB: 4+4+4 bits = 12 bits
    );
  END COMPONENT;
  TYPE INTEGER_VECTOR IS ARRAY (NATURAL RANGE <>) OF INTEGER;

  SIGNAL clk_25 : STD_LOGIC;
  SIGNAL red, green, blue : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL pixel_row, pixel_column : STD_LOGIC_VECTOR(9 DOWNTO 0);
  SIGNAL mouse_row, mouse_col : STD_LOGIC_VECTOR(9 DOWNTO 0);
  SIGNAL left_button, right_button : STD_LOGIC;
  SIGNAL lose_reset_click : STD_LOGIC;

  SIGNAL bird_y : INTEGER;
  SIGNAL bird_velocity : INTEGER;

  SIGNAL pipe_hit : STD_LOGIC;
  SIGNAL pipe_x_array : INTEGER_VECTOR(0 TO 3);
  SIGNAL pipe_x_out : STD_LOGIC_VECTOR(39 DOWNTO 0);
  SIGNAL pipe_y_out : STD_LOGIC_VECTOR(39 DOWNTO 0);
  SIGNAL pipe_y_array : INTEGER_VECTOR(0 TO 3);

  SIGNAL vsync_internal : STD_LOGIC;
  SIGNAL bg_red, bg_green, bg_blue : STD_LOGIC_VECTOR(3 DOWNTO 0);

  SIGNAL score : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '0');

  SIGNAL text_rgb_signal : STD_LOGIC_VECTOR(11 DOWNTO 0);
  SIGNAL text_on_signal : STD_LOGIC;

  CONSTANT bird_x : INTEGER := 100;

  SIGNAL number : INTEGER := 590;
  SIGNAL hundreds, tens, ones : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL game_active : STD_LOGIC;
  SIGNAL in_title : STD_LOGIC;
  SIGNAL in_lose : STD_LOGIC;

  SIGNAL start_training : STD_LOGIC;
  SIGNAL start_game : STD_LOGIC;

  SIGNAL mode_training : STD_LOGIC;

  SIGNAL label1_on : STD_LOGIC;
  SIGNAL label2_on : STD_LOGIC;
  SIGNAL label_title_on : STD_LOGIC;
  SIGNAL label_again_on : STD_LOGIC;
  SIGNAL label_gameover_on : STD_LOGIC;

  SIGNAL bird_limit_hit : STD_LOGIC;

  SIGNAL health : INTEGER := 50;
  SIGNAL hp_string : STRING(1 TO 8) := "HP-00999"; -- Displayed string

  SIGNAL health_zero : STD_LOGIC;

  SIGNAL score_value : INTEGER := 0;
  SIGNAL score_string : STRING(1 TO 11) := "SCORE-00000"; -- "SC-" + 5-digit score

  SIGNAL pipe_passed_tick : STD_LOGIC;

  SIGNAL pipe_speed : INTEGER := 1;

  SIGNAL bird_rgb : STD_LOGIC_VECTOR(11 DOWNTO 0);
  SIGNAL bird_addr : STD_LOGIC_VECTOR(9 DOWNTO 0);
  SIGNAL bird_on : STD_LOGIC;

  -- Sprite size (e.g., 32x32)
  CONSTANT bird_size : INTEGER := 32;
BEGIN
  -- Instantiate 7-segment decoders
  hundred_display : ENTITY work.BCD_to_SevenSeg
    PORT MAP(
      BCD_digit => hundreds,
      SevenSeg_out => HEX2
    );

  ten_display : ENTITY work.BCD_to_SevenSeg
    PORT MAP(
      BCD_digit => tens,
      SevenSeg_out => HEX1
    );

  one_display : ENTITY work.BCD_to_SevenSeg
    PORT MAP(
      BCD_digit => ones,
      SevenSeg_out => HEX0
    );

  digit_split : PROCESS (number)
    VARIABLE temp : INTEGER;
  BEGIN
    temp := number;
    hundreds <= STD_LOGIC_VECTOR(to_unsigned((temp / 100) MOD 10, 4));
    tens <= STD_LOGIC_VECTOR(to_unsigned((temp / 10) MOD 10, 4));
    ones <= STD_LOGIC_VECTOR(to_unsigned(temp MOD 10, 4));
  END PROCESS;

  LEDR(0) <= left_button;
  LEDR(1) <= pipe_hit AND game_active;
  LEDR(2) <= bird_limit_hit AND game_active;
  VGA_VS <= vsync_internal;
  lose_reset_click <= '1' WHEN (in_lose = '1' AND left_button = '1') ELSE
    '0';
  health_zero <= '1' WHEN health <= 0 ELSE
    '0';

  clk_divider : PROCESS (CLOCK_50)
    VARIABLE counter : STD_LOGIC := '0';
  BEGIN
    IF rising_edge(CLOCK_50) THEN
      counter := NOT counter;
      clk_25 <= counter;
    END IF;
  END PROCESS;

  PROCESS (vsync_internal)
    VARIABLE temp : INTEGER;
    VARIABLE hp_temp : STRING(1 TO 8);
    VARIABLE s_temp : INTEGER;
    VARIABLE s_text : STRING(1 TO 11);
  BEGIN
    IF rising_edge(vsync_internal) THEN
      -- Handle health logic
      IF RESET_N = '0' OR in_title = '1' THEN
        health <= 50;
        score_value <= 0;
      ELSIF start_game = '1' THEN
        health <= 100;
      ELSIF game_active = '1' THEN
        -- Decrement health
        IF (bird_limit_hit = '1' OR pipe_hit = '1') AND health > 0 THEN
          health <= health - 1;
        END IF;
      END IF;
      -- Reset speed on title screen
      IF RESET_N = '0' OR in_title = '1' THEN
        pipe_speed <= 1;

        -- Increase speed gradually in game mode
      ELSIF game_active = '1' AND mode_training = '0' THEN
        pipe_speed <= 1 + ((score_value / 5) * 1); -- +y speed per x points
      END IF;

      -- Format health as string
      temp := health;
      hp_temp(1) := 'H';
      hp_temp(2) := 'P';
      hp_temp(3) := '-';
      hp_temp(4) := CHARACTER'VAL((temp / 1000) MOD 10 + CHARACTER'POS('0'));
      hp_temp(5) := CHARACTER'VAL((temp / 100) MOD 10 + CHARACTER'POS('0'));
      hp_temp(6) := CHARACTER'VAL((temp / 10) MOD 10 + CHARACTER'POS('0'));
      hp_temp(7) := CHARACTER'VAL(temp MOD 10 + CHARACTER'POS('0'));
      hp_temp(8) := ' ';
      hp_string <= hp_temp;

      -- Handle score  logic
      IF game_active = '1' AND pipe_passed_tick = '1' THEN
        score_value <= score_value + 1;
      END IF;

      -- Format score_value into score_string
      s_temp := score_value;
      s_text(1) := 'S';
      s_text(2) := 'C';
      s_text(3) := 'O';
      s_text(4) := 'R';
      s_text(5) := 'E';
      s_text(6) := '-';
      s_text(7) := CHARACTER'VAL((s_temp / 10000) MOD 10 + CHARACTER'POS('0'));
      s_text(8) := CHARACTER'VAL((s_temp / 1000) MOD 10 + CHARACTER'POS('0'));
      s_text(9) := CHARACTER'VAL((s_temp / 100) MOD 10 + CHARACTER'POS('0'));
      s_text(10) := CHARACTER'VAL((s_temp / 10) MOD 10 + CHARACTER'POS('0'));
      s_text(11) := CHARACTER'VAL(s_temp MOD 10 + CHARACTER'POS('0'));

      score_string <= s_text;
    END IF;
  END PROCESS;

  vga_inst : ENTITY work.vga_sync
    PORT MAP(
      clock_25Mhz => clk_25,
      red => red,
      green => green,
      blue => blue,
      red_out => VGA_R,
      green_out => VGA_G,
      blue_out => VGA_B,
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
      bird_velocity => bird_velocity,
      bird_altitude => number,
      game_active => game_active,
      bird_limit_hit => bird_limit_hit,
      in_title => in_title
    );

  background_inst : ENTITY work.background
    PORT MAP(
      clk => clk_25,
      pixel_row => pixel_row,
      pixel_column => pixel_column,
      bg_red => bg_red,
      bg_green => bg_green,
      bg_blue => bg_blue
    );

  pipe_ctrl_inst : ENTITY work.pipe_controller
    PORT MAP(
      clk => vsync_internal,
      reset => NOT RESET_N,
      bird_x => bird_x,
      bird_y => bird_y,
      pipe_hit => pipe_hit,
      pipe_x_out => pipe_x_out,
      pipe_y_out => pipe_y_out,
      game_active => game_active,
      in_title => in_title,
      pipe_passed_tick => pipe_passed_tick,
      speed => pipe_speed
    );

  display_text_inst : ENTITY work.display_text
    PORT MAP(
      clk => clk_25,
      pixel_row => pixel_row,
      pixel_column => pixel_column,
      score => score,
      text_rgb => text_rgb_signal,
      text_on => text_on_signal,
      title_on => SW(0),
      score_on => SW(1),
      score_string => score_string,
      hp_on => SW(2),
      hp_string => hp_string
    );

  menu_ui : ENTITY work.menu_controller
    PORT MAP(
      clk => vsync_internal,
      in_title => in_title,
      mouse_x => mouse_col,
      mouse_y => mouse_row,
      mouse_click => left_button,
      start_training => start_training,
      start_game => start_game
    );

  fsm_inst : ENTITY work.game_fsm
    PORT MAP(
      clk => vsync_internal,
      reset => NOT RESET_N,
      start_training => start_training,
      start_game => start_game,
      pipe_hit => pipe_hit,
      click_reset => lose_reset_click,
      mode_training => mode_training, -- output from FSM now
      game_active => game_active,
      in_title => in_title,
      in_lose => in_lose,
      health_zero => health_zero

    );

  label_training : ENTITY work.draw_label
    GENERIC MAP(TEXT_LENGTH => 13, SCALE => 1)
    PORT MAP(
      clk => clk_25,
      active => in_title,
      pixel_x => pixel_column,
      pixel_y => pixel_row,
      start_x => 460,
      start_y => 160,
      text_string => "TRAINING MODE",
      pixel_on => label1_on
    );

  label_game : ENTITY work.draw_label
    GENERIC MAP(TEXT_LENGTH => 12, SCALE => 1)
    PORT MAP(
      clk => clk_25,
      active => in_title,
      pixel_x => pixel_column,
      pixel_y => pixel_row,
      start_x => 460,
      start_y => 230,
      text_string => "SINGLEPLAYER",
      pixel_on => label2_on
    );

  label_title : ENTITY work.draw_label
    GENERIC MAP(TEXT_LENGTH => 11, SCALE => 2)
    PORT MAP(
      clk => clk_25,
      active => in_title,
      pixel_x => pixel_column,
      pixel_y => pixel_row,
      start_x => 220,
      start_y => 80,
      text_string => "TOASTY BIRD",
      pixel_on => label_title_on
    );

  label_again : ENTITY work.draw_label
    GENERIC MAP(TEXT_LENGTH => 17, SCALE => 1)
    PORT MAP(
      clk => clk_25,
      active => in_lose,
      pixel_x => pixel_column,
      pixel_y => pixel_row,
      start_x => 240,
      start_y => 260,
      text_string => "CLICK TO GO AGAIN",
      pixel_on => label_again_on
    );

  label_gameover : ENTITY work.draw_label
    GENERIC MAP(TEXT_LENGTH => 9, SCALE => 3)
    PORT MAP(
      clk => clk_25,
      active => in_lose,
      pixel_x => pixel_column,
      pixel_y => pixel_row,
      start_x => 200,
      start_y => 220,
      text_string => "GAME OVER",
      pixel_on => label_gameover_on
    );


  -- Decode pipe_x_out to pipe_x_array
  pipe_x_array(0) <= to_integer(unsigned(pipe_x_out(9 DOWNTO 0)));
  pipe_x_array(1) <= to_integer(unsigned(pipe_x_out(19 DOWNTO 10)));
  pipe_x_array(2) <= to_integer(unsigned(pipe_x_out(29 DOWNTO 20)));
  pipe_x_array(3) <= to_integer(unsigned(pipe_x_out(39 DOWNTO 30)));

  -- Decode pipe_y_out to pipe_y_array
  pipe_y_array(0) <= to_integer(unsigned(pipe_y_out(9 DOWNTO 0)));
  pipe_y_array(1) <= to_integer(unsigned(pipe_y_out(19 DOWNTO 10)));
  pipe_y_array(2) <= to_integer(unsigned(pipe_y_out(29 DOWNTO 20)));
  pipe_y_array(3) <= to_integer(unsigned(pipe_y_out(39 DOWNTO 30)));

  draw_logic : PROCESS (pixel_row, pixel_column)
    VARIABLE size : INTEGER := 6;
    variable rel_x : integer;
    variable rel_y : integer;
  BEGIN
    red <= bg_red;
    green <= bg_green;
    blue <= bg_blue;

    -- Check for pipe 0
    IF (to_integer(unsigned(pixel_column)) >= pipe_x_array(0) AND
      to_integer(unsigned(pixel_column)) < pipe_x_array(0) + 20 AND
      (to_integer(unsigned(pixel_row)) < pipe_y_array(0) OR
      to_integer(unsigned(pixel_row)) > pipe_y_array(0) + 100)) THEN
      red <= "0000";
      green <= "1111";
      blue <= "0000";
    END IF;

    -- Check for pipe 1
    IF (to_integer(unsigned(pixel_column)) >= pipe_x_array(1) AND
      to_integer(unsigned(pixel_column)) < pipe_x_array(1) + 20 AND
      (to_integer(unsigned(pixel_row)) < pipe_y_array(1) OR
      to_integer(unsigned(pixel_row)) > pipe_y_array(1) + 100)) THEN
      red <= "0000";
      green <= "1111";
      blue <= "0000";
    END IF;

    -- Check for pipe 2
    IF (to_integer(unsigned(pixel_column)) >= pipe_x_array(2) AND
      to_integer(unsigned(pixel_column)) < pipe_x_array(2) + 20 AND
      (to_integer(unsigned(pixel_row)) < pipe_y_array(2) OR
      to_integer(unsigned(pixel_row)) > pipe_y_array(2) + 100)) THEN
      red <= "0000";
      green <= "1111";
      blue <= "0000";
    END IF;

    -- Check for pipe 3
    IF (to_integer(unsigned(pixel_column)) >= pipe_x_array(3) AND
      to_integer(unsigned(pixel_column)) < pipe_x_array(3) + 20 AND
      (to_integer(unsigned(pixel_row)) < pipe_y_array(3) OR
      to_integer(unsigned(pixel_row)) > pipe_y_array(3) + 100)) THEN
      red <= "0000";
      green <= "1111";
      blue <= "0000";
    END IF;

    -- Check if pixel is within bird bounds
    IF to_integer(unsigned(pixel_column)) >= bird_x AND
      to_integer(unsigned(pixel_column)) < bird_x + bird_size AND
      to_integer(unsigned(pixel_row)) >= bird_y AND
      to_integer(unsigned(pixel_row)) < bird_y + bird_size THEN

      -- Compute relative x/y within sprite
      rel_x := to_integer(unsigned(pixel_column)) - bird_x;
      rel_y := to_integer(unsigned(pixel_row)) - bird_y;

      -- ROM is 32x32: address = y * 32 + x
      bird_addr <= STD_LOGIC_VECTOR(to_unsigned(rel_y * 32 + rel_x, 10));
      bird_on <= '1';

      -- Set color from ROM
      red <= bird_rgb(11 DOWNTO 8);
      green <= bird_rgb(7 DOWNTO 4);
      blue <= bird_rgb(3 DOWNTO 0);
    ELSE
      bird_on <= '0';
    END IF;
    -- Text rendering logic
    IF text_on_signal = '1' THEN
      red <= (OTHERS => text_rgb_signal(11));
      green <= (OTHERS => text_rgb_signal(5));
      blue <= (OTHERS => text_rgb_signal(0));
    END IF;

    -- is this duplicated bird?
    if abs (to_integer(unsigned(pixel_column)) - bird_x) < size and
       abs (to_integer(unsigned(pixel_row)) - bird_y) < size then
      red <= "1111";
      green <= "1111";
      blue <= "0000";
    end if;

    IF text_on_signal = '1' THEN
      red <= (OTHERS => text_rgb_signal(11));
      green <= (OTHERS => text_rgb_signal(5));
      blue <= (OTHERS => text_rgb_signal(0));
    END IF;

    -- draw lose screen info
    IF in_lose = '1' THEN
      IF label_again_on = '1' OR label_gameover_on = '1' THEN
        red <= "0000";
        green <= "0000";
        blue <= "0000";
      END IF;

      -- Draw cursor (5x5 red square)
      IF to_integer(unsigned(pixel_column)) >= to_integer(unsigned(mouse_col)) AND
        to_integer(unsigned(pixel_column)) < to_integer(unsigned(mouse_col)) + 5 AND
        to_integer(unsigned(pixel_row)) >= to_integer(unsigned(mouse_row)) AND
        to_integer(unsigned(pixel_row)) < to_integer(unsigned(mouse_row)) + 5 THEN
        red <= "1111";
        green <= "0000";
        blue <= "0000";
      END IF;
    END IF;

    -- draw buttons on title screen
    IF in_title = '1' THEN
      IF label_title_on = '1' OR label1_on = '1' OR label2_on = '1' THEN
        red <= "1111";
        green <= "1111";
        blue <= "1111";
      END IF;

      -- Draw cursor (5x5 red square)
      IF to_integer(unsigned(pixel_column)) >= to_integer(unsigned(mouse_col)) AND
        to_integer(unsigned(pixel_column)) < to_integer(unsigned(mouse_col)) + 5 AND
        to_integer(unsigned(pixel_row)) >= to_integer(unsigned(mouse_row)) AND
        to_integer(unsigned(pixel_row)) < to_integer(unsigned(mouse_row)) + 5 THEN
        red <= "1111";
        green <= "0000";
        blue <= "0000";
      END IF;
    END IF;
  END PROCESS;

END ARCHITECTURE;