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

    signal dbg_status       : out std_logic_vector(7 downto 0);
    signal dbg_dec_oe_n    : out std_logic;
    signal dbg_dec_val     : out std_logic_vector (7 downto 0);
    signal dbg_int_dbus    : out std_logic_vector (7 downto 0);
    signal dbg_status_val    : out std_logic_vector (7 downto 0);
    signal dbg_stat_we_n    : out std_logic;
    
---monitor inside cpu
    signal dbg_d1, dbg_d2, dbg_d_out: out std_logic_vector (7 downto 0);
    signal dbg_ea_carry, dbg_carry_clr_n    : out std_logic;
    signal dbg_gate_n    : out std_logic;


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

    component dummy_ppu
        port (  ppu_clk     : in std_logic;
                rst_n       : in std_logic;
                pos_x       : out std_logic_vector (8 downto 0);
                pos_y       : out std_logic_vector (8 downto 0);
                nes_r       : out std_logic_vector (3 downto 0);
                nes_g       : out std_logic_vector (3 downto 0);
                nes_b       : out std_logic_vector (3 downto 0)
        );
    end component;

    component vga_clk_gen
        PORT
        (
            inclk0		: IN STD_LOGIC  := '0';
            c0		: OUT STD_LOGIC ;
            c1		: OUT STD_LOGIC ;
            locked		: OUT STD_LOGIC 
        );
    end component;

signal pos_x       : std_logic_vector (8 downto 0);
signal pos_y       : std_logic_vector (8 downto 0);
signal nes_r       : std_logic_vector (3 downto 0);
signal nes_g       : std_logic_vector (3 downto 0);
signal nes_b       : std_logic_vector (3 downto 0);

component vga_ctl
    port (  ppu_clk     : in std_logic;
            vga_clk     : in std_logic;
            rst_n       : in std_logic;
            pos_x       : in std_logic_vector (8 downto 0);
            pos_y       : in std_logic_vector (8 downto 0);
            nes_r       : in std_logic_vector (3 downto 0);
            nes_g       : in std_logic_vector (3 downto 0);
            nes_b       : in std_logic_vector (3 downto 0);
            h_sync_n    : out std_logic;
            v_sync_n    : out std_logic;
            r           : out std_logic_vector(3 downto 0);
            g           : out std_logic_vector(3 downto 0);
            b           : out std_logic_vector(3 downto 0)
    );
end component;

    constant data_size : integer := 8;
    constant addr_size : integer := 16;
    constant size14    : integer := 14;

    signal cpu_clk  : std_logic;
    signal ppu_clk  : std_logic;
    signal mem_clk   : std_logic;
    signal vga_clk   : std_logic;
    signal vga_clk_pll, sdram_clk : std_logic;
    signal pll_locked   : std_logic;

begin
    --ppu/cpu clock generator
    clock_inst : clock_divider port map 
        (base_clk, rst_n, cpu_clk, ppu_clk, mem_clk, vga_clk);

    ppu_inst: dummy_ppu 
        port map (  ppu_clk     ,
                rst_n       ,
                pos_x       ,
                pos_y       ,
                nes_r       ,
                nes_g       ,
                nes_b       
        );

        vga_clk_gen_inst : vga_clk_gen
        PORT map
        (
            --mem_clk_pll = 160 MHz.
            base_clk, vga_clk_pll, sdram_clk, pll_locked
        );
    --- testbench pll clock..
--    dummy_clock_p: process
--    begin
--        sdram_clk <= '1';
--        wait for 6250 ps / 2;
--        sdram_clk <= '0';
--        wait for 6250 ps / 2;
--    end process;

    
    vga_ctl_inst : vga_ctl
    port map (  ppu_clk     ,
            --vga_clk_pll, 
            --ppu_clk ,
            vga_clk     ,
            rst_n       ,
            pos_x       ,
            pos_y       ,
            nes_r       ,
            nes_g       ,
            nes_b       ,
            h_sync_n    ,
            v_sync_n    ,
            r           ,
            g           ,
            b           
    );

   
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

