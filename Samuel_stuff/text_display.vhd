LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- To Do List: Must Fix
-- - Replace Scale w/ Constants
-- - Get rid of Divisions (replace w/ bit right shift)  

ENTITY display_text IS
    PORT (
        clk : IN STD_LOGIC;
        pixel_row : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_column : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        score : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        text_rgb : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
        text_on : OUT STD_LOGIC;
        title_on : IN STD_LOGIC;
        score_on : IN STD_LOGIC;
        score_string : in  string(1 to 11);
        hp_on : IN STD_LOGIC;
        hp_string : in  string(1 to 8)

    );
END ENTITY;

ARCHITECTURE Behavioral OF display_text IS

    COMPONENT char_rom
        PORT (
            character_address : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
            font_row : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            font_col : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            clock : IN STD_LOGIC;
            rom_mux_output : OUT STD_LOGIC
        );
    END COMPONENT;

    CONSTANT CHAR_W : INTEGER := 8;
    CONSTANT CHAR_H : INTEGER := 8;
    CONSTANT SCREEN_W : INTEGER := 640;

    CONSTANT TITLE_TEXT : STRING := "FLAPPY BIRD";
    CONSTANT SCORE_LABEL : STRING := "SCORE-000";
    CONSTANT HP_LABEL : STRING := "HP-100";

    SIGNAL character_address : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL font_row, font_col : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL rom_pixel : STD_LOGIC;

BEGIN

    char_rom_inst : char_rom
    PORT MAP(
        character_address => character_address,
        font_row => font_row,
        font_col => font_col,
        clock => clk,
        rom_mux_output => rom_pixel
    );

    PROCESS (clk)
        VARIABLE row, col : INTEGER;
        VARIABLE char_x, char_y : INTEGER;
        VARIABLE txt : STRING(1 TO 20);
        VARIABLE txt_len : INTEGER;
        VARIABLE start_x : INTEGER;
        VARIABLE scale : INTEGER;
        VARIABLE score_val : INTEGER := 0;
        VARIABLE hp_val : INTEGER := 0;
        VARIABLE score_str : STRING(1 TO 10);
        VARIABLE hp_str : STRING(1 TO 10);
        VARIABLE temp_str : STRING(1 TO 20);
    BEGIN
        IF rising_edge(clk) THEN
            text_on <= '0';
            text_rgb <= (OTHERS => '0');

            row := to_integer(unsigned(pixel_row));
            col := to_integer(unsigned(pixel_column));
            score_val := to_integer(unsigned(score));
            ------------------------------------------------------------
            -- 1. FLAPPY BIRD (WHITE, CENTERED, SCALE=2)
            ------------------------------------------------------------
            txt := (OTHERS => ' ');
            FOR i IN 1 TO TITLE_TEXT'length LOOP
                txt(i) := TITLE_TEXT(i);
            END LOOP;
            txt_len := TITLE_TEXT'length;
            scale := 2;
            start_x := (SCREEN_W - txt_len * CHAR_W * scale) / 2;

            IF title_on = '1' THEN
                IF row >= 30 AND row < 30 + CHAR_H * scale THEN
                    FOR i IN 0 TO txt_len - 1 LOOP
                        IF col >= start_x + i * CHAR_W * scale AND col < start_x + (i + 1) * CHAR_W * scale THEN
                            char_y := (row - 30) / scale;
                            char_x := (col - (start_x + i * CHAR_W * scale)) / scale;
                            font_row <= STD_LOGIC_VECTOR(to_unsigned(char_y, 3));
                            font_col <= STD_LOGIC_VECTOR(to_unsigned(char_x, 3));
                            character_address <= STD_LOGIC_VECTOR(to_unsigned(CHARACTER'pos(txt(i + 1)), 6));
                            IF rom_pixel = '1' THEN
                                text_on <= '1';
                                text_rgb <= "111111111111"; -- white
                            END IF;
                        END IF;
                    END LOOP;
                END IF;
            END IF;

            ------------------------------------------------------------
            -- 2. SCORE STRING DISPLAY (BLACK, CENTERED BELOW, SCALE=1)
            ------------------------------------------------------------
            txt := (OTHERS => ' ');
            FOR i IN 1 TO 11 LOOP
                txt(i) := score_string(i);
            END LOOP;
            txt_len := 11;
            scale := 1;
            start_x := (SCREEN_W - txt_len * CHAR_W * scale) / 2;

            IF score_on = '1' THEN

                IF row >= 55 AND row < 55 + CHAR_H * scale THEN
                    FOR i IN 0 TO txt_len - 1 LOOP
                        IF col >= start_x + i * CHAR_W * scale AND col < start_x + (i + 1) * CHAR_W * scale THEN
                            char_y := (row - 55) / scale;
                            char_x := (col - (start_x + i * CHAR_W * scale)) / scale;
                            font_row <= STD_LOGIC_VECTOR(to_unsigned(char_y, 3));
                            font_col <= STD_LOGIC_VECTOR(to_unsigned(char_x, 3));
                            character_address <= STD_LOGIC_VECTOR(to_unsigned(CHARACTER'pos(txt(i + 1)), 6));
                            IF rom_pixel = '1' THEN
                                text_on <= '1';
                                text_rgb <= "000000000000"; -- black
                            END IF;
                        END IF;
                    END LOOP;
                END IF;

            END IF;

            ------------------------------------------------------------
            -- 3. HP (RED, TOP-RIGHT, SCALE=1)
            ------------------------------------------------------------
            txt := (OTHERS => ' ');
            FOR i IN 1 TO 8 LOOP
                txt(i) := hp_string(i);
            END LOOP;
            txt_len := 8;
            scale := 2;
            start_x := SCREEN_W - txt_len * CHAR_W * scale - 10;
            
            scale := 2;
            start_x := SCREEN_W - txt_len * CHAR_W * scale - 10;
            IF hp_on = '1' THEN
                IF row >= 10 AND row < 10 + CHAR_H * scale THEN
                    FOR i IN 0 TO txt_len - 1 LOOP
                        IF col >= start_x + i * CHAR_W * scale AND col < start_x + (i + 1) * CHAR_W * scale THEN
                            char_y := (row - 10) / scale;
                            char_x := (col - (start_x + i * CHAR_W * scale)) / scale;
                            font_row <= STD_LOGIC_VECTOR(to_unsigned(char_y, 3));
                            font_col <= STD_LOGIC_VECTOR(to_unsigned(char_x, 3));
                            character_address <= STD_LOGIC_VECTOR(to_unsigned(CHARACTER'pos(txt(i + 1)), 6));
                            IF rom_pixel = '1' THEN
                                text_on <= '1';
                                text_rgb <= "111100000000"; -- red
                            END IF;
                        END IF;
                    END LOOP;
                END IF;
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE;