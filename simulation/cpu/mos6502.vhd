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

    component decoder
        generic (dsize : integer := 8);
        port (  set_clk         : in std_logic;
                trig_clk        : in std_logic;
                res_n           : in std_logic;
                irq_n           : in std_logic;
                nmi_n           : in std_logic;
                rdy             : in std_logic;
                instruction     : in std_logic_vector (dsize - 1 downto 0);
                status_reg      : in std_logic_vector (dsize - 1 downto 0);
                pcl_d_i_n       : out std_logic;
                pcl_d_o_n       : out std_logic;
                pcl_a_o_n       : out std_logic;
                r_nw            : out std_logic
            );
    end component;

    signal set_clk : std_logic;
    signal trigger_clk : std_logic;

    signal pc_d_in_n : std_logic;
    signal pc_d_out_n : std_logic;
    signal pc_a_out_n : std_logic;

    --internal bus (address hi/lo, data)
    signal internal_abus_h : std_logic_vector (dsize - 1 downto 0);
    signal internal_abus_l : std_logic_vector (dsize - 1 downto 0);
    signal internal_dbus : std_logic_vector (dsize - 1 downto 0);

    signal instruction : std_logic_vector (dsize - 1 downto 0);
    signal status_reg : std_logic_vector (dsize - 1 downto 0);
begin

    ---instances....
    pc_l : pc generic map (dsize) 
            port map(trigger_clk, pc_d_in_n, pc_d_out_n, pc_a_out_n, 
                    internal_dbus, internal_abus_l);

    dec_inst : decoder generic map (dsize) 
            port map(set_clk, trigger_clk, rst_n, irq_n, nmi_n, 
                    rdy, instruction, status_reg,
                    pc_d_in_n, pc_d_out_n, pc_a_out_n,
                    r_nw
                    );

    -- clock generate.
    phi1 <= input_clk;
    phi2 <= not input_clk;
    set_clk <= input_clk;
    trigger_clk <= not input_clk;

    reset_p : process (rst_n)
    begin
        if (rst_n'event and rst_n = '0') then
            internal_dbus <= "10000000"; --address 0x8000

        end if;
    end process;

end rtl;

