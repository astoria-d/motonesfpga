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
    signal dbg_ea_carry     : out std_logic;
    signal dbg_status       : out std_logic_vector(7 downto 0);
    signal dbg_pcl, dbg_pch, dbg_sp, dbg_x, dbg_y, dbg_acc       : out std_logic_vector(7 downto 0);
    signal dbg_dec_oe_n    : out std_logic;
    signal dbg_dec_val     : out std_logic_vector (7 downto 0);
    signal dbg_stat_we_n    : out std_logic;
    signal dbg_idl_h, dbg_idl_l     : out std_logic_vector (7 downto 0);

            cpu_clk     : in std_logic; --phi0 input pin.
            rdy         : in std_logic;
            rst_n       : in std_logic;
            irq_n       : in std_logic;
            nmi_n       : in std_logic;
            r_nw        : out std_logic;
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
    port (
            --input lines.
            cpu_clk         : in std_logic;
            res_n           : in std_logic;
            irq_n           : in std_logic;
            nmi_n           : in std_logic;
            rdy             : in std_logic;
            instruction     : in std_logic_vector (dsize - 1 downto 0);
            exec_cycle      : out std_logic_vector (5 downto 0);
            ea_carry        : in  std_logic;
            status_reg      : inout std_logic_vector (dsize - 1 downto 0);

            --general control.
            inst_we_n       : out std_logic;
            ad_oe_n         : out std_logic;
            dbuf_int_oe_n   : out std_logic;
            r_nw            : out std_logic;

            ----control line for dual port registers.
            idl_l_cmd       : out std_logic_vector(3 downto 0);
            idl_h_cmd       : out std_logic_vector(3 downto 0);
            pcl_cmd         : out std_logic_vector(3 downto 0);
            pch_cmd         : out std_logic_vector(3 downto 0);
            sp_cmd          : out std_logic_vector(3 downto 0);
            x_cmd           : out std_logic_vector(3 downto 0);
            y_cmd           : out std_logic_vector(3 downto 0);
            acc_cmd         : out std_logic_vector(3 downto 0);
            
            --addr calc control
            pcl_inc_n       : out std_logic;
            sp_oe_n         : out std_logic;
            sp_push_n       : out std_logic;
            sp_pop_n        : out std_logic;
            abs_xy_n        : out std_logic;
            pg_next_n       : out std_logic;
            zp_n            : out std_logic;
            zp_xy_n         : out std_logic;
            rel_calc_n      : out std_logic;
            indir_n         : out std_logic;
            indir_x_n       : out std_logic;
            indir_y_n       : out std_logic;
            addr_cycle      : out std_logic_vector(2 downto 0);

            ---status register
            stat_dec_oe_n   : out std_logic;
            stat_bus_oe_n   : out std_logic;
            stat_set_flg_n  : out std_logic;
            stat_flg        : out std_logic;
            stat_bus_all_n  : out std_logic;
            stat_bus_nz_n   : out std_logic;
            stat_alu_we_n   : out std_logic;
            
            --ALU control
            arith_en_n      : out std_logic;
            alu_cycle       : out std_logic_vector(1 downto 0);
            
            --reset vectors.
            r_vec_oe_n      : out std_logic;
            n_vec_oe_n      : out std_logic;
            i_vec_oe_n      : out std_logic

            ;---for parameter check purpose!!!
            check_bit     : out std_logic_vector(1 to 5)
        );
end component;

component address_calcurator
    generic (   dsize : integer := 8
            );
    port (  
            cpu_clk         : in std_logic;

            --control line.
            pcl_inc_n       : in std_logic;
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
            addr_cycle      : in std_logic_vector(2 downto 0);

            --reset vectors.
            r_vec_oe_n      : in std_logic;
            n_vec_oe_n      : in std_logic;
            i_vec_oe_n      : in std_logic;

            --in/out buses.
            index_bus       : in std_logic_vector (dsize - 1 downto 0);
            bal             : in std_logic_vector (dsize - 1 downto 0);
            bah             : in std_logic_vector (dsize - 1 downto 0);
            int_d_bus       : in std_logic_vector (dsize - 1 downto 0);
            addr_back_l     : out std_logic_vector (dsize - 1 downto 0);
            addr_back_h     : out std_logic_vector (dsize - 1 downto 0);
            abl             : out std_logic_vector (dsize - 1 downto 0);
            abh             : out std_logic_vector (dsize - 1 downto 0);
            ea_carry        : out std_logic
    );
end component;

component alu
    generic (   dsize : integer := 8
            );
    port (  
            cpu_clk         : in std_logic;
            instruction     : in std_logic_vector (dsize - 1 downto 0);
            arith_en_n      : in std_logic;
            alu_cycle       : in std_logic_vector(1 downto 0);
            int_d_bus       : inout std_logic_vector (dsize - 1 downto 0);
            acc_in          : out std_logic_vector (dsize - 1 downto 0);
            acc_out         : in std_logic_vector (dsize - 1 downto 0);
            index_bus       : in std_logic_vector (dsize - 1 downto 0);
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
            int_oe_n    : in std_logic;
            ext_oe_n    : in std_logic;
            int_dbus : inout std_logic_vector (dsize - 1 downto 0);
            ext_dbus : inout std_logic_vector (dsize - 1 downto 0)
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
    signal dbg_stat_we_n    : out std_logic;

            cpu_clk     : in std_logic;
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
    signal exec_cycle : std_logic_vector(5 downto 0);
    signal status_reg : std_logic_vector (dsize - 1 downto 0);

    -------------------------------
    -------- control lines --------
    -------------------------------
    signal inst_we_n        : std_logic;
    signal inst_rst_n       : std_logic;
    signal ad_oe_n          : std_logic;

    signal dbuf_r_nw        : std_logic;
    signal dbuf_int_oe_n    : std_logic;

    signal pcl_inc_n        : std_logic;
    signal abs_xy_n         : std_logic;
    signal ea_carry         : std_logic;
    signal pg_next_n        : std_logic;
    signal zp_n             : std_logic;
    signal zp_xy_n          : std_logic;
    signal rel_calc_n       : std_logic;
    signal indir_n          : std_logic;
    signal indir_x_n        : std_logic;
    signal indir_y_n        : std_logic;
    signal sp_oe_n          : std_logic;
    signal sp_push_n        : std_logic;
    signal sp_pop_n         : std_logic;
    signal addr_cycle       : std_logic_vector(2 downto 0);

    signal arith_en_n       : std_logic;                    
    signal alu_cycle        : std_logic_vector(1 downto 0);
    signal stat_c           : std_logic;

    signal negative        : std_logic;
    signal zero            : std_logic;
    signal carry_out       : std_logic;
    signal overflow        : std_logic;

    ----control line for dual port registers.
    signal idl_l_cmd        : std_logic_vector(3 downto 0);
    signal idl_h_cmd        : std_logic_vector(3 downto 0);
    signal pcl_cmd          : std_logic_vector(3 downto 0);
    signal pch_cmd          : std_logic_vector(3 downto 0);
    signal sp_cmd           : std_logic_vector(3 downto 0);
    signal acc_cmd          : std_logic_vector(3 downto 0);
    signal x_cmd            : std_logic_vector(3 downto 0);
    signal y_cmd            : std_logic_vector(3 downto 0);

    ---status register
    signal stat_dec_oe_n    : std_logic;
    signal stat_bus_oe_n    : std_logic;
    signal stat_set_flg_n   : std_logic;
    signal stat_flg         : std_logic;
    signal stat_bus_all_n   : std_logic;
    signal stat_bus_nz_n    : std_logic;
    signal stat_alu_we_n    : std_logic;

    -------------------------------
    ------------ buses ------------
    -------------------------------
    signal instruction  : std_logic_vector(dsize - 1 downto 0);
    
    signal bah          : std_logic_vector(dsize - 1 downto 0);
    signal bal          : std_logic_vector(dsize - 1 downto 0);
    signal index_bus    : std_logic_vector(dsize - 1 downto 0);

    signal acc_out      : std_logic_vector(dsize - 1 downto 0);
    signal acc_in       : std_logic_vector(dsize - 1 downto 0);
    signal addr_back_l  : std_logic_vector(dsize - 1 downto 0);
    signal addr_back_h  : std_logic_vector(dsize - 1 downto 0);

    --not used bus.
    signal null_bus     : std_logic_vector(dsize - 1 downto 0);

    --address bus
    signal abh          : std_logic_vector(dsize - 1 downto 0);
    signal abl          : std_logic_vector(dsize - 1 downto 0);

    ---internal data bus
    signal int_d_bus    : std_logic_vector(dsize - 1 downto 0);

    ---reset vectors---
    signal r_vec_oe_n   : std_logic;
    signal n_vec_oe_n   : std_logic;
    signal i_vec_oe_n   : std_logic;

    signal check_bit    : std_logic_vector(1 to 5);

begin

    ----for debug monitoring....
    dbg_instruction <= instruction;
    dbg_int_d_bus <= int_d_bus;
    dbg_exec_cycle <= exec_cycle;
    dbg_ea_carry <= ea_carry;
--    dbg_index_bus <= index_bus;
--    dbg_acc_bus <= acc_out;
    dbg_status <= status_reg;

    r_nw <= dbuf_r_nw;

    --instruction register is reset when handling exceptions(nmi/irq cycle).
    inst_rst_n <= '0' when rst_n = '0' else
                  '0' when (exec_cycle(3) or exec_cycle(4)) = '1' else
                  '1';

    --------------------------------------------------
    ------------------- instances --------------------
    --------------------------------------------------

    dec_inst : decoder generic map (dsize) 
            port map(
                    --input lines.
                    cpu_clk         ,
                    rst_n           ,
                    irq_n           ,
                    nmi_n           ,
                    rdy             ,
                    instruction     ,
                    exec_cycle      ,
                    ea_carry        ,
                    status_reg      ,

                    inst_we_n       ,
                    ad_oe_n         ,
                    dbuf_int_oe_n   ,
                    dbuf_r_nw       ,

                    idl_l_cmd       ,
                    idl_h_cmd       ,
                    pcl_cmd         ,
                    pch_cmd         ,
                    sp_cmd          ,
                    x_cmd           ,
                    y_cmd           ,
                    acc_cmd         ,

                    pcl_inc_n       ,
                    sp_oe_n         ,
                    sp_push_n       ,
                    sp_pop_n        ,
                    abs_xy_n        ,
                    pg_next_n       ,
                    zp_n            ,
                    zp_xy_n         ,
                    rel_calc_n      ,
                    indir_n         ,
                    indir_x_n       ,
                    indir_y_n       ,
                    addr_cycle      ,

                    stat_dec_oe_n   ,
                    stat_bus_oe_n   ,
                    stat_set_flg_n  ,
                    stat_flg        ,
                    stat_bus_all_n  ,
                    stat_bus_nz_n   ,
                    stat_alu_we_n   ,

                    arith_en_n      ,
                    alu_cycle       ,

                    r_vec_oe_n      ,
                    n_vec_oe_n      ,
                    i_vec_oe_n

                    , check_bit --check bit.
                    );

    ad_calc_inst : address_calcurator generic map (dsize) 
            port map (
            cpu_clk         ,

            pcl_inc_n       ,
            sp_oe_n         ,
            sp_push_n       ,
            sp_pop_n        ,
            abs_xy_n        ,
            pg_next_n       ,
            zp_n            ,
            zp_xy_n         ,
            rel_calc_n      ,
            indir_n         ,
            indir_x_n       ,
            indir_y_n       ,
            addr_cycle      ,

            r_vec_oe_n      ,
            n_vec_oe_n      ,
            i_vec_oe_n      ,

            index_bus       ,
            bal             ,
            bah             ,
            int_d_bus       ,
            addr_back_l     ,
            addr_back_h     ,
            abl             ,
            abh             ,
            ea_carry
            );
                    
    alu_inst : alu generic map (dsize) 
            port map (
            cpu_clk         ,
            instruction     ,
            arith_en_n      ,
            alu_cycle       ,
            int_d_bus       ,
            acc_in          ,
            acc_out         ,
            index_bus       ,
            stat_c          ,
            negative        ,
            zero            ,
            carry_out       ,
            overflow
                    );

    --io data gateway
    dbus_buf : data_bus_buffer generic map (dsize) 
            port map(dbuf_int_oe_n, dbuf_r_nw, int_d_bus, d_io);

    -------- instruction register --------
    ir : d_flip_flop generic map (dsize) 
            port map(cpu_clk, inst_rst_n, '1', inst_we_n, d_io, instruction);

    --input data buffer.
    idl_l : dual_dff generic map (dsize) 
            port map(dbg_idl_l, cpu_clk, rst_n, '1', idl_l_cmd, int_d_bus, null_bus, bal);
    idl_h : dual_dff generic map (dsize) 
            port map(dbg_idl_h, cpu_clk, rst_n, '1', idl_h_cmd, int_d_bus, null_bus, bah);

    -------- program counter --------
    pcl_inst : dual_dff generic map (dsize) 
            port map(dbg_pcl, cpu_clk, rst_n, '1', pcl_cmd, int_d_bus, addr_back_l, bal);
    pch_inst : dual_dff generic map (dsize) 
            port map(dbg_pch, cpu_clk, rst_n, '1', pch_cmd, int_d_bus, addr_back_h, bah);


    --addressing register
    sp : dual_dff generic map (dsize) 
            port map(dbg_sp, cpu_clk, rst_n, '1', sp_cmd, int_d_bus, addr_back_l, bal);

    x : dual_dff generic map (dsize) 
            port map(dbg_x, cpu_clk, rst_n, '1', x_cmd, int_d_bus, null_bus, index_bus);
    y : dual_dff generic map (dsize) 
            port map(dbg_y, cpu_clk, rst_n, '1', y_cmd, int_d_bus, null_bus, index_bus);

    --accumurator
    acc : dual_dff generic map (dsize) 
            port map(dbg_acc, cpu_clk, rst_n, '1', acc_cmd, int_d_bus, acc_in, acc_out);


    --status register
    status_register : processor_status generic map (dsize) 
            port map (
    dbg_dec_oe_n,
    dbg_dec_val,
    dbg_stat_we_n    ,
                    cpu_clk, rst_n, 
                    stat_dec_oe_n, stat_bus_oe_n, 
                    stat_set_flg_n, stat_flg, stat_bus_all_n, stat_bus_nz_n, 
                    stat_alu_we_n, negative, overflow, zero, carry_out, stat_c,
                    status_reg, int_d_bus);

    --adh output is controlled by decoder.
    adh_buf : tri_state_buffer generic map (dsize)
            port map (ad_oe_n, abh, addr(asize - 1 downto dsize));
    adl_buf : tri_state_buffer generic map (dsize)
            port map (ad_oe_n, abl, addr(dsize - 1 downto 0));

    null_bus <= (others => 'Z');

end rtl;

