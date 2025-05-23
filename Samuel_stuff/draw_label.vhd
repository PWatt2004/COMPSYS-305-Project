LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY draw_label IS
    GENERIC (
        TEXT_LENGTH : INTEGER := 16
    );
    PORT (
        clk : IN STD_LOGIC;
        active : IN STD_LOGIC;

        pixel_x : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_y : IN STD_LOGIC_VECTOR(9 DOWNTO 0);

        start_x : IN INTEGER;
        start_y : IN INTEGER;

        text_string : IN STRING(1 TO TEXT_LENGTH);

        pixel_on : OUT STD_LOGIC
    );
END ENTITY;

ARCHITECTURE Behavioral OF draw_label IS
    COMPONENT char_rom
        PORT (
            character_address : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
            font_row : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            font_col : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            clock : IN STD_LOGIC;
            rom_mux_output : OUT STD_LOGIC
        );
    END COMPONENT;

    CONSTANT CHAR_WIDTH : INTEGER := 8;
    CONSTANT CHAR_HEIGHT : INTEGER := 8;

    SIGNAL char_code : STD_LOGIC_VECTOR(5 DOWNTO 0);
    SIGNAL char_x : INTEGER;
    SIGNAL char_y : INTEGER;
    SIGNAL pixel_in_char : STD_LOGIC;
BEGIN

    char_rom_inst : char_rom
    PORT MAP(
        character_address => char_code,
        font_row => STD_LOGIC_VECTOR(to_unsigned(char_y, 3)),
        font_col => STD_LOGIC_VECTOR(to_unsigned(char_x, 3)),
        clock => clk,
        rom_mux_output => pixel_in_char
    );

    PROCESS (clk)
        VARIABLE px, py : INTEGER;
        VARIABLE char_index : INTEGER;
    BEGIN
        IF rising_edge(clk) THEN
            pixel_on <= '0';
            IF active = '1' THEN
                px := to_integer(unsigned(pixel_x));
                py := to_integer(unsigned(pixel_y));

                IF py >= start_y AND py < start_y + CHAR_HEIGHT AND px >= start_x THEN
                    char_index := (px - start_x) / CHAR_WIDTH + 1;
                    IF char_index >= 1 AND char_index <= TEXT_LENGTH THEN
                        IF CHARACTER'pos(text_string(char_index)) >= 32 AND CHARACTER'pos(text_string(char_index)) <= 95 THEN
                            char_code <= STD_LOGIC_VECTOR(to_unsigned(CHARACTER'pos(text_string(char_index)) - 32, 6));
                            char_x <= (px - start_x) MOD CHAR_WIDTH;
                            char_y <= (py - start_y);
                            pixel_on <= pixel_in_char;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE;