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

    component pc
        generic (
                dsize : integer := 8;
                reset_addr : integer := 0
                );
        port (  
                trig_clk        : in std_logic;
                res_n           : in std_logic;
                dbus_we_n       : in std_logic;
                abus_we_n       : in std_logic;
                dbus_oe_n       : in std_logic;
                abus_oe_n       : in std_logic;
                addr_inc_n      : in std_logic;
                add_carry       : in std_logic;
                inc_carry       : out std_logic;
                int_d_bus       : inout std_logic_vector (dsize - 1 downto 0);
                int_a_bus       : inout std_logic_vector (dsize - 1 downto 0)
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
                status_reg      : inout std_logic_vector (dsize - 1 downto 0);
                ad_oe_n         : out std_logic;
                pcl_d_we_n      : out std_logic;
                pcl_a_we_n      : out std_logic;
                pcl_d_oe_n      : out std_logic;
                pcl_a_oe_n      : out std_logic;
                pch_d_we_n      : out std_logic;
                pch_a_we_n      : out std_logic;
                pch_d_oe_n      : out std_logic;
                pch_a_oe_n      : out std_logic;
                pc_inc_n        : out std_logic;
                inst_we_n       : out std_logic;
                dbuf_int_oe_n   : out std_logic;
                dl_al_we_n      : out std_logic;
                dl_ah_we_n      : out std_logic;
                dl_d_oe_n       : out std_logic;
                dl_al_oe_n      : out std_logic;
                dl_ah_oe_n      : out std_logic;
                sp_we_n         : out std_logic;
                sp_push_n       : out std_logic;
                sp_pop_n        : out std_logic;
                sp_int_d_oe_n   : out std_logic;
                sp_int_a_oe_n   : out std_logic;
                acc_d_we_n      : out std_logic;
                acc_alu_we_n    : out std_logic;
                acc_d_oe_n      : out std_logic;
                acc_alu_oe_n    : out std_logic;
                x_we_n          : out std_logic;
                x_oe_n          : out std_logic;
                y_we_n          : out std_logic;
                y_oe_n          : out std_logic;
                stat_dec_we_n   : out std_logic;
                stat_dec_oe_n   : out std_logic;
                stat_bus_we_n   : out std_logic;
                stat_bus_oe_n   : out std_logic;
                r_nw            : out std_logic;
                dbg_show_pc     : out std_logic
            );
    end component;

    component dff
        generic (
                dsize : integer := 8
                );
        port (  
                clk     : in std_logic;
                we_n    : in std_logic;
                oe_n    : in std_logic;
                d       : in std_logic_vector (dsize - 1 downto 0);
                q       : out std_logic_vector (dsize - 1 downto 0)
            );
    end component;

    component dbus_buf
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

    component input_dl
        generic (
                dsize : integer := 8
                );
        port (  
                int_al_we_n : in std_logic;
                int_ah_we_n : in std_logic;
                int_d_oe_n  : in std_logic;
                int_al_oe_n : in std_logic;
                int_ah_oe_n : in std_logic;
                int_dbus    : inout std_logic_vector (dsize - 1 downto 0);
                int_abus_l  : out std_logic_vector (dsize - 1 downto 0);
                int_abus_h  : out std_logic_vector (dsize - 1 downto 0)
            );
    end component;

    component sp
        generic (
                dsize : integer := 8
                );
        port (  
                clk         : in std_logic;
                we_n        : in std_logic;
                push_n      : in std_logic;
                pop_n       : in std_logic;
                int_d_oe_n  : in std_logic;
                int_a_oe_n  : in std_logic;
                int_dbus    : inout std_logic_vector (dsize - 1 downto 0);
                int_abus_l  : out std_logic_vector (dsize - 1 downto 0);
                int_abus_h  : out std_logic_vector (dsize - 1 downto 0)
            );
    end component;

    component tsb
        generic (
                dsize : integer := 8
                );
        port (  
                oe_n    : in std_logic;
                d       : in std_logic_vector (dsize - 1 downto 0);
                q       : out std_logic_vector (dsize - 1 downto 0)
            );
    end component;

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
            alu_c       : in std_logic;
            alu_v       : in std_logic;
            decoder     : inout std_logic_vector (dsize - 1 downto 0);
            int_dbus    : inout std_logic_vector (dsize - 1 downto 0)
        );
    end component;

    component accumulator
    generic (
            dsize : integer := 8
            );
    port (  
            clk         : in std_logic;
            d_we_n      : in std_logic;
            alu_we_n    : in std_logic;
            d_oe_n      : in std_logic;
            alu_oe_n    : in std_logic;
            int_dbus    : inout std_logic_vector (dsize - 1 downto 0);
            alu_bus     : inout std_logic_vector (dsize - 1 downto 0)
        );
    end component;


    signal set_clk : std_logic;
    signal trigger_clk : std_logic;

    signal pcl_d_we_n : std_logic;
    signal pcl_a_we_n : std_logic;
    signal pcl_d_oe_n : std_logic;
    signal pcl_a_oe_n : std_logic;
    signal pch_d_we_n : std_logic;
    signal pch_a_we_n : std_logic;
    signal pch_d_oe_n : std_logic;
    signal pch_a_oe_n : std_logic;
    signal pc_inc_n : std_logic;
    signal pc_cry : std_logic;
    signal pc_cry_n : std_logic;
    signal dum_terminate : std_logic := 'Z';

    signal inst_we_n : std_logic;
    signal dbuf_r_nw : std_logic;
    signal dbuf_int_oe_n : std_logic;
    signal dl_al_we_n : std_logic;
    signal dl_ah_we_n : std_logic;
    signal dl_d_oe_n : std_logic;
    signal dl_al_oe_n : std_logic;
    signal dl_ah_oe_n : std_logic;

    signal sp_we_n : std_logic;
    signal sp_push_n : std_logic;
    signal sp_pop_n : std_logic;
    signal sp_int_d_oe_n : std_logic;
    signal sp_int_a_oe_n : std_logic;

    signal acc_d_we_n      : std_logic;
    signal acc_alu_we_n    : std_logic;
    signal acc_d_oe_n      : std_logic;
    signal acc_alu_oe_n    : std_logic;
    signal alu_bus         : std_logic_vector(dsize - 1 downto 0);

    signal x_we_n : std_logic;
    signal x_oe_n : std_logic;
    signal y_we_n : std_logic;
    signal y_oe_n : std_logic;

    signal stat_dec_we_n : std_logic;
    signal stat_dec_oe_n : std_logic;
    signal stat_bus_we_n : std_logic;
    signal stat_bus_oe_n : std_logic;
    signal stat_alu_c : std_logic;
    signal stat_alu_v : std_logic;

    --internal bus (address hi/lo, data)
    signal ad_oe_n : std_logic;
    signal internal_abus_h : std_logic_vector (dsize - 1 downto 0);
    signal internal_abus_l : std_logic_vector (dsize - 1 downto 0);
    signal internal_dbus : std_logic_vector (dsize - 1 downto 0);

    signal instruction : std_logic_vector (dsize - 1 downto 0);
    signal status_reg : std_logic_vector (dsize - 1 downto 0);

    signal dbg_show_pc : std_logic;
begin

    ---instances....
    pc_l : pc generic map (dsize, 16#00#) 
            port map(trigger_clk, rst_n, 
                    pcl_d_we_n, pcl_a_we_n, pcl_d_oe_n, pcl_a_oe_n, 
                    pc_inc_n, '0', pc_cry, internal_dbus, internal_abus_l);
    pc_h : pc generic map (dsize, 16#80#) 
            port map(trigger_clk, rst_n, 
                    pch_d_we_n, pch_a_we_n, pch_d_oe_n, pch_a_oe_n, 
                    pc_cry_n, pc_cry, dum_terminate, internal_dbus, internal_abus_h);

    dec_inst : decoder generic map (dsize) 
            port map(set_clk, 
                    trigger_clk, 
                    rst_n, 
                    irq_n, 
                    nmi_n, 
                    rdy, 
                    instruction, 
                    status_reg, 
                    ad_oe_n, 
                    pcl_d_we_n, 
                    pcl_a_we_n, 
                    pcl_d_oe_n, 
                    pcl_a_oe_n,
                    pch_d_we_n, 
                    pch_a_we_n, 
                    pch_d_oe_n, 
                    pch_a_oe_n,
                    pc_inc_n, 
                    inst_we_n, 
                    dbuf_int_oe_n, 
                    dl_al_we_n, 
                    dl_ah_we_n, 
                    dl_d_oe_n, 
                    dl_al_oe_n, 
                    dl_ah_oe_n,
                    sp_we_n, 
                    sp_push_n, 
                    sp_pop_n, 
                    sp_int_d_oe_n, 
                    sp_int_a_oe_n,
                    acc_d_we_n,
                    acc_alu_we_n,
                    acc_d_oe_n,
                    acc_alu_oe_n,
                    x_we_n, 
                    x_oe_n, 
                    y_we_n, 
                    y_oe_n, 
                    stat_dec_we_n, 
                    stat_dec_oe_n, 
                    stat_bus_we_n, 
                    stat_bus_oe_n,
                    dbuf_r_nw,
                    dbg_show_pc
                    );

    instruction_register : dff generic map (dsize) 
            port map(trigger_clk, inst_we_n, '0', d_io, instruction);

    data_bus_buffer : dbus_buf generic map (dsize) 
            port map(set_clk, dbuf_r_nw, dbuf_int_oe_n, internal_dbus, d_io);

    input_data_latch : input_dl generic map (dsize) 
            port map(dl_al_we_n, dl_ah_we_n, dl_d_oe_n, dl_al_oe_n, dl_ah_oe_n, 
                    internal_dbus, internal_abus_l, internal_abus_h);

    stack_pointer : sp generic map (dsize) 
            port map(trigger_clk, sp_we_n, sp_push_n, sp_pop_n, 
                    sp_int_d_oe_n, sp_int_a_oe_n, 
                    internal_dbus, internal_abus_l, internal_abus_h);

    status_reg_component : processor_status generic map (dsize) 
            port map (trigger_clk, rst_n, stat_dec_we_n, stat_bus_we_n, 
                    stat_dec_oe_n, stat_bus_oe_n, 
                    stat_alu_c, stat_alu_v, 
                    status_reg, internal_dbus);

    x_reg : dff generic map (dsize) 
            port map(trigger_clk, x_we_n, x_oe_n, internal_dbus, internal_dbus);

    y_reg : dff generic map (dsize) 
            port map(trigger_clk, y_we_n, y_oe_n, internal_dbus, internal_dbus);

    acc_reg : accumulator generic map (dsize) 
            port map(trigger_clk, 
                    acc_d_we_n, acc_alu_we_n, acc_d_oe_n, acc_alu_oe_n,
                    internal_dbus, alu_bus);

    -- clock generate.
    phi1 <= input_clk;
    phi2 <= not input_clk;
    set_clk <= input_clk;
    trigger_clk <= not input_clk;
    pc_cry_n <= not pc_cry;
    r_nw <= dbuf_r_nw;

    --adh output is controlled by decoder.
    adh_buffer : tsb generic map (dsize)
            port map (ad_oe_n, internal_abus_h, addr(asize - 1 downto dsize));
    adl_buffer : tsb generic map (dsize)
            port map (ad_oe_n, internal_abus_l, addr(dsize - 1 downto 0));

    reset_p : process (rst_n)
    begin
        if (rst_n'event and rst_n = '0') then

        end if;
    end process;

    dbg_p : process (dbg_show_pc)
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
        if (dbg_show_pc = '1') then
            d_print("pc : " & conv_hex8(conv_integer(internal_abus_h)) 
                    & conv_hex8(conv_integer(internal_abus_l)));
        end if;
    end process;

end rtl;

