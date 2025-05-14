LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY pipe_controller IS
    PORT (
        clk         : IN  STD_LOGIC;
        reset       : IN  STD_LOGIC;
        bird_x      : IN  INTEGER RANGE 0 TO 639;
        bird_y      : IN  INTEGER RANGE 0 TO 479;
        pipe_hit    : OUT STD_LOGIC;
        pipe_x_out  : OUT STD_LOGIC_VECTOR(39 DOWNTO 0);
        pipe_y_out  : OUT STD_LOGIC_VECTOR(39 DOWNTO 0)
    );
END pipe_controller;

ARCHITECTURE behavior OF pipe_controller IS

    CONSTANT pipe_gap     : INTEGER := 100;
    CONSTANT pipe_width   : INTEGER := 20;
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

BEGIN

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                -- Reset all pipes to spaced starting positions
                for i in 0 to 3 loop
                    pipe_x(i) <= screen_width + i * pipe_spacing;
                    pipe_y(i) <= 80 + i * 40; -- basic vertical variation
                end loop;
            else
                -- Move and respawn pipes
                for i in 0 to 3 loop
                    pipe_x(i) <= pipe_x(i) - 1;

                    if pipe_x(i) < -pipe_width then
                        pipe_x(i) <= pipe_x(i) + 4 * pipe_spacing;
                        pipe_y(i) <= (pipe_y(i) + 97 + i * 31) mod (480 - pipe_gap);
                    end if;
                end loop;
            end if;
        end if;
    end process;

    -- Collision detection
    process(bird_x, bird_y, pipe_x, pipe_y)
    variable hit : STD_LOGIC := '0';
    begin
        for i in 0 to 3 loop
            if bird_x + 6 >= pipe_x(i) and bird_x - 6 <= pipe_x(i) + pipe_width then
                if bird_y < pipe_y(i) or bird_y > pipe_y(i) + pipe_gap then
                    hit := '1';
                end if;
            end if;
        end loop;
        pipe_hit <= hit;
    end process;

    -- Output encoded pipe positions
    pipe_x_out(9 downto 0)     <= std_logic_vector(to_unsigned(pipe_x(0), 10));
    pipe_x_out(19 downto 10)   <= std_logic_vector(to_unsigned(pipe_x(1), 10));
    pipe_x_out(29 downto 20)   <= std_logic_vector(to_unsigned(pipe_x(2), 10));
    pipe_x_out(39 downto 30)   <= std_logic_vector(to_unsigned(pipe_x(3), 10));

    pipe_y_out(9 downto 0)     <= std_logic_vector(to_unsigned(pipe_y(0), 10));
    pipe_y_out(19 downto 10)   <= std_logic_vector(to_unsigned(pipe_y(1), 10));
    pipe_y_out(29 downto 20)   <= std_logic_vector(to_unsigned(pipe_y(2), 10));
    pipe_y_out(39 downto 30)   <= std_logic_vector(to_unsigned(pipe_y(3), 10));

END behavior;
