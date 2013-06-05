
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;


entity testbench_mos6502 is
end testbench_mos6502;

architecture stimulus of testbench_mos6502 is 
    component mos6502
        generic (   dsize : integer := 8;
                    asize : integer :=16
                );
        port (  input_clk   : in std_logic; --phi0 input pin.
                rdy         : in std_logic;
                rst_n       : in std_logic;
                irq_n       : in std_logic;
                nmi_n       : in std_logic;
                dbe         : in std_logic;
                r_nw        : out std_logic;
                phi1        : out std_logic;
                phi2        : out std_logic;
                addr        : out std_logic_vector ( asize - 1 downto 0);
                d_io        : inout std_logic_vector ( dsize - 1 downto 0)
        );
    end component;

    component address_decoder
    generic (abus_size : integer := 16; dbus_size : integer := 8);
        port (  phi2        : in std_logic;
                R_nW        : in std_logic; 
                addr       : in std_logic_vector (abus_size - 1 downto 0);
                d_io       : inout std_logic_vector (dbus_size - 1 downto 0)
    );
    end component;


    constant dsize : integer := 8;
    constant asize : integer := 16;
    constant cpu_clk : time := 589 ns;
    signal phi0 : std_logic;
    signal rdy, rst_n, irq_n, nmi_n, dbe, r_nw, phi1, phi2 : std_logic;
    signal addr : std_logic_vector( asize - 1 downto 0);
    signal cpu_d : std_logic_vector( dsize - 1 downto 0);

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
            decoder     : inout std_logic_vector (dsize - 1 downto 0);
            int_dbus    : inout std_logic_vector (dsize - 1 downto 0)
        );
    end component;
    signal we1 : std_logic;
    signal we2 : std_logic;
    signal oe1 : std_logic;
    signal oe2 : std_logic;
    signal dec : std_logic_vector( dsize - 1 downto 0);
    signal int_bus : std_logic_vector( dsize - 1 downto 0);

begin

    irq_n <= '0';
    nmi_n <= '0';
    rdy <= '1';
--    cpu_inst : mos6502 generic map (dsize, asize) 
--        port map (phi0, rdy, rst_n, irq_n, nmi_n, dbe, r_nw, 
--                phi1, phi2, addr, cpu_d);
--
--    addr_dec_inst : address_decoder generic map (asize, dsize) 
--        port map (phi2, r_nw, addr, cpu_d);

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
        port map (phi0, rst_n, we1, we2, oe1, oe2, dec, int_bus);

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
        oe2 <= '1';
        tmp := dec;
        int_bus (6 downto 4) <= tmp (6 downto 4);
        int_bus (2 downto 0) <= tmp (2 downto 0);
        int_bus (3) <= '1';
        int_bus (7) <= '0';
        wait for cpu_clk;
        we2 <= '0';
        oe2 <= '1';
        wait for cpu_clk;
        we2 <= '1';
        int_bus <= (others => 'Z');
        oe2 <= '0';
        wait for cpu_clk;

        ----clock edge slide half...
        wait for cpu_clk / 2;
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
        wait for cpu_clk;
        tmp := dec;
        oe1 <= '1';
        oe2 <= '1';
        int_bus (7) <= '1';
        int_bus (6) <= '0';
        int_bus (5 downto 0) <= tmp (5 downto 0);
        we2 <= '0';
        wait for cpu_clk;
        we2 <= '1';
        dec <= (others => 'Z');
        int_bus <= (others => 'Z');
        oe1 <= '0';
        oe2 <= '0';
        wait for 3 * cpu_clk;
        tmp := dec;
        oe1 <= '1';
        oe2 <= '1';
        dec (7) <= '1';
        dec (0) <= '1';
        dec (6 downto 1) <= tmp (6 downto 1);
        we1 <= '0';
        wait for cpu_clk;
        we1 <= '1';
        dec <= (others => 'Z');
        int_bus <= (others => 'Z');
        oe1 <= '0';
        oe2 <= '0';
        wait;
    end process;

end stimulus ;

