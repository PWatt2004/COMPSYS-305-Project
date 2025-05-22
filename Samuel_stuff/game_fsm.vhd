library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity game_fsm is
    port (
        clk            : in  std_logic;
        reset          : in  std_logic;

        start_training : in  std_logic;
        start_game     : in  std_logic;
        pipe_hit       : in  std_logic;

        mode_training  : out std_logic;
        game_active    : out std_logic;
        in_title       : out std_logic;
        in_lose        : out std_logic
    );
end game_fsm;

architecture Behavioral of game_fsm is
    type state_type is (INIT, TITLE, GAMEPLAY, LOSE);
    signal current_state, next_state : state_type;

    signal mode_training_reg : std_logic := '0'; -- internal register
begin

    -- State Register
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

    -- State Transitions
    process(current_state, start_training, start_game, pipe_hit)
    begin
        next_state <= current_state; -- default

        case current_state is
            when INIT =>
                next_state <= TITLE;

            when TITLE =>
                if start_training = '1' then
                    next_state <= GAMEPLAY;
                    mode_training_reg <= '1';
                elsif start_game = '1' then
                    next_state <= GAMEPLAY;
                    mode_training_reg <= '0';
                end if;

            when GAMEPLAY =>
                if pipe_hit = '1' and mode_training_reg = '0' then
                    next_state <= LOSE;
                end if;

            when LOSE =>
                next_state <= TITLE;

            when others =>
                next_state <= INIT;
        end case;
    end process;

    -- Output Assignments
    mode_training <= mode_training_reg;
    game_active   <= '1' when current_state = GAMEPLAY else '0';
    in_title      <= '1' when current_state = TITLE else '0';
    in_lose       <= '1' when current_state = LOSE else '0';

end Behavioral;
