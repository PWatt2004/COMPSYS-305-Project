LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- =======================
-- Module: bird_controller
-- Description: This implements the logic and behaviour of the bird when the game is running
-- =======================

ENTITY bird_controller IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        flap_button : IN STD_LOGIC;
        bird_y : OUT INTEGER;
        bird_velocity : OUT INTEGER;
        bird_altitude : OUT INTEGER;
        game_active : IN STD_LOGIC;
        bird_limit_hit : OUT STD_LOGIC
    );
END bird_controller;

ARCHITECTURE behavior OF bird_controller IS
    SIGNAL velocity : INTEGER := 0;   
    SIGNAL y_pos : INTEGER := 240;
    SIGNAL alt_temp : INTEGER;
    SIGNAL hit_ceiling_or_floor : STD_LOGIC := '0';

    --SIGNAL alt_temp : INTEGER;  -- <== this is redundant, bird_altitude could just just be updated directly
BEGIN

    -- ================== Process 
    -- Mechcanics of the Brid/ball falling and flapping
    -- if reset is not initiated and flap_button is not '1' Brid falls 1 pixal per frame
    -- if flap_button is pressed '1' velocity goes up by 6 pixals per frame.
    -- when the Brid reachs the ceiling it stays there, and like wise with the bottom of the screen
    -- ================== 
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF reset = '1' THEN
                y_pos <= 240;
                velocity <= 0;

            ELSIF game_active = '1' THEN
                -- Only move if gameplay is active
                IF flap_button = '1' THEN
                    velocity <= - 6;
                ELSE
                    velocity <= velocity + 1;
                END IF;

                y_pos <= y_pos + velocity;

                IF y_pos < 0 THEN
                    y_pos <= 0;
                    hit_ceiling_or_floor <= '1';
                ELSIF y_pos > 480 THEN
                    y_pos <= 480;
                    hit_ceiling_or_floor <= '1';
                ELSE
                    hit_ceiling_or_floor <= '0';
                END IF;

            END IF;
        END IF;

    END PROCESS;

    -- ==================
    -- Notes for this file
    -- From ChatGPT:
    --      - Magic Numbers like -6 for velocity might not make sense for future updates
    --      - Inconsistance Frame Update: the FPGA base clk is different to the frame rate of the monitor
    --        this might cause so problems, one thing to mediate this is to implement a clk_counter which updates every (sys_clk/frame_clk) cycle.
    --        this will make the game run a bit smoother
    -- ==================   

    alt_temp <= 480 - y_pos;
    bird_y <= y_pos;
    bird_altitude <= alt_temp;
    bird_velocity <= velocity;
    bird_limit_hit <= hit_ceiling_or_floor;
END behavior;