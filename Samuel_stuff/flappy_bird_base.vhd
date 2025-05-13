library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity flappy_bird_base is
    port (
        CLOCK_50    : in  std_logic;
        RESET_N     : in  std_logic;
        PS2_CLK     : inout std_logic;
        PS2_DAT     : inout std_logic;
        VGA_R       : out std_logic_vector(3 downto 0);
        VGA_G       : out std_logic_vector(3 downto 0);
        VGA_B       : out std_logic_vector(3 downto 0);
        VGA_HS      : out std_logic;
        VGA_VS      : out std_logic
    );
end flappy_bird_base;

architecture top of flappy_bird_base is

    signal clk_25 : std_logic;
    signal red, green, blue : std_logic;
    signal pixel_row, pixel_column : std_logic_vector(9 downto 0);
    signal mouse_row, mouse_col : std_logic_vector(9 downto 0);
    signal left_button, right_button : std_logic;
    signal text_pixel : std_logic;

    signal bird_y : integer := 240;
    signal bird_velocity : integer := 0;

    signal vsync_internal : std_logic;

begin

    VGA_VS <= vsync_internal;

    -- Divide 50MHz clock to 25MHz for VGA
    clk_divider : process(CLOCK_50)
        variable counter : std_logic := '0';
    begin
        if rising_edge(CLOCK_50) then
            counter := not counter;
            clk_25 <= counter;
        end if;
    end process;

    -- Instantiate VGA sync generator
    vga_inst : entity work.vga_sync
        port map (
            clock_25Mhz     => clk_25,
            red             => red,
            green           => green,
            blue            => blue,
            red_out         => VGA_R(3),
            green_out       => VGA_G(3),
            blue_out        => VGA_B(3),
            horiz_sync_out  => VGA_HS,
            vert_sync_out   => vsync_internal,
            pixel_row       => pixel_row,
            pixel_column    => pixel_column
        );

    -- Instantiate mouse controller
    mouse_inst : entity work.mouse
        port map (
            clock_25Mhz         => clk_25,
            reset               => not RESET_N,
            mouse_data          => PS2_DAT,
            mouse_clk           => PS2_CLK,
            left_button         => left_button,
            right_button        => right_button,
            mouse_cursor_row    => mouse_row,
            mouse_cursor_column => mouse_col
        );

    -- Bird movement logic
    process(vsync_internal)
    variable temp_velocity : integer;
    variable temp_y : integer;
    begin
        if rising_edge(vsync_internal) then
            temp_velocity := bird_velocity;
            temp_y := bird_y;

            -- Apply gravity
            temp_velocity := temp_velocity + 1;

            -- Jump if left button is pressed
            if left_button = '1' then
                temp_velocity := -6;
            end if;

            -- Apply velocity to position
            temp_y := temp_y + temp_velocity;

            -- Clamp to screen
            if temp_y < 0 then temp_y := 0; end if;
            if temp_y > 480 then temp_y := 480; end if;

            -- Assign final values back to signals
            bird_velocity <= temp_velocity;
            bird_y <= temp_y;
        end if;
    end process;


    -- Bird drawing logic
    ball_logic : process(pixel_row, pixel_column)
        variable bird_x : integer := 100;
        variable size : integer := 6;
    begin
        if abs(to_integer(unsigned(pixel_column)) - bird_x) < size and
           abs(to_integer(unsigned(pixel_row)) - bird_y) < size then
            red   <= '1';
            green <= '1';
            blue  <= '0'; -- Yellow bird
        else
            red   <= '0';
            green <= '0';
            blue  <= '0';
        end if;
    end process;

    -- Connect lower bits of color to 0
    VGA_R(2 downto 0) <= (others => '0');
    VGA_G(2 downto 0) <= (others => '0');
    VGA_B(2 downto 0) <= (others => '0');

end top;
