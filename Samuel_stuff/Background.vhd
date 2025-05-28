-- background.vhd - Simple sky-colored background module for Flappy Bird
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY background IS
PORT (
    clk         : IN  STD_LOGIC;
    pixel_row   : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
    pixel_column: IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
    bg_red      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);  -- upgraded
    bg_green    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    bg_blue     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
);

END background;


ARCHITECTURE Behavioral OF background IS
BEGIN
    PROCESS(pixel_row, pixel_column)
    BEGIN
        -- Default to a light blue background for sky
        bg_red   <= "1001"; -- dim red
        bg_green <= "0001"; -- bright green
        bg_blue  <= "0100"; -- full blue
    END PROCESS;
END Behavioral;
