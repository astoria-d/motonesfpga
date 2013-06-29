library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.conv_std_logic_vector;
use ieee.std_logic_unsigned.all;

entity ppu_render is 
    port (  clk         : in std_logic;
            rst_n       : in std_logic;
            vblank_n    : out std_logic;
            rd_n        : out std_logic;
            wr_n        : out std_logic;
            ale         : out std_logic;
            vram_ad     : inout std_logic_vector (7 downto 0);
            vram_a      : out std_logic_vector (13 downto 8);
            pos_x       : out std_logic_vector (8 downto 0);
            pos_y       : out std_logic_vector (8 downto 0);
            r           : out std_logic_vector (3 downto 0);
            g           : out std_logic_vector (3 downto 0);
            b           : out std_logic_vector (3 downto 0)
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

component shift_register
    generic (
        dsize : integer := 8
    );
    port (  clk         : in std_logic;
            rst_n       : in std_logic;
            ce_n        : in std_logic;
            we_n        : in std_logic;
            d           : buffer std_logic_vector(dsize - 1 downto 0);
            q           : out std_logic_vector(dsize - 1 downto 0)
    );
end component;

component d_flip_flop
    generic (
            dsize : integer := 8
            );
    port (  
            clk     : in std_logic;
            res_n   : in std_logic;
            set_n   : in std_logic;
            we_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;

component tri_state_buffer
    generic (
            dsize : integer := 8
            );
    port (  
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;

component test_module_init_data
    port (  clk         : in std_logic;
            v_rd_n        : out std_logic;
            v_wr_n        : out std_logic;
            v_ale         : out std_logic;
            v_ad     : inout std_logic_vector (7 downto 0);
            v_a      : out std_logic_vector (13 downto 8)
    );
end component;

constant X_SIZE       : integer := 9;
constant dsize        : integer := 8;
constant asize        : integer := 14;
constant VSCAN_MAX    : integer := 261;
constant HSCAN_MAX    : integer := 340;

signal rst              : std_logic;
signal clk_n            : std_logic;

signal io_oe_n          : std_logic;

signal render_en_n      : std_logic;
signal render_x_res_n   : std_logic;
signal render_y_en_n    : std_logic;
signal render_y_res_n   : std_logic;

signal cur_x            : std_logic_vector(X_SIZE - 1 downto 0);
signal cur_y            : std_logic_vector(X_SIZE - 1 downto 0);

signal nt_we_n          : std_logic;
signal attr_we_n        : std_logic;
signal ptn_l_we_n       : std_logic;
signal ptn_h_we_n       : std_logic;

signal nt_val           : std_logic_vector (dsize - 1 downto 0);
signal attr_val         : std_logic_vector (dsize - 1 downto 0);
signal ptn_l_val        : std_logic_vector (dsize * 2 - 1 downto 0);
signal ptn_l_in         : std_logic_vector (dsize * 2 - 1 downto 0);
signal ptn_h_val        : std_logic_vector (dsize * 2 - 1 downto 0);
signal ptn_h_in         : std_logic_vector (dsize * 2 - 1 downto 0);


signal vram_addr        : std_logic_vector (asize - 1 downto 0);

signal init_ale          : std_logic;
signal init_rd_n          : std_logic;
signal init_wr_n          : std_logic;

begin

    rst <= not rst_n;
    clk_n <= not clk;


    render_en_n <= '0';

--    wr_n <= '1';
--    ale <= not cur_x(0) when rst_n = '1' else '1';
--    rd_n <= not cur_x(0) when rst_n = '1' else '1';
    ale <= cur_x(0) when rst_n = '1' else init_ale;
    rd_n <= cur_x(0) when rst_n = '1' else init_rd_n;
    wr_n <= '1' when rst_n = '1' else init_wr_n;
    io_oe_n <= not cur_x(0) when rst_n = '1' else '1';


    -----fill test data during the reset.....
    init_data : test_module_init_data 
        port map (clk, init_rd_n, init_wr_n, init_ale, vram_ad, vram_a);


    --current x,y pos
    cur_x_inst : counter_register generic map (X_SIZE)
            port map (clk, render_x_res_n, render_en_n, cur_x);
    cur_y_inst : counter_register generic map (X_SIZE)
            port map (clk, render_y_res_n, render_y_en_n, cur_y);

    nt_inst : d_flip_flop generic map(dsize)
            port map (clk_n, rst_n, '1', nt_we_n, vram_ad, nt_val);
    at_inst : d_flip_flop generic map(dsize)
            port map (clk_n, rst_n, '1', attr_we_n, vram_ad, attr_val);


    ptn_l_in <= vram_ad & ptn_l_val (dsize downto 1);
    ptn_l_inst : shift_register generic map(dsize * 2)
            port map (clk_n, rst_n, '0', ptn_l_we_n, ptn_l_in, ptn_l_val);

    ptn_h_in <= vram_ad & ptn_h_val (dsize downto 1);
    ptn_h_inst : shift_register generic map(dsize * 2)
            port map (clk_n, rst_n, '0', ptn_h_we_n, ptn_h_in, ptn_h_val);

    vram_io_buf : tri_state_buffer generic map (dsize)
            port map (io_oe_n, vram_addr(dsize - 1 downto 0), vram_ad);

    vram_a_buf : tri_state_buffer generic map (6)
            port map (rst, vram_addr(asize - 1 downto dsize), vram_a);

    pos_x <= cur_x;
    pos_y <= cur_y;

    clk_p : process (rst_n, clk) 
    begin
        if (rst_n = '0') then
            render_x_res_n <= '0';
            render_y_res_n <= '0';
            nt_we_n <= '1';
        else
            if (clk'event) then
                --x pos reset.
                if (clk = '1' and 
                        cur_x = conv_std_logic_vector(HSCAN_MAX, X_SIZE)) then
                    render_x_res_n <= '0';

                    --y pos reset.
                    if (cur_y = conv_std_logic_vector(VSCAN_MAX, X_SIZE)) then
                        render_y_res_n <= '0';
                    else
                        render_y_res_n <= '1';
                    end if;
                else
                    render_x_res_n <= '1';
                    render_y_res_n <= '1';
                end if;
            end if; --if (clk'event) then

            if (clk'event and clk = '0') then
                --y pos increment.
                if (cur_x = conv_std_logic_vector(HSCAN_MAX, X_SIZE)) then
                    render_y_en_n <= '0';
                else
                    render_y_en_n <= '1';
                end if;
            end if; --if (clk'event) then

            if (clk'event and clk = '1') then
                ----fetch name table byte.
                if (cur_x (2 downto 0) = "000" ) then
                    --vram addr is incremented every 8 cycle.
                    --name table at 0x2000
                    vram_addr(dsize - 1 downto 0) 
                        <= "000" & cur_x(dsize - 1 downto 3);
                    vram_addr(asize - 1 downto dsize) <= "100000";
                end if;
                if (cur_x (2 downto 0) = "001" ) then
                    nt_we_n <= '0';
                else
                    nt_we_n <= '1';
                end if;

                ----fetch attr table byte.
                if (cur_x (2 downto 0) = "010" ) then
                    --vram addr is incremented every 8 cycle.
                    --attr table at 0x23c0
                    vram_addr(dsize - 1 downto 0) 
                        <= "110" & cur_x(dsize - 1 downto 3);
                    vram_addr(asize - 1 downto dsize) <= "100011";
                end if;--if (cur_x (2 downto 0) = "010" ) then
                if (cur_x (2 downto 0) = "011" ) then
                    attr_we_n <= '0';
                else
                    attr_we_n <= '1';
                end if;

                ----fetch pattern table low byte.
                if (cur_x (2 downto 0) = "100" ) then
                    --vram addr is incremented every 8 cycle.
                    vram_addr(dsize - 1 downto 0) <= nt_val;
                    vram_addr(asize - 1 downto dsize) <= "000000";
                end if;--if (cur_x (2 downto 0) = "100" ) then
                if (cur_x (2 downto 0) = "101" ) then
                    ptn_l_we_n <= '0';
                else
                    ptn_l_we_n <= '1';
                end if;

                ----fetch pattern table high byte.
                if (cur_x (2 downto 0) = "110" ) then
                    --vram addr is incremented every 8 cycle.
                    vram_addr(dsize - 1 downto 0) <= nt_val + 1;
                    vram_addr(asize - 1 downto dsize) <= "000000";
                end if;
                if (cur_x (2 downto 0) = "111" ) then
                    ptn_h_we_n <= '0';
                else
                    ptn_h_we_n <= '1';
                end if;--if (cur_x (2 downto 0) = "001" ) then


                --output image.
            end if; --if (clk'event and clk = '1') then

        end if;--if (rst_n = '0') then
    end process;

end rtl;



------------------------------------------------------
------------------------------------------------------
------------------------------------------------------
------------------------------------------------------
--       initialize with dummy data
------------------------------------------------------
------------------------------------------------------
------------------------------------------------------
------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity test_module_init_data is
    port (  clk         : in std_logic;
            v_rd_n        : out std_logic;
            v_wr_n        : out std_logic;
            v_ale         : out std_logic;
            v_ad     : inout std_logic_vector (7 downto 0);
            v_a      : out std_logic_vector (13 downto 8)
    );
end test_module_init_data;

architecture stimulus of test_module_init_data is 
component d_flip_flop
    generic (
            dsize : integer := 8
            );
    port (  
            clk     : in std_logic;
            res_n   : in std_logic;
            set_n   : in std_logic;
            we_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;

    constant ppu_clk : time := 186 ns;
    constant size8 : integer := 8;
    constant size16 : integer := 16;
    constant size14 : integer := 14;


    signal v_addr       : std_logic_vector (size14 - 1 downto 0);

begin

    v_ad <= v_addr(size8 - 1 downto 0);
    v_a <= v_addr(size14 - 1 downto size8);

    -----test for vram/chr-rom
    p3 : process
    variable i : integer := 0;
    variable tmp : std_logic_vector (size8 - 1 downto 0);
    constant loopcnt : integer := 10;
    begin

        wait for 5 us;

        --copy from chr rom to name tbl.
        for i in 0 to loopcnt loop
            --write name tbl #0
            v_ale <= '1';
            v_rd_n <= '1';
            v_wr_n <= '1';
            v_addr <= conv_std_logic_vector(16#2000# + i, size14);
            wait for ppu_clk;
            v_addr(7 downto 0) <= (others => 'Z');
            v_ale <= '0';
            v_rd_n <= '1';
            v_wr_n <= '0';
            ---bg sprite start from 0.
            v_addr(7 downto 0) <= conv_std_logic_vector(16 * i, size8);
            wait for ppu_clk;

            --write attr tbl #0
            v_ale <= '1';
            v_rd_n <= '1';
            v_wr_n <= '1';
            v_addr <= conv_std_logic_vector(16#23c0# + i, size14);
            wait for ppu_clk;
            v_addr(7 downto 0) <= (others => 'Z');
            v_ale <= '0';
            v_rd_n <= '1';
            v_wr_n <= '0';
            v_addr(7 downto 0) <= conv_std_logic_vector(16#a0# + i, size8);
            wait for ppu_clk;
        end loop;

        v_addr <= (others => 'Z');

        wait;
    end process;

end stimulus ;