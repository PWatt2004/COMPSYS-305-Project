LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY background IS
    PORT (
        clk          : IN  STD_LOGIC;
        pixel_row    : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_column : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        bg_red       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        bg_green     : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        bg_blue      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END background;

ARCHITECTURE Behavioral OF background IS
    -- Scroll speeds
    CONSTANT BG_SCROLL_TICKS    : INTEGER := 5000000;   -- Clouds (L→R)
    CONSTANT MID_SCROLL_TICKS   : INTEGER := 10000000;  -- Middle (R→L, half speed)
    CONSTANT FLOOR_SCROLL_TICKS : INTEGER := 5000000;   -- Floor (R→L, full speed)

    -- Address/data
    SIGNAL base_address   : INTEGER RANGE 0 TO 4799;
    SIGNAL mid_address    : INTEGER RANGE 0 TO 4799;
    SIGNAL floor_address  : INTEGER RANGE 0 TO 799;

    SIGNAL base_data      : STD_LOGIC_VECTOR(11 DOWNTO 0);
    SIGNAL mid_data       : STD_LOGIC_VECTOR(11 DOWNTO 0);
    SIGNAL floor_data     : STD_LOGIC_VECTOR(11 DOWNTO 0);

    -- Scroll positions
    SIGNAL bg_scroll_offset    : INTEGER RANGE 0 TO 79 := 0;
    SIGNAL mid_scroll_offset   : INTEGER RANGE 0 TO 79 := 0;
    SIGNAL floor_scroll_offset : INTEGER RANGE 0 TO 79 := 0;

    -- Tick counters
    SIGNAL bg_tick_counter     : INTEGER RANGE 0 TO BG_SCROLL_TICKS := 0;
    SIGNAL mid_tick_counter    : INTEGER RANGE 0 TO MID_SCROLL_TICKS := 0;
    SIGNAL floor_tick_counter  : INTEGER RANGE 0 TO FLOOR_SCROLL_TICKS := 0;

    COMPONENT bg_rom
        PORT (
            clk  : IN  STD_LOGIC;
            addr : IN  INTEGER RANGE 0 TO 4799;
            dout : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT mid_rom
        PORT (
            clk  : IN  STD_LOGIC;
            addr : IN  INTEGER RANGE 0 TO 4799;
            dout : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT floor_rom
        PORT (
            clk  : IN  STD_LOGIC;
            addr : IN  INTEGER RANGE 0 TO 799;
            dout : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
        );
    END COMPONENT;
BEGIN

    ------------------------------------------------------------------------
    -- Scroll counter logic
    ------------------------------------------------------------------------
    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            -- Background (clouds)
            IF bg_tick_counter = BG_SCROLL_TICKS - 1 THEN
                bg_tick_counter <= 0;
                bg_scroll_offset <= (bg_scroll_offset + 1) MOD 80;
            ELSE
                bg_tick_counter <= bg_tick_counter + 1;
            END IF;

            -- Middle (foreground)
            IF mid_tick_counter = MID_SCROLL_TICKS - 1 THEN
                mid_tick_counter <= 0;
                mid_scroll_offset <= (mid_scroll_offset + 1) MOD 80;
            ELSE
                mid_tick_counter <= mid_tick_counter + 1;
            END IF;

            -- Floor
            IF floor_tick_counter = FLOOR_SCROLL_TICKS - 1 THEN
                floor_tick_counter <= 0;
                floor_scroll_offset <= (floor_scroll_offset + 1) MOD 80;
            ELSE
                floor_tick_counter <= floor_tick_counter + 1;
            END IF;
        END IF;
    END PROCESS;

    ------------------------------------------------------------------------
    -- Address generation
    ------------------------------------------------------------------------
    PROCESS(pixel_row, pixel_column, bg_scroll_offset, mid_scroll_offset, floor_scroll_offset)
        VARIABLE row_idx   : INTEGER RANGE 0 TO 59;
        VARIABLE col_idx   : INTEGER RANGE 0 TO 79;
        VARIABLE base_col  : INTEGER;
        VARIABLE mid_col   : INTEGER;
        VARIABLE floor_col : INTEGER;
    BEGIN
        row_idx := to_integer(unsigned(pixel_row(9 DOWNTO 3)));
        col_idx := to_integer(unsigned(pixel_column(9 DOWNTO 3)));

        -- Background: left to right
        IF col_idx >= bg_scroll_offset THEN
            base_col := col_idx - bg_scroll_offset;
        ELSE
            base_col := col_idx + 80 - bg_scroll_offset;
        END IF;
        base_address <= row_idx * 80 + base_col;

        -- Middle: right to left
        mid_col := col_idx + mid_scroll_offset;
        IF mid_col >= 80 THEN
            mid_col := mid_col - 80;
        END IF;
        mid_address <= row_idx * 80 + mid_col;

        -- Floor (row 50–59)
        IF row_idx >= 50 THEN
            floor_col := col_idx + floor_scroll_offset;
            IF floor_col >= 80 THEN
                floor_col := floor_col - 80;
            END IF;
            floor_address <= (row_idx - 50) * 80 + floor_col;
        ELSE
            floor_address <= 0;
        END IF;
    END PROCESS;

    ------------------------------------------------------------------------
    -- ROM Instantiation
    ------------------------------------------------------------------------
    bg_inst : bg_rom
        PORT MAP (
            clk  => clk,
            addr => base_address,
            dout => base_data
        );

    mid_inst : mid_rom
        PORT MAP (
            clk  => clk,
            addr => mid_address,
            dout => mid_data
        );

    floor_inst : floor_rom
        PORT MAP (
            clk  => clk,
            addr => floor_address,
            dout => floor_data
        );

    ------------------------------------------------------------------------
    -- Layer selection priority: Floor > Middle > Background
    ------------------------------------------------------------------------
    PROCESS(base_data, mid_data, floor_data, pixel_row)
        VARIABLE row_idx : INTEGER;
    BEGIN
        row_idx := to_integer(unsigned(pixel_row(9 DOWNTO 3)));

        IF row_idx >= 50 THEN  -- Floor has top priority in bottom 10 rows
            bg_red   <= floor_data(11 DOWNTO 8);
            bg_green <= floor_data(7 DOWNTO 4);
            bg_blue  <= floor_data(3 DOWNTO 0);
        ELSIF mid_data /= X"FFF" THEN  -- Middle layer visible
            bg_red   <= mid_data(11 DOWNTO 8);
            bg_green <= mid_data(7 DOWNTO 4);
            bg_blue  <= mid_data(3 DOWNTO 0);
        ELSE  -- Fallback to background
            bg_red   <= base_data(11 DOWNTO 8);
            bg_green <= base_data(7 DOWNTO 4);
            bg_blue  <= base_data(3 DOWNTO 0);
        END IF;
    END PROCESS;

END Behavioral;
