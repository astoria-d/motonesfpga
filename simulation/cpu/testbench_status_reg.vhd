
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;


entity testbench_status_reg is
end testbench_status_reg;

architecture stimulus of testbench_status_reg is 
    constant dsize : integer := 8;
    constant asize : integer := 16;
    constant cpu_clk : time := 589 ns;
    signal phi0 : std_logic;
    signal rst_n : std_logic;

    --status reg test.
    component processor_status 
    generic (
            dsize : integer := 8
            );
    port (  
            clk         : in std_logic;
            res_n       : in std_logic;
            dec_we_n    : in std_logic;
            bus_we_n    : in std_logic;
            dec_oe_n    : in std_logic;
            bus_oe_n    : in std_logic;
            alu_c       : in std_logic;
            alu_v       : in std_logic;
            decoder     : inout std_logic_vector (dsize - 1 downto 0);
            int_dbus    : inout std_logic_vector (dsize - 1 downto 0)
        );
    end component;
    signal we1 : std_logic;
    signal we2 : std_logic;
    signal oe1 : std_logic;
    signal oe2 : std_logic;
    signal alu_c, alu_v : std_logic;
    signal dec : std_logic_vector( dsize - 1 downto 0);
    signal int_bus : std_logic_vector( dsize - 1 downto 0);

begin

    reset_p : process
    begin
        wait for 1 us;
        rst_n <= '0';
        wait for 1 us;
        rst_n <= '1';
        wait;
    end process;

    clock_p : process
    begin
        phi0 <= '1';
        wait for cpu_clk / 2;
        phi0 <= '0';
        wait for cpu_clk / 2;
    end process;

    status_inst : processor_status generic map (dsize) 
        port map (phi0, rst_n, we1, we2, oe1, oe2, alu_c, alu_v, dec, int_bus);

    status_test_p : process
    variable tmp : std_logic_vector(dsize -1 downto 0);
    begin
        wait for 5 * cpu_clk;
        we1 <= '1';
        we2 <= '1';
        --when setting oe=0, must clear old val.
        dec <= (others => 'Z');
        oe1 <= '0';
        oe2 <= '1';
        wait for cpu_clk;
        int_bus <= (others => 'Z');
        oe2 <= '0';
        wait for 3 * cpu_clk;
        tmp := dec;
        oe1 <= '1';
        dec (5 downto 0) <= tmp (5 downto 0);
        dec(7) <= '1';
        dec(6) <= '1';
        wait for cpu_clk;
        we1 <= '0';
        oe1 <= '1';
        wait for cpu_clk;
        we1 <= '1';
        dec <= (others => 'Z');
        oe1 <= '0';
        wait for cpu_clk;
        tmp := dec;
        oe1 <= '1';
        dec (7 downto 2) <= tmp (7 downto 2);
        dec (0) <= tmp (0);
        dec(1) <= '1';
        wait for cpu_clk;
        we1 <= '0';
        oe1 <= '1';
        wait for cpu_clk;
        we1 <= '1';
        dec <= (others => 'Z');
        oe1 <= '0';
        wait for cpu_clk;
--        oe2 <= '1';
--        tmp := dec;
--        int_bus (6 downto 4) <= tmp (6 downto 4);
--        int_bus (2 downto 0) <= tmp (2 downto 0);
--        int_bus (3) <= '1';
--        int_bus (7) <= '0';
--        wait for cpu_clk;
--        we2 <= '0';
--        oe2 <= '1';
--        wait for cpu_clk;
--        we2 <= '1';
--        int_bus <= (others => 'Z');
--        oe2 <= '0';
--        wait for cpu_clk;


        ----clock edge slide half...
        wait for cpu_clk / 2;
        oe1 <= '1';
        oe2 <= '1';
        int_bus <= (others => 'Z');
        dec <= (others => 'Z');
        

        wait for 5 * cpu_clk;

        dec <= "00000000";
        we1 <= '0';
        wait for cpu_clk;
        we1 <= '1';

        wait for cpu_clk;
        tmp := dec;
        oe1 <= '1';
        oe2 <= '1';
        dec (7 downto 4) <= tmp (7 downto 4);
        dec (2 downto 0) <= tmp (2 downto 0);
        dec(3) <= '0';
        we1 <= '0';
        wait for cpu_clk;
        we1 <= '1';
        dec <= (others => 'Z');
        int_bus <= (others => 'Z');
        oe1 <= '0';
        oe2 <= '0';



        --flag set test from the data bus.
        wait for cpu_clk;
        oe1 <= '1';
        oe2 <= '1';
        --set negative and zero.
        dec(7 downto 0) <= "10000010";
        int_bus <= "11111111";
        we2 <= '0';
        wait for cpu_clk;
        we2 <= '1';

        wait for cpu_clk;
        --set negative and zero.
        dec(7 downto 0) <= "10000010";
        int_bus <= "00000000";
        we2 <= '0';
        wait for cpu_clk;
        we2 <= '1';

        wait for cpu_clk;
        --set negative and zero.
        dec(7 downto 0) <= "10000010";
        int_bus <= conv_std_logic_vector(16#3a#, dsize);
        we2 <= '0';
        wait for cpu_clk;
        we2 <= '1';

        wait for cpu_clk;
        --set negative and zero.
        dec(7 downto 0) <= "10000010";
        int_bus <= conv_std_logic_vector(16#e9#, dsize);
        we2 <= '0';
        wait for cpu_clk;
        we2 <= '1';

        wait for cpu_clk;
        --set negative, zero overflow and carry.
        dec(7 downto 0) <= "11000011";
        alu_c <= '1';
        alu_v <= '0';
        int_bus <= conv_std_logic_vector(16#a3#, dsize);
        we2 <= '0';
        wait for cpu_clk;
        we2 <= '1';

        wait for cpu_clk;
        --set negative, zero overflow and carry.
        dec(7 downto 0) <= "11000011";
        alu_c <= '1';
        alu_v <= '1';
        int_bus <= conv_std_logic_vector(16#00#, dsize);
        we2 <= '0';
        wait for cpu_clk;
        we2 <= '1';

        wait for cpu_clk;
        --set negative, carry.
        dec(7 downto 0) <= "10000001";
        alu_c <= '0';
        alu_v <= '0';
        int_bus <= conv_std_logic_vector(16#b2#, dsize);
        we2 <= '0';
        wait for cpu_clk;
        we2 <= '1';

        wait for cpu_clk;
        --push all
        dec(7 downto 0) <= "11111111";
        alu_c <= '0';
        alu_v <= '0';
        int_bus <= "10000010";
        we2 <= '0';
        wait for cpu_clk;
        we2 <= '1';

        wait for cpu_clk;
        --set flag from decoder.
        dec <= (others => 'Z');
        oe1 <= '0';
        --tmp := dec;
        --interrupt disable.
        wait for cpu_clk;
        oe1 <= '1';
        dec (7 downto 3) <= dec (7 downto 3);
        dec (1 downto 0) <= dec (1 downto 0);
        dec(2) <= '1';
        we1 <= '0';
        wait for cpu_clk;
        we1 <= '1';

        wait;

    end process;

end stimulus ;

