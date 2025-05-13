library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bouncy_ball is
    Port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        pixel_row   : in  std_logic_vector(9 downto 0);
        pixel_col   : in  std_logic_vector(9 downto 0);
        mouse_click : in  std_logic;  -- New: input for left click
        ball_on     : out std_logic
    );
end bouncy_ball;

architecture Behavioral of bouncy_ball is
    signal bird_y        : integer range 0 to 479 := 240; -- bird's vertical position
    signal bird_x        : integer := 100;               -- fixed horizontal position
    signal velocity      : integer := 0;                 -- vertical velocity
    constant gravity     : integer := 1;                 -- gravity pulling down
    constant flap_force  : integer := -6;                -- upward force
    constant max_speed   : integer := 6;
    signal tick          : integer := 0;                 -- divider for slow updates
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                bird_y   <= 240;
                velocity <= 0;
            else
                -- Slow down updates to ~60fps logic
                if tick = 1 then
                    tick <= 0;

                    -- On mouse click, apply upward flap
                    if mouse_click = '1' then
                        velocity <= flap_force;
                    else
                        -- Gravity
                        if velocity < max_speed then
                            velocity <= velocity + gravity;
                        end if;
                    end if;

                    -- Update position
                    bird_y <= bird_y + velocity;

                    -- Bounds checking
                    if bird_y < 0 then
                        bird_y <= 0;
                        velocity <= 0;
                    elsif bird_y > 479 then
                        bird_y <= 479;
                        velocity <= 0;
                    end if;
                else
                    tick <= tick + 1;
                end if;
            end if;
        end if;
    end process;

    -- Draw the bird as a square (8x8 pixels)
    ball_on <= '1' when
        (to_integer(unsigned(pixel_col)) >= bird_x and to_integer(unsigned(pixel_col)) < bird_x + 8) and
        (to_integer(unsigned(pixel_row)) >= bird_y and to_integer(unsigned(pixel_row)) < bird_y + 8)
        else '0';

end Behavioral;

