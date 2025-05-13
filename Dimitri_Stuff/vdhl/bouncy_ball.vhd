library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bouncy_ball is
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        click       : in  std_logic;  -- Flap signal (mouse click)
        pixel_row   : in  std_logic_vector(9 downto 0);
        pixel_col   : in  std_logic_vector(9 downto 0);
        bird_on     : out std_logic
    );
end bouncy_ball;

architecture Behavioral of bouncy_ball is

    constant BIRD_WIDTH  : integer := 16;
    constant BIRD_HEIGHT : integer := 16;
    constant SCREEN_HEIGHT : integer := 480;
    constant BIRD_X : integer := 100;

    signal bird_y         : integer range 0 to SCREEN_HEIGHT - BIRD_HEIGHT := 200;
    signal velocity       : integer range -10 to 10 := 0;
    signal gravity        : integer := 1;
    signal flap_strength  : integer := -5;

    signal pixel_row_int  : integer;
    signal pixel_col_int  : integer;

    signal click_last     : std_logic := '0';
    signal flap_trigger   : std_logic := '0';

begin

    -- Convert std_logic_vector to integer
    pixel_row_int <= to_integer(unsigned(pixel_row));
    pixel_col_int <= to_integer(unsigned(pixel_col));

    -- Rising edge detection for click signal
    process(clk)
    begin
        if rising_edge(clk) then
            click_last <= click;
            if (click = '1' and click_last = '0') then
                flap_trigger <= '1';
            else
                flap_trigger <= '0';
            end if;
        end if;
    end process;

    -- Vertical position update
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                bird_y <= 200;
                velocity <= 0;
            else
                -- On flap, apply upward velocity
                if flap_trigger = '1' then
                    velocity <= flap_strength;
                else
                    velocity <= velocity + gravity;
                end if;

                -- Clamp the velocity
                if velocity > 5 then
                    velocity <= 5;
                elsif velocity < -8 then
                    velocity <= -8;
                end if;

                -- Update position
                bird_y <= bird_y + velocity;

                -- Boundary conditions
                if bird_y < 0 then
                    bird_y <= 0;
                    velocity <= 0;
                elsif bird_y > SCREEN_HEIGHT - BIRD_HEIGHT then
                    bird_y <= SCREEN_HEIGHT - BIRD_HEIGHT;
                    velocity <= 0;
                end if;
            end if;
        end if;
    end process;

    -- Output logic: draw the bird at BIRD_X and bird_y
    bird_on <= '1' when
        pixel_col_int >= BIRD_X and pixel_col_int < BIRD_X + BIRD_WIDTH and
        pixel_row_int >= bird_y and pixel_row_int < bird_y + BIRD_HEIGHT
        else '0';

end Behavioral;

