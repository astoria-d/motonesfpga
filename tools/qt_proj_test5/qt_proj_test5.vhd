library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;

--  
--   MOTO NES FPGA On GHDL Simulation Environment Virtual Cuicuit Board
--   All of the components are assembled and instanciated on this board.
--  

entity qt_proj_test5 is 
    port (

    signal dbg_cpu_clk  : out std_logic;
    signal dbg_ppu_clk  : out std_logic;
    signal dbg_addr : out std_logic_vector( 16 - 1 downto 0);
    signal dbg_d_io : out std_logic_vector( 8 - 1 downto 0);

    signal dbg_ppu_ce_n    : out std_logic;
    signal dbg_ppu_ctrl, dbg_ppu_mask, dbg_ppu_status : out std_logic_vector (7 downto 0);
    signal dbg_ppu_addr : out std_logic_vector (13 downto 0);
    signal dbg_ppu_data, dbg_ppu_scrl_x, dbg_ppu_scrl_y : out std_logic_vector (7 downto 0);
    signal dbg_disp_nt, dbg_disp_attr : out std_logic_vector (7 downto 0);
    signal dbg_disp_ptn_h, dbg_disp_ptn_l : out std_logic_vector (15 downto 0);

    signal dbg_ppu_addr_we_n    : out std_logic;
    signal dbg_ppu_clk_cnt          : out std_logic_vector(1 downto 0);



        base_clk 	: in std_logic;
        base_clk_27mhz 	: in std_logic;
        rst_n     	: in std_logic;
        h_sync_n    : out std_logic;
        v_sync_n    : out std_logic;
        r           : out std_logic_vector(3 downto 0);
        g           : out std_logic_vector(3 downto 0);
        b           : out std_logic_vector(3 downto 0)

        );
end qt_proj_test5;

architecture rtl of qt_proj_test5 is

    component clock_divider
        port (  base_clk    : in std_logic;
                reset_n     : in std_logic;
                cpu_clk     : out std_logic;
                ppu_clk     : out std_logic;
                mem_clk     : out std_logic;
                vga_clk     : out std_logic
            );
    end component;

    component ram
        generic (abus_size : integer := 16; dbus_size : integer := 8);
        port (  
                clk               : in std_logic;
                ce_n, oe_n, we_n  : in std_logic;   --select pin active low.
                addr              : in std_logic_vector (abus_size - 1 downto 0);
                d_io              : inout std_logic_vector (dbus_size - 1 downto 0)
        );
    end component;

    component ppu port (
        signal dbg_ppu_ce_n    : out std_logic;
        signal dbg_ppu_ctrl, dbg_ppu_mask, dbg_ppu_status : out std_logic_vector (7 downto 0);
        signal dbg_ppu_addr : out std_logic_vector (13 downto 0);
        signal dbg_ppu_data, dbg_ppu_scrl_x, dbg_ppu_scrl_y : out std_logic_vector (7 downto 0);

        signal dbg_ppu_clk                      : out std_logic;
        signal dbg_nes_x                        : out std_logic_vector (8 downto 0);
        signal dbg_vga_x                        : out std_logic_vector (9 downto 0);
        signal dbg_disp_nt, dbg_disp_attr       : out std_logic_vector (7 downto 0);
        signal dbg_disp_ptn_h, dbg_disp_ptn_l   : out std_logic_vector (15 downto 0);
        signal dbg_plt_addr                     : out std_logic_vector (4 downto 0);
        signal dbg_plt_data                     : out std_logic_vector (7 downto 0);

        signal dbg_ppu_addr_we_n                : out std_logic;
        signal dbg_ppu_clk_cnt                  : out std_logic_vector(1 downto 0);

                clk         : in std_logic;
                mem_clk     : in std_logic;
                ce_n        : in std_logic;
                rst_n       : in std_logic;
                r_nw        : in std_logic;
                cpu_addr    : in std_logic_vector (2 downto 0);
                cpu_d       : inout std_logic_vector (7 downto 0);

                vblank_n    : out std_logic;
                rd_n        : out std_logic;
                wr_n        : out std_logic;
                ale         : out std_logic;
                vram_ad     : inout std_logic_vector (7 downto 0);
                vram_a      : out std_logic_vector (13 downto 8);

                vga_clk     : in std_logic;
                h_sync_n    : out std_logic;
                v_sync_n    : out std_logic;
                r           : out std_logic_vector(3 downto 0);
                g           : out std_logic_vector(3 downto 0);
                b           : out std_logic_vector(3 downto 0)
    );
    end component;

    component v_address_decoder
    generic (abus_size : integer := 14; dbus_size : integer := 8);
        port (  clk         : in std_logic; 
                mem_clk     : in std_logic;
                rd_n        : in std_logic;
                wr_n        : in std_logic;
                ale         : in std_logic;
                v_addr      : in std_logic_vector (13 downto 0);
                v_data      : in std_logic_vector (7 downto 0);
                nt_v_mirror : in std_logic;
                pt_ce_n     : out std_logic;
                nt0_ce_n    : out std_logic;
                nt1_ce_n    : out std_logic
            );
    end component;

    component chr_rom
        generic (abus_size : integer := 13; dbus_size : integer := 8);
        port (  
                clk             : in std_logic;
                ce_n            : in std_logic;     --active low.
                addr            : in std_logic_vector (abus_size - 1 downto 0);
                data            : out std_logic_vector (dbus_size - 1 downto 0);
                nt_v_mirror     : out std_logic
        );
    end component;

    component ls373
        generic (
            dsize : integer := 8
        );
        port (  c         : in std_logic;
                oc_n      : in std_logic;
                d         : in std_logic_vector(dsize - 1 downto 0);
                q         : out std_logic_vector(dsize - 1 downto 0)
        );
    end component;

    
    
    constant data_size : integer := 8;
    constant addr_size : integer := 16;
    constant vram_size14    : integer := 14;

    constant ram_2k : integer := 11;      --2k = 11 bit width.
    constant rom_32k : integer := 15;     --32k = 15 bit width.
    constant rom_4k : integer := 12;     --4k = 12 bit width. (for test use)
    constant vram_1k : integer := 10;      --1k = 10 bit width.
    constant chr_rom_8k : integer := 13;     --32k = 15 bit width.

    signal cpu_clk  : std_logic;
    signal ppu_clk  : std_logic;
    signal mem_clk   : std_logic;
    signal vga_clk   : std_logic;

    signal ppu_ce_n    : std_logic;
    signal r_nw        : std_logic;
    signal cpu_addr    : std_logic_vector (2 downto 0);
    signal cpu_d       : std_logic_vector (7 downto 0);
    signal vblank_n    : std_logic;
    signal rd_n        : std_logic;
    signal wr_n        : std_logic;
    signal ale         : std_logic;
    signal vram_ad     : std_logic_vector (7 downto 0);
    signal vram_a      : std_logic_vector (13 downto 8);
    signal v_addr   : std_logic_vector (13 downto 0);
    signal nt_v_mirror  : std_logic;
    signal pt_ce_n  : std_logic;
    signal nt0_ce_n : std_logic;
    signal nt1_ce_n : std_logic;
        
    signal dbg_ppu_addr_dummy               : std_logic_vector (13 downto 0);
    signal dbg_nes_x                        : std_logic_vector (8 downto 0);
    signal dbg_vga_x                        : std_logic_vector (9 downto 0);
    signal dbg_plt_addr                     : std_logic_vector (4 downto 0);
    signal dbg_plt_data                     : std_logic_vector (7 downto 0);
    signal dbg_ppu_data_dummy               : std_logic_vector (7 downto 0);
    signal dbg_ppu_status_dummy             : std_logic_vector (7 downto 0);
    signal dbg_ppu_scrl_x_dummy             : std_logic_vector (7 downto 0);
    
    

begin
    --ppu/cpu clock generator
    clock_inst : clock_divider port map 
        (base_clk, rst_n, cpu_clk, ppu_clk, mem_clk, vga_clk);

    dbg_cpu_clk <= vga_clk;
    dbg_ppu_addr <= "00000" & dbg_nes_x;
    dbg_d_io <= "000" & dbg_plt_addr;
    dbg_ppu_data <= dbg_plt_data;
    dbg_addr <= "0000000000" & vram_a;
    dbg_ppu_status <= vram_ad;
    dbg_ppu_scrl_x(0) <= ale;
    dbg_ppu_scrl_x(1) <= rd_n;
    dbg_ppu_scrl_x(2) <= wr_n;
    
    ppu_inst: ppu port map (  
        dbg_ppu_ce_n                                        ,
        dbg_ppu_ctrl, dbg_ppu_mask, dbg_ppu_status_dummy          ,
        dbg_ppu_addr_dummy                                        ,
        dbg_ppu_data_dummy, dbg_ppu_scrl_x_dummy, dbg_ppu_scrl_y        ,

        dbg_ppu_clk                      ,
        dbg_nes_x                        ,
        dbg_vga_x                        ,
        dbg_disp_nt, dbg_disp_attr                          ,
        dbg_disp_ptn_h, dbg_disp_ptn_l                      ,
        dbg_plt_addr                     ,
        dbg_plt_data                     ,
        dbg_ppu_addr_we_n                                   ,
        dbg_ppu_clk_cnt                                     ,

                ppu_clk         ,
                mem_clk     ,
                ppu_ce_n        ,
                rst_n       ,
                r_nw        ,
                cpu_addr    ,
                cpu_d       ,

                vblank_n    ,
                rd_n        ,
                wr_n        ,
                ale         ,
                vram_ad     ,
                vram_a      ,

                vga_clk     ,
                h_sync_n    ,
                v_sync_n    ,
                r           ,
                g           ,
                b           

        );

    ppu_addr_decoder : v_address_decoder generic map (vram_size14, data_size) 
        port map (ppu_clk, mem_clk, rd_n, wr_n, ale, v_addr, vram_ad, 
                nt_v_mirror, pt_ce_n, nt0_ce_n, nt1_ce_n);

    ---VRAM/CHR ROM instances
    v_addr (13 downto 8) <= vram_a;

    --transparent d-latch
    vram_latch : ls373 generic map (data_size)
                port map(ale, '0', vram_ad, v_addr(7 downto 0));

    vchr_rom : chr_rom generic map (chr_rom_8k, data_size)
            port map (mem_clk, pt_ce_n, v_addr(chr_rom_8k - 1 downto 0), vram_ad, nt_v_mirror);

    --name table/attr table
    vram_nt0 : ram generic map (vram_1k, data_size)
            port map (mem_clk, nt0_ce_n, rd_n, wr_n, v_addr(vram_1k - 1 downto 0), vram_ad);

    vram_nt1 : ram generic map (vram_1k, data_size)
            port map (mem_clk, nt1_ce_n, rd_n, wr_n, v_addr(vram_1k - 1 downto 0), vram_ad);

    --set initial vram value...
    vram_p : process (cpu_clk, rst_n)
use ieee.std_logic_arith.conv_std_logic_vector;
    variable init_step_cnt, plt_step_cnt, 
            nt_step_cnt, enable_ppu_step_cnt : integer;
    variable init_done : std_logic;
    variable global_step_cnt : integer;

procedure ppu_set (ad: in integer; dt : in integer) is
begin
    r_nw <= '0';
    ppu_ce_n <= '0';
    cpu_addr <= conv_std_logic_vector(ad, 16)(2 downto 0);
    cpu_d <= conv_std_logic_vector(dt, 8);
end;
procedure ppu_clr is
begin
    cpu_addr <= (others => 'Z');
    cpu_d <= (others => 'Z');
    r_nw <= '1';
    ppu_ce_n <= '1';
end;

    begin
        if (rst_n = '0') then
            
            r_nw <= 'Z';
            ppu_ce_n <= 'Z';
            cpu_addr <= (others => 'Z');
            cpu_d <= (others => 'Z');
            
            init_done := '0';
            global_step_cnt := 0;
            init_step_cnt := 0;
            plt_step_cnt := 0;
            nt_step_cnt := 0;
            enable_ppu_step_cnt := 0;

        elsif (rising_edge(cpu_clk)) then
            if (init_done = '0') then
                if (global_step_cnt = 0) then
                    --step0.0 = init ppu.
                    if (init_step_cnt = 0) then
                        --PPUCTRL=00
                        ppu_set(16#2000#, 16#00#);
                    elsif (init_step_cnt = 2) then
                        --PPUMASK=00
                        ppu_set(16#2001#, 16#00#);
                    else
                        ppu_clr;
                        if (init_step_cnt > 2) then
                            global_step_cnt := global_step_cnt + 1;
                        end if;
                    end if;
                    init_step_cnt := init_step_cnt + 1;

                elsif (global_step_cnt = 1) then
                    --step0.1 = palette set.
--palettes:
--;;;bg palette
--	.byte	$0f, $00, $10, $20
--	.byte	$0f, $04, $14, $24
--	.byte	$0f, $08, $18, $28
--	.byte	$0f, $0c, $1c, $2c
--;;;spr palette
--	.byte	$0f, $00, $10, $20
--	.byte	$0f, $06, $16, $26
--	.byte	$0f, $08, $18, $28
--	.byte	$0f, $0a, $1a, $2a
                    
                    
                    if (plt_step_cnt = 0) then
                        --set vram addr 3f00
                        ppu_set(16#2006#, 16#3f#);
                    elsif (plt_step_cnt = 2) then
                        ppu_set(16#2006#, 16#00#);
                    
                    elsif (plt_step_cnt = 4) then
                        --set palette data
                        ppu_set(16#2007#, 16#0f#);
                    elsif (plt_step_cnt = 6) then
                        ppu_set(16#2007#, 16#00#);
                    elsif (plt_step_cnt = 8) then
                        ppu_set(16#2007#, 16#10#);
                    elsif (plt_step_cnt = 10) then
                        ppu_set(16#2007#, 16#20#);

                    elsif (plt_step_cnt = 12) then
                        ppu_set(16#2007#, 16#0f#);
                    elsif (plt_step_cnt = 14) then
                        ppu_set(16#2007#, 16#04#);
                    elsif (plt_step_cnt = 16) then
                        ppu_set(16#2007#, 16#14#);
                    elsif (plt_step_cnt = 18) then
                        ppu_set(16#2007#, 16#24#);
 
                    elsif (plt_step_cnt = 20) then
                        ppu_set(16#2007#, 16#0f#);
                    elsif (plt_step_cnt = 22) then
                        ppu_set(16#2007#, 16#08#);
                    elsif (plt_step_cnt = 24) then
                        ppu_set(16#2007#, 16#18#);
                    elsif (plt_step_cnt = 26) then
                        ppu_set(16#2007#, 16#28#);
 
                    elsif (plt_step_cnt = 28) then
                        ppu_set(16#2007#, 16#0f#);
                    elsif (plt_step_cnt = 30) then
                        ppu_set(16#2007#, 16#0c#);
                    elsif (plt_step_cnt = 32) then
                        ppu_set(16#2007#, 16#1c#);
                    elsif (plt_step_cnt = 34) then
                        ppu_set(16#2007#, 16#2c#);
 
                    else
                        ppu_clr;
                        if (plt_step_cnt > 34) then
                            global_step_cnt := global_step_cnt + 1;
                        end if;
                    end if;
                    plt_step_cnt := plt_step_cnt + 1;
                    
                elsif (global_step_cnt = 2) then
                    --step1 = name table set.
                    if (nt_step_cnt = 0) then
                        --set vram addr 2004 (first row, 4th col)
                        ppu_set(16#2006#, 16#20#);
                    elsif (nt_step_cnt = 2) then
                        ppu_set(16#2006#, 16#04#);
                    elsif (nt_step_cnt = 4) then
                        --set name tbl data
                        --0x44, 45, 45 = DEE
                        ppu_set(16#2007#, 16#44#);
                    elsif (nt_step_cnt = 6) then
                        ppu_set(16#2007#, 16#45#);
                    elsif (nt_step_cnt = 8) then
                        ppu_set(16#2007#, 16#45#);
                    else
                        ppu_clr;
                        if (nt_step_cnt > 8) then
                            global_step_cnt := global_step_cnt + 1;
                        end if;
                    end if;
                    nt_step_cnt := nt_step_cnt + 1;
                    
                elsif (global_step_cnt = 3) then
                    --final step = enable ppu.
                    if (enable_ppu_step_cnt = 0) then
                        --show bg
                        --PPUMASK=1e (show bg and sprite)
                        --PPUMASK=0e (show bg only)
                        ppu_set(16#2001#, 16#0e#);
                    elsif (enable_ppu_step_cnt = 2) then
                        --show enable nmi
                        --PPUCTRL=80
                        ppu_set(16#2000#, 16#80#);
                    else
                        ppu_clr;
                        if (enable_ppu_step_cnt > 2) then
                            global_step_cnt := global_step_cnt + 1;
                        end if;
                    end if;
                    enable_ppu_step_cnt := enable_ppu_step_cnt + 1;

                else
                    init_done := '1';
                end if;
            end if;
        
        end if;
    end process;
            
--    signal addr : std_logic_vector( addr_size - 1 downto 0);
--    signal d_io : std_logic_vector( data_size - 1 downto 0);
--
--component counter_register
--    generic (
--        dsize       : integer := 8;
--        inc         : integer := 1
--    );
--    port (  clk         : in std_logic;
--            rst_n       : in std_logic;
--            ce_n        : in std_logic;
--            we_n        : in std_logic;
--            d           : in std_logic_vector(dsize - 1 downto 0);
--            q           : out std_logic_vector(dsize - 1 downto 0)
--    );
--end component;
--
--component prg_rom
--    generic (abus_size : integer := 15; dbus_size : integer := 8);
--    port (  clk             : in std_logic;
--            ce_n           : in std_logic;   --select pin active low.
--            addr            : in std_logic_vector (abus_size - 1 downto 0);
--            data            : inout std_logic_vector (dbus_size - 1 downto 0)
--        );
--end component;
--
--component processor_status 
--    generic (
--            dsize : integer := 8
--            );
--    port (  
--    signal dbg_dec_oe_n    : out std_logic;
--    signal dbg_dec_val     : out std_logic_vector (dsize - 1 downto 0);
--    signal dbg_int_dbus    : out std_logic_vector (dsize - 1 downto 0);
--    signal dbg_status_val    : out std_logic_vector (7 downto 0);
--    signal dbg_stat_we_n    : out std_logic;
--    
--            clk         : in std_logic;
--            res_n       : in std_logic;
--            dec_oe_n    : in std_logic;
--            bus_oe_n    : in std_logic;
--            set_flg_n   : in std_logic;
--            flg_val     : in std_logic;
--            load_bus_all_n      : in std_logic;
--            load_bus_nz_n       : in std_logic;
--            set_from_alu_n      : in std_logic;
--            alu_n       : in std_logic;
--            alu_v       : in std_logic;
--            alu_z       : in std_logic;
--            alu_c       : in std_logic;
--            stat_c      : out std_logic;
--            dec_val     : inout std_logic_vector (dsize - 1 downto 0);
--            int_dbus    : inout std_logic_vector (dsize - 1 downto 0)
--        );
--end component;
--
--    ---status register
--    signal status_reg, int_d_bus : std_logic_vector (7 downto 0);
--    signal stat_dec_oe_n : std_logic;
--    signal stat_bus_oe_n : std_logic;
--    signal stat_set_flg_n : std_logic;
--    signal stat_flg : std_logic;
--    signal stat_bus_all_n : std_logic;
--    signal stat_bus_nz_n : std_logic;
--    signal stat_alu_we_n : std_logic;
--    signal alu_n : std_logic;
--    signal alu_z : std_logic;
--    signal alu_c : std_logic;
--    signal alu_v : std_logic;
--    signal stat_c : std_logic;
--    signal trig_clk : std_logic;
--    
--    
--    
--    component alu_test
--    port (  
--        d1    : in std_logic_vector(7 downto 0);
--        d2    : in std_logic_vector(7 downto 0);
--        d_out    : out std_logic_vector(7 downto 0);
--        carry_clr_n : in std_logic;
--        ea_carry : out std_logic
--        );
--end component;
--
--    signal d1, d2, d_out : std_logic_vector (7 downto 0);
--    signal ea_carry, gate_n    : std_logic;
--        signal carry_clr_n : std_logic;


    
    
--    trig_clk <= not cpu_clk;
--
--    pcl_inst : counter_register generic map (16) port map
--        (cpu_clk, rst_n, '0', '1', (others => '0'), addr(15 downto 0));
--
--    rom_inst : prg_rom generic map (12, 8) port map
--        (base_clk, '0', addr(11 downto 0), d_io);
--
--    dbg_addr <= addr;
--    dbg_d_io <= d_io;
--
--    dbg_cpu_clk <= cpu_clk;
--    dbg_ppu_clk <= ppu_clk;
--
--    dbg_d1 <= d1;
--    dbg_d2 <= d2;
--    dbg_d_out <= d_out;
--    dbg_ea_carry <= ea_carry;
--    dbg_carry_clr_n <= carry_clr_n;
--    dbg_gate_n <= gate_n;
--    
--    dummy_alu : alu_test
--    port map (  
--        d1, d2, d_out, carry_clr_n , ea_carry
--        );
--
--        gate_n <= not ea_carry;
--    dec_test_p : process (rst_n, ea_carry, trig_clk)
--    begin
--        if (rst_n = '0') then
--            d1 <= "00000000";
--            d2 <= "00000000";
--            carry_clr_n <= '0';
--            --gate_n <= '1';
----        elsif (ea_carry = '1') then
----            gate_n <= '0';
----            carry_clr_n <= '0';
--        elsif (rising_edge(trig_clk)) then
--            if (addr(5 downto 0) = "000001") then
--            --addr=01
--                carry_clr_n <= '1';
--                d1 <= "00010011";
--                d2 <= "01000111";
--                --gate_n <= '1';
--            elsif (addr(5 downto 0) = "000010") then
--            --addr=02
--                carry_clr_n <= '1';
--                d1 <= "00110011";
--                d2 <= "11001111";
--                --gate_n <= '1';
--            elsif (addr(5 downto 0) = "000011") then
--            --addr=03
--                carry_clr_n <= '1';
--                d1 <= "00001010";
--                d2 <= "01011001";
--                --gate_n <= '1';
--            elsif (addr(5 downto 0) = "000100") then
--            --addr=04
--                carry_clr_n <= '1';
--                d1 <= "10001010";
--                d2 <= "10011001";
--                --gate_n <= '1';
--            else
--                carry_clr_n <= '1';
--                d1 <= "00000000";
--                d2 <= "00000000";
--                --gate_n <= '1';
--            end if;
--        end if;
--    end process;
--
--
--    --status register
--    status_register : processor_status generic map (8) 
--            port map (
--    dbg_dec_oe_n,
--    dbg_dec_val,
--    dbg_int_dbus,
--    dbg_status_val,
--    dbg_stat_we_n    ,
--                    trig_clk , rst_n, 
--                    stat_dec_oe_n, stat_bus_oe_n, 
--                    stat_set_flg_n, stat_flg, stat_bus_all_n, stat_bus_nz_n, 
--                    stat_alu_we_n, alu_n, alu_v, alu_z, alu_c, stat_c,
--                    status_reg, int_d_bus);
--
--    dbg_status <= status_reg;
--    status_test_p : process (addr)
--    begin
--        if (addr(5 downto 0) = "000010") then
--        --addr=02
--        --set status(7) = '1'
--            stat_dec_oe_n <= '1';
--            stat_bus_oe_n <= '1';
--            stat_set_flg_n <= '0';
--            stat_flg <= '1';
--            stat_bus_all_n <= '1';
--            stat_bus_nz_n <= '1'; 
--            stat_alu_we_n <= '1';
--            status_reg <= "01000000";
--            int_d_bus <= "00000000";
--
--        elsif (addr(5 downto 0) = "000100") then
--        --addr=04
--        --set status(2) = '0'
--            stat_dec_oe_n <= '1';
--            stat_bus_oe_n <= '1';
--            stat_set_flg_n <= '0';
--            stat_flg <= '0';
--            stat_bus_all_n <= '1';
--            stat_bus_nz_n <= '1'; 
--            stat_alu_we_n <= '1';
--            status_reg <= "00000100";
--            int_d_bus <= "00000000";
--
--        elsif (addr(5 downto 0) = "000110") then
--        --addr=06
--        --set nz from bus, n=1
--            stat_dec_oe_n <= '1';
--            stat_bus_oe_n <= '1';
--            stat_set_flg_n <= '1';
--            stat_flg <= '0';
--            stat_bus_all_n <= '1';
--            stat_bus_nz_n <= '0'; 
--            stat_alu_we_n <= '1';
--            status_reg <= (others => 'Z');
--            int_d_bus <= "10000000";
--
--        elsif (addr(5 downto 0) = "001000") then
--        --addr=08
--        --set nz from bus, z=1
--            stat_dec_oe_n <= '1';
--            stat_bus_oe_n <= '1';
--            stat_set_flg_n <= '1';
--            stat_flg <= '0';
--            stat_bus_all_n <= '1';
--            stat_bus_nz_n <= '0'; 
--            stat_alu_we_n <= '1';
--            status_reg <= (others => 'Z');
--            int_d_bus <= "00000000";
--
--        else
--            stat_dec_oe_n <= '0';
--            stat_bus_oe_n <= '1';
--            stat_set_flg_n <= '1';
--            stat_flg <= '1';
--            stat_bus_all_n <= '1';
--            stat_bus_nz_n <= '1'; 
--            stat_alu_we_n <= '1';
--            status_reg <= (others => 'Z');
--            int_d_bus <= (others => 'Z');
--        end if;
--    end process;

end rtl;

