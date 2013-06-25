library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.conv_std_logic_vector;

entity ppu_render is 
    port (  clk         : in std_logic;
            rst_n       : in std_logic
    );
end ppu_render;

architecture rtl of ppu_render is

component counter_register
    
    generic (
        dsize : integer := 8
    );
    port (  clk         : in std_logic;
            rst_n       : in std_logic;
            ce_n        : in std_logic;
            q           : out std_logic_vector(dsize - 1 downto 0)
    );
end component;

constant X_SIZE       : integer := 9;
constant HSCAN_MAX    : integer := 340;
constant VSCAN_MAX    : integer := 261;


signal render_en_n      : std_logic;
signal render_x_res_n   : std_logic;
signal render_y_en_n      : std_logic;
signal render_y_res_n   : std_logic;

signal cur_x            : std_logic_vector(X_SIZE - 1 downto 0);
signal cur_y            : std_logic_vector(X_SIZE - 1 downto 0);

begin

    render_en_n <= '0';
    cur_x_inst : counter_register generic map (X_SIZE)
            port map (clk, render_x_res_n, render_en_n, cur_x);
    --y pos increment when x pos reset.
    render_y_en_n <= render_x_res_n;
    cur_y_inst : counter_register generic map (X_SIZE)
            port map (clk, render_y_res_n, render_y_en_n, cur_y);

    clk_p : process (rst_n, clk) 
    begin
        if (rst_n = '0') then
            render_x_res_n <= '0';
            render_y_res_n <= '0';
        end if;

        if (clk'event and clk = '0' and rst_n = '1') then
            --x pos reset.
            if (cur_x = conv_std_logic_vector(VSCAN_MAX, X_SIZE)) then
                render_x_res_n <= '0';
            else
                render_x_res_n <= '1';
            end if;

            --y pos reset.
            if (cur_y = conv_std_logic_vector(HSCAN_MAX, X_SIZE)) then
                render_y_res_n <= '0';
            else
                render_y_res_n <= '1';
            end if;
        end if;
    end process;

end rtl;

