LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY bird2_rom IS
    PORT (
        clk  : IN  STD_LOGIC;
        addr : IN  INTEGER RANGE 0 TO 1023;
        dout : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE Behavioral OF bird2_rom IS
    TYPE rom_type IS ARRAY (0 TO 1023) OF STD_LOGIC_VECTOR(11 DOWNTO 0);
    SIGNAL memory : rom_type;
BEGIN
    PROCESS
    BEGIN
        -- synthesis translate_off
        FILE mif_file : text OPEN read_mode IS "bird2.mif";
        VARIABLE line_data : line;
        VARIABLE i : INTEGER := 0;
        WHILE NOT endfile(mif_file) LOOP
            READLINE(mif_file, line_data);
            READ(line_data, memory(i));
            i := i + 1;
        END LOOP;
        -- synthesis translate_on
        WAIT;
    END PROCESS;

    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            dout <= memory(addr);
        END IF;
    END PROCESS;
END Behavioral;
