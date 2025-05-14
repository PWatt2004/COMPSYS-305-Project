library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity display_text is
    port (
        clk               : in  std_logic;
        pixel_row         : in  std_logic_vector(9 downto 0);
        pixel_column      : in  std_logic_vector(9 downto 0);
        score             : in  std_logic_vector(11 downto 0);
        health_percentage : in  std_logic_vector(11 downto 0);
        text_rgb          : out std_logic_vector(11 downto 0);
        text_on           : out std_logic
    );
end entity;

architecture Behavioral of display_text is

    component char_rom
        port (
            character_address : in  std_logic_vector(5 downto 0);
            font_row          : in  std_logic_vector(2 downto 0);
            font_col          : in  std_logic_vector(2 downto 0);
            clock             : in  std_logic;
            rom_mux_output    : out std_logic
        );
    end component;

    constant CHAR_W      : integer := 8;
    constant CHAR_H      : integer := 8;
    constant SCREEN_W    : integer := 640;

    constant TITLE_TEXT  : string := "FLAPPY BIRD";
    constant SCORE_LABEL : string := "SCORE:";
    constant HP_LABEL    : string := "HP:";

    signal character_address : std_logic_vector(5 downto 0);
    signal font_row, font_col: std_logic_vector(2 downto 0);
    signal rom_pixel         : std_logic;

begin

    char_rom_inst : char_rom
        port map (
            character_address => character_address,
            font_row          => font_row,
            font_col          => font_col,
            clock             => clk,
            rom_mux_output    => rom_pixel
        );

    process(clk)
        variable row, col        : integer;
        variable char_x, char_y : integer;
        variable txt             : string(1 to 20);
        variable txt_len         : integer;
        variable start_x         : integer;
        variable scale           : integer;
        variable score_val       : integer := 0;
        variable hp_val          : integer := 0;
        variable score_str       : string(1 to 10);
        variable hp_str          : string(1 to 10);
        variable temp_str        : string(1 to 20);
    begin
        if rising_edge(clk) then
            text_on  <= '0';
            text_rgb <= (others => '0');

            row := to_integer(unsigned(pixel_row));
            col := to_integer(unsigned(pixel_column));
            score_val := to_integer(unsigned(score));
            hp_val := to_integer(unsigned(health_percentage));

            ------------------------------------------------------------
            -- 1. FLAPPY BIRD (WHITE, CENTERED, SCALE=2)
            ------------------------------------------------------------
            txt := (others => ' ');
            for i in 1 to TITLE_TEXT'length loop
                txt(i) := TITLE_TEXT(i);
            end loop;
            txt_len := TITLE_TEXT'length;
            scale := 2;
            start_x := (SCREEN_W - txt_len * CHAR_W * scale) / 2;

            if row >= 30 and row < 30 + CHAR_H * scale then
                for i in 0 to txt_len - 1 loop
                    if col >= start_x + i * CHAR_W * scale and col < start_x + (i + 1) * CHAR_W * scale then
                        char_y := (row - 30) / scale;
                        char_x := (col - (start_x + i * CHAR_W * scale)) / scale;
                        font_row <= std_logic_vector(to_unsigned(char_y, 3));
                        font_col <= std_logic_vector(to_unsigned(char_x, 3));
                        character_address <= std_logic_vector(to_unsigned(character'pos(txt(i + 1)), 6));
                        if rom_pixel = '1' then
                            text_on <= '1';
                            text_rgb <= "111111111111"; -- white
                        end if;
                    end if;
                end loop;
            end if;

            ------------------------------------------------------------
            -- 2. SCORE (BLACK, CENTERED BELOW, SCALE=1)
            ------------------------------------------------------------
            temp_str := (others => ' ');
            for i in 1 to integer'image(score_val)'length loop
                temp_str(i) := integer'image(score_val)(i);
            end loop;
            for i in 1 to 10 loop
                score_str(i) := temp_str(i);
            end loop;

            txt := (others => ' ');
            for i in 1 to SCORE_LABEL'length loop
                txt(i) := SCORE_LABEL(i);
            end loop;
            for j in 1 to integer'image(score_val)'length loop
                txt(SCORE_LABEL'length + j) := score_str(j);
            end loop;
            txt_len := SCORE_LABEL'length + integer'image(score_val)'length;
            scale := 1;
            start_x := (SCREEN_W - txt_len * CHAR_W * scale) / 2;

            if row >= 55 and row < 55 + CHAR_H * scale then
                for i in 0 to txt_len - 1 loop
                    if col >= start_x + i * CHAR_W * scale and col < start_x + (i + 1) * CHAR_W * scale then
                        char_y := (row - 55) / scale;
                        char_x := (col - (start_x + i * CHAR_W * scale)) / scale;
                        font_row <= std_logic_vector(to_unsigned(char_y, 3));
                        font_col <= std_logic_vector(to_unsigned(char_x, 3));
                        character_address <= std_logic_vector(to_unsigned(character'pos(txt(i + 1)), 6));
                        if rom_pixel = '1' then
                            text_on <= '1';
                            text_rgb <= "000000000000"; -- black
                        end if;
                    end if;
                end loop;
            end if;

            ------------------------------------------------------------
            -- 3. HP (RED, TOP-RIGHT, SCALE=1)
            ------------------------------------------------------------
            temp_str := (others => ' ');
            for i in 1 to integer'image(hp_val)'length loop
                temp_str(i) := integer'image(hp_val)(i);
            end loop;
            for i in 1 to 10 loop
                hp_str(i) := temp_str(i);
            end loop;

            txt := (others => ' ');
            for i in 1 to HP_LABEL'length loop
                txt(i) := HP_LABEL(i);
            end loop;
            for j in 1 to integer'image(hp_val)'length loop
                txt(HP_LABEL'length + j) := hp_str(j);
            end loop;
            txt_len := HP_LABEL'length + integer'image(hp_val)'length;
            scale := 2;
            start_x := SCREEN_W - txt_len * CHAR_W * scale - 10;

            if row >= 10 and row < 10 + CHAR_H * scale then
                for i in 0 to txt_len - 1 loop
                    if col >= start_x + i * CHAR_W * scale and col < start_x + (i + 1) * CHAR_W * scale then
                        char_y := (row - 10) / scale;
                        char_x := (col - (start_x + i * CHAR_W * scale)) / scale;
                        font_row <= std_logic_vector(to_unsigned(char_y, 3));
                        font_col <= std_logic_vector(to_unsigned(char_x, 3));
                        character_address <= std_logic_vector(to_unsigned(character'pos(txt(i + 1)), 6));
                        if rom_pixel = '1' then
                            text_on <= '1';
                            text_rgb <= "111100000000"; -- red
                        end if;
                    end if;
                end loop;
            end if;
        end if;
    end process;

end architecture;
