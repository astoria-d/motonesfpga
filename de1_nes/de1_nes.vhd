library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;

--  
--   MOTO NES FPGA On GHDL Simulation Environment Virtual Cuicuit Board
--   All of the components are assembled and instanciated on this board.
--  

entity de1_nes is 
    port (
--debug signal
    signal dbg_cpu_clk  : out std_logic;
    signal dbg_ppu_clk  : out std_logic;
    signal dbg_emu_ppu_clk  : out std_logic;
    signal dbg_cpu_mem_clk  : out std_logic;
    signal dbg_r_nw     : out std_logic;
    signal dbg_addr     : out std_logic_vector( 16 - 1 downto 0);
    signal dbg_d_io     : out std_logic_vector( 8 - 1 downto 0);
    signal dbg_vram_ad  : out std_logic_vector (7 downto 0);
    signal dbg_vram_a   : out std_logic_vector (13 downto 8);

---monitor inside cpu
    signal dbg_instruction  : out std_logic_vector(7 downto 0);
    signal dbg_int_d_bus    : out std_logic_vector(7 downto 0);
    signal dbg_exec_cycle   : out std_logic_vector (5 downto 0);
    signal dbg_ea_carry     : out std_logic;
    signal dbg_status       : out std_logic_vector(7 downto 0);
    signal dbg_sp, dbg_x, dbg_y, dbg_acc       : out std_logic_vector(7 downto 0);
    signal dbg_dec_oe_n    : out std_logic;
    signal dbg_dec_val     : out std_logic_vector (7 downto 0);

    signal dbg_int_dbus    : out std_logic_vector (7 downto 0);

--ppu debug pins
    signal dbg_ppu_ce_n    : out std_logic;
    signal dbg_ppu_ctrl, dbg_ppu_ctrl_dummy, dbg_ppu_mask, dbg_ppu_mask_dummy, dbg_ppu_status : out std_logic_vector (7 downto 0);
    signal dbg_ppu_addr : out std_logic_vector (13 downto 0);
    signal dbg_ppu_data, dbg_ppu_scrl_x, dbg_ppu_scrl_y : out std_logic_vector (7 downto 0);
    signal dbg_disp_nt, dbg_disp_attr : out std_logic_vector (7 downto 0);
    signal dbg_disp_ptn_h, dbg_disp_ptn_l : out std_logic_vector (15 downto 0);
    signal dbg_nmi  : out std_logic;
    signal dummy_nmi  : in std_logic;

--NES instance
        base_clk 	: in std_logic;
        rst_n     	: in std_logic;
        joypad1     : in std_logic_vector(7 downto 0);
        joypad2     : in std_logic_vector(7 downto 0);
        h_sync_n    : out std_logic;
        v_sync_n    : out std_logic;
        r           : out std_logic_vector(3 downto 0);
        g           : out std_logic_vector(3 downto 0);
        b           : out std_logic_vector(3 downto 0);
        nt_v_mirror : in std_logic
         );
end de1_nes;

architecture rtl of de1_nes is
    component mos6502
        generic (   dsize : integer := 8;
                    asize : integer :=16
                );
        port (  
    signal dbg_instruction  : out std_logic_vector(7 downto 0);
    signal dbg_int_d_bus  : out std_logic_vector(7 downto 0);
    signal dbg_exec_cycle      : out std_logic_vector (5 downto 0);
    signal dbg_ea_carry     : out std_logic;
    signal dbg_status       : out std_logic_vector(7 downto 0);
    signal dbg_pcl, dbg_pch, dbg_sp, dbg_x, dbg_y, dbg_acc       : out std_logic_vector(7 downto 0);
    signal dbg_dec_oe_n    : out std_logic;
    signal dbg_dec_val     : out std_logic_vector (7 downto 0);
    signal dbg_stat_we_n    : out std_logic;
    signal dbg_idl_h, dbg_idl_l     : out std_logic_vector (7 downto 0);

                cpu_clk     : in std_logic; --phi0 input pin.
                dl_cpu_clk  : in std_logic; --phi1 delayed clock.
                rdy         : in std_logic;
                rst_n       : in std_logic;
                irq_n       : in std_logic;
                nmi_n       : in std_logic;
                r_nw        : out std_logic;
                addr        : out std_logic_vector ( asize - 1 downto 0);
                d_io        : inout std_logic_vector ( dsize - 1 downto 0)
        );
    end component;

    component clock_divider
        port (  base_clk    : in std_logic;
                reset_n     : in std_logic;
                cpu_clk     : out std_logic;
                ppu_clk     : out std_logic;
                emu_ppu_clk : out std_logic;
                vga_clk     : out std_logic;
                cpu_mem_clk     : out std_logic;
                cpu_recv_clk     : out std_logic;
                emu_ppu_mem_clk : out std_logic
            );
    end component;

    component address_decoder
    generic (abus_size : integer := 16; dbus_size : integer := 8);
        port (
                addr        : in std_logic_vector (abus_size - 1 downto 0);
                rom_ce_n    : out std_logic;
                ram_ce_n    : out std_logic;
                ppu_ce_n    : out std_logic;
                apu_ce_n    : out std_logic
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

    component prg_rom
        generic (abus_size : integer := 15; dbus_size : integer := 8);
        port (
                clk             : in std_logic;
                ce_n            : in std_logic;     --active low.
                addr            : in std_logic_vector (abus_size - 1 downto 0);
                data            : out std_logic_vector (dbus_size - 1 downto 0)
        );
    end component;

    component ppu port (
        signal dbg_ppu_ce_n    : out std_logic;
        signal dbg_ppu_ctrl, dbg_ppu_mask, dbg_ppu_status : out std_logic_vector (7 downto 0);
        signal dbg_ppu_addr : out std_logic_vector (13 downto 0);
        signal dbg_ppu_data, dbg_ppu_scrl_x, dbg_ppu_scrl_y : out std_logic_vector (7 downto 0);

        signal dbg_nes_x                        : out std_logic_vector (8 downto 0);
        signal dbg_vga_x                        : out std_logic_vector (9 downto 0);
        signal dbg_nes_y                        : out std_logic_vector (8 downto 0);
        signal dbg_vga_y                        : out std_logic_vector (9 downto 0);
        signal dbg_disp_nt, dbg_disp_attr       : out std_logic_vector (7 downto 0);
        signal dbg_disp_ptn_h, dbg_disp_ptn_l   : out std_logic_vector (15 downto 0);
        signal dbg_plt_ce_rn_wn                 : out std_logic_vector (2 downto 0);
        signal dbg_plt_addr                     : out std_logic_vector (4 downto 0);
        signal dbg_plt_data                     : out std_logic_vector (7 downto 0);
        signal dbg_p_oam_ce_rn_wn               : out std_logic_vector (2 downto 0);
        signal dbg_p_oam_addr                   : out std_logic_vector (7 downto 0);
        signal dbg_p_oam_data                   : out std_logic_vector (7 downto 0);
        signal dbg_s_oam_ce_rn_wn               : out std_logic_vector (2 downto 0);
        signal dbg_s_oam_addr                   : out std_logic_vector (4 downto 0);
        signal dbg_s_oam_data                   : out std_logic_vector (7 downto 0);

        signal dbg_ppu_addr_we_n                : out std_logic;
        signal dbg_ppu_clk_cnt                  : out std_logic_vector(1 downto 0);

                ppu_clk     : in std_logic;
                vga_clk     : in std_logic;
                emu_ppu_clk : in std_logic;
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

                h_sync_n    : out std_logic;
                v_sync_n    : out std_logic;
                r           : out std_logic_vector(3 downto 0);
                g           : out std_logic_vector(3 downto 0);
                b           : out std_logic_vector(3 downto 0)
    );
    end component;

    component v_address_decoder
    generic (abus_size : integer := 14; dbus_size : integer := 8);
        port (
                v_addr      : in std_logic_vector (13 downto 0);
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
                data            : out std_logic_vector (dbus_size - 1 downto 0)
        );
    end component;

    component ls373
        generic (
            dsize : integer := 8
        );
        port (  c         : in std_logic;
                we_n      : in std_logic;
                oc_n      : in std_logic;
                d         : in std_logic_vector(dsize - 1 downto 0);
                q         : out std_logic_vector(dsize - 1 downto 0)
        );
    end component;

    component apu
        port (  clk         : in std_logic;
                ce_n        : in std_logic;
                rst_n       : in std_logic;
                r_nw        : inout std_logic;
                cpu_addr    : inout std_logic_vector (15 downto 0);
                cpu_d       : inout std_logic_vector (7 downto 0);
                rdy         : out std_logic
        );
    end component;

    constant data_size : integer := 8;
    constant addr_size : integer := 16;
    constant vram_size14    : integer := 14;

    constant ram_2k : integer := 11;      --2k = 11 bit width.
    constant rom_32k : integer := 15;     --32k = 15 bit width.
    constant rom_8k : integer := 13;     --8k = 13 bit width. (for test use)
    constant vram_1k : integer := 10;      --1k = 10 bit width.
    constant chr_rom_8k : integer := 13;     --32k = 15 bit width.

    signal cpu_clk  : std_logic;
    signal ppu_clk  : std_logic;
    signal vga_clk  : std_logic;
    signal emu_ppu_clk  : std_logic;
    signal cpu_mem_clk     : std_logic;
    signal cpu_recv_clk    : std_logic;
    signal emu_ppu_mem_clk : std_logic;

    signal rdy, irq_n, nmi_n, r_nw : std_logic;
    signal addr : std_logic_vector( addr_size - 1 downto 0);
    signal d_io : std_logic_vector( data_size - 1 downto 0);

    signal rom_ce_n : std_logic;
    signal ram_ce_n : std_logic;
    signal ram_oe_n : std_logic;
    signal ppu_ce_n : std_logic;
    signal apu_ce_n : std_logic;

    signal rd_n     : std_logic;
    signal wr_n     : std_logic;
    signal ale      : std_logic;
    signal vram_ad  : std_logic_vector (7 downto 0);
    signal vram_a   : std_logic_vector (13 downto 8);
    signal v_addr   : std_logic_vector (13 downto 0);
    signal pt_ce_n  : std_logic;
    signal nt0_ce_n : std_logic;
    signal nt1_ce_n : std_logic;

    signal ale_n       : std_logic;

--    signal dbg_disp_nt, dbg_disp_attr : std_logic_vector (7 downto 0);
--    signal dbg_disp_ptn_h, dbg_disp_ptn_l : std_logic_vector (15 downto 0);
    signal dbg_pcl, dbg_pch : std_logic_vector(7 downto 0);
    signal dbg_stat_we_n    : std_logic;
    signal dbg_idl_h, dbg_idl_l     : std_logic_vector (7 downto 0);

    signal dbg_vga_clk                      : std_logic;
    signal dbg_ppu_addr_we_n                : std_logic;
    signal dbg_ppu_clk_cnt                  : std_logic_vector(1 downto 0);
    signal dbg_ppu_addr_dummy               : std_logic_vector (13 downto 0);
    signal dbg_nes_x                        : std_logic_vector (8 downto 0);
    signal dbg_vga_x                        : std_logic_vector (9 downto 0);
    signal dbg_nes_y                        : std_logic_vector (8 downto 0);
    signal dbg_vga_y                        : std_logic_vector (9 downto 0);
    signal dbg_plt_ce_rn_wn                 : std_logic_vector (2 downto 0);
    signal dbg_plt_addr                     : std_logic_vector (4 downto 0);
    signal dbg_plt_data                     : std_logic_vector (7 downto 0);
    signal dbg_p_oam_ce_rn_wn               : std_logic_vector (2 downto 0);
    signal dbg_p_oam_addr                   : std_logic_vector (7 downto 0);
    signal dbg_p_oam_data                   : std_logic_vector (7 downto 0);
    signal dbg_s_oam_ce_rn_wn               : std_logic_vector (2 downto 0);
    signal dbg_s_oam_addr                   : std_logic_vector (4 downto 0);
    signal dbg_s_oam_data                   : std_logic_vector (7 downto 0);
    signal dbg_ppu_data_dummy               : std_logic_vector (7 downto 0);
    signal dbg_ppu_status_dummy             : std_logic_vector (7 downto 0);
    signal dbg_ppu_scrl_x_dummy             : std_logic_vector (7 downto 0);
    signal dbg_ppu_scrl_y_dummy             : std_logic_vector (7 downto 0);
    signal dbg_disp_ptn_h_dummy, dbg_disp_ptn_l_dummy   : std_logic_vector (15 downto 0);

    signal dbg_instruction_dummy  : std_logic_vector(7 downto 0);
    signal dbg_int_d_bus_dummy    : std_logic_vector(7 downto 0);
    signal dbg_exec_cycle_dummy   : std_logic_vector (5 downto 0);
    signal dbg_ea_carry_dummy     : std_logic;
    signal dbg_status_dummy       : std_logic_vector(7 downto 0);
    signal dbg_sp_dummy, dbg_x_dummy, dbg_y_dummy, dbg_acc_dummy       : std_logic_vector(7 downto 0);

begin

    irq_n <= '0';

    --ppu/cpu clock generator
    clock_inst : clock_divider port map 
        (base_clk, rst_n, cpu_clk, ppu_clk, emu_ppu_clk, vga_clk, cpu_mem_clk, cpu_recv_clk, emu_ppu_mem_clk);

    addr_dec_inst : address_decoder generic map (addr_size, data_size) 
        port map (addr, rom_ce_n, ram_ce_n, ppu_ce_n, apu_ce_n);

    --mos 6502 cpu instance
    cpu_inst : mos6502 generic map (data_size, addr_size) 
        port map (
    dbg_instruction,
    dbg_int_d_bus,
    dbg_exec_cycle,
    dbg_ea_carry,
    dbg_status,
    dbg_pcl, dbg_pch, dbg_sp, dbg_x, dbg_y, dbg_acc,
    dbg_dec_oe_n,
    dbg_dec_val,
    dbg_stat_we_n    ,
    dbg_idl_h, dbg_idl_l,

                cpu_clk, cpu_recv_clk, rdy,
                rst_n, irq_n, nmi_n, r_nw, 
                addr, d_io);

    --main ROM/RAM instance
--    prg_rom_inst : prg_rom generic map (rom_32k, data_size)
--            port map (cpu_clk, rom_ce_n, addr(rom_32k - 1 downto 0), d_io);

    prg_rom_inst : prg_rom generic map (rom_8k, data_size)
            port map (cpu_mem_clk, rom_ce_n, addr(rom_8k - 1 downto 0), d_io);

    ram_oe_n <= not R_nW;
    prg_ram_inst : ram generic map (ram_2k, data_size)
            port map (cpu_mem_clk, ram_ce_n, ram_oe_n, R_nW, addr(ram_2k - 1 downto 0), d_io);

    --nes ppu instance
    ppu_inst: ppu port map (  
        dbg_ppu_ce_n                                        ,
        dbg_ppu_ctrl_dummy, dbg_ppu_mask_dummy, dbg_ppu_status_dummy          ,
        dbg_ppu_addr_dummy                                        ,
        dbg_ppu_data_dummy, dbg_ppu_scrl_x_dummy, dbg_ppu_scrl_y_dummy        ,

        dbg_nes_x                        ,
        dbg_vga_x                        ,
        dbg_nes_y                        ,
        dbg_vga_y                        ,
        dbg_disp_nt, dbg_disp_attr                          ,
        dbg_disp_ptn_h, dbg_disp_ptn_l_dummy     ,
        dbg_plt_ce_rn_wn                 ,
        dbg_plt_addr                     ,
        dbg_plt_data                     ,
        dbg_p_oam_ce_rn_wn              ,
        dbg_p_oam_addr                  ,
        dbg_p_oam_data                  ,
        dbg_s_oam_ce_rn_wn              ,
        dbg_s_oam_addr                  ,
        dbg_s_oam_data                  ,
        dbg_ppu_addr_we_n                                   ,
        dbg_ppu_clk_cnt                                     ,

                ppu_clk         ,
                vga_clk     ,
                emu_ppu_clk     ,
                ppu_ce_n        ,
                rst_n       ,
                r_nw        ,
                addr(2 downto 0)    ,
                d_io       ,

                nmi_n    ,
                rd_n        ,
                wr_n        ,
                ale         ,
                vram_ad     ,
                vram_a      ,

                h_sync_n    ,
                v_sync_n    ,
                r           ,
                g           ,
                b           

        );

    ppu_addr_decoder : v_address_decoder generic map (vram_size14, data_size) 
        port map (v_addr, nt_v_mirror, pt_ce_n, nt0_ce_n, nt1_ce_n);

    ---VRAM/CHR ROM instances
    v_addr (13 downto 8) <= vram_a;

    --transparent d-latch
    --ale=1 >> addr latch
    --ale=0 >> addr output.
	ale_n <= not ale;
	vram_latch : ls373 generic map (data_size)
                port map(vga_clk, ale_n, ale, vram_ad, v_addr(7 downto 0));

    vchr_rom : chr_rom generic map (chr_rom_8k, data_size)
            port map (emu_ppu_clk, pt_ce_n, v_addr(chr_rom_8k - 1 downto 0), vram_ad);

    --name table/attr table
    vram_nt0 : ram generic map (vram_1k, data_size)
            port map (emu_ppu_clk, nt0_ce_n, rd_n, wr_n, v_addr(vram_1k - 1 downto 0), vram_ad);

    vram_nt1 : ram generic map (vram_1k, data_size)
            port map (emu_ppu_clk, nt1_ce_n, rd_n, wr_n, v_addr(vram_1k - 1 downto 0), vram_ad);

    --APU/DMA instance
    apu_inst : apu
        port map (cpu_clk, apu_ce_n, rst_n, r_nw, addr, d_io, rdy);



-----------------------------------------------------------
-----------------------------------------------------------
------------------debug pin setting....--------------------    
-----------------------------------------------------------
-----------------------------------------------------------

    --ppu debug....
--    dbg_exec_cycle(0) <= dbg_nes_x(8);
--    dbg_instruction <= dbg_nes_x(7 downto 0);
--    dbg_exec_cycle(4) <= dbg_nes_y(8);
--    dbg_status <= dbg_nes_y(7 downto 0);
--    dbg_sp(7 downto 6) <= dbg_ppu_clk_cnt;
--
--    dbg_disp_ptn_l (7 downto 0) <= dbg_p_oam_addr;
--    dbg_disp_ptn_l (15 downto 8) <= dbg_p_oam_data;
--    dbg_int_d_bus(4 downto 0) <= dbg_s_oam_addr(4 downto 0);
--    dbg_ppu_scrl_y <= dbg_s_oam_data;
--
--    dbg_ppu_scrl_x(0) <= ale;
--    dbg_ppu_scrl_x(1) <= rd_n;
--    dbg_ppu_scrl_x(2) <= wr_n;
--    dbg_ppu_scrl_x(3) <= nt0_ce_n;

--    nmi_n <= dummy_nmi;
    ---------------

    ----general...
    dbg_cpu_clk <= cpu_clk;
    dbg_ppu_clk <= ppu_clk;
    dbg_emu_ppu_clk <= emu_ppu_clk;
    dbg_cpu_mem_clk <= cpu_mem_clk;
    dbg_vga_clk <= vga_clk;
    dbg_r_nw <= r_nw;
    dbg_addr <= addr;
    dbg_d_io <= d_io;
    dbg_vram_ad  <= vram_ad ;
    dbg_vram_a  <= vram_a ;
    dbg_nmi <= nmi_n;

    ----cpu...
    dbg_ppu_ctrl <= dbg_pcl;
    dbg_ppu_data <= dbg_idl_l;
    dbg_ppu_mask <= dbg_idl_h;

end rtl;

