-------------------------------------------------------------
-------------------------------------------------------------
------------------- PPU VGA Output Control ------------------
-------------------------------------------------------------
-------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;
use ieee.std_logic_arith.conv_std_logic_vector;
use work.motonesfpga_common.all;

entity vga_ctl is 
    port (  
    signal dbg_disp_nt, dbg_disp_attr : out std_logic_vector (7 downto 0);
    signal dbg_disp_ptn_h, dbg_disp_ptn_l : out std_logic_vector (15 downto 0);

            vga_clk     : in std_logic;
            mem_clk     : in std_logic;
            rst_n       : in std_logic;

            --vram i/f
            rd_n        : out std_logic;
            wr_n        : out std_logic;
            ale         : out std_logic;
            vram_ad     : in  std_logic_vector (7 downto 0);
            vram_a      : out std_logic_vector (13 downto 8);

            --vga output
            h_sync_n    : out std_logic;
            v_sync_n    : out std_logic;
            r           : out std_logic_vector (3 downto 0);
            g           : out std_logic_vector (3 downto 0);
            b           : out std_logic_vector (3 downto 0)
    );
end vga_ctl;

architecture rtl of vga_ctl is

component counter_register
    generic (
        dsize       : integer := 8;
        inc         : integer := 1
    );
    port (  clk         : in std_logic;
            rst_n       : in std_logic;
            ce_n        : in std_logic;
            we_n        : in std_logic;
            d           : in std_logic_vector(dsize - 1 downto 0);
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


--------- screen constant -----------
constant VGA_W          : integer := 640;
constant VGA_H          : integer := 480;
constant VGA_W_MAX      : integer := 800;
constant VGA_H_MAX      : integer := 525;
constant H_SP           : integer := 95;
constant H_BP           : integer := 48;
constant H_FP           : integer := 15;
constant V_SP           : integer := 2;
constant V_BP           : integer := 33;
constant V_FP           : integer := 10;

constant NES_W          : integer := 256;
constant NES_H          : integer := 240;


--------- signal declaration -----------
signal vga_x        : std_logic_vector (9 downto 0);
signal vga_y        : std_logic_vector (9 downto 0);
signal x_res_n      : std_logic;
signal y_res_n      : std_logic;
signal y_en_n       : std_logic;

signal cnt_clk      : std_logic;

signal count5_res_n  : std_logic;
signal count5        : std_logic_vector(2 downto 0);
signal nes_x_en_n    : std_logic;
signal nes_x         : std_logic_vector(7 downto 0);

signal nes_x_we_n       : std_logic;
signal nes_x_old        : std_logic_vector(7 downto 0);

---DE1 base clock 50 MHz
---motones sim project uses following clock.
--cpu clock = base clock / 24 = 2.08 MHz (480 ns / cycle)
--ppu clock = base clock / 8
--vga clock = base clock / 2
--sdram clock = 135 MHz

begin

    cnt_clk <= not vga_clk;
    x_inst : counter_register generic map (10, 1)
            port map (cnt_clk , x_res_n, '0', '1', (others => '0'), vga_x);

    nes_x_old_inst: d_flip_flop generic map (8)
        port map (cnt_clk, rst_n, '1', nes_x_we_n, nes_x, nes_x_old);
        
    y_inst : counter_register generic map (10, 1)
            port map (cnt_clk , y_res_n, y_en_n, '1', (others => '0'), vga_y);

    count5_inst : counter_register generic map (3, 1)
            port map (cnt_clk, count5_res_n, '0', '1', (others => '0'), count5);

    nes_x_inst : counter_register generic map (8, 1)
            port map (vga_clk, x_res_n, nes_x_en_n, '1', (others => '0'), nes_x);
            
    dram_latch_p : process (rst_n, vga_clk)
    begin
        if (rst_n = '0') then
            nes_x_en_n <= '1';
            
        elsif (falling_edge(vga_clk)) then

            if (count5 = "001" or count5 = "011") then
                nes_x_en_n <= '0';
            else
                nes_x_en_n <= '1';
            end if;
        end if;
    end process;

    vga_out_p : process (rst_n, vga_clk)
    begin
        if (rst_n = '0') then
            h_sync_n <= '0';
            v_sync_n <= '0';
            x_res_n <= '0';
            y_res_n <= '0';
            count5_res_n <= '0';
            
            r<=(others => '0');
            g<=(others => '0');
            b<=(others => '0');
            
        elsif (rising_edge(vga_clk)) then
            --xmax = 799
            if (vga_x = conv_std_logic_vector(VGA_W_MAX, 10)) then
                x_res_n <= '0';
                y_en_n <= '0';
                --ymax=524
                if (vga_y = conv_std_logic_vector(VGA_H_MAX, 10)) then
                    y_res_n <= '0';
                else
                    y_res_n <= '1';
                end if;
            else
                x_res_n <= '1';
                y_en_n <= '1';
                y_res_n <= '1';
            end if;
            
            --sync signal assert.
            if (vga_x >= conv_std_logic_vector((VGA_W + H_FP) , 10) and 
                vga_x < conv_std_logic_vector((VGA_W + H_FP + H_SP) , 10)) then
                h_sync_n <= '0';
            else
                h_sync_n <= '1';
            end if;

            if (vga_y >= conv_std_logic_vector((VGA_H + V_FP) , 10) and 
                vga_y < conv_std_logic_vector((VGA_H + V_FP + V_SP) , 10)) then
                v_sync_n <= '0';
            else
                v_sync_n <= '1';
            end if;

            if (vga_y <=conv_std_logic_vector((VGA_H) , 10)) then
                if (vga_x < conv_std_logic_vector((VGA_W) , 10)) then
                    r<= "1111";
                    g<= "0000";
                    b<= "0000";
                else
                    r<=(others => '0');
                    g<=(others => '0');
                    b<=(others => '0');
                end if;
            else
                r<=(others => '0');
                g<=(others => '0');
                b<=(others => '0');
            end if;
            
            if (vga_x = conv_std_logic_vector(VGA_W_MAX, 10)) then
                count5_res_n <= '0';
            elsif (count5 = "100") then
                count5_res_n <= '0';
            else
                count5_res_n <= '1';
            end if;

        end if;
    end process;

end rtl;
