library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity clock_divider is 
    port (  base_clk    : in std_logic;
            reset_n     : in std_logic;
            cpu_clk     : out std_logic;
            ppu_clk     : out std_logic
        );
end clock_divider;

architecture rtl of clock_divider is

constant cpu_division : integer := 12;
constant ppu_division : integer := 4;

signal loop4 : std_logic_vector (1 downto 0);
signal loop6 : std_logic_vector (2 downto 0);
signal tmp : std_logic;

begin

    ppu_clk <= not loop4(1);
    cpu_clk <= tmp;

    main_p : process (reset_n, base_clk)
    variable i : integer;
    begin
        if (reset_n'event) then
            if (reset_n = '0') then
                loop4 <= (others => '1');
                loop6 <= "101";
                tmp <= '0';
            end if;
        elsif (base_clk'event and base_clk = '1') then
            loop4 <= loop4 + '1';
            loop6 <= loop6 + '1';
            if (loop6 = "101") then
                loop6 <= (others => '0');
                tmp <= not tmp;
            end if;
        end if;
    end process;

end rtl;

