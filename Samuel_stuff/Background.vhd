-- background.vhd - Simple sky-colored background module for Flappy Bird
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY background IS
    PORT (
        pixel_row     : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_column  : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        bg_red        : OUT STD_LOGIC;
        bg_green      : OUT STD_LOGIC;
        bg_blue       : OUT STD_LOGIC
    );
END background;

ARCHITECTURE Behavioral OF background IS
BEGIN
    PROCESS(pixel_row, pixel_column)
    BEGIN
        -- Default to a light blue background for sky
        bg_red   <= '0';
        bg_green <= '1';
        bg_blue  <= '1';
    END PROCESS;
END Behavioral;
