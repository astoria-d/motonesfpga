library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity chip_selector is 
    port (  
                pi_rst_n        : in std_logic;
                pi_base_clk     : in std_logic;
                po_cpu_en       : out std_logic_vector (7 downto 0);
                po_ppu_en       : out std_logic_vector (3 downto 0)
        );
end chip_selector;

architecture rtl of chip_selector is

signal reg_cpu_en       : std_logic_vector (7 downto 0);
signal reg_ppu_en       : std_logic_vector (3 downto 0);

begin
    --Actual NES base clock =  21.477272 MHz
    --CPU clock = base clock / 12
    --PPU clock = base clock / 4
    --Actual NES CPU clock = 1.78 MHz (559 ns / cycle)
    --VGA clock = 25 MHz.

	---DE1 base clock 50 MHz
    ---motones sim project uses following clock.
    --cpu clock = base clock / 16
    --ppu clock = base clock / 8
    --vga clock = base clock / 2
    --emu ppu clock = base clock / 4

    po_cpu_en <= reg_cpu_en;
    po_ppu_en <= reg_ppu_en;
    
    cpu_clk_p : process (pi_rst_n, pi_base_clk)
    variable ref_cnt : integer range 0 to 15;
    begin
        if (pi_rst_n = '0') then
            reg_cpu_en <= (others => '0');
            ref_cnt := 0;
        else
            if (rising_edge(pi_base_clk)) then
                if (ref_cnt = 0) then
                    reg_cpu_en <= "00000001";
                elsif (ref_cnt = 3) then
                    reg_cpu_en <= "00000010";
                elsif (ref_cnt = 7) then
                    reg_cpu_en <= "00000100";
                elsif (ref_cnt = 11) then
                    reg_cpu_en <= "00001000";
                elsif (ref_cnt = 15) then
                    reg_cpu_en <= "00010000";
                elsif (ref_cnt = 19) then
                    reg_cpu_en <= "00100000";
                elsif (ref_cnt = 23) then
                    reg_cpu_en <= "01000000";
                elsif (ref_cnt = 27) then
                    reg_cpu_en <= "10000000";
                end if;
                ref_cnt := ref_cnt + 1;
            end if;
        end if;
    end process;

    ppu_clk_p : process (pi_rst_n, pi_base_clk)
    variable ref_cnt : integer range 0 to 31;
    begin
        if (pi_rst_n = '0') then
            reg_ppu_en <= (others => '0');
            ref_cnt := 0;
        else
            if (rising_edge(pi_base_clk)) then
                if (ref_cnt = 0) then
                    reg_ppu_en <= "0001";
                elsif (ref_cnt = 3) then
                    reg_ppu_en <= "0010";
                elsif (ref_cnt = 7) then
                    reg_ppu_en <= "0100";
                elsif (ref_cnt = 11) then
                    reg_ppu_en <= "1000";
                end if;
                ref_cnt := ref_cnt + 1;
            end if;
        end if;
    end process;

end rtl;

