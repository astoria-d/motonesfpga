library ieee;
use ieee.std_logic_1164.all;

entity mos6502 is 
    port (  
            pi_rst_n       : in std_logic;
            pi_base_clk 	: in std_logic;
            pi_cpu_en       : in std_logic_vector (7 downto 0);
            pi_rdy         : in std_logic;
            pi_irq_n       : in std_logic;
            pi_nmi_n       : in std_logic;
            po_r_nw        : out std_logic;
            po_addr        : out std_logic_vector ( 15 downto 0);
            pio_d_io       : inout std_logic_vector ( 7 downto 0)
    );
end mos6502;

architecture rtl of mos6502 is

signal reg_r_nw     : std_logic;
signal reg_addr     : std_logic_vector ( 15 downto 0);
signal reg_d_in     : std_logic_vector ( 7 downto 0);
signal reg_d_out    : std_logic_vector ( 7 downto 0);

begin

    po_r_nw     <= reg_r_nw;
    po_addr     <= reg_addr;
    pio_d_io    <= reg_d_out;
    reg_d_in    <= pio_d_io;

end rtl;

