library ieee;
use ieee.std_logic_1164.all;

entity mos6502 is 
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
end mos6502;

architecture rtl of mos6502 is

    component pc
        generic (dsize : integer := 8);
        port (  trig_clk    : in std_logic;
                dbus_in_n       : in std_logic;
                dbus_out_n      : in std_logic;
                abus_out_n      : in std_logic;
                int_d_bus       : inout std_logic_vector (dsize - 1 downto 0);
                int_a_bus       : out std_logic_vector (dsize - 1 downto 0)
            );
    end component;

    signal trigger_clk : std_logic;
    signal pc_d_in_n : std_logic;
    signal pc_d_out_n : std_logic;
    signal pc_a_out_n : std_logic;

    signal internal_abus_h : std_logic_vector (dsize - 1 downto 0);
    signal internal_abus_l : std_logic_vector (dsize - 1 downto 0);
    signal internal_dbus : std_logic_vector (dsize - 1 downto 0);

begin

    pc_l : pc generic map (dsize) 
            port map(trigger_clk, pc_d_in_n, pc_d_out_n, pc_a_out_n, 
                    internal_dbus, internal_abus_l);

    -- clock generate.
    phi1 <= input_clk;
    phi2 <= not input_clk;
    trigger_clk <= not input_clk;

    reset_p : process (rst_n)
    begin
        if (rst_n'event and rst_n = '0') then

        end if;
    end process;

end rtl;

