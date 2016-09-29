library ieee;
use ieee.std_logic_1164.all;

entity mos6502 is 
    port (  
            pi_rst_n       : in std_logic;
            pi_base_clk 	: in std_logic;
            pi_cpu_en       : in std_logic_vector (7 downto 0);
            pi_rdy         : in std_logic;
            pi_irq_n       : in std_logic;
            pi_nmi_n       : in std_logic;
            po_oe_n        : out std_logic;
            po_we_n        : out std_logic;
            po_addr        : out std_logic_vector ( 15 downto 0);
            pio_d_io       : inout std_logic_vector ( 7 downto 0);

            --for debugging..
            po_dbg_cnt     : out std_logic_vector (63 downto 0);
            po_exc_cnt     : out std_logic_vector (63 downto 0)
    );
end mos6502;

architecture rtl of mos6502 is

signal reg_oe_n     : std_logic;
signal reg_we_n     : std_logic;
signal reg_addr     : std_logic_vector ( 15 downto 0);
signal reg_d_in     : std_logic_vector ( 7 downto 0);
signal reg_d_out    : std_logic_vector ( 7 downto 0);



type nes_plt_array    is array (0 to 31) of integer;

constant nes_palette_data : nes_plt_array := (
16#22#, 16#29#, 16#1a#, 16#0f#, 16#0f#, 16#36#, 16#17#, 16#0f#, 16#0f#, 16#30#, 16#21#, 16#0f#, 16#0f#, 16#27#, 16#17#, 16#0f#,
16#22#, 16#16#, 16#27#, 16#18#, 16#0f#, 16#1a#, 16#30#, 16#27#, 16#0f#, 16#16#, 16#30#, 16#27#, 16#0f#, 16#0f#, 16#36#, 16#17#
);

type nes_bg_array    is array (0 to 1023) of integer;
constant nes_bg_data : nes_bg_array := (
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#16#, 16#0a#, 16#1b#, 16#12#, 16#18#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#20#, 16#18#, 16#1b#, 16#15#, 16#0d#, 16#24#, 16#24#, 16#1d#, 16#12#, 16#16#, 16#0e#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#00#, 16#00#, 16#00#, 16#00#, 16#00#, 16#00#, 16#24#, 16#24#, 16#2e#, 16#29#, 16#00#, 16#00#, 16#24#,
16#24#, 16#24#, 16#24#, 16#01#, 16#28#, 16#01#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#44#, 16#48#, 16#48#, 16#48#, 16#48#, 16#48#, 16#48#, 16#48#, 16#48#, 16#48#, 16#48#,
16#48#, 16#48#, 16#48#, 16#48#, 16#48#, 16#48#, 16#48#, 16#48#, 16#48#, 16#48#, 16#49#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#46#, 16#d0#, 16#d1#, 16#d8#, 16#d8#, 16#de#, 16#d1#, 16#d0#, 16#da#, 16#de#, 16#d1#,
16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#4a#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#46#, 16#d2#, 16#d3#, 16#db#, 16#db#, 16#db#, 16#d9#, 16#db#, 16#dc#, 16#db#, 16#df#,
16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#4a#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#46#, 16#d4#, 16#d5#, 16#d4#, 16#d9#, 16#db#, 16#e2#, 16#d4#, 16#da#, 16#db#, 16#e0#,
16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#4a#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#46#, 16#d6#, 16#d7#, 16#d6#, 16#d7#, 16#e1#, 16#26#, 16#d6#, 16#dd#, 16#e1#, 16#e1#,
16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#4a#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#46#, 16#d0#, 16#e8#, 16#d1#, 16#d0#, 16#d1#, 16#de#, 16#d1#, 16#d8#, 16#d0#, 16#d1#,
16#26#, 16#de#, 16#d1#, 16#de#, 16#d1#, 16#d0#, 16#d1#, 16#d0#, 16#d1#, 16#26#, 16#4a#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#46#, 16#db#, 16#42#, 16#42#, 16#db#, 16#42#, 16#db#, 16#42#, 16#db#, 16#db#, 16#42#,
16#26#, 16#db#, 16#42#, 16#db#, 16#42#, 16#db#, 16#42#, 16#db#, 16#42#, 16#26#, 16#4a#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#46#, 16#db#, 16#db#, 16#db#, 16#db#, 16#db#, 16#db#, 16#df#, 16#db#, 16#db#, 16#db#,
16#26#, 16#db#, 16#df#, 16#db#, 16#df#, 16#db#, 16#db#, 16#e4#, 16#e5#, 16#26#, 16#4a#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#46#, 16#db#, 16#db#, 16#db#, 16#de#, 16#43#, 16#db#, 16#e0#, 16#db#, 16#db#, 16#db#,
16#26#, 16#db#, 16#e3#, 16#db#, 16#e0#, 16#db#, 16#db#, 16#e6#, 16#e3#, 16#26#, 16#4a#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#46#, 16#db#, 16#db#, 16#db#, 16#db#, 16#42#, 16#db#, 16#db#, 16#db#, 16#d4#, 16#d9#,
16#26#, 16#db#, 16#d9#, 16#db#, 16#db#, 16#d4#, 16#d9#, 16#d4#, 16#d9#, 16#e7#, 16#4a#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#5f#, 16#95#, 16#95#, 16#95#, 16#95#, 16#95#, 16#95#, 16#95#, 16#95#, 16#97#, 16#98#,
16#78#, 16#95#, 16#96#, 16#95#, 16#95#, 16#97#, 16#98#, 16#97#, 16#98#, 16#95#, 16#7a#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#cf#, 16#01#, 16#09#,
16#08#, 16#05#, 16#24#, 16#17#, 16#12#, 16#17#, 16#1d#, 16#0e#, 16#17#, 16#0d#, 16#18#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#ce#, 16#24#, 16#01#, 16#24#, 16#19#, 16#15#, 16#0a#,
16#22#, 16#0e#, 16#1b#, 16#24#, 16#10#, 16#0a#, 16#16#, 16#0e#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#02#, 16#24#, 16#19#, 16#15#, 16#0a#,
16#22#, 16#0e#, 16#1b#, 16#24#, 16#10#, 16#0a#, 16#16#, 16#0e#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#31#, 16#32#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#30#, 16#26#, 16#34#, 16#33#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#30#, 16#26#, 16#26#, 16#26#, 16#26#, 16#33#, 16#24#, 16#24#, 16#24#, 16#24#, 16#1d#, 16#18#, 16#19#, 16#28#,
16#24#, 16#00#, 16#00#, 16#00#, 16#00#, 16#00#, 16#00#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#30#, 16#26#, 16#34#, 16#26#, 16#26#, 16#34#, 16#26#, 16#33#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#36#, 16#37#, 16#36#, 16#37#, 16#36#, 16#37#, 16#24#, 16#24#,
16#30#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#26#, 16#33#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#,
16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#24#, 16#35#, 16#25#, 16#25#, 16#25#, 16#25#, 16#25#, 16#25#, 16#38#, 16#24#,
16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#,
16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#,
16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#,
16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#,
16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#,
16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#, 16#b4#, 16#b5#,
16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#,
16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#, 16#b6#, 16#b7#,
16#aa#, 16#aa#, 16#ea#, 16#aa#, 16#aa#, 16#aa#, 16#aa#, 16#aa#, 16#00#, 16#55#, 16#55#, 16#55#, 16#55#, 16#55#, 16#55#, 16#55#,
16#55#, 16#55#, 16#55#, 16#55#, 16#55#, 16#55#, 16#55#, 16#55#, 16#55#, 16#55#, 16#55#, 16#55#, 16#55#, 16#55#, 16#55#, 16#00#,
16#00#, 16#00#, 16#99#, 16#aa#, 16#aa#, 16#aa#, 16#00#, 16#00#, 16#00#, 16#00#, 16#99#, 16#aa#, 16#aa#, 16#aa#, 16#00#, 16#00#,
16#50#, 16#50#, 16#50#, 16#50#, 16#50#, 16#50#, 16#50#, 16#50#, 16#05#, 16#05#, 16#05#, 16#05#, 16#05#, 16#05#, 16#05#, 16#05#
);

begin

    po_oe_n     <= reg_oe_n;
    po_we_n     <= reg_we_n;
    po_addr     <= reg_addr;
    pio_d_io    <= reg_d_out;
    reg_d_in    <= pio_d_io;

    --set ppu value...
    set_ppu_p : process (pi_base_clk, pi_rst_n)
    use ieee.std_logic_arith.conv_std_logic_vector;

    constant cpu_io_multi : integer := 3; --io happens every 4 cpu cycle.
    variable init_plt_cnt : integer;
    variable init_vram_cnt : integer;
    variable init_final_cnt : integer;
    variable init_done : std_logic;
    variable global_step_cnt : integer;

    variable ref_cnt : integer range 0 to 120;

procedure io_out (ad: in integer; dt : in integer) is
begin
    reg_oe_n <= '1';
    reg_we_n <= '0';
    reg_addr <= conv_std_logic_vector(ad, 16);
    reg_d_out <= conv_std_logic_vector(dt, 8);
end;

procedure io_brk is
use ieee.std_logic_unsigned.all;
begin
    --fake ram read/write to emulate dummy i/o.
    reg_d_out <= (others => 'Z');
    reg_oe_n <= 'Z';
    reg_we_n <= 'Z';
end;

procedure io_read (ad: in integer) is
begin
    reg_oe_n <= '0';
    reg_we_n <= '1';
    reg_addr <= conv_std_logic_vector(ad, 16);
    reg_d_out <= (others => 'Z');
end;

    begin
        if (pi_rst_n = '0') then
            
            reg_oe_n <= '1';
            reg_we_n <= '1';
            reg_addr <= (others => 'Z');
            reg_d_out <= (others => 'Z');
            
            init_done := '0';
            global_step_cnt := 0;
            init_plt_cnt := 0;
            init_vram_cnt := 0;
            init_final_cnt := 0;

        elsif (rising_edge(pi_base_clk)) then
            if (pi_cpu_en(0) = '1') then
            if (pi_rdy = '1') then
                if (init_done = '0') then
                    if (global_step_cnt = 0) then
                        --step0.0 = init ppu.
                        if (init_plt_cnt = 0 * cpu_io_multi) then
                            --PPUCTRL=00
                            io_out(16#2000#, 16#00#);
                        elsif (init_plt_cnt = 1 * cpu_io_multi) then
                            --PPUMASK=00
                            io_out(16#2001#, 16#00#);

                            --set vram addr 3f00
                        elsif (init_plt_cnt = 2 * cpu_io_multi) then
                            io_out(16#2006#, 16#3f#);
                        elsif (init_plt_cnt = 3 * cpu_io_multi) then
                            io_out(16#2006#, 16#00#);

                        elsif (init_plt_cnt mod cpu_io_multi = 0 and init_plt_cnt <= (32 + 4) * cpu_io_multi) then
                            --ppuaddr
                            io_out(16#2007#, nes_palette_data(init_plt_cnt / cpu_io_multi - 4));

                        else
                            io_read(16#00#);
                            if (init_plt_cnt > (32 + 3) * cpu_io_multi) then
                                global_step_cnt := global_step_cnt + 1;
                            end if;
                        end if;
                        init_plt_cnt := init_plt_cnt + 1;

                    elsif (global_step_cnt = 1) then
                            --set vram addr 2000
                        if (init_vram_cnt = 0* cpu_io_multi) then
                            io_out(16#2006#, 16#20#);
                        elsif (init_vram_cnt = 1 * cpu_io_multi) then
                            io_out(16#2006#, 16#00#);

                        elsif (init_vram_cnt mod cpu_io_multi = 0 and init_vram_cnt <= (1023 + 2) * cpu_io_multi) then
                            --ppuaddr
                            io_out(16#2007#, nes_bg_data(init_vram_cnt / cpu_io_multi - 2));

                        else
                            io_read(16#00#);
                            if (init_vram_cnt > (1023 + 2) * cpu_io_multi) then
                                global_step_cnt := global_step_cnt + 1;
                            end if;
                        end if;
                        init_vram_cnt := init_vram_cnt + 1;

                    elsif (global_step_cnt = 2) then
                        --enable bg.
                        if (init_final_cnt = 0 * cpu_io_multi) then
                            --show bg
                            --PPUMASK=1e (show bg and sprite)
                            --PPUMASK=0e (show bg only)
                            io_out(16#2001#, 16#1e#);
                        elsif (init_final_cnt = 1 * cpu_io_multi) then
                            --enable nmi
                            --PPUCTRL=80
                            io_out(16#2000#, 16#80#);
                        else
                            io_read(16#00#);
                            if (init_final_cnt > 2 * cpu_io_multi) then
                                global_step_cnt := global_step_cnt + 1;
                            end if;
                        end if;
                        init_final_cnt := init_final_cnt + 1;

                    end if;
                else
                    io_read(16#00#);
                end if;--if (init_done = '0') then
            else
                io_brk;
            end if;--if (rdy = '1') then
            end if;--if (pi_cpu_en(0) = '1') then
        end if; --if (rst_n = '0') then
    end process;

end rtl;





-----------dummy prg rom
library ieee;
use ieee.std_logic_1164.all;
entity prg_rom is 
    port (
            pi_base_clk 	: in std_logic;
            pi_ce_n         : in std_logic;
            pi_oe_n         : in std_logic;
            pi_addr         : in std_logic_vector (14 downto 0);
            po_data         : out std_logic_vector (7 downto 0)
        );
end prg_rom;
architecture rtl of prg_rom is
begin
    p_read : process (pi_base_clk)
    begin
        if (rising_edge(pi_base_clk)) then
            if (pi_ce_n = '0') then
                ---dummy data.
                po_data <= "00110011";
            else
                po_data <= (others => 'Z');
            end if;
        end if;
    end process;

end rtl;



-----------dummy apu
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.conv_std_logic_vector;

entity apu is 
    port (
        pi_rst_n       : in std_logic;
        pi_base_clk    : in std_logic;
        pi_cpu_en      : in std_logic_vector (7 downto 0);
        pi_rnd_en      : in std_logic_vector (3 downto 0);
        pi_ce_n        : in std_logic;

        --cpu i/f
        pio_oe_n       : inout std_logic;
        pio_we_n       : inout std_logic;
        pio_cpu_addr   : inout std_logic_vector (15 downto 0);
        pio_cpu_d      : inout std_logic_vector (7 downto 0);
        po_rdy         : out std_logic;

        --sprite i/f
        po_spr_ce_n    : out std_logic;
        po_spr_rd_n    : out std_logic;
        po_spr_wr_n    : out std_logic;
        po_spr_addr    : out std_logic_vector (7 downto 0);
        po_spr_data    : out std_logic_vector (7 downto 0)
    );
end apu;

architecture rtl of apu is
begin
    pio_oe_n       <= 'Z';
    pio_we_n       <= 'Z';
    pio_cpu_addr   <= (others => 'Z');
    pio_cpu_d      <= (others => 'Z');
    po_rdy         <= '1';
    po_spr_ce_n    <= 'Z';
    po_spr_rd_n    <= 'Z';
    po_spr_wr_n    <= 'Z';
    po_spr_addr    <= (others => 'Z');
    po_spr_data    <= (others => 'Z');
end rtl;
