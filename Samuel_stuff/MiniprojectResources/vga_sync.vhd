LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY VGA_SYNC IS
    PORT (
        clock_25Mhz     : IN  STD_LOGIC;
        red             : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        green           : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        blue            : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        red_out         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        green_out       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        blue_out        : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        horiz_sync_out  : OUT STD_LOGIC;
        vert_sync_out   : OUT STD_LOGIC;
        pixel_row       : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_column    : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
    );
END VGA_SYNC;

ARCHITECTURE a OF VGA_SYNC IS
    SIGNAL horiz_sync, vert_sync : STD_LOGIC;
    SIGNAL video_on, video_on_v, video_on_h : STD_LOGIC;
    SIGNAL h_count, v_count : STD_LOGIC_VECTOR(9 DOWNTO 0);

BEGIN

    -- video_on is high only when RGB data is displayed
    video_on <= video_on_h AND video_on_v;

    PROCESS (clock_25Mhz)
    BEGIN
        IF rising_edge(clock_25Mhz) THEN
            -- Horizontal counter
            IF (h_count = 799) THEN
                h_count <= (OTHERS => '0');
            ELSE
                h_count <= h_count + 1;
            END IF;

            -- Vertical counter
            IF (v_count = 524) AND (h_count = 699) THEN
                v_count <= (OTHERS => '0');
            ELSIF (h_count = 699) THEN
                v_count <= v_count + 1;
            END IF;

            -- Generate Horizontal Sync Pulse
            IF (h_count >= 659 AND h_count <= 755) THEN
                horiz_sync <= '0';
            ELSE
                horiz_sync <= '1';
            END IF;

            -- Generate Vertical Sync Pulse
            IF (v_count >= 493 AND v_count <= 494) THEN
                vert_sync <= '0';
            ELSE
                vert_sync <= '1';
            END IF;

            -- Visible area
            IF (h_count <= 639) THEN
                video_on_h <= '1';
                pixel_column <= h_count;
            ELSE
                video_on_h <= '0';
            END IF;

            IF (v_count <= 479) THEN
                video_on_v <= '1';
                pixel_row <= v_count;
            ELSE
                video_on_v <= '0';
            END IF;
        END IF;
    END PROCESS;

    -- Output RGB and syncs
    red_out     <= red   WHEN video_on = '1' ELSE (OTHERS => '0');
    green_out   <= green WHEN video_on = '1' ELSE (OTHERS => '0');
    blue_out    <= blue  WHEN video_on = '1' ELSE (OTHERS => '0');

    horiz_sync_out <= horiz_sync;
    vert_sync_out  <= vert_sync;

END a;
