LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY bird_controller IS
    PORT (
        clk           : IN STD_LOGIC;
        reset         : IN STD_LOGIC;
        flap_button   : IN STD_LOGIC;
        bird_y        : OUT INTEGER;
        bird_velocity : OUT INTEGER
    );
END bird_controller;

ARCHITECTURE behavior OF bird_controller IS
    SIGNAL velocity : INTEGER := 0;
    SIGNAL y_pos    : INTEGER := 240;
BEGIN
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF reset = '1' THEN
                y_pos <= 240;
                velocity <= 0;
            ELSE
                IF flap_button = '1' THEN
                    velocity <= -6;
                ELSE
                    velocity <= velocity + 1;
                END IF;

                y_pos <= y_pos + velocity;
                IF y_pos < 0 THEN y_pos <= 0; END IF;
                IF y_pos > 480 THEN y_pos <= 480; END IF;
            END IF;
        END IF;
    END PROCESS;

    bird_y <= y_pos;
    bird_velocity <= velocity;
END behavior;
