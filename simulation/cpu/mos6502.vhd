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
            d_io        : inout std_logic_vector ( dsize - 1 downto 0)
    );
end mos6502;

architecture rtl of mos6502 is

    ----------------------------------------------
    ------------ decoder declaration -------------
    ----------------------------------------------
component decoder
    generic (dsize : integer := 8);
    port (  set_clk         : in std_logic;
            trig_clk        : in std_logic;
            res_n           : in std_logic;
            irq_n           : in std_logic;
            nmi_n           : in std_logic;
            rdy             : in std_logic;
            instruction     : in std_logic_vector (dsize - 1 downto 0);
            exec_cycle      : in std_logic_vector (5 downto 0);
            next_cycle      : out std_logic_vector (5 downto 0);
            status_reg      : inout std_logic_vector (dsize - 1 downto 0);
            inst_we_n       : out std_logic;
            ad_oe_n         : out std_logic;
            pcl_cmd         : out std_logic_vector(3 downto 0);
            pch_cmd         : out std_logic_vector(3 downto 0);
            sp_cmd          : out std_logic_vector(3 downto 0);
            acc_cmd         : out std_logic_vector(3 downto 0);
            x_cmd           : out std_logic_vector(3 downto 0);
            y_cmd           : out std_logic_vector(3 downto 0);
            r_nw            : out std_logic
            ;---for parameter check purpose!!!
            check_bit     : out std_logic_vector(1 to 5)
        );
end component;

    ----------------------------------------------
    ------------ register declaration ------------
    ----------------------------------------------
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

component dual_dff
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
end component;

component data_bus_buffer
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
end component;

component input_data_latch
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

    ----------------------------------------------
    ------------ signal declareration ------------
    ----------------------------------------------
    signal set_clk : std_logic;
    signal trigger_clk : std_logic;

    signal exec_cycle : std_logic_vector(5 downto 0);
    signal next_cycle : std_logic_vector(5 downto 0);
    signal status_reg : std_logic_vector (dsize - 1 downto 0);

    -------------------------------
    -------- control lines --------
    -------------------------------
    signal inst_we_n : std_logic;
    signal ad_oe_n : std_logic;

    signal dbuf_r_nw : std_logic;
    signal dbuf_int_oe_n : std_logic;

    signal dl_al_we_n : std_logic;
    signal dl_ah_we_n : std_logic;
    signal dl_al_oe_n : std_logic;
    signal dl_ah_oe_n : std_logic;

    ----control line for dual port registers.
    signal pcl_cmd : std_logic_vector(3 downto 0);
    signal pch_cmd : std_logic_vector(3 downto 0);
    signal sp_cmd : std_logic_vector(3 downto 0);
    signal acc_cmd : std_logic_vector(3 downto 0);
    signal x_cmd : std_logic_vector(3 downto 0);
    signal y_cmd : std_logic_vector(3 downto 0);

    -------------------------------
    ------------ buses ------------
    -------------------------------
    signal instruction : std_logic_vector(dsize - 1 downto 0);
    
    signal alu_h : std_logic_vector(dsize - 1 downto 0);
    signal alu_l : std_logic_vector(dsize - 1 downto 0);
    signal index_bus : std_logic_vector(dsize - 1 downto 0);

    signal acc_in : std_logic_vector(dsize - 1 downto 0);
    signal acc_out : std_logic_vector(dsize - 1 downto 0);

    --not used bus.
    signal null_bus : std_logic_vector(dsize - 1 downto 0);

    --address bus
    signal abh : std_logic_vector(dsize - 1 downto 0);
    signal abl : std_logic_vector(dsize - 1 downto 0);

    ---internal data bus
    signal d_bus : std_logic_vector(dsize - 1 downto 0);

    signal check_bit     : std_logic_vector(1 to 5);

begin


    -- clock generate.
    phi1 <= input_clk;
    phi2 <= not input_clk;
    set_clk <= input_clk;
    trigger_clk <= not input_clk;
    r_nw <= dbuf_r_nw;


    --------------------------------------------------
    ------------------- instances --------------------
    --------------------------------------------------

    dec_inst : decoder generic map (dsize) 
            port map(set_clk, 
                    trigger_clk, 
                    rst_n, 
                    irq_n, 
                    nmi_n, 
                    rdy, 
                    instruction, 
                    exec_cycle,
                    next_cycle,
                    status_reg, 
                    inst_we_n, 
                    ad_oe_n, 
                    pcl_cmd,
                    pch_cmd,
                    sp_cmd,
                    acc_cmd,
                    x_cmd,
                    y_cmd,
                    dbuf_r_nw
                    , check_bit --check bit.
                    );

    --cpu execution cycle number
    exec_cycle_inst : d_flip_flop generic map (6) 
            port map(trigger_clk, '1', '1', '0', next_cycle, exec_cycle);

    --io data buffer
    dbus_buf : data_bus_buffer generic map (dsize) 
            port map(set_clk, dbuf_r_nw, dbuf_int_oe_n, d_bus, d_io);

    --address operand data buffer.
    idl_l : input_data_latch generic map (dsize) 
            port map(set_clk, dl_al_oe_n, dl_al_we_n, alu_l, d_bus);
    idl_h : input_data_latch generic map (dsize) 
            port map(set_clk, dl_ah_oe_n, dl_ah_we_n, alu_h, d_bus);

    -------- registers --------
    ir : d_flip_flop generic map (dsize) 
            port map(trigger_clk, '1', '1', inst_we_n, d_io, instruction);

    pc_l : dual_dff generic map (dsize) 
            port map(trigger_clk, '1', rst_n, pcl_cmd, d_bus, abl, alu_l);
    pc_h : dual_dff generic map (dsize) 
            port map(trigger_clk, '1', rst_n, pch_cmd, d_bus, abh, alu_h);

    sp : dual_dff generic map (dsize) 
            port map(trigger_clk, rst_n, '1', sp_cmd, d_bus, abl, alu_l);

    x : dual_dff generic map (dsize) 
            port map(trigger_clk, rst_n, '1', x_cmd, d_bus, null_bus, index_bus);
    y : dual_dff generic map (dsize) 
            port map(trigger_clk, rst_n, '1', y_cmd, d_bus, null_bus, index_bus);

    acc : dual_dff generic map (dsize) 
            port map(trigger_clk, rst_n, '1', acc_cmd, d_bus, acc_in, acc_out);

    ---temporarily...
    abl <= alu_l;
    abh <= alu_h;
    --adh output is controlled by decoder.
    adh_buf : tri_state_buffer generic map (dsize)
            port map (ad_oe_n, abh, addr(asize - 1 downto dsize));
    adl_buf : tri_state_buffer generic map (dsize)
            port map (ad_oe_n, abl, addr(dsize - 1 downto 0));

    null_bus <= (others => 'Z');


    reset_p : process (rst_n)
    begin
        if (rst_n = '0') then
            --reset vector set to pc.
            d_bus <= "10000000";
            abl <= "00000000";
        else
            d_bus <= (others => 'Z');
            abl <= (others => 'Z');
        end if;
    end process;


------------------------------------------------------------
------------------------ for debug... ----------------------
------------------------------------------------------------

    dbg_p : process (set_clk)
use std.textio.all;
use ieee.std_logic_textio.all;
use ieee.std_logic_unsigned.conv_integer;

procedure d_print(msg : string) is
variable out_l : line;
begin
    write(out_l, msg);
    writeline(output, out_l);
end  procedure;

function conv_hex8(ival : integer) return string is
variable tmp1, tmp2 : integer;
variable hex_chr: string (1 to 16) := "0123456789abcdef";
begin
    tmp2 := (ival mod 16 ** 2) / 16 ** 1;
    tmp1 := ival mod 16 ** 1;
    return hex_chr(tmp2 + 1) & hex_chr(tmp1 + 1);
end;
    begin
        if (set_clk = '0' and exec_cycle = "000000") then
            --show pc on the T0 (fetch) cycle.
            d_print("pc : " & conv_hex8(conv_integer(abh)) 
                    & conv_hex8(conv_integer(abl)));
        end if;
    end process;

end rtl;

