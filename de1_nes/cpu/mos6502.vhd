library ieee;
use ieee.std_logic_1164.all;

entity mos6502 is 
    generic (   dsize : integer := 8;
                asize : integer :=16
            );
    port (  
    signal dbg_instruction  : out std_logic_vector(7 downto 0);
    signal dbg_int_d_bus    : out std_logic_vector(7 downto 0);
    signal dbg_exec_cycle   : out std_logic_vector (5 downto 0);
--    signal dbg_index_bus    : out std_logic_vector(7 downto 0);
--    signal dbg_acc_bus      : out std_logic_vector(7 downto 0);
    signal dbg_status       : out std_logic_vector(7 downto 0);
    signal dbg_pcl, dbg_pch, dbg_sp, dbg_x, dbg_y, dbg_acc       : out std_logic_vector(7 downto 0);
    signal dbg_dec_oe_n    : out std_logic;
    signal dbg_dec_val     : out std_logic_vector (7 downto 0);
    signal dbg_int_dbus    : out std_logic_vector (7 downto 0);
--    signal dbg_status_val    : out std_logic_vector (7 downto 0);
    signal dbg_stat_we_n    : out std_logic;

            input_clk   : in std_logic; --phi0 input pin.
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
            dbuf_int_oe_n   : out std_logic;
            dl_al_we_n      : out std_logic;
            dl_ah_we_n      : out std_logic;
            dl_al_oe_n      : out std_logic;
            dl_ah_oe_n      : out std_logic;
            dl_dh_oe_n      : out std_logic;
            pcl_inc_n       : out std_logic;
            pch_inc_n       : out std_logic;
            pcl_cmd         : out std_logic_vector(3 downto 0);
            pch_cmd         : out std_logic_vector(3 downto 0);
            sp_cmd          : out std_logic_vector(3 downto 0);
            sp_oe_n         : out std_logic;
            sp_push_n       : out std_logic;
            sp_pop_n        : out std_logic;
            acc_cmd         : out std_logic_vector(3 downto 0);
            x_cmd           : out std_logic_vector(3 downto 0);
            y_cmd           : out std_logic_vector(3 downto 0);
            abs_xy_n        : out std_logic;
            ea_carry        : in  std_logic;
            pg_next_n       : out std_logic;
            zp_n            : out std_logic;
            zp_xy_n         : out std_logic;
            rel_calc_n      : out std_logic;
            indir_n         : out std_logic;
            indir_x_n       : out std_logic;
            indir_y_n       : out std_logic;
            arith_en_n      : out std_logic;
            stat_dec_oe_n   : out std_logic;
            stat_bus_oe_n   : out std_logic;
            stat_set_flg_n  : out std_logic;
            stat_flg        : out std_logic;
            stat_bus_all_n  : out std_logic;
            stat_bus_nz_n   : out std_logic;
            stat_alu_we_n   : out std_logic;
            r_vec_oe_n      : out std_logic;
            n_vec_oe_n      : out std_logic;
            i_vec_oe_n      : out std_logic;
            r_nw            : out std_logic
            ;---for parameter check purpose!!!
            check_bit     : out std_logic_vector(1 to 5)
        );
end component;

component alu
    generic (   dsize : integer := 8
            );
    port (  clk             : in std_logic;
            pcl_inc_n       : in std_logic;
            pch_inc_n       : in std_logic;
            sp_oe_n         : in std_logic;
            sp_push_n       : in std_logic;
            sp_pop_n        : in std_logic;
            abs_xy_n        : in std_logic;
            pg_next_n       : in std_logic;
            zp_n            : in std_logic;
            zp_xy_n         : in std_logic;
            rel_calc_n      : in std_logic;
            indir_n         : in std_logic;
            indir_x_n       : in std_logic;
            indir_y_n       : in std_logic;
            arith_en_n      : in std_logic;
            instruction     : in std_logic_vector (dsize - 1 downto 0);
            exec_cycle      : in std_logic_vector (5 downto 0);
            int_d_bus       : inout std_logic_vector (dsize - 1 downto 0);
            acc_out         : in std_logic_vector (dsize - 1 downto 0);
            index_bus       : in std_logic_vector (dsize - 1 downto 0);
            bal             : in std_logic_vector (dsize - 1 downto 0);
            bah             : in std_logic_vector (dsize - 1 downto 0);
            addr_back       : out std_logic_vector (dsize - 1 downto 0);
            acc_in          : out std_logic_vector (dsize - 1 downto 0);
            abl             : out std_logic_vector (dsize - 1 downto 0);
            abh             : out std_logic_vector (dsize - 1 downto 0);
            pcl_inc_carry   : out std_logic;
            ea_carry        : out std_logic;
            carry_in        : in std_logic;
            negative        : out std_logic;
            zero            : out std_logic;
            carry_out       : out std_logic;
            overflow        : out std_logic
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
            dbg_out_port    : out std_logic_vector (dsize - 1 downto 0);

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

component processor_status 
    generic (
            dsize : integer := 8
            );
    port (  
    signal dbg_dec_oe_n    : out std_logic;
    signal dbg_dec_val     : out std_logic_vector (dsize - 1 downto 0);
    signal dbg_int_dbus    : out std_logic_vector (dsize - 1 downto 0);
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
    signal inst_rst_n : std_logic;
    signal ad_oe_n : std_logic;

    signal dbuf_r_nw : std_logic;
    signal dbuf_int_oe_n : std_logic;

    signal dl_al_we_n : std_logic;
    signal dl_ah_we_n : std_logic;
    signal dl_al_oe_n : std_logic;
    signal dl_ah_oe_n : std_logic;
    signal dl_dh_oe_n : std_logic;

    signal pcl_inc_n : std_logic;
    signal pch_inc_n : std_logic;
    signal pcl_inc_carry : std_logic;
    signal abs_xy_n        : std_logic;
    signal ea_carry        : std_logic;
    signal pg_next_n       : std_logic;
    signal zp_n            : std_logic;
    signal zp_xy_n         : std_logic;
    signal rel_calc_n      : std_logic;
    signal indir_n         : std_logic;
    signal indir_x_n       : std_logic;
    signal indir_y_n       : std_logic;
    signal arith_en_n      : std_logic;
                    
    signal alu_n : std_logic;
    signal alu_z : std_logic;
    signal alu_c : std_logic;
    signal alu_v : std_logic;
    signal stat_c : std_logic;

    ----control line for dual port registers.
    signal pcl_cmd : std_logic_vector(3 downto 0);
    signal pch_cmd : std_logic_vector(3 downto 0);
    signal sp_cmd : std_logic_vector(3 downto 0);
    signal acc_cmd : std_logic_vector(3 downto 0);
    signal x_cmd : std_logic_vector(3 downto 0);
    signal y_cmd : std_logic_vector(3 downto 0);
    signal sp_oe_n : std_logic;
    signal sp_push_n : std_logic;
    signal sp_pop_n  : std_logic;

    ---status register
    signal stat_dec_oe_n : std_logic;
    signal stat_bus_oe_n : std_logic;
    signal stat_set_flg_n : std_logic;
    signal stat_flg : std_logic;
    signal stat_bus_all_n : std_logic;
    signal stat_bus_nz_n : std_logic;
    signal stat_alu_we_n : std_logic;

    -------------------------------
    ------------ buses ------------
    -------------------------------
    signal instruction : std_logic_vector(dsize - 1 downto 0);
    
    signal bah : std_logic_vector(dsize - 1 downto 0);
    signal bal : std_logic_vector(dsize - 1 downto 0);
    signal index_bus : std_logic_vector(dsize - 1 downto 0);
    signal idl_h_out : std_logic_vector(dsize - 1 downto 0);

    signal acc_out : std_logic_vector(dsize - 1 downto 0);
    signal acc_in : std_logic_vector(dsize - 1 downto 0);
    signal addr_back : std_logic_vector(dsize - 1 downto 0);

    --not used bus.
    signal null_bus : std_logic_vector(dsize - 1 downto 0);

    --address bus
    signal abh : std_logic_vector(dsize - 1 downto 0);
    signal abl : std_logic_vector(dsize - 1 downto 0);

    ---internal data bus
    signal int_d_bus : std_logic_vector(dsize - 1 downto 0);

    ---reset vectors---
    signal r_vec_oe_n : std_logic;
    signal n_vec_oe_n : std_logic;
    signal i_vec_oe_n : std_logic;
    signal reset_l : std_logic_vector(dsize - 1 downto 0);
    signal reset_h : std_logic_vector(dsize - 1 downto 0);
    signal nmi_l : std_logic_vector(dsize - 1 downto 0);
    signal nmi_h : std_logic_vector(dsize - 1 downto 0);
    signal irq_l : std_logic_vector(dsize - 1 downto 0);
    signal irq_h : std_logic_vector(dsize - 1 downto 0);

    signal check_bit     : std_logic_vector(1 to 5);

    --signal dbg_pcl, dbg_pch, dbg_sp, dbg_x, dbg_y, dbg_acc       : std_logic_vector(7 downto 0);

begin

    ----for debug monitoring....
    dbg_instruction <= instruction;
    dbg_int_d_bus <= int_d_bus;
    dbg_exec_cycle <= exec_cycle;
--    dbg_index_bus <= index_bus;
--    dbg_acc_bus <= acc_out;
    dbg_status <= status_reg;


    -- clock generate.
    phi1 <= input_clk;
    phi2 <= not input_clk;
    set_clk <= input_clk;
    trigger_clk <= not input_clk;

    r_nw <= dbuf_r_nw;
    reset_l <= "11111100";
    reset_h <= "11111111";
    nmi_l <= "11111010";
    nmi_h <= "11111111";
    irq_l <= "11111110";
    irq_h <= "11111111";

    --instruction register is reset when handling exceptions(nmi/irq cycle).
    inst_rst_n <= '0' when rst_n = '0' else
                  '0' when (exec_cycle(3) or exec_cycle(4)) = '1' else
                  '1';

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
                    dbuf_int_oe_n,
                    dl_al_we_n,
                    dl_ah_we_n,
                    dl_al_oe_n,
                    dl_ah_oe_n,
                    dl_dh_oe_n,
                    pcl_inc_n,
                    pch_inc_n,
                    pcl_cmd,
                    pch_cmd,
                    sp_cmd,
                    sp_oe_n,
                    sp_push_n,
                    sp_pop_n,
                    acc_cmd,
                    x_cmd,
                    y_cmd,
                    abs_xy_n,
                    ea_carry,
                    pg_next_n,
                    zp_n,
                    zp_xy_n,
                    rel_calc_n,
                    indir_n,
                    indir_x_n,
                    indir_y_n,
                    arith_en_n,
                    stat_dec_oe_n, 
                    stat_bus_oe_n, 
                    stat_set_flg_n, 
                    stat_flg, 
                    stat_bus_all_n, 
                    stat_bus_nz_n, 
                    stat_alu_we_n, 
                    r_vec_oe_n,
                    n_vec_oe_n,
                    i_vec_oe_n,
                    dbuf_r_nw
                    , check_bit --check bit.
                    );

    alu_inst : alu generic map (dsize) 
            port map (trigger_clk, 
                    pcl_inc_n,
                    pch_inc_n,
                    sp_oe_n,
                    sp_push_n,
                    sp_pop_n,
                    abs_xy_n,
                    pg_next_n,
                    zp_n,
                    zp_xy_n,
                    rel_calc_n,
                    indir_n,
                    indir_x_n,
                    indir_y_n,
                    arith_en_n,
                    instruction,
                    exec_cycle,
                    int_d_bus,
                    acc_out,
                    index_bus,
                    bal,
                    bah,
                    addr_back,
                    acc_in,
                    abl,
                    abh,
                    pcl_inc_carry,
                    ea_carry,
                    stat_c,
                    alu_n,
                    alu_z,
                    alu_c,
                    alu_v 
                    );

    --cpu execution cycle number
    exec_cycle_inst : d_flip_flop generic map (5) 
            port map(trigger_clk, '1', '1', '0', 
                    next_cycle(4 downto 0), exec_cycle(4 downto 0));

    --exec_cycle top bit is phc carry flag.
    exec_cycle(5) <= pcl_inc_carry;

    --io data buffer
    dbus_buf : data_bus_buffer generic map (dsize) 
            port map(set_clk, dbuf_r_nw, dbuf_int_oe_n, int_d_bus, d_io);

    --address operand data buffer.
    idl_l : input_data_latch generic map (dsize) 
            port map(set_clk, dl_al_oe_n, dl_al_we_n, int_d_bus, bal);
    idl_h : input_data_latch generic map (dsize) 
            port map(set_clk, '0', dl_ah_we_n, int_d_bus, idl_h_out);
    ---only DLH has b-bus side output.
    idl_h_a_buf : tri_state_buffer generic map (dsize)
            port map (dl_ah_oe_n, idl_h_out, bah);
    idl_h_d_buf : tri_state_buffer generic map (dsize)
            port map (dl_dh_oe_n, idl_h_out, int_d_bus);

    -------- registers --------
    ir : d_flip_flop generic map (dsize) 
            port map(trigger_clk, inst_rst_n, '1', inst_we_n, d_io, instruction);

    pcl_inst : dual_dff generic map (dsize) 
            port map(dbg_pcl, trigger_clk, rst_n, '1', pcl_cmd, int_d_bus, addr_back, bal);
    pch_inst : dual_dff generic map (dsize) 
            port map(dbg_pch, trigger_clk, rst_n, '1', pch_cmd, int_d_bus, addr_back, bah);

    --status register
    status_register : processor_status generic map (dsize) 
            port map (
    dbg_dec_oe_n,
    dbg_dec_val,
    dbg_int_dbus,
--    dbg_status_val,
    dbg_stat_we_n    ,
                    trigger_clk, rst_n, 
                    stat_dec_oe_n, stat_bus_oe_n, 
                    stat_set_flg_n, stat_flg, stat_bus_all_n, stat_bus_nz_n, 
                    stat_alu_we_n, alu_n, alu_v, alu_z, alu_c, stat_c,
                    status_reg, int_d_bus);


    sp : dual_dff generic map (dsize) 
            port map(dbg_sp, trigger_clk, rst_n, '1', sp_cmd, int_d_bus, addr_back, bal);

    x : dual_dff generic map (dsize) 
            port map(dbg_x, trigger_clk, rst_n, '1', x_cmd, int_d_bus, null_bus, index_bus);
    y : dual_dff generic map (dsize) 
            port map(dbg_y, trigger_clk, rst_n, '1', y_cmd, int_d_bus, null_bus, index_bus);

    acc : dual_dff generic map (dsize) 
            port map(dbg_acc, trigger_clk, rst_n, '1', acc_cmd, int_d_bus, acc_in, acc_out);

    --adh output is controlled by decoder.
    adh_buf : tri_state_buffer generic map (dsize)
            port map (ad_oe_n, abh, addr(asize - 1 downto dsize));
    adl_buf : tri_state_buffer generic map (dsize)
            port map (ad_oe_n, abl, addr(dsize - 1 downto 0));

    null_bus <= (others => 'Z');

    ----gating reset vector.
    res_l_buf : tri_state_buffer generic map (dsize)
            port map (r_vec_oe_n, reset_l, bal);
    res_h_buf : tri_state_buffer generic map (dsize)
            port map (r_vec_oe_n, reset_h, bah);
    nmi_l_buf : tri_state_buffer generic map (dsize)
            port map (n_vec_oe_n, nmi_l, bal);
    nmi_h_buf : tri_state_buffer generic map (dsize)
            port map (n_vec_oe_n, nmi_h, bah);
    irq_l_buf : tri_state_buffer generic map (dsize)
            port map (i_vec_oe_n, irq_l, bal);
    irq_h_buf : tri_state_buffer generic map (dsize)
            port map (i_vec_oe_n, irq_h, bah);

    reset_p : process (rst_n)
    begin
        if (rst_n = '0') then

        end if;
    end process;


------------------------------------------------------------
------------------------ for debug... ----------------------
------------------------------------------------------------

    dbg_p : process (set_clk)
use work.motonesfpga_common.all;
use ieee.std_logic_unsigned.conv_integer;

    begin
        if (set_clk = '0' and rdy = '1' and exec_cycle = "000000") then
            --show pc on the T0 (fetch) cycle.
            d_print("pc : " & conv_hex8(conv_integer(abh)) 
                    & conv_hex8(conv_integer(abl)));
        end if;
    end process;

end rtl;

