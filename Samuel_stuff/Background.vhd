-- background.vhd - Simple sky-colored background module for Flappy Bird
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY background IS
    PORT (
        clk          : IN  STD_LOGIC;
        pixel_row    : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_column : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        bg_red       : OUT STD_LOGIC;
        bg_green     : OUT STD_LOGIC;
        bg_blue      : OUT STD_LOGIC
    );
END background;

ARCHITECTURE Behavioral OF background IS
    CONSTANT NUM_CLOUDS  : INTEGER := 3;
    CONSTANT SCREEN_WIDTH: INTEGER := 640;
    CONSTANT SCREEN_HEIGHT: INTEGER := 480;

    TYPE int_array IS ARRAY(0 TO NUM_CLOUDS - 1) OF INTEGER;

    SIGNAL cloud_x : int_array := (100, 300, 500);
    SIGNAL cloud_y : int_array := (60, 90, 50);
    SIGNAL lfsr    : STD_LOGIC_VECTOR(7 DOWNTO 0) := "10101010";
BEGIN

    -- Cloud scrolling + LFSR random y-update
    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            FOR i IN 0 TO NUM_CLOUDS - 1 LOOP
                IF cloud_x(i) > 0 THEN
                    cloud_x(i) <= cloud_x(i) - 1;
                ELSE
                    cloud_x(i) <= SCREEN_WIDTH;
                    -- LFSR for new Y position
                    lfsr <= lfsr(6 DOWNTO 0) & (lfsr(7) XOR lfsr(5));
                    cloud_y(i) <= 30 + TO_INTEGER(unsigned(lfsr(6 DOWNTO 3))) * 10;  -- Range: 30–150 approx
                END IF;
            END LOOP;
        END IF;
    END PROCESS;

    -- Draw background with terrain and clouds
    PROCESS(pixel_row, pixel_column, cloud_x, cloud_y)
        VARIABLE col : INTEGER := TO_INTEGER(unsigned(pixel_column));
        VARIABLE row : INTEGER := TO_INTEGER(unsigned(pixel_row));
        VARIABLE is_cloud : BOOLEAN := FALSE;
    BEGIN
        -- Default to sky
        bg_red   <= '0';
        bg_green <= '1';
        bg_blue  <= '1';

        -- Terrain
        IF row >= 440 THEN
            bg_red   <= '0';
            bg_green <= '1';
            bg_blue  <= '0';
        ELSE
            -- Check for clouds
            is_cloud := FALSE;
            FOR i IN 0 TO NUM_CLOUDS - 1 LOOP
                IF ((col - cloud_x(i))**2 + (row - cloud_y(i))**2 < 400) OR
                   ((col - (cloud_x(i) + 10))**2 + (row - cloud_y(i))**2 < 400) THEN
                    is_cloud := TRUE;
                END IF;
            END LOOP;

            IF is_cloud THEN
                bg_red   <= '1';
                bg_green <= '1';
                bg_blue  <= '1';
            END IF;
        END IF;
    END PROCESS;

END Behavioral;
