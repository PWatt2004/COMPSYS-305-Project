LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY display_text IS
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
        hp_label : IN STRING(1 TO 24)
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

    SIGNAL character_address : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL font_row, font_col : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL rom_pixel : STD_LOGIC;
	SIGNAL hp_label_signal : STRING(1 TO 24) := "feed me something to display";

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
            hp_val := to_integer(unsigned(health_percentage));

            ------------------------------------------------------------
            -- 1. FLAPPY BIRD (WHITE, CENTERED, SCALE=2)
            ------------------------------------------------------------
            txt := (OTHERS => ' ');
            FOR i IN 1 TO hp_label'length LOOP
                txt(i) := hp_label(i);
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
            -- 2. SCORE (BLACK, CENTERED BELOW, SCALE=1)
            ------------------------------------------------------------
            temp_str := (OTHERS => ' ');
            FOR i IN 1 TO INTEGER'image(score_val)'length LOOP
                temp_str(i) := INTEGER'image(score_val)(i);
            END LOOP;
            FOR i IN 1 TO 10 LOOP
                score_str(i) := temp_str(i);
            END LOOP;

            txt := (OTHERS => ' ');
            FOR i IN 1 TO SCORE_LABEL'length LOOP
                txt(i) := SCORE_LABEL(i);
            END LOOP;
            FOR j IN 1 TO INTEGER'image(score_val)'length LOOP
                txt(SCORE_LABEL'length + j) := score_str(j);
            END LOOP;
            txt_len := SCORE_LABEL'length + INTEGER'image(score_val)'length;
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
            temp_str := (OTHERS => ' ');
            FOR i IN 1 TO INTEGER'image(hp_val)'length LOOP
                temp_str(i) := INTEGER'image(hp_val)(i);
            END LOOP;
            FOR i IN 1 TO 10 LOOP
                hp_str(i) := temp_str(i);
            END LOOP;

            txt := (OTHERS => ' ');
            FOR i IN 1 TO HP_LABEL'length LOOP
                txt(i) := HP_LABEL(i);
            END LOOP;
            FOR j IN 1 TO INTEGER'image(hp_val)'length LOOP
                txt(HP_LABEL'length + j) := hp_str(j);
            END LOOP;
            txt_len := HP_LABEL'length + INTEGER'image(hp_val)'length;
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