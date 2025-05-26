LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY game_fsm IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;

        start_training : IN STD_LOGIC;
        start_game : IN STD_LOGIC;
        pipe_hit : IN STD_LOGIC;
        health_zero : IN STD_LOGIC;
        click_reset : IN STD_LOGIC; --click to reset from LOSE
        mode_training : OUT STD_LOGIC;
        game_active : OUT STD_LOGIC;
        in_title : OUT STD_LOGIC;
        in_lose : OUT STD_LOGIC

    );
END game_fsm;

ARCHITECTURE Behavioral OF game_fsm IS
    TYPE state_type IS (INIT, TITLE, GAMEPLAY, LOSE);
    SIGNAL current_state, next_state : state_type;

    SIGNAL mode_training_reg : STD_LOGIC := '0'; -- internal register
BEGIN

    -- State Register
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF reset = '1' THEN
                current_state <= INIT;
            ELSE
                current_state <= next_state;
            END IF;
        END IF;
    END PROCESS;

    -- State Transitions
    PROCESS (current_state, start_training, start_game, pipe_hit, health_zero)
    BEGIN
        next_state <= current_state; -- default

        CASE current_state IS
            WHEN INIT =>
                next_state <= TITLE;

            WHEN TITLE =>
                IF start_training = '1' THEN
                    next_state <= GAMEPLAY;
                    mode_training_reg <= '1';
                ELSIF start_game = '1' THEN
                    next_state <= GAMEPLAY;
                    mode_training_reg <= '0';
                END IF;

            WHEN GAMEPLAY =>
                IF mode_training_reg = '0' AND pipe_hit = '1' THEN
                    next_state <= LOSE;
                ELSIF mode_training_reg = '1' AND health_zero = '1' THEN
                    next_state <= LOSE;
                END IF;

            WHEN LOSE =>
                IF click_reset = '1' THEN
                    next_state <= TITLE;
                END IF;

            WHEN OTHERS =>
                next_state <= INIT;
        END CASE;
    END PROCESS;

    -- Output Assignments
    mode_training <= mode_training_reg;
    game_active <= '1' WHEN current_state = GAMEPLAY ELSE
        '0';
    in_title <= '1' WHEN current_state = TITLE ELSE
        '0';
    in_lose <= '1' WHEN current_state = LOSE ELSE
        '0';

END Behavioral;