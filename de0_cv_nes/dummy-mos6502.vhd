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
            po_r_nw        : out std_logic;
            po_addr        : out std_logic_vector ( 15 downto 0);
            pio_d_io       : inout std_logic_vector ( 7 downto 0)
    );
end mos6502;

architecture rtl of mos6502 is


begin

    --set ppu value...
    set_ppu_p : process (pi_base_clk, pi_rst_n)
    use ieee.std_logic_arith.conv_std_logic_vector;

    variable init_step_cnt, plt_step_cnt, 
            nt_step_cnt, spr_step_cnt, dma_step_cnt, scl_step_cnt, 
            enable_ppu_step_cnt, nmi_step_cnt : integer;
    variable init_done : std_logic;
    variable global_step_cnt : integer;
    constant cpu_io_multi : integer := 3; --io happens every 4 cpu cycle.
    variable i, j : integer;
    variable ch : integer := 16#41# ;
    variable nmi_oam_x : integer range 0 to 255;
    variable nmi_scl_y : integer range 0 to 255;

    variable ref_cnt : integer range 0 to 120;

procedure io_out (ad: in integer; dt : in integer) is
begin
    po_r_nw <= '0';
    po_addr <= conv_std_logic_vector(ad, 16);
    pio_d_io <= conv_std_logic_vector(dt, 8);
end;

procedure io_brk is
begin
    po_addr <= (others => 'Z');
    pio_d_io <= (others => 'Z');
    po_r_nw <= 'Z';
end;

procedure io_read (ad: in integer) is
begin
    po_r_nw <= '1';
    po_addr <= conv_std_logic_vector(ad, 16);
    pio_d_io <= (others => 'Z');
end;

    begin
        if (pi_rst_n = '0') then
            
            po_r_nw <= 'Z';
            po_addr <= (others => 'Z');
            pio_d_io <= (others => 'Z');
            
            init_done := '0';
            global_step_cnt := 0;
            init_step_cnt := 0;
            plt_step_cnt := 0;
            nt_step_cnt := 0;
            spr_step_cnt := 0;
            dma_step_cnt := 0;
            scl_step_cnt := 0;
            enable_ppu_step_cnt := 0;
            nmi_step_cnt := 0;
            nmi_oam_x := 0;
            nmi_scl_y := 200;
            ref_cnt := 0;

        elsif (rising_edge(pi_base_clk)) then
            if (pi_cpu_en(0) = '1') then
            if (pi_rdy = '1') then
                if (init_done = '0') then
                    if (global_step_cnt = 0) then
                        --step0.0 = init ppu.
                        if (init_step_cnt = 0 * cpu_io_multi) then
                            --PPUCTRL=01 for test...
                            io_out(16#2000#, 16#01#);
                        elsif (init_step_cnt = 1 * cpu_io_multi) then
                            --PPUMASK=02
                            io_out(16#2001#, 16#02#);
                        elsif (init_step_cnt = 2 * cpu_io_multi) then
                            --PPUCTRL=00
                            io_out(16#2000#, 16#00#);
                        elsif (init_step_cnt = 3 * cpu_io_multi) then
                            --PPUMASK=00
                            io_out(16#2001#, 16#00#);
                        elsif (init_step_cnt = 4 * cpu_io_multi) then
                            --ppuaddr
                            io_out(16#2006#, 16#02#);
                        elsif (init_step_cnt = 5 * cpu_io_multi) then
                            io_out(16#2006#, 16#40#);
                        elsif (init_step_cnt = 6 * cpu_io_multi) then
                            --scroll
                            io_out(16#2005#, 16#21#);
                        elsif (init_step_cnt = 7 * cpu_io_multi) then
                            io_out(16#2005#, 16#5#);
                        else
                            io_brk;
                            if (init_step_cnt > 8 * cpu_io_multi) then
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
                        
                        
                        if (plt_step_cnt = 0 * cpu_io_multi) then
                            --set vram addr 3f00
                            io_out(16#2006#, 16#3f#);
                        elsif (plt_step_cnt = 1 * cpu_io_multi) then
                            io_out(16#2006#, 16#00#);
                        
                        elsif (plt_step_cnt = 2 * cpu_io_multi) then
                            --set palette bg data
                            io_out(16#2007#, 16#11#);
                        elsif (plt_step_cnt = 3 * cpu_io_multi) then
                            io_out(16#2007#, 16#01#);
                        elsif (plt_step_cnt = 4 * cpu_io_multi) then
                            io_out(16#2007#, 16#03#);
                        elsif (plt_step_cnt = 5 * cpu_io_multi) then
                            io_out(16#2007#, 16#13#);

                        elsif (plt_step_cnt = 6 * cpu_io_multi) then
                            io_out(16#2007#, 16#0f#);
                        elsif (plt_step_cnt = 7 * cpu_io_multi) then
                            io_out(16#2007#, 16#04#);
                        elsif (plt_step_cnt = 8 * cpu_io_multi) then
                            io_out(16#2007#, 16#14#);
                        elsif (plt_step_cnt = 9 * cpu_io_multi) then
                            io_out(16#2007#, 16#24#);
     
                        elsif (plt_step_cnt = 10 * cpu_io_multi) then
                            io_out(16#2007#, 16#0f#);
                        elsif (plt_step_cnt = 11 * cpu_io_multi) then
                            io_out(16#2007#, 16#08#);
                        elsif (plt_step_cnt = 12 * cpu_io_multi) then
                            io_out(16#2007#, 16#18#);
                        elsif (plt_step_cnt = 13 * cpu_io_multi) then
                            io_out(16#2007#, 16#28#);
     
                        elsif (plt_step_cnt = 14 * cpu_io_multi) then
                            io_out(16#2007#, 16#05#);
                        elsif (plt_step_cnt = 15 * cpu_io_multi) then
                            io_out(16#2007#, 16#0c#);
                        elsif (plt_step_cnt = 16 * cpu_io_multi) then
                            io_out(16#2007#, 16#1c#);
                        elsif (plt_step_cnt = 17 * cpu_io_multi) then
                            io_out(16#2007#, 16#2c#);

                         elsif (plt_step_cnt = 18 * cpu_io_multi) then
                            --below is sprite pallete
                            io_out(16#2007#, 16#00#);
                        elsif (plt_step_cnt = 19 * cpu_io_multi) then
                            io_out(16#2007#, 16#24#);
                        elsif (plt_step_cnt = 20 * cpu_io_multi) then
                            io_out(16#2007#, 16#1b#);
                        elsif (plt_step_cnt = 21 * cpu_io_multi) then
                            io_out(16#2007#, 16#11#);

                        elsif (plt_step_cnt = 22 * cpu_io_multi) then
                            io_out(16#2007#, 16#00#);
                        elsif (plt_step_cnt = 23 * cpu_io_multi) then
                            io_out(16#2007#, 16#32#);
                        elsif (plt_step_cnt = 24 * cpu_io_multi) then
                            io_out(16#2007#, 16#16#);
                        elsif (plt_step_cnt = 25 * cpu_io_multi) then
                            io_out(16#2007#, 16#20#);

                        elsif (plt_step_cnt = 26 * cpu_io_multi) then
                            io_out(16#2007#, 16#00#);
                        elsif (plt_step_cnt = 27 * cpu_io_multi) then
                            io_out(16#2007#, 16#26#);
                        elsif (plt_step_cnt = 28 * cpu_io_multi) then
                            io_out(16#2007#, 16#01#);
                        elsif (plt_step_cnt = 29 * cpu_io_multi) then
                            io_out(16#2007#, 16#31#);

                        else
                            io_brk;
                            if (plt_step_cnt > 30 * cpu_io_multi) then
                                global_step_cnt := global_step_cnt + 1;
                            end if;
                        end if;
                        plt_step_cnt := plt_step_cnt + 1;
                        
                    elsif (global_step_cnt = 2) then
                        --step1 = name table set.
                        if (nt_step_cnt = 0 * cpu_io_multi) then
                            --set vram addr 2005 (first row, 6th col)
                            io_out(16#2006#, 16#20#);
                        elsif (nt_step_cnt = 1 * cpu_io_multi) then
                            io_out(16#2006#, 16#03#);
                        elsif (nt_step_cnt = 2 * cpu_io_multi) then
                            --set name tbl data
                            --0x44, 45, 45 = DEE
                            io_out(16#2007#, 16#44#);
                        elsif (nt_step_cnt = 3 * cpu_io_multi) then
                            io_out(16#2007#, 16#45#);
                        elsif (nt_step_cnt = 4 * cpu_io_multi) then
                            io_out(16#2007#, 16#45#);


                        elsif (nt_step_cnt = 5 * cpu_io_multi) then
                            io_out(16#2006#, 16#20#);
                        elsif (nt_step_cnt = 6 * cpu_io_multi) then
                            io_out(16#2006#, 16#2a#);
                        elsif (nt_step_cnt = 7 * cpu_io_multi) then
                            io_out(16#2007#, 16#44#);

                        elsif (nt_step_cnt = 8 * cpu_io_multi) then
                            io_out(16#2006#, 16#24#);
                        elsif (nt_step_cnt = 9 * cpu_io_multi) then
                            io_out(16#2006#, 16#43#);
                        elsif (nt_step_cnt = 10 * cpu_io_multi) then
                            io_out(16#2007#, 16#6d#);
                        elsif (nt_step_cnt = 11 * cpu_io_multi) then
                            io_out(16#2007#, 16#6f#);
                        elsif (nt_step_cnt = 12 * cpu_io_multi) then
                            io_out(16#2007#, 16#74#);
                        elsif (nt_step_cnt = 13 * cpu_io_multi) then
                            io_out(16#2007#, 16#6f#);
                            
                        elsif (nt_step_cnt = 14 * cpu_io_multi) then
                            io_out(16#2006#, 16#2e#);
                        elsif (nt_step_cnt = 15 * cpu_io_multi) then
                            io_out(16#2006#, 16#93#);
                        elsif (nt_step_cnt = 16 * cpu_io_multi) then
                            io_out(16#2007#, 16#59#);

                        elsif (nt_step_cnt = 17 * cpu_io_multi) then
                            io_out(16#2007#, 16#00#);

                        else
                            io_brk;
                            if (nt_step_cnt > 4 * cpu_io_multi) then
                                global_step_cnt := global_step_cnt + 1;
                            end if;
                        end if;
                        
                        nt_step_cnt := nt_step_cnt + 1;
                        
                    elsif (global_step_cnt = 3) then
                        --step2 = sprite set.
                        if (spr_step_cnt = 0) then
                            --set sprite addr=00 (first sprite)
                            io_out(16#2003#, 16#00#);
                        
                        elsif (spr_step_cnt = 1 * cpu_io_multi) then
                            --set sprite data: y=02
                            io_out(16#2004#, 16#05#);
                        elsif (spr_step_cnt = 2 * cpu_io_multi) then
                            --tile=0x4d (ascii 'O')
                            io_out(16#2004#, 16#4f#);
                        elsif (spr_step_cnt = 3 * cpu_io_multi) then
                            --set sprite attr=01 (palette 01)
                            io_out(16#2004#, 16#01#);
                        elsif (spr_step_cnt = 4 * cpu_io_multi) then
                            --set sprite data: x=60
                            io_out(16#2004#, 16#3c#);

                        elsif (spr_step_cnt = 5 * cpu_io_multi) then
                            --set sprite data: y=50
                            io_out(16#2004#, 1);
                        elsif (spr_step_cnt = 6 * cpu_io_multi) then
                            --tile=0x4f (ascii 'M')
                            io_out(16#2004#, 16#4d#);
                        elsif (spr_step_cnt = 7 * cpu_io_multi) then
                            --set sprite attr=02
                            io_out(16#2004#, 16#02#);
                        elsif (spr_step_cnt = 8 * cpu_io_multi) then
                            --set sprite data: x=100
                            io_out(16#2004#, 16#64#);

                        elsif (spr_step_cnt = 9 * cpu_io_multi) then
                            --set sprite data: y=60
                            io_out(16#2004#, 60);
                        elsif (spr_step_cnt = 10 * cpu_io_multi) then
                            --tile=0x4d (ascii 'P')
                            io_out(16#2004#, 16#50#);
                        elsif (spr_step_cnt = 11 * cpu_io_multi) then
                            --set sprite attr=01
                            io_out(16#2004#, 16#01#);
                        elsif (spr_step_cnt = 12 * cpu_io_multi) then
                            --set sprite data: x=33
                            io_out(16#2004#, 16#21#);

                        elsif (spr_step_cnt = 13 * cpu_io_multi) then
                            --set sprite data: y=61
                            io_out(16#2004#, 16#3d#);
                        elsif (spr_step_cnt = 14 * cpu_io_multi) then
                            --tile=0x4d (ascii 'Q')
                            io_out(16#2004#, 16#51#);
                        elsif (spr_step_cnt = 15 * cpu_io_multi) then
                            --set sprite attr=02
                            io_out(16#2004#, 16#02#);
                        elsif (spr_step_cnt = 16 * cpu_io_multi) then
                            --set sprite data: x=45
                            io_out(16#2004#, 45);

                        else
                            io_brk;
                            if (spr_step_cnt > 8 * cpu_io_multi) then
                                global_step_cnt := global_step_cnt + 2;
                            end if;
                        end if;
                        spr_step_cnt := spr_step_cnt + 1;

                    elsif (global_step_cnt = 4) then
                        --step3 = dma set.
                        for i in 0 to 64 loop
                            j := i * 4;
                            if (ch = 16#5b#) then
                                ch := 16#41#;
                            else
                                ch := 16#41# + i;
                            end if;

                            --if (i < 64) then
                            if (i < 10) then
                                --set dma value on the ram.
                                if    (dma_step_cnt = (0 + j) * cpu_io_multi) then
                                    io_out(16#0200# + j, i);
                                elsif (dma_step_cnt = (1 + j) * cpu_io_multi) then
                                    io_out(16#0201# + j, ch);
                                elsif (dma_step_cnt = (2 + j) * cpu_io_multi) then
                                    io_out(16#0202# + j, 16#01#);
                                elsif (dma_step_cnt = (3 + j) * cpu_io_multi) then
                                    io_out(16#0203# + j, j);
                                elsif (dma_step_cnt = (0 + j) * cpu_io_multi + 1) or
                                        (dma_step_cnt = (1 + j) * cpu_io_multi + 1) or
                                        (dma_step_cnt = (2 + j) * cpu_io_multi + 1) or
                                        (dma_step_cnt = (3 + j) * cpu_io_multi + 1) then
                                    io_brk;
                                end if;
                            else
                                if    (dma_step_cnt = (0 + j) * cpu_io_multi) then
                                    --start dma
                                    io_out(16#4014#, 16#02#);
                                elsif (dma_step_cnt = (0 + j) * cpu_io_multi + 1) then
                                    io_brk;
                                elsif (dma_step_cnt = (0 + j) * cpu_io_multi + 2) then
                                    io_brk;
                                    global_step_cnt := global_step_cnt + 1;
                                end if;
                            end if;
                        end loop;
                        
                        dma_step_cnt := dma_step_cnt + 1;

                    elsif (global_step_cnt = 5) then
                        --step4 = scroll test and ppu reg read test.
                        if (scl_step_cnt = 0) then
                            --x scroll pos=123
                            io_out(16#2005#, 11);
                        elsif (scl_step_cnt = 1 * cpu_io_multi) then
                            --y scroll pos=100
                            io_out(16#2005#, 0);

                        elsif (scl_step_cnt = 2 * cpu_io_multi) then
                            --read status reg.
                            io_read(16#2002#);

                        elsif (scl_step_cnt = 3 * cpu_io_multi) then
                            --read vram nt0.
                            io_out(16#2006#, 16#20#);

                        elsif (scl_step_cnt = 4 * cpu_io_multi) then
                            io_out(16#2006#, 16#03#);

                        elsif (scl_step_cnt = 5 * cpu_io_multi) then
                            io_read(16#2007#);

                        elsif (scl_step_cnt = 6 * cpu_io_multi) then
                            --pattern tbl.
                            io_out(16#2006#, 16#04#);

                        elsif (scl_step_cnt = 7 * cpu_io_multi) then
                            io_out(16#2006#, 16#d1#);

                        elsif (scl_step_cnt = 8 * cpu_io_multi) then
                            io_read(16#2007#);

                        elsif (scl_step_cnt = 9 * cpu_io_multi) then
                            --attr tbl.
                            io_out(16#2006#, 16#23#);

                        elsif (scl_step_cnt = 10 * cpu_io_multi) then
                            io_out(16#2006#, 16#c0#);

                        elsif (scl_step_cnt = 11 * cpu_io_multi) then
                            --set attr first.
                            io_out(16#2007#, 16#5a#);

                        elsif (scl_step_cnt = 12 * cpu_io_multi) then
                            io_out(16#2006#, 16#23#);

                        elsif (scl_step_cnt = 13 * cpu_io_multi) then
                            io_out(16#2006#, 16#c0#);

                        elsif (scl_step_cnt = 14 * cpu_io_multi) then
                            io_read(16#2007#);

                        elsif (scl_step_cnt = 15 * cpu_io_multi) then
                            --read palette tbl.
                            io_out(16#2006#, 16#3f#);

                        elsif (scl_step_cnt = 16 * cpu_io_multi) then
                            io_out(16#2006#, 16#11#);

                        elsif (scl_step_cnt = 17 * cpu_io_multi) then
                            io_read(16#2007#);

                        else
                            io_brk;
                            if (scl_step_cnt > 17 * cpu_io_multi) then
                                global_step_cnt := global_step_cnt + 1;
                            end if;
                        end if;
                        scl_step_cnt := scl_step_cnt + 1;

                    elsif (global_step_cnt = 6) then
                        --final step = enable ppu.
                        if (enable_ppu_step_cnt = 0 * cpu_io_multi) then
                            --show bg
                            --PPUMASK=1e (show bg and sprite)
                            --PPUMASK=0e (show bg only)
                            io_out(16#2001#, 16#1e#);
                        elsif (enable_ppu_step_cnt = 1 * cpu_io_multi) then
                            --enable nmi
                            --PPUCTRL=80
                            io_out(16#2000#, 16#80#);
                        else
                            io_brk;
                            if (enable_ppu_step_cnt > 1 * cpu_io_multi) then
                                global_step_cnt := global_step_cnt + 1;
                            end if;
                        end if;
                        enable_ppu_step_cnt := enable_ppu_step_cnt + 1;

                    elsif (global_step_cnt = 7) then
                        ----nmi tests.....
                        if (pi_nmi_n = '0') then

                            if (nmi_step_cnt = 0 * cpu_io_multi) then
                                --set sprite addr=00 (first sprite)
                                io_out(16#2003#, 16#03#);
                            elsif (nmi_step_cnt = 1 * cpu_io_multi) then
                                --set sprite data: x=100
                                io_out(16#2004#, nmi_oam_x);
                            elsif (nmi_step_cnt = 2 * cpu_io_multi) then
                                --scroll x=0
--                                io_out(16#2005#, nmi_scl_y);
                                io_brk;
                            elsif (nmi_step_cnt = 3 * cpu_io_multi) then
                                --scroll y++
--                                io_out(16#2005#, nmi_scl_y);
                                io_brk;
                            elsif (nmi_step_cnt = 4 * cpu_io_multi) then
                                --set sprite addr=00 (first sprite)
                                io_out(16#2003#, 16#04#);
                            elsif (nmi_step_cnt = 5 * cpu_io_multi) then
                                --set sprite data: x=100
                                io_out(16#2004#, nmi_oam_x);
                            else
                                if (ref_cnt = 0) then
                                    nmi_oam_x := nmi_oam_x + 1;
                                end if;
                                if (nmi_step_cnt mod 10 = 0) then
                                    nmi_scl_y := nmi_scl_y + 1;
                                end if;
                                io_brk;
                                if (nmi_step_cnt > 5 * cpu_io_multi) then
                                    ref_cnt := ref_cnt + 1;
                                    global_step_cnt := global_step_cnt + 1;
                                end if;
                            end if;
                            nmi_step_cnt := nmi_step_cnt + 1;
                        end if;
                    elsif (global_step_cnt = 8) then
                        ----back to nmi tests.....
                        if (pi_nmi_n = '1') then
                            nmi_step_cnt := 0;
                            global_step_cnt := global_step_cnt - 1;
                        end if;
                    else
                        io_brk;
                        init_done := '1';
                    end if;
                end if;--if (init_done = '0') then
            else
                po_r_nw <= 'Z';
                po_addr <= (others => 'Z');
                pio_d_io <= (others => 'Z');
            end if;--if (rdy = '1') then
            end if;--if (pi_cpu_en(0) = '1') then
        end if; --if (rst_n = '0') then
    end process;

end rtl;




