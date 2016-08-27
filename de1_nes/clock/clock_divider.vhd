library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity clock_divider is 
    port (  base_clk    : in std_logic;
            reset_n     : in std_logic;
            cpu_clk     : out std_logic;
            ppu_clk     : out std_logic;
            emu_ppu_clk : out std_logic;
            vga_clk     : out std_logic;
            cpu_mem_clk     : out std_logic;
            cpu_recv_clk     : out std_logic;
            emu_ppu_mem_clk : out std_logic
        );
end clock_divider;

architecture rtl of clock_divider is

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

signal loop16 : std_logic_vector (3 downto 0);
signal cpu_mem_clk_wk   : std_logic;
signal cpu_dl_clk_wk   : std_logic;

constant CPU_MEM_DELAY  : time := 40 ns;

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
    --emu ppu clock = base clock / 4
    --mem clock = base clock

	vga_clk <= not loop16(0);
	emu_ppu_clk <= not loop16(1);
    ppu_clk <= not loop16(2);
    cpu_clk <= not loop16(3);
    
    clock_divider_inst : counter_register generic map (4) port map 
        (base_clk, reset_n, '0', '1', (others=>'0'), loop16);

    --delayed clock for cpu memory...
    --loop16(1) is emu ppu clock = 12.5 MHz (80ns) cycle.
    --cpu_mem_clk is delayed to cpu_clk by 80ns.
    delay_cpu_clk_p : process (loop16(1))
    begin
        if (reset_n = '0') then
            cpu_mem_clk_wk <= '0';
            cpu_dl_clk_wk <= '0';
        else
            if (falling_edge(loop16(1))) then
                cpu_dl_clk_wk <= not loop16(3);
                cpu_mem_clk_wk <= cpu_dl_clk_wk;
            end if;
        end if;
    end process;

    --one phase delayed clock for memory...
    cpu_mem_clk <= cpu_mem_clk_wk;
    --two phase delayed clock for cpu register...
    cpu_recv_clk <= not cpu_dl_clk_wk;

    delay_vram_clk_p : process (base_clk)
    begin
        if (reset_n = '0') then
            emu_ppu_mem_clk <= '0';
        else
            if (falling_edge(base_clk)) then
                emu_ppu_mem_clk <= not loop16(1);
            end if;
        end if;
    end process;


end rtl;

