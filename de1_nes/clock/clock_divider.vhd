library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity clock_divider is 
    port (  base_clk    : in std_logic;
            reset_n     : in std_logic;
            cpu_clk     : out std_logic;
            ppu_clk     : out std_logic;
            mem_clk     : out std_logic;
            vga_clk     : out std_logic
        );
end clock_divider;

architecture rtl of clock_divider is

signal loop8 : std_logic_vector (2 downto 0);
signal loop24 : std_logic_vector (4 downto 0);
signal base_clk_n       : std_logic;
signal cpu_cnt_rst_n 	: std_logic;
signal cpu_we_n			: std_logic;
signal cpu_clk_new	 	: std_logic;
signal cpu_clk_old	 	: std_logic;

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
    --Actual NES base clock =  21.477272 MHz
    --CPU clock = base clock / 12
    --PPU clock = base clock / 4
    --Actual NES CPU clock = 1.78 MHz (559 ns / cycle)
    --VGA clock = 25 MHz.


	---DE1 base clock 50 MHz
    ---motones sim project uses following clock.
    --cpu clock = base clock / 24 = 2.08 MHz (480 ns / cycle)
    --ppu clock = base clock / 8
    --vga clock = base clock / 2
    --mem clock = base clock

    base_clk_n <= not base_clk;

	cpu_clk_old <= not cpu_clk_new;
	cpu_clk <= cpu_clk_new;

    ppu_clk <= loop8(2);
	vga_clk <= not loop8(0);
    mem_clk <= base_clk;
    
    cpu_we_n <= '0' when loop24 = "00011" else
                '0' when loop24 = "01111" else
                '1';
    ppu_clk_cnt : counter_register generic map (3) port map 
        (base_clk, reset_n, '0', '1', (others=>'0'), loop8);

    cpu_clk_cnt : counter_register generic map (5) port map 
        (base_clk_n, cpu_cnt_rst_n, '0', '1', (others=>'0'), loop24);

    cpu_clk_inst : d_flip_flop_bit port map 
        (base_clk, reset_n, '1', cpu_we_n, cpu_clk_old, cpu_clk_new);

    clock_p : process (base_clk)
    begin
        if (reset_n = '0') then
            cpu_cnt_rst_n <= '0';
        else
            if (base_clk'event and base_clk = '1') then
                if (loop24 = "10111") then
                    cpu_cnt_rst_n <= '0';
                else
                    cpu_cnt_rst_n <= '1';
                end if;
            end if;
        end if;
    end process;

end rtl;

