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
            dbg_out_port    : out std_logic_vector (dsize - 1 downto 0);

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

    dbg_out_port <= q;
end rtl;


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
            int_oe_n    : in std_logic;
            ext_oe_n    : in std_logic;
            int_dbus : inout std_logic_vector (dsize - 1 downto 0);
            ext_dbus : inout std_logic_vector (dsize - 1 downto 0)
        );
end data_bus_buffer;

architecture rtl of data_bus_buffer is

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

begin
    --read from i/o to cpu
    read_tsb : tri_state_buffer generic map (dsize) 
                    port map(int_oe_n, ext_dbus, int_dbus);
    --write from cpu to io
    write_tsb : tri_state_buffer generic map (dsize) 
                    port map(ext_oe_n, int_dbus, ext_dbus);
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
    signal dbg_idl_val     : out std_logic_vector (7 downto 0);
    
            clk         : in std_logic;
            oe_n        : in std_logic;
            we_n        : in std_logic;
            int_dbus    : in std_logic_vector (dsize - 1 downto 0);
            alu_bus     : out std_logic_vector (dsize - 1 downto 0)
        );
end input_data_latch;

architecture rtl of input_data_latch is

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

signal latch_buf : std_logic_vector (dsize - 1 downto 0);

begin
    latch_inst : d_flip_flop generic map (dsize) 
                    port map(clk, '1', '1', we_n, int_dbus, latch_buf);
    iput_data_tsb : tri_state_buffer generic map (dsize) 
                    port map(oe_n, latch_buf, alu_bus);

end rtl;

----------------------------------------
--- status register component
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity processor_status is 
    generic (
            dsize : integer := 8
            );
    port (  
    signal dbg_dec_oe_n    : out std_logic;
    signal dbg_dec_val     : out std_logic_vector (7 downto 0);
    signal dbg_int_dbus    : out std_logic_vector (7 downto 0);
--    signal dbg_status_val    : out std_logic_vector (7 downto 0);
    signal dbg_stat_we_n    : out std_logic;

    
            clk         : in std_logic;
            res_n       : in std_logic;
            dec_oe_n    : in std_logic;
            bus_oe_n    : in std_logic;
            set_flg_n   : in std_logic;
            flg_val     : in std_logic;
            load_bus_all_n      : in std_logic;
            load_bus_nz_n       : in std_logic;
            set_from_alu_n      : in std_logic;
            alu_n       : in std_logic;
            alu_v       : in std_logic;
            alu_z       : in std_logic;
            alu_c       : in std_logic;
            stat_c      : out std_logic;
            dec_val     : inout std_logic_vector (dsize - 1 downto 0);
            int_dbus    : inout std_logic_vector (dsize - 1 downto 0)
        );
end processor_status;

architecture rtl of processor_status is

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
signal d : std_logic_vector (dsize - 1 downto 0);
signal d2 : std_logic_vector (dsize - 1 downto 0);
signal status_val : std_logic_vector (dsize - 1 downto 0);

begin
    dec_tsb : tri_state_buffer generic map (dsize) 
                    port map(dec_oe_n, status_val, dec_val);
    dbus_tsb : tri_state_buffer generic map (dsize) 
                    port map(bus_oe_n, status_val, int_dbus);

    we_n <= set_flg_n and load_bus_all_n and 
                load_bus_nz_n and set_from_alu_n;

    ---status val: researved bit always 1, decimal bit always 0.        
    d2 <= d(7 downto 6) & "1" & d(4) & "0" & d(2 downto 0);
    dff_inst : d_flip_flop generic map (dsize) 
                    port map(clk, '1', res_n, we_n, d2, status_val);

    --carry status for adc/sbc.
    stat_c <= status_val(0);

    dbg_dec_oe_n    <= dec_oe_n    ;
    --dbg_dec_val     <= dec_val     ;
    --dbg_int_dbus    <= int_dbus    ;
    --dbg_status_val <= status_val;
    dbg_stat_we_n <= we_n;

    main_p : process (clk, res_n, we_n, dec_val, int_dbus, 
                            alu_n, alu_v, alu_z, alu_c)
    variable tmp : std_logic_vector (dsize - 1 downto 0);
    begin
--        SR Flags (bit 7 to bit 0):
--
--        N   ....    Negative
--        V   ....    Overflow
--        -   ....    ignored   -- always 1 for NES 6502
--        B   ....    Break
--        D   ....    Decimal (use BCD for arithmetics)     -- not supported. always 0.
--        I   ....    Interrupt (IRQ disable)
--        Z   ....    Zero
--        C   ....    Carry
    
      ---only interrupt flag is set on reset.
        if (res_n = '0') then
            d <= "00000100";
        else
            d <= (others => 'Z');
        end if;

        ---from flag set/clear instructions
        if (set_flg_n = '0') then
            if flg_val = '1' then
                tmp := (dec_val and "11111111");
            else
                tmp := "00000000";
            end if;
            d <= tmp or (status_val and not dec_val);

        ---status flag set from the data on the internal data bus.
        ---interpret the input data by the dec_val input.
        ---load/pop/rti/t[asxy]
        elsif (load_bus_all_n = '0') then
            ---set the data bus data as they are.
            d <= int_dbus;
        elsif (load_bus_nz_n = '0') then
            tmp := status_val;
            d (6 downto 2) <= tmp (6 downto 2);
            d (0) <= tmp (0);

            ---other case: n/z data must be interpreted.
            --n bit.
            if int_dbus(7) = '1' then
                d (7) <= '1';
            else
                d (7) <= '0';
            end if;
            --z bit.
            ---nor outputs 1 when all inputs are 0.
            if  (int_dbus(7) or int_dbus(6) or 
                    int_dbus(5) or int_dbus(4) or int_dbus(3) or 
                    int_dbus(2) or int_dbus(1) or int_dbus(0)) = '0' then
                d (1) <= '1';
            else
                d (1) <= '0';
            end if;

        ---status set from alu
        elsif (set_from_alu_n = '0') then
            tmp := status_val;
            d (5 downto 2) <= tmp (5 downto 2);

            --n bit.
            if (dec_val(7) = '1') then
                d (7) <= alu_n;
            else
                d (7) <= tmp (7);
            end if;
            --v bit.
            if (dec_val(6) = '1') then
                d (6) <= alu_v;
            else
                d (6) <= tmp (6);
            end if;
            --z bit.
            if (dec_val(1) = '1') then
                d (1) <= alu_z;
            else
                d (1) <= tmp (1);
            end if;
            --c bit.
            if (dec_val(0) = '1') then
                d (0) <= alu_c;
            else
                d (0) <= tmp (0);
            end if;
        end if; --if (set_flg_n = '0') then
    end process;
end rtl;


