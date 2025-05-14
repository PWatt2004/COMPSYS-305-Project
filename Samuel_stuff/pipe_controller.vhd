-- pipe_controller.vhd - updated to spawn pipes every 160 pixels and vary vertical gap positions
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

    CONSTANT pipe_gap      : INTEGER := 100;
    CONSTANT pipe_width    : INTEGER := 20;
    CONSTANT pipe_spacing  : INTEGER := 160;
    CONSTANT screen_width  : INTEGER := 640;

    TYPE pipe_array IS ARRAY (0 TO 3) OF INTEGER RANGE 0 TO screen_width;
    SIGNAL pipe_x : pipe_array := (others => screen_width);
    SIGNAL pipe_y : pipe_array := (others => 200); -- default gap height

    SIGNAL pipe_spawn_counter : INTEGER RANGE 0 TO pipe_spacing := 0;
    SIGNAL spawn_pipe : STD_LOGIC := '0';

BEGIN

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                pipe_x <= (others => screen_width);
                pipe_y <= (others => 200);
                pipe_spawn_counter <= 0;
                spawn_pipe <= '0';
            else
                -- scroll pipes
                for i in 0 to 3 loop
                    if pipe_x(i) > 0 then
                        pipe_x(i) <= pipe_x(i) - 1;
                    end if;
                end loop;

                -- handle pipe spawn timing
                if pipe_spawn_counter = pipe_spacing then
                    pipe_spawn_counter <= 0;
                    spawn_pipe <= '1';
                else
                    pipe_spawn_counter <= pipe_spawn_counter + 1;
                    spawn_pipe <= '0';
                end if;

                -- spawn a pipe if triggered
                if spawn_pipe = '1' then
                    for i in 0 to 3 loop
                        if pipe_x(i) = 0 then -- reuse pipe slot
                            pipe_x(i) <= screen_width;
                            pipe_y(i) <= (pipe_y(i) + 57 * i + pipe_spawn_counter * 13) mod (480 - pipe_gap);
                            exit;
                        end if;
                    end loop;
                end if;
            end if;
        end if;
    end process;

    -- collision detection (simplified)
    process(bird_x, bird_y, pipe_x, pipe_y)
    variable hit : STD_LOGIC := '0';
    begin
        for i in 0 to 3 loop
            if bird_x + 10 >= pipe_x(i) and bird_x <= pipe_x(i) + pipe_width then
                if bird_y < pipe_y(i) or bird_y > pipe_y(i) + pipe_gap then
                    hit := '1';
                end if;
            end if;
        end loop;
        pipe_hit <= hit;
    end process;

    -- Encode 4 pipe_x values (each 10 bits) into pipe_x_out
    pipe_x_out(9 downto 0)    <= std_logic_vector(to_unsigned(pipe_x(0), 10));
    pipe_x_out(19 downto 10)  <= std_logic_vector(to_unsigned(pipe_x(1), 10));
    pipe_x_out(29 downto 20)  <= std_logic_vector(to_unsigned(pipe_x(2), 10));
    pipe_x_out(39 downto 30)  <= std_logic_vector(to_unsigned(pipe_x(3), 10));

    -- Encode 4 pipe_y values (each 10 bits) into pipe_y_out
    pipe_y_out(9 downto 0)    <= std_logic_vector(to_unsigned(pipe_y(0), 10));
    pipe_y_out(19 downto 10)  <= std_logic_vector(to_unsigned(pipe_y(1), 10));
    pipe_y_out(29 downto 20)  <= std_logic_vector(to_unsigned(pipe_y(2), 10));
    pipe_y_out(39 downto 30)  <= std_logic_vector(to_unsigned(pipe_y(3), 10));

END behavior;
