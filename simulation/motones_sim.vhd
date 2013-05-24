library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;

--  
--   MOTO NES FPGA On GHDL Simulation Environment Virtual Cuicuit Board
--   All of the components are assembled and instanciated on this board.
--  

entity motones_sim is 
    port (  reset_n     : in std_logic
         );
end motones_sim;

architecture rtl of motones_sim is
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

    component clock_divider
        port (  base_clk    : in std_logic;
                reset_n     : in std_logic;
                cpu_clk     : out std_logic;
                ppu_clk     : out std_logic
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

    ---clock frequency = 21,477,270 (21 MHz)
    constant base_clock_time : time := 46 ns;

    signal base_clk : std_logic;
    signal cpu_clk, ppu_clk : std_logic;

    constant data_size : integer := 8;
    constant addr_size : integer := 16;

    signal rdy, irq_n, nmi_n, dbe, r_nw : std_logic;
    signal phi1, phi2 : std_logic;
    signal addr : std_logic_vector( addr_size - 1 downto 0);
    signal d_in : std_logic_vector( data_size - 1 downto 0);
    signal d_out : std_logic_vector( data_size - 1 downto 0);

begin

    clock_inst : clock_divider port map 
        (base_clk, reset_n, cpu_clk, ppu_clk);

    cpu_inst : mos6502 generic map (data_size, addr_size) 
        port map (cpu_clk, rdy, reset_n, irq_n, nmi_n, dbe, r_nw, 
                phi1, phi2, addr, d_in, d_out);

    addr_dec_inst : address_decoder generic map (addr_size, data_size) 
        port map (phi2, r_nw, addr, d_out, d_in);

    --- generate base clock.
    clock_p: process
    begin
        base_clk <= '1';
        wait for base_clock_time / 2;
        base_clk <= '0';
        wait for base_clock_time / 2;
    end process;


end rtl;

