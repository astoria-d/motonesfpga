
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;
use std.textio.all;

entity testbench_ram is
end testbench_ram;

architecture stimulus of testbench_ram is 
    component ram
        generic (abus_size : integer := 16; dbus_size : integer := 8);
        port (  ce_n, oe_n, we_n  : in std_logic;   --select pin active low.
                addr            : in std_logic_vector (abus_size - 1 downto 0);
                d_in             : in std_logic_vector (dbus_size - 1 downto 0);
                d_out            : out std_logic_vector (dbus_size - 1 downto 0)
            );
    end component;
    constant cpu_clk : time := 589 ns;
    constant dsize : integer := 8;
    --constant asize : integer := 16#8000#;
    constant asize_2k : integer := 11;      --2k = 11 bit width.
    signal cce_n, ooe_n, wwe_n : std_logic;
    signal aa       : std_logic_vector (asize_2k - 1 downto 0);
    signal ddin         : std_logic_vector (dsize - 1 downto 0);
    signal ddout        : std_logic_vector (dsize - 1 downto 0);
    signal clk : std_logic;

begin
    dut0 : ram generic map (asize_2k, dsize) 
        port map (cce_n, ooe_n, wwe_n, aa, ddin, ddout);

    p : process
    variable i : integer := 0;
    constant loopcnt : integer := 5;
    variable out_line : line;
    begin

        cce_n <= '1';
        wait for cpu_clk;

        for i in 0 to loopcnt loop
            aa <= conv_std_logic_vector(i, asize_2k);
            ddin <= conv_std_logic_vector(i, dsize);
            wait for cpu_clk;
        end loop;

        cce_n <= '0';   --active low.

        for i in 0 to loopcnt loop
            aa <= conv_std_logic_vector(i, asize_2k);
            ddin <= conv_std_logic_vector(i, dsize);
            wait for cpu_clk;
        end loop;

        --write test.
        ooe_n <= '1';
        wwe_n <= '1';
        for i in 0 to loopcnt loop
            ddin <= conv_std_logic_vector(i, dsize);
            aa <= conv_std_logic_vector(i, asize_2k);
            wait for cpu_clk / 2;
            wwe_n <= '0';
            wait for cpu_clk / 2;
            wwe_n <= '1';
            --ddin <= (others => 'Z');
        end loop;

        --read check.
        wwe_n <= '1';
        ooe_n <= '0';

        for i in 0 to loopcnt loop
            aa <= conv_std_logic_vector(i, asize_2k);
            wait for cpu_clk;
        end loop;

        cce_n <= '1';   --disable check.

        for i in 0 to loopcnt loop
            aa <= conv_std_logic_vector(i, asize_2k);
            wait for cpu_clk;
        end loop;

        ------------------------ memroy r/w and boundary test.

        cce_n <= '0';

        write(out_line, string'("mem test1"));
        writeline(output, out_line);
        wwe_n <= '1';
        ooe_n <= '1';
        aa <= conv_std_logic_vector(2**(asize_2k - 1), asize_2k);
        ddin <= x"5a";
        wait for cpu_clk / 2;
        wwe_n <= '0';
        wait for cpu_clk / 2;

        wwe_n <= '1';
        ooe_n <= '0';
        aa <= conv_std_logic_vector(2**(asize_2k - 1), asize_2k);
        wait for cpu_clk;
        assert (ddout = x"5a")
            report "mem r/w error." severity failure;

        write(out_line, string'("mem test2"));
        writeline(output, out_line);
        wwe_n <= '1';
        ooe_n <= '1';
        aa <= conv_std_logic_vector(2**asize_2k - 1, asize_2k);
        ddin <= x"aa";
        wait for cpu_clk / 2;
        wwe_n <= '0';
        wait for cpu_clk / 2;

        wwe_n <= '1';
        ooe_n <= '0';
        aa <= conv_std_logic_vector(2**asize_2k - 1, asize_2k);
        wait for cpu_clk;
        assert (ddout = x"aa")
            report "mem r/w error." severity failure;

        write(out_line, string'("mem test3"));
        writeline(output, out_line);
        wwe_n <= '1';
        ooe_n <= '1';
        -- address wrapped..
        aa <= conv_std_logic_vector(2**asize_2k, asize_2k);       
        ddin <= x"ff";
        wait for cpu_clk / 2;
        wwe_n <= '0';
        wait for cpu_clk / 2;

        wwe_n <= '1';
        ooe_n <= '0';
        aa <= conv_std_logic_vector(2**asize_2k, asize_2k);       
        wait for cpu_clk;
        assert (ddout = x"ff")
            report "mem test error." severity failure;

        write(out_line, string'("mem test4"));
        writeline(output, out_line);
        ooe_n <= '1';
        wwe_n <= '1';
        for i in 0 to 50 loop
            aa <= conv_std_logic_vector(100 + i * 2, asize_2k);
            ddin <= conv_std_logic_vector(i * 3, dsize);
            wait for cpu_clk / 2;
            wwe_n <= '0';
            wait for cpu_clk / 2;
            wwe_n <= '1';
        end loop;

        wwe_n <= '1';
        ooe_n <= '0';
        ddin <= (others => 'Z');
        for i in 0 to 50 loop
            aa <= conv_std_logic_vector(100 + i * 2, asize_2k);
            wait for cpu_clk;
            assert (ddout = conv_std_logic_vector(i * 3, dsize))
                report "mem test error." severity failure;
        end loop;

        write(out_line, string'("test success."));
        writeline(output, out_line);
        cce_n <= '1';
        wait;
    end process;

    p_clk : process
    begin
        clk <= '1';
        wait for cpu_clk / 2;
        clk <= '0';
        wait for cpu_clk / 2;
    end process;
end stimulus ;

