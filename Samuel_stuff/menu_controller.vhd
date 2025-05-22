library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity menu_controller is
    port (
        clk         : in  std_logic;
        in_title    : in  std_logic;

        mouse_x     : in std_logic_vector(9 downto 0);
        mouse_y     : in std_logic_vector(9 downto 0);
        mouse_click : in std_logic;

        start_training : out std_logic;
        start_game     : out std_logic
    );
end entity;

architecture Behavioral of menu_controller is
    signal training_clicked : std_logic := '0';
    signal game_clicked     : std_logic := '0';
begin

    process(clk)
        variable x, y : integer;
    begin
        if rising_edge(clk) then
            x := to_integer(unsigned(mouse_x));
            y := to_integer(unsigned(mouse_y));

            if in_title = '1' and mouse_click = '1' then
                -- Button 1: Training Mode
                if x > 450 and x < 600 and y > 150 and y < 200 then
                    training_clicked <= '1';
                end if;

                -- Button 2: Game Mode
                if x > 450 and x < 600 and y > 220 and y < 270 then
                    game_clicked <= '1';
                end if;
            else
                training_clicked <= '0';
                game_clicked <= '0';
            end if;
        end if;
    end process;

    start_training <= training_clicked;
    start_game     <= game_clicked;

end Behavioral;
