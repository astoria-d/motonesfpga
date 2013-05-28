
library IEEE;
use IEEE.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;


entity testbench_address_decoder is
end testbench_address_decoder;

architecture stimulus of testbench_address_decoder is 
    component address_decoder
    generic (abus_size : integer := 16; dbus_size : integer := 8);
        port (  phi2        : in std_logic;
                R_nW        : in std_logic; 
                addr       : in std_logic_vector (abus_size - 1 downto 0);
                d_io       : inout std_logic_vector (dbus_size - 1 downto 0)
    );
    end component;

    constant cpu_clk : time := 589 ns;
    constant size8 : integer := 8;
    constant size16 : integer := 16;

    signal cclk         : std_logic;
    signal phi2         : std_logic;
    signal rr_nw        : std_logic;
    signal aa16         : std_logic_vector (size16 - 1 downto 0);
    signal dd8_io       : std_logic_vector (size8 - 1 downto 0);
begin
    dut0 : address_decoder generic map (size16, size8) 
        port map (phi2, rr_nw, aa16, dd8_io);

    phi2 <= not cclk;

    p1 : process
    variable i : integer := 0;
    begin
        cclk <= '1';
        wait for cpu_clk / 2;
        cclk <= '0';
        wait for cpu_clk / 2;
    end process;

    p2 : process
    variable i : integer := 0;
    variable tmp : std_logic_vector (size8 - 1 downto 0);
    constant loopcnt : integer := 5;
    begin

        --syncronize with clock dropping edge.
        wait for cpu_clk;

        dd8_io <= (others => 'Z');

        for i in 0 to loopcnt loop
            dd8_io <= conv_std_logic_vector(i, size8);
            aa16 <= conv_std_logic_vector(i, size16);
            wait for cpu_clk;
        end loop;
        dd8_io <= (others => 'Z');

        ---read test.
        rr_nw <= '1';
        --ram at 0x0000
        aa16 <= x"0000";
        wait for cpu_clk;
        aa16 <= x"0010";
        wait for cpu_clk;

        --rom at 0x8000
        aa16 <= x"8000";
        wait for cpu_clk;
        aa16 <= x"8001";
        wait for cpu_clk;
        aa16 <= x"ffff";
        wait for cpu_clk;

        --unknown addr at 0x4000
        aa16 <= x"4000";
        wait for cpu_clk;
        aa16 <= x"0010";
        wait for cpu_clk;

        --write test
        rr_nw <= '0';
        for i in 0 to loopcnt loop
            --write to ram
            aa16 <= conv_std_logic_vector(i, size16);
            dd8_io <= conv_std_logic_vector(i, size8);
            wait for cpu_clk;
        end loop;

        dd8_io <= (others => 'Z');
        rr_nw <= '1';
        for i in 0 to loopcnt loop
            --read ram
            aa16 <= conv_std_logic_vector(i, size16);
            wait for cpu_clk;
        end loop;
        --wait;

        rr_nw <= '0';
        for i in 0 to loopcnt loop
            --write to rom
            aa16 <= conv_std_logic_vector(16#8000# + i, size16);
            dd8_io <= conv_std_logic_vector(i * 10, size8);
            wait for cpu_clk;
            aa16 <= conv_std_logic_vector(16#F000# + i, size16);
            dd8_io <= conv_std_logic_vector(i * 10, size8);
            wait for cpu_clk;
        end loop;

        rr_nw <= '1';
        dd8_io <= (others => 'Z');
        for i in 0 to loopcnt loop
            --read ram
            aa16 <= conv_std_logic_vector(16#8000# + i, size16);
            wait for cpu_clk;
            aa16 <= conv_std_logic_vector(16#F000# + i, size16);
            wait for cpu_clk;
        end loop;

        rr_nw <= '0';
        for i in 0 to loopcnt loop
            --write to rom
            aa16 <= conv_std_logic_vector(i, size16);
            dd8_io <= conv_std_logic_vector(i ** 2, size8);
            wait for cpu_clk;
        end loop;

        dd8_io <= "ZZZZZZZZ";
        rr_nw <= '1';
        --ram mirror test.
        for i in 0 to loopcnt loop
            --write to rom
            aa16 <= conv_std_logic_vector(16#0000# + i, size16);
            wait for cpu_clk;
            aa16 <= conv_std_logic_vector(16#0800# + i, size16);
            wait for cpu_clk;
            aa16 <= conv_std_logic_vector(16#1000# + i, size16);
            wait for cpu_clk;
            aa16 <= conv_std_logic_vector(16#1800# + i, size16);
            wait for cpu_clk;
            aa16 <= conv_std_logic_vector(16#2000# + i, size16);
            wait for cpu_clk;
            aa16 <= conv_std_logic_vector(16#4000# + i, size16);
            wait for cpu_clk;
            aa16 <= conv_std_logic_vector(16#8000# + i, size16);
            wait for cpu_clk;
        end loop;
        wait for cpu_clk;

        --write ram
        rr_nw <= '0';
        for i in 100 to 110 loop
            --write to ram
            aa16 <= conv_std_logic_vector(i, size16);
            dd8_io <= conv_std_logic_vector(i, size8);
            wait for cpu_clk;
        end loop;
        --read.
        rr_nw <= '1';
        dd8_io <= "ZZZZZZZZ";
        for i in 100 to 110 loop
            --write to ram
            aa16 <= conv_std_logic_vector(i, size16);
            wait for cpu_clk;
        end loop;

        dd8_io <= "ZZZZZZZZ";
        --read rom, ram, rom, ram ...
        rr_nw <= '1';
        aa16 <= conv_std_logic_vector(100, size16);
        wait for cpu_clk;
        aa16 <= conv_std_logic_vector(16#8010#, size16);
        wait for cpu_clk;
        aa16 <= conv_std_logic_vector(103, size16);
        wait for cpu_clk;
        aa16 <= conv_std_logic_vector(16#8013#, size16);
        wait for cpu_clk;
        aa16 <= conv_std_logic_vector(109, size16);
        wait for cpu_clk;
        aa16 <= conv_std_logic_vector(16#f0a3#, size16);
        wait for cpu_clk;

        --w,r,w,r,w,r,w...
        aa16 <= conv_std_logic_vector(100, size16);
        dd8_io <= conv_std_logic_vector(100, size8);
        rr_nw <= '0';
        wait for cpu_clk;
        dd8_io <= "ZZZZZZZZ";
        rr_nw <= '1';
        wait for cpu_clk;

        aa16 <= conv_std_logic_vector(101, size16);
        dd8_io <= conv_std_logic_vector(200, size8);
        rr_nw <= '0';
        wait for cpu_clk;
        dd8_io <= "ZZZZZZZZ";
        rr_nw <= '1';
        wait for cpu_clk;

        aa16 <= conv_std_logic_vector(401, size16); -- 401 = 0x191
        dd8_io <= conv_std_logic_vector(30, size8);
        rr_nw <= '0';
        wait for cpu_clk;
        rr_nw <= '1';
        dd8_io <= "ZZZZZZZZ";
        wait for cpu_clk;

        --copy rom > ram > rom > ram
        aa16 <= conv_std_logic_vector(16#f024#, size16);
        rr_nw <= '1';
        wait for cpu_clk;
        aa16 <= conv_std_logic_vector(500, size16);  -- 500 = 0x1f4
        tmp := dd8_io;
        dd8_io <= tmp;
        rr_nw <= '0';
        wait for cpu_clk;

        dd8_io <= "ZZZZZZZZ";
        aa16 <= conv_std_logic_vector(16#8003#, size16);
        rr_nw <= '1';
        wait for cpu_clk;
        aa16 <= conv_std_logic_vector(501, size16);
        dd8_io <= dd8_io;
        rr_nw <= '0';
        wait for cpu_clk;

        aa16 <= conv_std_logic_vector(16#8005#, size16);
        dd8_io <= "ZZZZZZZZ";
        rr_nw <= '1';
        wait for cpu_clk;
        aa16 <= conv_std_logic_vector(502, size16);
        dd8_io <= dd8_io;
        rr_nw <= '0';
        wait for cpu_clk;

        --read the written value
        rr_nw <= '1';
        dd8_io <= "ZZZZZZZZ";
        aa16 <= conv_std_logic_vector(500, size16);
        wait for cpu_clk;
        rr_nw <= '1';
        aa16 <= conv_std_logic_vector(501, size16);
        wait for cpu_clk;
        rr_nw <= '1';
        aa16 <= conv_std_logic_vector(502, size16);
        wait for cpu_clk;

        --copy rom to ram.
        for i in 0 to 50 loop
            dd8_io <= "ZZZZZZZZ";
            aa16 <= conv_std_logic_vector(16#8000# + i, size16);
            rr_nw <= '1';
            wait for cpu_clk;
            aa16 <= conv_std_logic_vector(1024 + i, size16);
            dd8_io <= dd8_io;
            rr_nw <= '0';
            wait for cpu_clk;
        end loop;
        --check the valude.
        dd8_io <= "ZZZZZZZZ";
        rr_nw <= '1';
        for i in 0 to 50 loop
            aa16 <= conv_std_logic_vector(1024 + i, size16);
            wait for cpu_clk;
        end loop;
        
        --copy ram to ram.
        --fill the value in the empty address.
        for i in 6 to 50 loop
            aa16 <= conv_std_logic_vector(i, size16);
            dd8_io <= conv_std_logic_vector(i**2, size8);
            rr_nw <= '0';
            wait for cpu_clk;
            rr_nw <= '1';
            wait for cpu_clk;
        end loop;
        for i in 0 to 50 loop
            dd8_io <= "ZZZZZZZZ";
            aa16 <= conv_std_logic_vector(i, size16);
            rr_nw <= '1';
            wait for cpu_clk;
            aa16 <= conv_std_logic_vector(2000 + i, size16);
            dd8_io <= dd8_io;
            rr_nw <= '0';
            wait for cpu_clk;
        end loop;
        --check the valude.
        dd8_io <= "ZZZZZZZZ";
        rr_nw <= '1';
        for i in 0 to 50 loop
            aa16 <= conv_std_logic_vector(2000 + i, size16);
            wait for cpu_clk;
        end loop;
        
        wait;
    end process;

end stimulus ;

