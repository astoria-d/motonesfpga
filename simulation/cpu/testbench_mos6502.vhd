
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
                d_in        : in std_logic_vector ( dsize - 1 downto 0);
                d_out       : out std_logic_vector ( dsize - 1 downto 0)
        );
    end component;

    component address_decoder
    generic (abus_size : integer := 16; dbus_size : integer := 8);
        port (  phi2        : in std_logic;
                R_nW        : in std_logic; 
                addr       : in std_logic_vector (abus_size - 1 downto 0);
                d_in       : in std_logic_vector (dbus_size - 1 downto 0);
                d_out      : out std_logic_vector (dbus_size - 1 downto 0)
    );
    end component;

    constant dsize : integer := 8;
    constant asize : integer := 16;
    constant cpu_clk : time := 589 ns;
    signal phi0 : std_logic;
    signal rdy, rst_n, irq_n, nmi_n, dbe, r_nw, phi1, phi2 : std_logic;
    signal addr : std_logic_vector( asize - 1 downto 0);
    signal cpu_d_in : std_logic_vector( dsize - 1 downto 0);
    signal cpu_d_out : std_logic_vector( dsize - 1 downto 0);

begin

    cpu_inst : mos6502 generic map (dsize, asize) 
        port map (phi0, rdy, rst_n, irq_n, nmi_n, dbe, r_nw, 
                phi1, phi2, addr, cpu_d_in, cpu_d_out);

    addr_dec_inst : address_decoder generic map (asize, dsize) 
        port map (phi2, r_nw, addr, cpu_d_out, cpu_d_in);

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

end stimulus ;

