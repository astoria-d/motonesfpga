---------------------------------------------
---------------------------------------------
-------- synchronized clock selector --------
---------------------------------------------
---------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity clock_selector is 
    port (  
                pi_rst_n        : in std_logic;
                pi_base_clk     : in std_logic;
                po_cpu_en       : out std_logic_vector (7 downto 0);
                po_ppu_en       : out std_logic_vector (3 downto 0)
        );
end clock_selector;

architecture rtl of clock_selector is

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
    variable ref_cnt : integer range 0 to 31;
    begin
        if (pi_rst_n = '0') then
            reg_cpu_en <= (others => '0');
            ref_cnt := 0;
        else
            if (rising_edge(pi_base_clk)) then
                if (ref_cnt = 0) then
                    reg_cpu_en <= "00000001";
                elsif (ref_cnt = 4) then
                    reg_cpu_en <= "00000010";
                elsif (ref_cnt = 8) then
                    reg_cpu_en <= "00000100";
                elsif (ref_cnt = 12) then
                    reg_cpu_en <= "00001000";
                elsif (ref_cnt = 16) then
                    reg_cpu_en <= "00010000";
                elsif (ref_cnt = 20) then
                    reg_cpu_en <= "00100000";
                elsif (ref_cnt = 24) then
                    reg_cpu_en <= "01000000";
                elsif (ref_cnt = 28) then
                    reg_cpu_en <= "10000000";
                else
                    reg_cpu_en <= "00000000";
                end if;

                if (ref_cnt = 31) then
                    ref_cnt := 0;
                else
                    ref_cnt := ref_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    ppu_clk_p : process (pi_rst_n, pi_base_clk)
    variable ref_cnt : integer range 0 to 15;
    begin
        if (pi_rst_n = '0') then
            reg_ppu_en <= (others => '0');
            ref_cnt := 0;
        else
            if (rising_edge(pi_base_clk)) then
                if (ref_cnt = 0) then
                    reg_ppu_en <= "0001";
                elsif (ref_cnt = 4) then
                    reg_ppu_en <= "0010";
                elsif (ref_cnt = 8) then
                    reg_ppu_en <= "0100";
                elsif (ref_cnt = 12) then
                    reg_ppu_en <= "1000";
                else
                    reg_ppu_en <= "0000";
                end if;
                
                if (ref_cnt = 15) then
                    ref_cnt := 0;
                else
                    ref_cnt := ref_cnt + 1;
                end if;
            end if;
        end if;
    end process;

end rtl;


---------------------------------------------
---------------------------------------------
--------------- chip selector ---------------
---------------------------------------------
---------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity chip_selector is 
    port (
                pi_rst_n        : in std_logic;
                pi_base_clk    : in std_logic;
                pi_addr         : in std_logic_vector (15 downto 0);
                po_rom_ce_n     : out std_logic;
                po_ram_ce_n     : out std_logic;
                po_ppu_ce_n     : out std_logic;
                po_apu_ce_n     : out std_logic
        );
end chip_selector;

architecture rtl of chip_selector is

signal reg_rom_ce_n      : std_logic;
signal reg_ram_ce_n      : std_logic;
signal reg_ppu_ce_n      : std_logic;
signal reg_apu_ce_n      : std_logic;

begin
    po_rom_ce_n <= reg_rom_ce_n;
    po_ram_ce_n <= reg_ram_ce_n;
    po_ppu_ce_n <= reg_ppu_ce_n;
    po_apu_ce_n <= reg_apu_ce_n;

    chip_sel_p : process (pi_rst_n, pi_base_clk)
    begin
        if (pi_rst_n = '0') then
            reg_rom_ce_n <= '1';
            reg_ram_ce_n <= '1';
            reg_ppu_ce_n <= '1';
            reg_apu_ce_n <= '1';
        else
            if (rising_edge(pi_base_clk)) then
                if (pi_addr(15) = '1') then
                    reg_rom_ce_n <= '0';
                else
                    reg_rom_ce_n <= '1';
                end if;

                if (pi_addr(15) = '0' and pi_addr(14) = '0' and pi_addr(13) = '1') then
                    reg_ppu_ce_n <= '0';
                else
                    reg_ppu_ce_n <= '1';
                end if;

                if (pi_addr(15) = '0' and pi_addr(14) = '1' and pi_addr(13) = '0') then
                    reg_apu_ce_n <= '0';
                else
                    reg_apu_ce_n <= '1';
                end if;

                if ((pi_addr(15) or pi_addr(14) or pi_addr(13)) = '0') then
                    reg_ram_ce_n <= '0';
                else
                    reg_ram_ce_n <= '1';
                end if;
            end if;
        end if;
    end process;

end rtl;



---------------------------------------------
---------------------------------------------
------------ vram chip selector -------------
---------------------------------------------
---------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity v_chip_selector is 
    port (
                pi_rst_n        : in std_logic;
                pi_base_clk     : in std_logic;
                pi_v_addr       : in std_logic_vector (13 downto 0);
                pi_nt_v_mirror  : in std_logic;
                po_pt_ce_n      : out std_logic;
                po_nt0_ce_n     : out std_logic;
                po_nt1_ce_n     : out std_logic;
                po_plt_ce_n     : out std_logic
        );
end v_chip_selector;

architecture rtl of v_chip_selector is

signal reg_pt_ce_n       : std_logic;
signal reg_nt0_ce_n      : std_logic;
signal reg_nt1_ce_n      : std_logic;
signal reg_plt_ce_n      : std_logic;

begin
    po_pt_ce_n <= reg_pt_ce_n;
    po_nt0_ce_n <= reg_nt0_ce_n;
    po_nt1_ce_n <= reg_nt1_ce_n;
    po_plt_ce_n <= reg_plt_ce_n;

    v_chip_sel_p : process (pi_rst_n, pi_base_clk)
    begin
        if (pi_rst_n = '0') then
            reg_pt_ce_n <= '1';
            reg_nt0_ce_n <= '1';
            reg_nt1_ce_n <= '1';
            reg_plt_ce_n <= '1';
        else
            if (rising_edge(pi_base_clk)) then
                if ((pi_v_addr(13) = '0')) then
                    reg_pt_ce_n <= '0';
                else
                    reg_pt_ce_n <= '1';
                end if;

                if (pi_v_addr(13) = '0') then
                    reg_nt0_ce_n <= '1';
                elsif (pi_v_addr(13 downto 8) = "111111") then
                    reg_nt0_ce_n <= '1';
                elsif (((pi_v_addr(11) or pi_v_addr(10)) = '0') 
                        or (pi_nt_v_mirror = '1' and pi_v_addr(11) = '1' and pi_v_addr(10) = '0')
                        or (pi_nt_v_mirror = '0' and pi_v_addr(11) = '0' and pi_v_addr(10) = '1')) then
                    reg_nt0_ce_n <= '0';
                else
                    reg_nt0_ce_n <= '1';
                end if;

                if (pi_v_addr(13) = '0') then
                    reg_nt1_ce_n <= '1';
                elsif (pi_v_addr(13 downto 8) = "111111") then
                    reg_nt1_ce_n <= '1';
                elsif (((pi_v_addr(11) and pi_v_addr(10)) = '1') 
                    or (pi_nt_v_mirror = '1' and pi_v_addr(11) = '0' and pi_v_addr(10) = '1')
                    or (pi_nt_v_mirror = '0' and pi_v_addr(11) = '1' and pi_v_addr(10) = '0')) then
                    reg_nt1_ce_n <= '0';
                else
                    reg_nt1_ce_n <= '1';
                end if;

                if (pi_v_addr(13 downto 8) = "111111") then
                    reg_plt_ce_n <= '0';
                else
                    reg_plt_ce_n <= '1';
                end if;

            end if;
        end if;
    end process;

end rtl;
