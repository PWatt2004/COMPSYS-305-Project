LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY fsm IS
    PORT (
        clk             : IN  STD_LOGIC;
        reset           : IN  STD_LOGIC;
        key0            : IN  STD_LOGIC;  -- press to select TRAINING
        key1            : IN  STD_LOGIC;  -- press to select SINGLEPLAYER
        click           : IN  STD_LOGIC;  -- mouse click to start
        pipe_hit        : IN  STD_LOGIC;
        life_zero       : IN  STD_LOGIC;

        -- Outputs
        game_active     : OUT STD_LOGIC;
        show_mode_text  : OUT STD_LOGIC;
        game_over_flag  : OUT STD_LOGIC;
        mode_select     : OUT STD_LOGIC
    );
END fsm;

ARCHITECTURE Behavioral OF fsm IS
    TYPE state_type IS (INIT, WAIT_START, RUNNING, GAME_OVER);
    SIGNAL current_state, next_state : state_type;

    SIGNAL mode_reg : STD_LOGIC := '0';  -- '0' = TRAINING, '1' = SINGLEPLAYER
BEGIN

    -- Sequential state transition
    PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            current_state <= INIT;
        ELSIF rising_edge(clk) THEN
            current_state <= next_state;
        END IF;
    END PROCESS;

    -- Mode selection in INIT state using KEY0 and KEY1
    PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            mode_reg <= '0';  -- default to TRAINING
        ELSIF rising_edge(clk) THEN
            IF current_state = INIT THEN
                IF key0 = '0' THEN
                    mode_reg <= '0';  -- TRAINING
                ELSIF key1 = '0' THEN
                    mode_reg <= '1';  -- SINGLEPLAYER
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- Mealy FSM: state transitions + outputs
    PROCESS (current_state, click, pipe_hit, life_zero, mode_reg)
    BEGIN
        -- Defaults
        game_active     <= '0';
        show_mode_text  <= '0';
        game_over_flag  <= '0';
        mode_select     <= mode_reg;

        CASE current_state IS
            WHEN INIT =>
                show_mode_text <= '1';
                IF click = '1' THEN
                    next_state <= WAIT_START;
                ELSE
                    next_state <= INIT;
                END IF;

            WHEN WAIT_START =>
                show_mode_text <= '1';
                IF click = '1' THEN
                    next_state <= RUNNING;
                ELSE
                    next_state <= WAIT_START;
                END IF;

            WHEN RUNNING =>
                game_active <= '1';
                IF pipe_hit = '1' OR life_zero = '1' THEN
                    next_state <= GAME_OVER;
                ELSE
                    next_state <= RUNNING;
                END IF;

            WHEN GAME_OVER =>
                game_over_flag <= '1';
                next_state <= GAME_OVER;
        END CASE;
    END PROCESS;

END Behavioral;
