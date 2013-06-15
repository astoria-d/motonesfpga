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
                clk             : in std_logic;
                res_n           : in std_logic;
                pc_type         : in std_logic;
                dbus_we_n       : in std_logic;
                abus_we_n       : in std_logic;
                dbus_oe_n       : in std_logic;
                abus_oe_n       : in std_logic;
                addr_inc_n      : in std_logic;
                addr_dec_n      : in std_logic;
                add_carry       : out std_logic;
                rel_we_n        : in std_logic;
                rel_calc_n      : in std_logic;
                rel_prev        : out std_logic;
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
                exec_cycle      : in std_logic_vector (4 downto 0);
                next_cycle      : out std_logic_vector (4 downto 0);
                status_reg      : inout std_logic_vector (dsize - 1 downto 0);
                inst_we_n       : out std_logic;
                alu_en_n        : out std_logic;
                ad_oe_n         : out std_logic;
                pcl_inc_n       : out std_logic;
                pcl_d_we_n      : out std_logic;
                pcl_a_we_n      : out std_logic;
                pcl_d_oe_n      : out std_logic;
                pcl_a_oe_n      : out std_logic;
                pcl_rel_we_n    : out std_logic;
                pcl_rel_calc_n  : out std_logic;
                pch_d_we_n      : out std_logic;
                pch_a_we_n      : out std_logic;
                pch_d_oe_n      : out std_logic;
                pch_a_oe_n      : out std_logic;
                rel_pg_crs_n    : in std_logic;
                dbuf_int_oe_n   : out std_logic;
                dl_al_we_n      : out std_logic;
                dl_ah_we_n      : out std_logic;
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
                x_we_n          : out std_logic;
                x_oe_n          : out std_logic;
                x_ea_oe_n       : out std_logic;
                x_inc_n         : out std_logic;
                x_dec_n         : out std_logic;
                y_we_n          : out std_logic;
                y_oe_n          : out std_logic;
                y_ea_oe_n       : out std_logic;
                y_inc_n         : out std_logic;
                y_dec_n         : out std_logic;
                ea_calc_n       : out std_logic;
                ea_zp_n         : out std_logic;
                ea_pg_next_n    : out std_logic;
                ea_carry        : in  std_logic;
                stat_dec_oe_n   : out std_logic;
                stat_bus_oe_n   : out std_logic;
                stat_set_flg_n  : out std_logic;
                stat_flg        : out std_logic;
                stat_bus_all_n  : out std_logic;
                stat_bus_nz_n   : out std_logic;
                stat_alu_we_n   : out std_logic;
                r_nw            : out std_logic
                ;---for parameter check purpose!!!
                check_bit     : out std_logic_vector(1 to 5)
            );
    end component;


    component alu
        generic (   dsize : integer := 8
                );
        port (  clk             : in std_logic;
                alu_en_n        : in std_logic;
                instruction     : in std_logic_vector (dsize - 1 downto 0);
                int_d_bus       : inout std_logic_vector (dsize - 1 downto 0);
                alu_in          : in std_logic_vector (dsize - 1 downto 0);
                alu_out         : out std_logic_vector (dsize - 1 downto 0);
                carry_in        : in std_logic;
                negative        : out std_logic;
                zero            : out std_logic;
                carry_out       : out std_logic;
                overflow        : out std_logic
        );
    end component;

    ----------------------------------------------
    ---------- register declareration ------------
    ----------------------------------------------
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
                clk         : in std_logic;
                al_we_n     : in std_logic;
                ah_we_n     : in std_logic;
                al_oe_n     : in std_logic;
                ah_oe_n     : in std_logic;
                int_dbus    : in std_logic_vector (dsize - 1 downto 0);
                ea_al       : out std_logic_vector (dsize - 1 downto 0);
                ea_ah       : out std_logic_vector (dsize - 1 downto 0)
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
            dec_oe_n    : in std_logic;
            bus_oe_n    : in std_logic;
            set_flg_n   : in std_logic;
            flg_val     : in std_logic;
            load_bus_all_n : in std_logic;
            load_bus_nz_n  : in std_logic;
            alu_we_n    : in std_logic;
            alu_n       : in std_logic;
            alu_v       : in std_logic;
            alu_z       : in std_logic;
            alu_c       : in std_logic;
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
            int_dbus    : inout std_logic_vector (dsize - 1 downto 0);
            alu_out     : in std_logic_vector (dsize - 1 downto 0);
            alu_in      : out std_logic_vector (dsize - 1 downto 0)
        );
    end component;

    component index_reg
    generic (
            dsize : integer := 8
            );
    port (  
            clk         : in std_logic;
            d_we_n      : in std_logic;
            d_oe_n      : in std_logic;
            ea_oe_n     : in std_logic;
            inc_n       : in std_logic;
            dec_n       : in std_logic;
            int_dbus    : inout std_logic_vector (dsize - 1 downto 0);
            ea_bus      : out std_logic_vector (dsize - 1 downto 0);
            n           : out std_logic;
            z           : out std_logic
        );
    end component;

    component effective_adder
    generic (   dsize : integer := 8
            );
    port (  
            ea_calc_n       : in std_logic;
            zp_n            : in std_logic;
            pg_next_n       : in std_logic;
            base_l          : in std_logic_vector (dsize - 1 downto 0);
            base_h          : in std_logic_vector (dsize - 1 downto 0);
            index           : in std_logic_vector (dsize - 1 downto 0);
            ah_bus          : out std_logic_vector (dsize - 1 downto 0);
            al_bus          : out std_logic_vector (dsize - 1 downto 0);
            carry           : out std_logic
    );
    end component;

    ----------------------------------------------
    ------------ signal declareration ------------
    ----------------------------------------------
    signal set_clk : std_logic;
    signal trigger_clk : std_logic;

    signal pcl_inc_n : std_logic;
    signal pcl_d_we_n : std_logic;
    signal pcl_a_we_n : std_logic;
    signal pcl_d_oe_n : std_logic;
    signal pcl_a_oe_n : std_logic;
    signal pcl_rel_we_n : std_logic;
    signal pcl_rel_calc_n : std_logic;
    signal pch_d_we_n : std_logic;
    signal pch_a_we_n : std_logic;
    signal pch_d_oe_n : std_logic;
    signal pch_a_oe_n : std_logic;
    signal pc_cry : std_logic;
    signal pc_cry_n : std_logic;
    signal dum_terminate : std_logic := 'Z';
    signal pc_rel_prev : std_logic;
    signal pc_rel_prev_n : std_logic;
    signal rel_pg_crs_n : std_logic;

    signal inst_we_n : std_logic;
    signal dbuf_r_nw : std_logic;
    signal dbuf_int_oe_n : std_logic;
    signal dl_al_we_n : std_logic;
    signal dl_ah_we_n : std_logic;
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
    signal alu_en_n        : std_logic;
    signal alu_in          : std_logic_vector(dsize - 1 downto 0);
    signal alu_out         : std_logic_vector(dsize - 1 downto 0);

    signal x_we_n : std_logic;
    signal x_oe_n : std_logic;
    signal x_inc_n : std_logic;
    signal x_dec_n : std_logic;

    signal y_we_n : std_logic;
    signal y_oe_n : std_logic;
    signal y_inc_n : std_logic;
    signal y_dec_n : std_logic;

    signal ea_base_l : std_logic_vector(dsize - 1 downto 0);
    signal ea_base_h : std_logic_vector(dsize - 1 downto 0);
    signal ea_calc_n : std_logic;
    signal ea_zp_n : std_logic;
    signal ea_pg_next_n : std_logic;
    signal ea_carry : std_logic;

    signal ea_index : std_logic_vector(dsize - 1 downto 0);
    signal x_ea_oe_n : std_logic;
    signal y_ea_oe_n : std_logic;

    signal stat_dec_oe_n : std_logic;
    signal stat_bus_oe_n : std_logic;
    signal stat_set_flg_n : std_logic;
    signal stat_flg : std_logic;
    signal stat_bus_all_n : std_logic;
    signal stat_bus_nz_n : std_logic;
    signal stat_alu_we_n : std_logic;

    signal alu_n : std_logic;
    signal alu_v : std_logic;
    signal alu_z : std_logic;
    signal alu_c : std_logic;

    --internal bus (address hi/lo, data)
    signal ad_oe_n : std_logic;
    signal internal_abus_h : std_logic_vector (dsize - 1 downto 0);
    signal internal_abus_l : std_logic_vector (dsize - 1 downto 0);
    signal internal_dbus : std_logic_vector (dsize - 1 downto 0);

    signal instruction : std_logic_vector (dsize - 1 downto 0);
    signal exec_cycle  : std_logic_vector (4 downto 0);
    signal next_cycle  : std_logic_vector (4 downto 0);
    signal status_reg : std_logic_vector (dsize - 1 downto 0);

    signal check_bit     : std_logic_vector(1 to 5);

begin

    ---------------------------------------
    -------------- instances --------------
    ---------------------------------------
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
                    alu_en_n,
                    ad_oe_n, 
                    pcl_inc_n, 
                    pcl_d_we_n, 
                    pcl_a_we_n, 
                    pcl_d_oe_n, 
                    pcl_a_oe_n,
                    pcl_rel_we_n,
                    pcl_rel_calc_n,
                    pch_d_we_n, 
                    pch_a_we_n, 
                    pch_d_oe_n, 
                    pch_a_oe_n,
                    rel_pg_crs_n,
                    dbuf_int_oe_n, 
                    dl_al_we_n, 
                    dl_ah_we_n, 
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
                    x_we_n, 
                    x_oe_n, 
                    x_ea_oe_n,
                    x_inc_n,
                    x_dec_n,
                    y_we_n, 
                    y_oe_n, 
                    y_ea_oe_n,
                    y_inc_n,
                    y_dec_n,
                    ea_calc_n,
                    ea_zp_n,
                    ea_pg_next_n,
                    ea_carry,
                    stat_dec_oe_n, 
                    stat_bus_oe_n, 
                    stat_set_flg_n, 
                    stat_flg, 
                    stat_bus_all_n, 
                    stat_bus_nz_n, 
                    stat_alu_we_n, 
                    dbuf_r_nw
                    , check_bit --check bit.
                    );

    alu_inst : alu generic map (dsize) 
            port map (trigger_clk, alu_en_n, instruction, 
                internal_dbus, alu_in, alu_out,
                status_reg(0), 
                alu_n, alu_z, alu_c, alu_v
            );

    --cpu execution cycle number
    exec_cycle_inst : dff generic map (5) 
            port map(trigger_clk, '0', '0', next_cycle, exec_cycle);

    --io data buffer
    data_bus_buffer : dbus_buf generic map (dsize) 
            port map(set_clk, dbuf_r_nw, dbuf_int_oe_n, internal_dbus, d_io);

    ---effective addres calcurator.
    ea_calc: effective_adder generic map (dsize)
            port map (ea_calc_n, ea_zp_n, ea_pg_next_n,
                    ea_base_l, ea_base_h, ea_index, 
                    internal_abus_h, internal_abus_l, ea_carry);

    --address operand data buffer.
    input_data_latch : input_dl generic map (dsize) 
            port map(set_clk, dl_al_we_n, dl_ah_we_n, dl_al_oe_n, dl_ah_oe_n, 
                    internal_dbus, ea_base_l, ea_base_h);

    pc_l : pc generic map (dsize, 16#00#) 
            port map(trigger_clk, rst_n, '0', 
                    pcl_d_we_n, pcl_a_we_n, pcl_d_oe_n, pcl_a_oe_n, 
                    pcl_inc_n, '1', pc_cry, 
                    pcl_rel_we_n, pcl_rel_calc_n, pc_rel_prev,  
                    internal_dbus, internal_abus_l);
    pc_h : pc generic map (dsize, 16#80#) 
            port map(trigger_clk, rst_n, '1', 
                    pch_d_we_n, pch_a_we_n, pch_d_oe_n, pch_a_oe_n, 
                    pc_cry_n, pc_rel_prev_n, dum_terminate, 
                    '1', '1', dum_terminate, 
                    internal_dbus, internal_abus_h);

    instruction_register : dff generic map (dsize) 
            port map(trigger_clk, inst_we_n, '0', d_io, instruction);

    stack_pointer : sp generic map (dsize) 
            port map(trigger_clk, sp_we_n, sp_push_n, sp_pop_n, 
                    sp_int_d_oe_n, sp_int_a_oe_n, 
                    internal_dbus, internal_abus_l, internal_abus_h);

    status_register : processor_status generic map (dsize) 
            port map (trigger_clk, rst_n, 
                    stat_dec_oe_n, stat_bus_oe_n, 
                    stat_set_flg_n, stat_flg, stat_bus_all_n, stat_bus_nz_n, 
                    stat_alu_we_n, alu_n, alu_v, alu_z, alu_c,
                    status_reg, internal_dbus);

    --x/y output pin is connected to effective address calcurator
    x_reg : index_reg generic map (dsize) 
            port map(trigger_clk, x_we_n, x_oe_n, x_ea_oe_n, 
                    x_inc_n, x_dec_n, internal_dbus, ea_index, 
                    alu_n, alu_z);

    y_reg : index_reg generic map (dsize) 
            port map(trigger_clk, y_we_n, y_oe_n, y_ea_oe_n, 
                    y_inc_n, y_dec_n, internal_dbus, ea_index,
                    alu_n, alu_z);

    acc_reg : accumulator generic map (dsize) 
            port map(trigger_clk, 
                    acc_d_we_n, acc_alu_we_n, acc_d_oe_n, 
                    internal_dbus, alu_out, alu_in);

    -- clock generate.
    phi1 <= input_clk;
    phi2 <= not input_clk;
    set_clk <= input_clk;
    trigger_clk <= not input_clk;

    pc_cry_n <= not pc_cry;
    pc_rel_prev_n <= not pc_rel_prev;
    r_nw <= dbuf_r_nw;

    --branch instruction page crossed?
    rel_pg_crs_n <= pc_cry nand pc_rel_prev;

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
        if (set_clk = '0' and exec_cycle = "00000") then
            --show pc on the T0 (fetch) cycle.
            d_print("pc : " & conv_hex8(conv_integer(internal_abus_h)) 
                    & conv_hex8(conv_integer(internal_abus_l)));
        end if;
    end process;

end rtl;

