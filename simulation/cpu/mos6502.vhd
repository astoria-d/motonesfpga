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

    component cpu_reg
        generic (dsize : integer := 8);
        port (  clk, en     : in std_logic;
                d           : in std_logic_vector (dsize - 1 downto 0);
                q           : out std_logic_vector (dsize - 1 downto 0)
            );
    end component;

    signal trigger_clk : std_logic;
    signal pc_l_en : std_logic;
    signal internal_dbus : std_logic_vector (dsize - 1 downto 0);

begin

    pc_l : cpu_reg generic map (dsize) 
            port map(trigger_clk, pc_l_en, internal_dbus, internal_dbus);

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

