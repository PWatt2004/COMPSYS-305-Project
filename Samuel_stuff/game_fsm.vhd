library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity game_fsm is
    port (
        clk            : in  std_logic;
        reset          : in  std_logic;
        start_button   : in  std_logic;
        pipe_hit       : in  std_logic;
        mode_training  : in  std_logic;

        game_active    : out std_logic;
        in_title       : out std_logic;
        in_lose        : out std_logic
    );
end entity;

architecture Behavioral of game_fsm is
    type state_type is (INIT, TITLE, GAMEPLAY, LOSE);
    signal current_state, next_state : state_type;
begin

    -- STATE REGISTER
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                current_state <= INIT;
            else
                current_state <= next_state;
            end if;
        end if;
    end process;

    -- TRANSITION LOGIC
    process(current_state, start_button, pipe_hit, mode_training)
    begin
        case current_state is
            when INIT =>
                next_state <= TITLE;

            when TITLE =>
                if start_button = '1' then
                    next_state <= GAMEPLAY;
                else
                    next_state <= TITLE;
                end if;

            when GAMEPLAY =>
                if pipe_hit = '1' and mode_training = '0' then
                    next_state <= LOSE;
                else
                    next_state <= GAMEPLAY;
                end if;

            when LOSE =>
                next_state <= TITLE;

            when others =>
                next_state <= INIT;
        end case;
    end process;

    -- OUTPUTS BASED ON STATE
    game_active <= '1' when current_state = GAMEPLAY else '0';
    in_title    <= '1' when current_state = TITLE else '0';
    in_lose     <= '1' when current_state = LOSE else '0';

end Behavioral;
