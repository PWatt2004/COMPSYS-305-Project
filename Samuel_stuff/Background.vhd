LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY background IS
    PORT (
        clk : IN STD_LOGIC;
        pixel_row : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_column : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        bg_red : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        bg_green : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        bg_blue : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END background;

ARCHITECTURE Behavioral OF background IS
    SIGNAL address : INTEGER RANGE 0 TO 4799;
    SIGNAL data : STD_LOGIC_VECTOR(11 DOWNTO 0);
    SIGNAL scroll_offset : INTEGER := 0;
    signal slow_counter : integer := 0;

    COMPONENT bg_rom
        PORT (
            clk : IN STD_LOGIC;
            addr : IN INTEGER RANGE 0 TO 4799;
            dout : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
        );
    END COMPONENT;
BEGIN
    -- Map pixel to background resolution (scale 640x480 -> 80x60)
    PROCESS (pixel_row, pixel_column)
    BEGIN
        address <= (to_integer(unsigned(pixel_row)) / 8) * 80 +
            (to_integer(unsigned(pixel_column)) / 8);
    END PROCESS;

    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF slow_counter = 3 THEN -- scroll every 4 ticks (¼ speed)
                scroll_offset <= (scroll_offset + 1) MOD 80;
                slow_counter <= 0;
            ELSE
                slow_counter <= slow_counter + 1;
            END IF;
        END IF;
    END PROCESS;

    -- Instantiate ROM
    rom_inst : bg_rom
    PORT MAP(
        clk => clk,
        addr => address,
        dout => data
    );

    -- Decode 12-bit color
    bg_red <= data(11 DOWNTO 8);
    bg_green <= data(7 DOWNTO 4);
    bg_blue <= data(3 DOWNTO 0);
END Behavioral;