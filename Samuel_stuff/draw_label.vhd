library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity draw_label is
    generic (
        TEXT_LENGTH : integer := 16;
        SCALE       : integer := 1
    );
    port (
        clk         : in  std_logic;
        active      : in  std_logic;
        pixel_x     : in  std_logic_vector(9 downto 0);
        pixel_y     : in  std_logic_vector(9 downto 0);
        start_x     : in  integer;
        start_y     : in  integer;
        text_string : in  string(1 to TEXT_LENGTH);
        pixel_on    : out std_logic
    );
end entity draw_label;

architecture Behavioral of draw_label is

    component char_rom
        port (
            character_address : in  std_logic_vector(5 downto 0);
            font_row          : in  std_logic_vector(2 downto 0);
            font_col          : in  std_logic_vector(2 downto 0);
            clock             : in  std_logic;
            rom_mux_output    : out std_logic
        );
    end component;

    constant CHAR_WIDTH  : integer := 8 * SCALE;
    constant CHAR_HEIGHT : integer := 8 * SCALE;

    signal char_code      : std_logic_vector(5 downto 0);
    signal char_x         : integer;
    signal char_y         : integer;
    signal pixel_in_char  : std_logic;
    signal pixel_in_last  : std_logic := '0';  -- ROM delay
begin

    -- ROM instance
    char_rom_inst : char_rom
        port map (
            character_address => char_code,
            font_row          => std_logic_vector(to_unsigned(char_y, 3)),
            font_col          => std_logic_vector(to_unsigned(char_x, 3)),
            clock             => clk,
            rom_mux_output    => pixel_in_char
        );

process(clk)
    variable px, py : integer;
    variable char_index : integer;
		begin
			 if rising_edge(clk) then
				  if active = '1' then
						px := to_integer(unsigned(pixel_x));
						py := to_integer(unsigned(pixel_y));

						if py >= start_y and py < start_y + CHAR_HEIGHT then
							 char_index := (px - start_x) / CHAR_WIDTH + 1;
							 if char_index >= 1 and char_index <= TEXT_LENGTH then
								  char_code <= std_logic_vector(to_unsigned(character'pos(text_string(char_index)), 6));
								  char_x <= ((px - start_x) mod CHAR_WIDTH) / SCALE;
								  char_y <= (py - start_y) / SCALE;
							 else
								  char_code <= std_logic_vector(to_unsigned(0, 6)); -- fallback to space
							 end if;
						else
							 char_code <= std_logic_vector(to_unsigned(0, 6));
						end if;
				  else
						char_code <= std_logic_vector(to_unsigned(0, 6));
				  end if;

				  -- After all addressing, register ROM output
				  pixel_on <= pixel_in_last;
				  pixel_in_last <= pixel_in_char;
			 end if;
		end process;

end architecture Behavioral;