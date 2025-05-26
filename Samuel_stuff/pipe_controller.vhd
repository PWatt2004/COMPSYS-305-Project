LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY pipe_controller IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        bird_x : IN INTEGER RANGE 0 TO 639;
        bird_y : IN INTEGER RANGE 0 TO 479;
        pipe_hit : OUT STD_LOGIC;
        pipe_x_out : OUT STD_LOGIC_VECTOR(39 DOWNTO 0);
        pipe_y_out : OUT STD_LOGIC_VECTOR(39 DOWNTO 0);
        game_active : IN STD_LOGIC;
        in_title : IN STD_LOGIC;
        pipe_passed_tick : OUT STD_LOGIC
    );
END pipe_controller;

ARCHITECTURE behavior OF pipe_controller IS

    CONSTANT pipe_gap : INTEGER := 100;
    CONSTANT pipe_width : INTEGER := 20;
    CONSTANT pipe_spacing : INTEGER := 160;
    CONSTANT screen_width : INTEGER := 640;

    TYPE pipe_array IS ARRAY (0 TO 3) OF INTEGER;
    SIGNAL pipe_x : pipe_array := (
        screen_width + 0 * pipe_spacing,
        screen_width + 1 * pipe_spacing,
        screen_width + 2 * pipe_spacing,
        screen_width + 3 * pipe_spacing
    );
    SIGNAL pipe_y : pipe_array := (200, 220, 240, 260); -- initial gaps

    SIGNAL lfsr : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"ACE1";

    SIGNAL passed_tick : STD_LOGIC := '0';
BEGIN

    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF reset = '1' OR in_title = '1' THEN
                -- Reset all pipes to spaced starting positions
                FOR i IN 0 TO 3 LOOP
                    pipe_x(i) <= screen_width + i * pipe_spacing;
                    pipe_y(i) <= 80 + i * 40;
                END LOOP;
                lfsr <= x"ACE1";

            ELSIF game_active = '1' THEN
                -- Only update when gameplay is active

                -- Update LFSR
                lfsr <= lfsr(14 DOWNTO 0) & (lfsr(15) XOR lfsr(13) XOR lfsr(12) XOR lfsr(10));
                
                
                
                passed_tick <= '0';
                -- Move and respawn pipes
                FOR i IN 0 TO 3 LOOP
                    pipe_x(i) <= pipe_x(i) - 1;

                    IF pipe_x(i) <- pipe_width THEN
                        pipe_x(i) <= pipe_x(i) + 4 * pipe_spacing;
                        pipe_y(i) <= to_integer(unsigned(lfsr(7 DOWNTO 0))) MOD (480 - pipe_gap - 40) + 20;
                        passed_tick <= '1'; -- Set the tick
                    END IF;
                END LOOP;
            END IF;
        END IF;
    END PROCESS;

    -- Collision detection
    PROCESS (bird_x, bird_y, pipe_x, pipe_y)
        VARIABLE hit : STD_LOGIC := '0';
    BEGIN
        hit := '0'; -- reset the flag at the start

        FOR i IN 0 TO 3 LOOP
            IF bird_x + 6 >= pipe_x(i) AND bird_x - 6 <= pipe_x(i) + pipe_width THEN
                IF bird_y < pipe_y(i) OR bird_y > pipe_y(i) + pipe_gap THEN
                    hit := '1'; -- set only if there's overlap
                END IF;
            END IF;
        END LOOP;

        pipe_hit <= hit; -- assign the result after checking all pipes
    END PROCESS;
    -- Output encoded pipe positions
    pipe_x_out(9 DOWNTO 0) <= STD_LOGIC_VECTOR(to_unsigned(pipe_x(0), 10));
    pipe_x_out(19 DOWNTO 10) <= STD_LOGIC_VECTOR(to_unsigned(pipe_x(1), 10));
    pipe_x_out(29 DOWNTO 20) <= STD_LOGIC_VECTOR(to_unsigned(pipe_x(2), 10));
    pipe_x_out(39 DOWNTO 30) <= STD_LOGIC_VECTOR(to_unsigned(pipe_x(3), 10));

    pipe_y_out(9 DOWNTO 0) <= STD_LOGIC_VECTOR(to_unsigned(pipe_y(0), 10));
    pipe_y_out(19 DOWNTO 10) <= STD_LOGIC_VECTOR(to_unsigned(pipe_y(1), 10));
    pipe_y_out(29 DOWNTO 20) <= STD_LOGIC_VECTOR(to_unsigned(pipe_y(2), 10));
    pipe_y_out(39 DOWNTO 30) <= STD_LOGIC_VECTOR(to_unsigned(pipe_y(3), 10));
    pipe_passed_tick <= passed_tick;

END behavior;