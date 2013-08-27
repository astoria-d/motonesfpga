library ieee;
use ieee.std_logic_1164.all;

entity apu is 
    port (  clk         : in std_logic;
            ce_n        : in std_logic;
            rst_n       : in std_logic;
            r_nw        : in std_logic;
            cpu_addr    : in std_logic_vector (2 downto 0);
            cpu_d       : inout std_logic_vector (7 downto 0);
            vram_ad     : inout std_logic_vector (7 downto 0);
            vram_a      : out std_logic_vector (13 downto 8)
    );
end apu;

architecture rtl of apu is


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

procedure d_print(msg : string) is
use std.textio.all;
use ieee.std_logic_textio.all;
variable out_l : line;
begin
    write(out_l, msg);
    writeline(output, out_l);
end  procedure;

constant dsize     : integer := 8;


signal clk_n            : std_logic;

signal oam_addr         : std_logic_vector (dsize - 1 downto 0);
signal oam_data         : std_logic_vector (dsize - 1 downto 0);

signal oam_bus_ce_n     : std_logic;

begin

    clk_n <= not clk;

--    ppu_clk_cnt_inst : counter_register generic map (2, 1)
--            port map (clk_n, ppu_clk_cnt_res_n, '0', '1', (others => '0'), ppu_clk_cnt); 
--
--    ppu_ctrl_inst : d_flip_flop generic map(dsize)
--            port map (clk_n, rst_n, '1', ppu_ctrl_we_n, cpu_d, ppu_ctrl);
--
    reg_set_p : process (rst_n, ce_n, r_nw, cpu_addr, cpu_d)
    begin

        if (rst_n = '1' and ce_n = '0') then

--            if(cpu_addr = PPUCTRL) then
--                ppu_ctrl_we_n <= '0';
--            else
--                ppu_ctrl_we_n <= '1';
--            end if;

        else
        end if; --if (rst_n = '1' and ce_n = '0') 

    end process;


end rtl;

