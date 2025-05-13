LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY pipe_controller IS
    PORT (
        clk            : IN STD_LOGIC;
        reset          : IN STD_LOGIC;
        bird_x         : IN INTEGER;
        bird_y         : IN INTEGER;
        pipe_speed     : IN INTEGER := 1;
        pipe_init_x    : IN INTEGER;
        pipe_x_out     : OUT INTEGER;
        pipe_gap_y_out : OUT INTEGER;
        score_trigger  : OUT STD_LOGIC
    );
END pipe_controller;

ARCHITECTURE behavior OF pipe_controller IS
    SIGNAL pipe_x     : INTEGER;
    SIGNAL pipe_gap_y : INTEGER := 200;
    SIGNAL passed     : STD_LOGIC := '0';
BEGIN

    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF reset = '1' THEN
                pipe_x     <= pipe_init_x;
                pipe_gap_y <= 200;
                passed     <= '0';
            ELSE
                pipe_x <= pipe_x - pipe_speed;

                IF pipe_x + 20 = bird_x AND passed = '0' THEN
                    score_trigger <= '1';
                    passed <= '1';
                ELSE
                    score_trigger <= '0';
                END IF;

                IF pipe_x < -20 THEN
                    pipe_x <= 640;
                    pipe_gap_y <= (pipe_gap_y * 73 + 19) MOD 300 + 60;
                    passed <= '0';
                END IF;
            END IF;
        END IF;
    END PROCESS;

    pipe_x_out     <= pipe_x;
    pipe_gap_y_out <= pipe_gap_y;

END behavior;
