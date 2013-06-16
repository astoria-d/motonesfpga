
----------------------------------------
--- d-flipflop with set/reset
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity d_flip_flop is 
    generic (
            dsize : integer := 8
            );
    port (  
            clk     : in std_logic;
            res_n   : in std_logic;
            set_n   : in std_logic;
            we_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end d_flip_flop;

architecture rtl of d_flip_flop is
begin

    process (clk, res_n, set_n)
    begin
        if (res_n = '0') then
            q <= (others => '0');
        elsif (clk'event and clk = '1' and set_n = '0') then
            q <= d;
        elsif (clk'event and clk = '1') then
            if (we_n = '0') then
                q <= d;
            end if;
        end if;
    end process;
end rtl;

----------------------------------------
--- data latch declaration
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity latch is 
    generic (
            dsize : integer := 8
            );
    port (  
            clk     : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end latch;

architecture rtl of latch is
begin

    process (clk, d)
    begin
        if ( clk = '1') then
            --latch only when clock is high
            q <= d;
        end if;
    end process;
end rtl;

----------------------------------------
--- tri-state buffer
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity tri_state_buffer is 
    generic (
            dsize : integer := 8
            );
    port (  
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end tri_state_buffer;

architecture rtl of tri_state_buffer is
begin
    q <= d when oe_n = '0' else
        (others => 'Z');
end rtl;


----------------------------------------
--- dual port d flip flop w/ tri-state buffer
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity dual_dff is 
    generic (
            dsize : integer := 8
            );
    port (  
            clk             : in std_logic;
            res_n           : in std_logic;
            set_n           : in std_logic;
            gate_cmd        : in std_logic_vector (3 downto 0);
            front_port      : inout std_logic_vector (dsize - 1 downto 0);
            back_in_port    : in std_logic_vector (dsize - 1 downto 0);
            back_out_port   : out std_logic_vector (dsize - 1 downto 0)
        );
end dual_dff;

architecture rtl of dual_dff is

component d_flip_flop
    generic (
            dsize : integer := 8
            );
    port (  
            clk     : in std_logic;
            res_n   : in std_logic;
            set_n   : in std_logic;
            we_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;

component tri_state_buffer
    generic (
            dsize : integer := 8
            );
    port (  
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;

signal we_n : std_logic;
signal q : std_logic_vector (dsize - 1 downto 0);
signal d : std_logic_vector (dsize - 1 downto 0);

begin
    ----------gate_cmd format 
    ------3 : front port oe_n
    ------2 : front port we_n
    ------1 : back port oe_n
    ------0 : back port we_n
    we_n <= (gate_cmd(2) and gate_cmd(0));

    d <= front_port when gate_cmd(2) = '0' else
         back_in_port when gate_cmd(0) = '0' else
         (others => 'Z');

    dff_inst : d_flip_flop generic map (dsize) 
                    port map(clk, res_n, set_n, we_n, d, q);

    front_tsb : tri_state_buffer generic map (dsize) 
                    port map(gate_cmd(3), q, front_port);

    back_tsb : tri_state_buffer generic map (dsize) 
                    port map(gate_cmd(1), q, back_out_port);
end rtl;


-----------------

----------------------------------------
--- data bus buffer
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity data_bus_buffer is 
    generic (
            dsize : integer := 8
            );
    port (  
            clk         : in std_logic;
            r_nw        : in std_logic;
            int_oe_n    : in std_logic;
            int_dbus : inout std_logic_vector (dsize - 1 downto 0);
            ext_dbus : inout std_logic_vector (dsize - 1 downto 0)
        );
end data_bus_buffer;

architecture rtl of data_bus_buffer is
component latch
    generic (
            dsize : integer := 8
            );
    port (  
            clk     : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;

component tri_state_buffer
    generic (
            dsize : integer := 8
            );
    port (  
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;

signal rd_clk : std_logic;
signal wr_clk : std_logic;
signal read_buf : std_logic_vector (dsize - 1 downto 0);
signal write_buf : std_logic_vector (dsize - 1 downto 0);
begin
    rd_clk <= r_nw and clk;
    wr_clk <= (not r_nw) and clk;

    --read from i/o to cpu
    latch_r : latch generic map (dsize) 
                    port map(rd_clk, ext_dbus, read_buf);
    read_tsb : tri_state_buffer generic map (dsize) 
                    port map(int_oe_n, read_buf, int_dbus);
    --write from cpu to io
    latch_w : latch generic map (dsize) 
                    port map(wr_clk, int_dbus, write_buf);
    write_tsb : tri_state_buffer generic map (dsize) 
                    port map(r_nw, write_buf, ext_dbus);
end rtl;

------------------------------------------
----- input data latch register
------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity input_data_latch is 
    generic (
            dsize : integer := 8
            );
    port (  
            clk         : in std_logic;
            oe_n        : in std_logic;
            we_n        : in std_logic;
            int_dbus    : in std_logic_vector (dsize - 1 downto 0);
            alu_bus     : out std_logic_vector (dsize - 1 downto 0)
        );
end input_data_latch;

architecture rtl of input_data_latch is

component latch
    generic (
            dsize : integer := 8
            );
    port (  
            clk     : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;

component tri_state_buffer
    generic (
            dsize : integer := 8
            );
    port (  
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;

signal latch_clk : std_logic;
signal latch_buf : std_logic_vector (dsize - 1 downto 0);

begin
    latch_clk <= (not we_n) and clk;
    latch_inst : latch generic map (dsize) 
                    port map(latch_clk, int_dbus, latch_buf);
    iput_data_tsb : tri_state_buffer generic map (dsize) 
                    port map(oe_n, latch_buf, alu_bus);

end rtl;


