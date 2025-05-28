library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bg_rom is
    port (
        clk   : in  std_logic;
        addr  : in  integer range 0 to 4799;  -- 80 * 60 = 4800 pixels
        dout  : out std_logic_vector(11 downto 0)  -- 12-bit RGB (RRRGGGBBBB)
    );
end bg_rom;

architecture rtl of bg_rom is
    type memory_array is array (0 to 4799) of std_logic_vector(11 downto 0);
    signal memory : memory_array;

    attribute ram_init_file : string;
    attribute ram_init_file of memory : signal is "back_bg";  -- No file extension
begin
    process (clk)
    begin
        if rising_edge(clk) then
            dout <= memory(addr);
        end if;
    end process;
end rtl;
