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

constant cpu_io_multi   : integer := 3; --io happens every 4 cpu cycle.
constant bg_tile_cnt    : integer := 1023;
constant spr_tile_cnt    : integer := 255;
    
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

type nes_spr_array    is array (0 to 255) of integer;
constant nes_spr_data : nes_spr_array := (
16#18#, 16#ff#, 16#23#, 16#58#, 16#b0#, 16#fc#, 16#00#, 16#28#, 16#b0#, 16#fc#, 16#00#, 16#30#, 16#b8#, 16#fc#, 16#00#, 16#28#,
16#b8#, 16#fc#, 16#00#, 16#30#, 16#c0#, 16#3a#, 16#00#, 16#28#, 16#c0#, 16#37#, 16#00#, 16#30#, 16#c8#, 16#4f#, 16#00#, 16#28#,
16#c8#, 16#4f#, 16#40#, 16#30#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#,
16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#,
16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#,
16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#,
16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#,
16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#,
16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#,
16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#,
16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#,
16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#,
16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#,
16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#,
16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#,
16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#, 16#f8#, 16#00#, 16#00#, 16#00#
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

    variable init_plt_cnt : integer;
    variable init_vram_cnt : integer;
    variable init_spr_cnt : integer;
    variable init_final_cnt : integer;
    variable nmi_step_cnt : integer;
    variable global_step_cnt : integer;
    variable nmi_handled : integer;
    variable nmi_cnt : integer;

    variable spr_x : integer;
    variable spr_y : integer;
    variable scr_x : integer;

procedure io_out (ad: in integer; dt : in integer) is
begin

----real cpu implementation..
----ST_SUB00, ST_SUB01, ST_SUB02, ST_SUB03,
----ST_SUB10, ST_SUB11, ST_SUB12, ST_SUB13,
----ST_SUB20, ST_SUB21, ST_SUB22, ST_SUB23,
----ST_SUB30, ST_SUB31, ST_SUB32, ST_SUB33,
----ST_SUB40, ST_SUB41, ST_SUB42, ST_SUB43,
----ST_SUB50, ST_SUB51, ST_SUB52, ST_SUB53,
----ST_SUB60, ST_SUB61, ST_SUB62, ST_SUB63,
----ST_SUB70, ST_SUB71, ST_SUB72, ST_SUB73
----procedure write_enable is
----begin
----    reg_oe_n    <= '1';
----    if (reg_sub_state = ST_SUB32 or
----        reg_sub_state = ST_SUB33 or
----        reg_sub_state = ST_SUB40 or
----        reg_sub_state = ST_SUB41
----        ) then
----        reg_we_n    <= '0';
----    else
----        reg_we_n    <= '1';
----    end if;
----end;


    reg_oe_n <= '1';
    if (pi_cpu_en(0) = '1') then
        reg_we_n <= '1';
    elsif (pi_cpu_en(3) = '1') then
        reg_we_n <= '0';
    elsif (pi_cpu_en(5) = '1') then
        reg_we_n <= '1';
    end if;
    reg_addr <= conv_std_logic_vector(ad, 16);
    reg_d_out <= conv_std_logic_vector(dt, 8);
end;

procedure io_brk is
use ieee.std_logic_unsigned.all;
begin
    --fake ram read/write to emulate dummy i/o.
    reg_d_out <= (others => 'Z');
    reg_addr <= (others => 'Z');
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

function cnt_next (
    pr_cpu_en   : in std_logic_vector (7 downto 0);
    val         : in integer;
    step        : in integer) return integer is
begin
    if (pr_cpu_en(0) = '1') then
        return val + step;
    else
        return val;
    end if;
end;

    begin
        if (pi_rst_n = '0') then
            
            reg_oe_n <= 'Z';
            reg_we_n <= 'Z';
            reg_addr <= (others => 'Z');
            reg_d_out <= (others => 'Z');
            
            global_step_cnt := 0;
            init_plt_cnt := 0;
            init_vram_cnt := 0;
            init_spr_cnt := 0;
            init_final_cnt := 0;
            spr_x := 16#28#;
            spr_y := 16#c8#;
            scr_x := 0;
            nmi_step_cnt := 0;
            nmi_handled := 0;
            nmi_cnt := 0;

        elsif (rising_edge(pi_base_clk)) then
            if (pi_rdy = '1') then
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
                            global_step_cnt := cnt_next(pi_cpu_en, global_step_cnt, 1);
                        end if;
                    end if;
                    init_plt_cnt := cnt_next(pi_cpu_en, init_plt_cnt, 1);

                elsif (global_step_cnt = 1) then
                        --set vram addr 2000
                    if (init_vram_cnt = 0* cpu_io_multi) then
                        io_out(16#2006#, 16#20#);
                    elsif (init_vram_cnt = 1 * cpu_io_multi) then
                        io_out(16#2006#, 16#00#);

                    elsif (init_vram_cnt mod cpu_io_multi = 0 and init_vram_cnt <= (bg_tile_cnt + 2) * cpu_io_multi) then
                        --ppuaddr
                        io_out(16#2007#, nes_bg_data(init_vram_cnt / cpu_io_multi - 2));

                    else
                        io_read(16#00#);
                        if (init_vram_cnt > (bg_tile_cnt + 2) * cpu_io_multi) then
                            global_step_cnt := cnt_next(pi_cpu_en, global_step_cnt, 1);
                        end if;
                    end if;
                    init_vram_cnt := cnt_next(pi_cpu_en, init_vram_cnt, 1);

                elsif (global_step_cnt = 2) then
                    --set dma data.
                    --dma addr = 0x0300.
                    if (init_spr_cnt mod cpu_io_multi = 0 and init_spr_cnt <= (spr_tile_cnt + 0) * cpu_io_multi) then
                        io_out(16#0300# + init_spr_cnt / cpu_io_multi, nes_spr_data(init_spr_cnt / cpu_io_multi));

                    elsif (init_spr_cnt = (spr_tile_cnt + 1) * cpu_io_multi) then
                        --dma start.
                        io_out(16#4014#, 3);

                    else
                        io_read(16#00#);
                        if (init_spr_cnt > (spr_tile_cnt + 2) * cpu_io_multi) then
                            global_step_cnt := cnt_next(pi_cpu_en, global_step_cnt, 1);
                        end if;
                    end if;
                    init_spr_cnt := cnt_next(pi_cpu_en, init_spr_cnt, 1);

                elsif (global_step_cnt = 3) then
                    --enable bg.
                    if (init_final_cnt = 0 * cpu_io_multi) then
                        --show bg
                        --PPUMASK=1e (show bg and sprite)
                        --PPUMASK=0e (show bg only)
                        io_out(16#2001#, 16#1e#);
                    elsif (init_final_cnt = 1 * cpu_io_multi) then
                        --enable nmi
                        --bg base = 0x1000
                        --PPUCTRL=90
                        io_out(16#2000#, 16#90#);
                    else
                        io_read(16#00#);
                        if (init_final_cnt > 2 * cpu_io_multi) then
                            global_step_cnt := cnt_next(pi_cpu_en, global_step_cnt, 1);
                        end if;
                    end if;
                    init_final_cnt := cnt_next(pi_cpu_en, init_final_cnt, 1);

                else
                --nmi
                    if (pi_nmi_n = '0' and nmi_handled = 0) then

                        --stop ppu.
                        if (nmi_step_cnt = 0 * cpu_io_multi) then
                            io_out(16#2001#, 0);
                        elsif (nmi_step_cnt = 1 * cpu_io_multi) then
                            io_out(16#2000#, 0);

                        --sprite x,y change.
                        elsif (nmi_step_cnt = 2 * cpu_io_multi) then
                            io_out(16#0314#, (spr_y) mod 255);
                        elsif (nmi_step_cnt = 3 * cpu_io_multi) then
                            io_out(16#0317#, (spr_x) mod 255);

                        elsif (nmi_step_cnt = 4 * cpu_io_multi) then
                            io_out(16#0318#, (spr_y) mod 255);
                        elsif (nmi_step_cnt = 5 * cpu_io_multi) then
                            io_out(16#031b#, (spr_x + 8) mod 255);

                        elsif (nmi_step_cnt = 6 * cpu_io_multi) then
                            io_out(16#031c#, (spr_y  + 8) mod 255);
                        elsif (nmi_step_cnt = 7 * cpu_io_multi) then
                            io_out(16#031f#, (spr_x) mod 255);

                        elsif (nmi_step_cnt = 8 * cpu_io_multi) then
                            io_out(16#0320#, (spr_y  + 8) mod 255);
                        elsif (nmi_step_cnt = 9 * cpu_io_multi) then
                            io_out(16#0323#, (spr_x + 8) mod 255);

                        elsif (nmi_step_cnt = 10 * cpu_io_multi) then
                            --dma start.
                            io_out(16#4014#, 3);
                            if (nmi_cnt mod 10 = 0) then
                                spr_x := cnt_next(pi_cpu_en, spr_x, 3);
                                spr_y := cnt_next(pi_cpu_en, spr_y, 1);
                            end if;

                        --scroll
                        elsif (nmi_step_cnt = 11 * cpu_io_multi) then
                            io_out(16#2005#, (scr_x) mod 255);
                            scr_x := cnt_next(pi_cpu_en, scr_x, 3);
                        elsif (nmi_step_cnt = 12 * cpu_io_multi) then
                            io_out(16#2005#, 0);

                        --enable ppu
                        elsif (nmi_step_cnt = 13 * cpu_io_multi) then
                            io_out(16#2001#, 16#1e#);
                        elsif (nmi_step_cnt = 14 * cpu_io_multi) then
                            io_out(16#2000#, 16#90#);
                            if (nmi_cnt = 59) then
                                nmi_cnt := 0;
                            else
                                nmi_cnt := cnt_next(pi_cpu_en, nmi_cnt, 1);
                            end if;

                        else
                            io_read(16#00#);
                        end if;
                        nmi_step_cnt := cnt_next(pi_cpu_en, nmi_step_cnt, 1);
                    else
                        if (pi_nmi_n = '1' and  nmi_handled = 1) then
                            nmi_handled := 0;
                        end if;
                        nmi_step_cnt := 0;
                        io_read(16#00#);
                    end if;--if (pi_nmi_n = '0' and nmi_handled = 0) then

                end if;--if (global_step_cnt = 0) then
            else
                io_brk;
            end if;--if (rdy = '1') then
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
            if (pi_ce_n = '0' and pi_oe_n = '0') then
                ---dummy data.
                po_data <= "00110011";
            else
                po_data <= (others => 'Z');
            end if;
        end if;
    end process;

end rtl;

