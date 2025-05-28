-- Step 1: Create this new file as a replacement for RNG logic
-- Save this as random_number_generator.vhd

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY random_number_generator IS
    PORT (
        clk    : IN  STD_LOGIC;
        reset  : IN  STD_LOGIC;
        rnd_out : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
    );
END random_number_generator;

ARCHITECTURE behavior OF random_number_generator IS
    SIGNAL lfsr : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"ACE1";
BEGIN
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF reset = '1' THEN
                lfsr <= x"ACE1";
            ELSE
                lfsr <= lfsr(14 DOWNTO 0) & (lfsr(15) XOR lfsr(13) XOR lfsr(12) XOR lfsr(10));
            END IF;
        END IF;
    END PROCESS;

    rnd_out <= lfsr(1 DOWNTO 0); -- Only 2-bit output
END behavior;
