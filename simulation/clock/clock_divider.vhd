library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity clock_divider is 
    port (  base_clk    : in std_logic;
            reset_n     : in std_logic;
            cpu_clk     : out std_logic;
            ppu_clk     : out std_logic;
            vga_clk     : out std_logic
        );
end clock_divider;

architecture rtl of clock_divider is

signal loop2 : std_logic_vector (0 downto 0);
signal loop6 : std_logic_vector (2 downto 0);
signal cpu_cnt_rst_n 	: std_logic;
signal cpu_clk_new	 	: std_logic;
signal cpu_clk_old	 	: std_logic;
signal cpu_we_n			: std_logic;

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

component d_flip_flop_bit
    port (  
            clk     : in std_logic;
            res_n   : in std_logic;
            set_n   : in std_logic;
            we_n    : in std_logic;
            d       : in std_logic;
            q       : out std_logic
        );
end component;

begin
	---base clock 25 MHz = VGA clock.
	cpu_clk_old <= not cpu_clk_new;
	cpu_clk <= cpu_clk_new;
    ppu_clk <= loop2(0);
	vga_clk <= base_clk;

	cpu_cnt_rst_n <= '0' when reset_n = '0' else
					 '0' when loop6 = "110" else
					 '1';
	cpu_we_n <= '0' when loop6 = "101" else
				 '1';

    ppu_clk_cnt : counter_register generic map (1) port map 
        (base_clk, reset_n, '0', '1', (others=>'0'), loop2);

	cpu_clk_cnt : counter_register generic map (3) port map 
        (base_clk, cpu_cnt_rst_n, '0', '1', (others=>'0'), loop6);

    cpu_clk_cnt2 : d_flip_flop_bit port map 
        (base_clk, reset_n, '1', cpu_we_n, cpu_clk_old, cpu_clk_new);

end rtl;

