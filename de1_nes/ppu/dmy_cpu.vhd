library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.conv_std_logic_vector;
use ieee.std_logic_unsigned.conv_integer;

entity mos6502 is 
    generic (   dsize : integer := 8;
                asize : integer :=16
            );
    port (  
    signal dbg_instruction  : out std_logic_vector(7 downto 0);
    signal dbg_int_d_bus    : out std_logic_vector(7 downto 0);
    signal dbg_exec_cycle   : out std_logic_vector (5 downto 0);
    signal dbg_ea_carry     : out std_logic;
    signal dbg_wait_a58_branch_next     : out std_logic;

--    signal dbg_index_bus    : out std_logic_vector(7 downto 0);
--    signal dbg_acc_bus      : out std_logic_vector(7 downto 0);
    signal dbg_status       : out std_logic_vector(7 downto 0);
    signal dbg_pcl, dbg_pch, dbg_sp, dbg_x, dbg_y, dbg_acc       : out std_logic_vector(7 downto 0);
    signal dbg_dec_oe_n    : out std_logic;
    signal dbg_dec_val     : out std_logic_vector (7 downto 0);
    signal dbg_int_dbus    : out std_logic_vector (7 downto 0);
--    signal dbg_status_val    : out std_logic_vector (7 downto 0);
    signal dbg_stat_we_n    : out std_logic;
    signal dbg_idl_h, dbg_idl_l, dbg_dbb_r, dbg_dbb_w    : out std_logic_vector (7 downto 0);

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

signal init_done : std_logic;
signal global_step_cnt : integer;

begin

    phi1 <= input_clk;
    phi2 <= not input_clk;

    main_p : process (input_clk, rst_n)
    variable plt_step_cnt, nt_step_cnt : integer;
    begin
        if (rst_n = '0') then
            init_done <= '0';
            global_step_cnt <= 0;
            
            r_nw <= 'Z';
            addr <= (others => 'Z');
            d_io <= (others => 'Z');
            
            plt_step_cnt := 0;
            nt_step_cnt := 0;

        elsif (rising_edge(input_clk)) then
            if (init_done = '0') then
                if (global_step_cnt = 0) then
                    --step0 = palette set.
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
                        addr <= conv_std_logic_vector(16#2006#, 16);
                        d_io <= conv_std_logic_vector(16#3f#, 8);
                        r_nw <= '0';
                        plt_step_cnt := plt_step_cnt + 1;
                    elsif (plt_step_cnt = 1) then
                        d_io <= conv_std_logic_vector(16#00#, 8);
                        plt_step_cnt := plt_step_cnt + 1;

                    elsif (plt_step_cnt = 2) then
                        addr <= conv_std_logic_vector(16#2007#, 16);
                        d_io <= conv_std_logic_vector(16#0f#, 8);
                        plt_step_cnt := plt_step_cnt + 1;
                    elsif (plt_step_cnt = 3) then
                        d_io <= conv_std_logic_vector(16#00#, 8);
                        plt_step_cnt := plt_step_cnt + 1;
                    elsif (plt_step_cnt = 4) then
                        d_io <= conv_std_logic_vector(16#10#, 8);
                        plt_step_cnt := plt_step_cnt + 1;
                    elsif (plt_step_cnt = 5) then
                        d_io <= conv_std_logic_vector(16#20#, 8);
                        plt_step_cnt := plt_step_cnt + 1;
                    
                    else
                        addr <= (others => 'Z');
                        d_io <= (others => 'Z');
                        r_nw <= '1';
                        global_step_cnt <= global_step_cnt + 1;
                    end if;
                    
                elsif (global_step_cnt = 1) then
                    --step1 = name table set.
                    
                    if (nt_step_cnt = 0) then
                        addr <= conv_std_logic_vector(16#2006#, 16);
                        d_io <= conv_std_logic_vector(16#20#, 8);
                        r_nw <= '0';
                        nt_step_cnt := nt_step_cnt + 1;
                    elsif (nt_step_cnt = 1) then
                        d_io <= conv_std_logic_vector(16#00#, 8);
                        nt_step_cnt := nt_step_cnt + 1;

                    elsif (nt_step_cnt = 2) then
                        addr <= conv_std_logic_vector(16#2007#, 16);
                        d_io <= conv_std_logic_vector(16#41#, 8);
                        nt_step_cnt := nt_step_cnt + 1;
                    elsif (nt_step_cnt = 3) then
                        d_io <= conv_std_logic_vector(16#42#, 8);
                        nt_step_cnt := nt_step_cnt + 1;
                    elsif (nt_step_cnt = 4) then
                        d_io <= conv_std_logic_vector(16#43#, 8);
                        nt_step_cnt := nt_step_cnt + 1;

                    else
                        addr <= (others => 'Z');
                        d_io <= (others => 'Z');
                        r_nw <= '1';
                        global_step_cnt <= global_step_cnt + 1;
                    end if;
                else
                    init_done <= '1';
                end if;
            end if;
        
        end if;
    end process;



end rtl;

