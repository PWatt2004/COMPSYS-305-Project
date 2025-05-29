library IEEE;
  use IEEE.STD_LOGIC_1164.all;
  use IEEE.NUMERIC_STD.all;

entity flappy_bird_base is
  port (
    CLOCK_50 : in    STD_LOGIC;
    RESET_N  : in    STD_LOGIC;
    PS2_CLK  : inout STD_LOGIC;
    PS2_DAT  : inout STD_LOGIC;
    VGA_R    : out   STD_LOGIC_VECTOR(3 downto 0);
    VGA_G    : out   STD_LOGIC_VECTOR(3 downto 0);
    VGA_B    : out   STD_LOGIC_VECTOR(3 downto 0);
    VGA_HS   : out   STD_LOGIC;
    VGA_VS   : out   STD_LOGIC;
    LEDR     : out   STD_LOGIC_VECTOR(9 downto 0);
    SW       : in    STD_LOGIC_VECTOR(9 downto 0);

    HEX0     : out   STD_LOGIC_VECTOR(6 downto 0);
    HEX1     : out   STD_LOGIC_VECTOR(6 downto 0);
    HEX2     : out   STD_LOGIC_VECTOR(6 downto 0)

  );
end entity;

architecture top of flappy_bird_base is

  component char_rom
    port (
      character_address : in  STD_LOGIC_VECTOR(5 downto 0);
      font_row          : in  STD_LOGIC_VECTOR(2 downto 0);
      font_col          : in  STD_LOGIC_VECTOR(2 downto 0);
      clock             : in  STD_LOGIC;
      rom_mux_output    : out STD_LOGIC
    );
  end component;

  component background
    port (
      clk          : in  STD_LOGIC;
      pixel_row    : in  STD_LOGIC_VECTOR(9 downto 0);
      pixel_column : in  STD_LOGIC_VECTOR(9 downto 0);
      bg_red       : out STD_LOGIC_VECTOR(3 downto 0);
      bg_green     : out STD_LOGIC_VECTOR(3 downto 0);
      bg_blue      : out STD_LOGIC_VECTOR(3 downto 0)
    );
  end component;

  component display_text
    port (
      clk          : in  STD_LOGIC;
      pixel_row    : in  STD_LOGIC_VECTOR(9 downto 0);
      pixel_column : in  STD_LOGIC_VECTOR(9 downto 0);
      score        : in  STD_LOGIC_VECTOR(11 downto 0);
      text_rgb     : out STD_LOGIC_VECTOR(11 downto 0);
      text_on      : out STD_LOGIC
    );
  end component;
  type INTEGER_VECTOR is array (NATURAL range <>) of INTEGER;

  signal clk_25                    : STD_LOGIC;
  signal red, green, blue          : STD_LOGIC_VECTOR(3 downto 0);
  signal pixel_row, pixel_column   : STD_LOGIC_VECTOR(9 downto 0);
  signal mouse_row, mouse_col      : STD_LOGIC_VECTOR(9 downto 0);
  signal left_button, right_button : STD_LOGIC;
  signal lose_reset_click          : STD_LOGIC;

  signal bird_y        : INTEGER;
  signal bird_velocity : INTEGER;

  signal pipe_hit     : STD_LOGIC;
  signal pipe_x_array : INTEGER_VECTOR(0 to 3);
  signal pipe_x_out   : STD_LOGIC_VECTOR(39 downto 0);
  signal pipe_y_out   : STD_LOGIC_VECTOR(39 downto 0);
  signal pipe_y_array : INTEGER_VECTOR(0 to 3);

  signal vsync_internal            : STD_LOGIC;
  signal bg_red, bg_green, bg_blue : STD_LOGIC_VECTOR(3 downto 0);

  signal score : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');

  signal text_rgb_signal : STD_LOGIC_VECTOR(11 downto 0);
  signal text_on_signal  : STD_LOGIC;

  constant bird_x : INTEGER := 100;

  signal number               : INTEGER := 590;
  signal hundreds, tens, ones : STD_LOGIC_VECTOR(3 downto 0);
  signal game_active          : STD_LOGIC;
  signal in_title             : STD_LOGIC;
  signal in_lose              : STD_LOGIC;

  signal start_training : STD_LOGIC;
  signal start_game     : STD_LOGIC;

  signal mode_training : STD_LOGIC;

  signal label1_on : STD_LOGIC;
  signal label2_on : STD_LOGIC;
  SIGNAL label_title_on  : STD_LOGIC;
	SIGNAL label_again_on : STD_LOGIC;  
  SIGNAL label_gameover_on : STD_LOGIC;

  signal bird_limit_hit : STD_LOGIC;

  signal health    : INTEGER        := 50;
  signal hp_string : STRING(1 to 8) := "HP-00999"; -- Displayed string

  signal health_zero : STD_LOGIC;

  signal score_value  : INTEGER         := 0;
  signal score_string : STRING(1 to 11) := "SCORE-00000"; -- "SC-" + 5-digit score

  signal pipe_passed_tick : STD_LOGIC;

  signal pipe_speed : INTEGER := 1;
begin
  -- Instantiate 7-segment decoders
  hundred_display: entity work.BCD_to_SevenSeg
    port map (
      BCD_digit    => hundreds,
      SevenSeg_out => HEX2
    );

  ten_display: entity work.BCD_to_SevenSeg
    port map (
      BCD_digit    => tens,
      SevenSeg_out => HEX1
    );

  one_display: entity work.BCD_to_SevenSeg
    port map (
      BCD_digit    => ones,
      SevenSeg_out => HEX0
    );

  digit_split: process (number)
    variable temp : INTEGER;
  begin
    temp := number;
    hundreds <= STD_LOGIC_VECTOR(to_unsigned((temp / 100) mod 10, 4));
    tens <= STD_LOGIC_VECTOR(to_unsigned((temp / 10) mod 10, 4));
    ones <= STD_LOGIC_VECTOR(to_unsigned(temp mod 10, 4));
  end process;

  LEDR(0)         <= left_button;
  LEDR(1)         <= pipe_hit and game_active;
  LEDR(2)         <= bird_limit_hit and game_active;
  VGA_VS          <= vsync_internal;
  lose_reset_click <= '1' when (in_lose = '1' and left_button = '1') else
                      '0';
  health_zero <= '1' when health <= 0 else
                 '0';

  clk_divider: process (CLOCK_50)
    variable counter : STD_LOGIC := '0';
  begin
    if rising_edge(CLOCK_50) then
      counter := not counter;
      clk_25 <= counter;
    end if;
  end process;

  process (vsync_internal)
    variable temp    : INTEGER;
    variable hp_temp : STRING(1 to 8);
    variable s_temp  : INTEGER;
    variable s_text  : STRING(1 to 11);
  begin
    if rising_edge(vsync_internal) then
      -- Handle health logic
      if RESET_N = '0' or in_title = '1' then
        health <= 50;
        score_value <= 0;
      elsif start_game = '1' then
        health <= 1;
      elsif game_active = '1' then
        -- Decrement health
        if (bird_limit_hit = '1' or pipe_hit = '1') and health > 0 then
          health <= health - 1;
        end if;
      end if;
      -- Reset speed on title screen
      if RESET_N = '0' or in_title = '1' then
        pipe_speed <= 1;

        -- Increase speed gradually in game mode
      elsif game_active = '1' and mode_training = '0' then
        pipe_speed <= 1 + ((score_value / 1) * 4); -- +y speed per x points
      end if;

      -- Format health as string
      temp := health;
      hp_temp(1) := 'H';
      hp_temp(2) := 'P';
      hp_temp(3) := '-';
      hp_temp(4) := CHARACTER'VAL((temp / 1000) mod 10 + CHARACTER'POS('0'));
      hp_temp(5) := CHARACTER'VAL((temp / 100) mod 10 + CHARACTER'POS('0'));
      hp_temp(6) := CHARACTER'VAL((temp / 10) mod 10 + CHARACTER'POS('0'));
      hp_temp(7) := CHARACTER'VAL(temp mod 10 + CHARACTER'POS('0'));
      hp_temp(8) := ' ';
      hp_string <= hp_temp;

      -- Handle score  logic
      if game_active = '1' and pipe_passed_tick = '1' then
        score_value <= score_value + 1;
      end if;

      -- Format score_value into score_string
      s_temp := score_value;
      s_text(1) := 'S';
      s_text(2) := 'C';
      s_text(3) := 'O';
      s_text(4) := 'R';
      s_text(5) := 'E';
      s_text(6) := '-';
      s_text(7) := CHARACTER'VAL((s_temp / 10000) mod 10 + CHARACTER'POS('0'));
      s_text(8) := CHARACTER'VAL((s_temp / 1000) mod 10 + CHARACTER'POS('0'));
      s_text(9) := CHARACTER'VAL((s_temp / 100) mod 10 + CHARACTER'POS('0'));
      s_text(10) := CHARACTER'VAL((s_temp / 10) mod 10 + CHARACTER'POS('0'));
      s_text(11) := CHARACTER'VAL(s_temp mod 10 + CHARACTER'POS('0'));

      score_string <= s_text;
    end if;
  end process;

  vga_inst: entity work.vga_sync
    port map (
      clock_25Mhz    => clk_25,
      red            => red,
      green          => green,
      blue           => blue,
      red_out        => VGA_R,
      green_out      => VGA_G,
      blue_out       => VGA_B,
      horiz_sync_out => VGA_HS,
      vert_sync_out  => vsync_internal,
      pixel_row      => pixel_row,
      pixel_column   => pixel_column
    );

  mouse_inst: entity work.mouse
    port map (
      clock_25Mhz         => clk_25,
      reset               => not RESET_N,
      mouse_data          => PS2_DAT,
      mouse_clk           => PS2_CLK,
      left_button         => left_button,
      right_button        => right_button,
      mouse_cursor_row    => mouse_row,
      mouse_cursor_column => mouse_col
    );

  bird_inst: entity work.bird_controller
    port map (
      clk            => vsync_internal,
      reset          => not RESET_N,
      flap_button    => left_button,
      bird_y         => bird_y,
      bird_velocity  => bird_velocity,
      bird_altitude  => number,
      game_active    => game_active,
      bird_limit_hit => bird_limit_hit,
      in_title       => in_title
    );

  background_inst: entity work.background
    port map (
      clk          => clk_25,
      pixel_row    => pixel_row,
      pixel_column => pixel_column,
      bg_red       => bg_red,
      bg_green     => bg_green,
      bg_blue      => bg_blue
    );

  pipe_ctrl_inst: entity work.pipe_controller
    port map (
      clk              => vsync_internal,
      reset            => not RESET_N,
      bird_x           => bird_x,
      bird_y           => bird_y,
      pipe_hit         => pipe_hit,
      pipe_x_out       => pipe_x_out,
      pipe_y_out       => pipe_y_out,
      game_active      => game_active,
      in_title         => in_title,
      pipe_passed_tick => pipe_passed_tick,
      speed            => pipe_speed
    );

  display_text_inst: entity work.display_text
    port map (
      clk          => clk_25,
      pixel_row    => pixel_row,
      pixel_column => pixel_column,
      score        => score,
      text_rgb     => text_rgb_signal,
      text_on      => text_on_signal,
      title_on     => SW(0),
      score_on     => SW(1),
      score_string => score_string,
      hp_on        => SW(2),
      hp_string    => hp_string
    );

  menu_ui: entity work.menu_controller
    port map (
      clk            => vsync_internal,
      in_title       => in_title,
      mouse_x        => mouse_col,
      mouse_y        => mouse_row,
      mouse_click    => left_button,
      start_training => start_training,
      start_game     => start_game
    );

  fsm_inst: entity work.game_fsm
    port map (
      clk            => vsync_internal,
      reset          => not RESET_N,
      start_training => start_training,
      start_game     => start_game,
      pipe_hit       => pipe_hit,
      click_reset    => lose_reset_click,
      mode_training  => mode_training, -- output from FSM now
      game_active    => game_active,
      in_title       => in_title,
      in_lose        => in_lose,
      health_zero    => health_zero

    );

  label_training: entity work.draw_label
    generic map (TEXT_LENGTH => 13, SCALE => 1)
    port map (
      clk         => clk_25,
      active      => in_title,
      pixel_x     => pixel_column,
      pixel_y     => pixel_row,
      start_x     => 460,
      start_y     => 160,
      text_string => "TRAINING MODE",
      pixel_on    => label1_on
    );

  label_game: entity work.draw_label
    generic map (TEXT_LENGTH => 12, SCALE => 1)
    port map (
      clk         => clk_25,
      active      => in_title,
      pixel_x     => pixel_column,
      pixel_y     => pixel_row,
      start_x     => 460,
      start_y     => 230,
      text_string => "SINGLEPLAYER",
      pixel_on    => label2_on
    );

  label_title: entity work.draw_label
    generic map (TEXT_LENGTH => 11, SCALE => 2)
    port map (
      clk         => clk_25,
      active      => in_title,
      pixel_x     => pixel_column,
      pixel_y     => pixel_row,
      start_x     => 220,
      start_y     => 80,
      text_string => "TOASTY BIRD",
      pixel_on    => label_title_on
    );

  label_again: entity work.draw_label
    generic map (TEXT_LENGTH => 17, SCALE => 1)
    port map (
      clk         => clk_25,
      active      => in_lose,
      pixel_x     => pixel_column,
      pixel_y     => pixel_row,
      start_x     => 240,
      start_y     => 260,
      text_string => "CLICK TO GO AGAIN",
      pixel_on    => label_again_on
    );

  label_gameover: entity work.draw_label
    generic map (TEXT_LENGTH => 9, SCALE => 3)
    port map (
      clk         => clk_25,
      active      => in_lose,
      pixel_x     => pixel_column,
      pixel_y     => pixel_row,
      start_x     => 200,
      start_y     => 220,
      text_string => "GAME OVER",
      pixel_on    => label_gameover_on
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

  draw_logic: process (pixel_row, pixel_column)
    variable size : INTEGER := 6;
  begin
    red <= bg_red;
    green <= bg_green;
    blue <= bg_blue;

    -- Check for pipe 0
    if (to_integer(unsigned(pixel_column)) >= pipe_x_array(0) and
         to_integer(unsigned(pixel_column)) < pipe_x_array(0) + 20 and
         (to_integer(unsigned(pixel_row)) < pipe_y_array(0) or
           to_integer(unsigned(pixel_row)) > pipe_y_array(0) + 100)) then
      red <= "0000";
      green <= "1111";
      blue <= "0000";
    end if;

    -- Check for pipe 1
    if (to_integer(unsigned(pixel_column)) >= pipe_x_array(1) and
         to_integer(unsigned(pixel_column)) < pipe_x_array(1) + 20 and
         (to_integer(unsigned(pixel_row)) < pipe_y_array(1) or
           to_integer(unsigned(pixel_row)) > pipe_y_array(1) + 100)) then
      red <= "0000";
      green <= "1111";
      blue <= "0000";
    end if;

    -- Check for pipe 2
    if (to_integer(unsigned(pixel_column)) >= pipe_x_array(2) and
         to_integer(unsigned(pixel_column)) < pipe_x_array(2) + 20 and
         (to_integer(unsigned(pixel_row)) < pipe_y_array(2) or
           to_integer(unsigned(pixel_row)) > pipe_y_array(2) + 100)) then
      red <= "0000";
      green <= "1111";
      blue <= "0000";
    end if;

    -- Check for pipe 3
    if (to_integer(unsigned(pixel_column)) >= pipe_x_array(3) and
         to_integer(unsigned(pixel_column)) < pipe_x_array(3) + 20 and
         (to_integer(unsigned(pixel_row)) < pipe_y_array(3) or
           to_integer(unsigned(pixel_row)) > pipe_y_array(3) + 100)) then
      red <= "0000";
      green <= "1111";
      blue <= "0000";
    end if;

    -- Bird rendering logic
    if abs (to_integer(unsigned(pixel_column)) - bird_x) < size and
       abs (to_integer(unsigned(pixel_row)) - bird_y) < size then
      red <= "1111";
      green <= "1111";
      blue <= "0000";
    end if;

    -- Text rendering logic
    if text_on_signal = '1' then
      red <= (others => text_rgb_signal(11));
      green <= (others => text_rgb_signal(5));
      blue <= (others => text_rgb_signal(0));
    end if;

    if abs (to_integer(unsigned(pixel_column)) - bird_x) < size and
       abs (to_integer(unsigned(pixel_row)) - bird_y) < size then
      red <= "1111";
      green <= "1111";
      blue <= "0000";
    end if;

    if text_on_signal = '1' then
      red <= (others => text_rgb_signal(11));
      green <= (others => text_rgb_signal(5));
      blue <= (others => text_rgb_signal(0));
    end if;

    -- draw lose screen info
    if in_lose = '1' then
      if label_again_on = '1' or label_gameover_on = '1' then
        red <= "0000";
        green <= "0000";
        blue <= "0000";
      end if;

      -- Draw cursor (5x5 red square)
      if to_integer(unsigned(pixel_column)) >= to_integer(unsigned(mouse_col)) and
         to_integer(unsigned(pixel_column)) < to_integer(unsigned(mouse_col)) + 5 and
         to_integer(unsigned(pixel_row)) >= to_integer(unsigned(mouse_row)) and
         to_integer(unsigned(pixel_row)) < to_integer(unsigned(mouse_row)) + 5 then
        red <= "1111";
        green <= "0000";
        blue <= "0000";
      end if;
    end if;

    -- draw buttons on title screen
    if in_title = '1' then
      if label_title_on = '1' or label1_on = '1' or label2_on = '1' then
        red <= "1111";
        green <= "1111";
        blue <= "1111";
      end if;

      -- Draw cursor (5x5 red square)
      if to_integer(unsigned(pixel_column)) >= to_integer(unsigned(mouse_col)) and
         to_integer(unsigned(pixel_column)) < to_integer(unsigned(mouse_col)) + 5 and
         to_integer(unsigned(pixel_row)) >= to_integer(unsigned(mouse_row)) and
         to_integer(unsigned(pixel_row)) < to_integer(unsigned(mouse_row)) + 5 then
        red <= "1111";
        green <= "0000";
        blue <= "0000";
      end if;
    end if;
  end process;

end architecture;
