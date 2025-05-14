library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_flappy is
    port (
        CLOCK_50 : in std_logic;
        RESET_N  : in std_logic;
        PS2_CLK  : in std_logic;
        PS2_DAT  : in std_logic;
        VGA_HS   : out std_logic;
        VGA_VS   : out std_logic;
        VGA_R    : out std_logic;
        VGA_G    : out std_logic;
        VGA_B    : out std_logic
    );
end entity;

architecture Behavioral of top_flappy is

    signal clk_25       : std_logic := '0';
    signal clk_div      : std_logic := '0';
    signal clk_cnt      : integer range 0 to 1 := 0;

    -- VGA signals
    signal pixel_row    : std_logic_vector(9 downto 0);
    signal pixel_col    : std_logic_vector(9 downto 0);
    signal h_sync, v_sync : std_logic;
    signal video_on     : std_logic;

    -- Mouse signals
    signal mouse_x, mouse_y : std_logic_vector(9 downto 0);

    -- Color signals
    signal red, green, blue : std_logic;

    -- Ball draw flag
    signal draw_ball    : std_logic;

begin

    -- === Clock Divider: Divide 50MHz to 25MHz for VGA ===
    process (CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            clk_cnt <= clk_cnt + 1;
            if clk_cnt = 1 then
                clk_cnt <= 0;
                clk_div <= not clk_div;
            end if;
        end if;
    end process;
    clk_25 <= clk_div;

    -- === VGA Sync Generator ===
    vga_sync_inst: entity work.vga_sync
        port map (
            clk       => clk_25,
            reset     => not RESET_N,
            row       => pixel_row,
            col       => pixel_col,
            h_sync    => h_sync,
            v_sync    => v_sync,
            video_on  => video_on
        );

    -- === Mouse Interface ===
    mouse_inst: entity work.mouse
        port map (
            clk       => CLOCK_50,
            reset     => not RESET_N,
            ps2_clk   => PS2_CLK,
            ps2_data  => PS2_DAT,
            xpos      => mouse_x,
            ypos      => mouse_y
        );

    -- === Bouncy Ball Display (controlled by mouse_x/mouse_y) ===
    ball_inst: entity work.bouncy_ball
        port map (
            clk     => clk_25,
            row     => pixel_row,
            col     => pixel_col,
            x_pos   => mouse_x,
            y_pos   => mouse_y,
            draw    => draw_ball
        );

    -- === RGB Output Logic ===
    red   <= draw_ball;
    green <= '0';
    blue  <= '0';

    VGA_HS <= h_sync;
    VGA_VS <= v_sync;
    VGA_R  <= red when video_on = '1' else '0';
    VGA_G  <= green when video_on = '1' else '0';
    VGA_B  <= blue when video_on = '1' else '0';

end architecture;
