library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.conv_std_logic_vector;
use ieee.std_logic_unsigned.conv_integer;

entity decoder is 
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
            ad_oe_n         : out std_logic;
            pcl_d_we_n      : out std_logic;
            pcl_a_we_n      : out std_logic;
            pcl_d_oe_n      : out std_logic;
            pcl_a_oe_n      : out std_logic;
            pch_d_we_n      : out std_logic;
            pch_a_we_n      : out std_logic;
            pch_d_oe_n      : out std_logic;
            pch_a_oe_n      : out std_logic;
            pc_inc_n        : out std_logic;
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
            acc_alu_oe_n    : out std_logic;
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
end decoder;

architecture rtl of decoder is

procedure d_print(msg : string) is
use std.textio.all;
use ieee.std_logic_textio.all;
variable out_l : line;
begin
    write(out_l, msg);
    writeline(output, out_l);
end  procedure;

procedure d_print(msg : string; sig : std_logic_vector) is
use std.textio.all;
use ieee.std_logic_textio.all;
variable out_l : line;
begin
    write(out_l, msg);
    write(out_l, sig);
    writeline(output, out_l);
end  procedure;

procedure d_print(msg : string; ival : integer) is
use std.textio.all;
use ieee.std_logic_textio.all;
variable out_l : line;
begin
    write(out_l, msg);
    write(out_l, ival);
    writeline(output, out_l);
end  procedure;

---ival : 0x0000 - 0xffff
function conv_hex16(ival : integer) return string is
variable tmp1, tmp2, tmp3, tmp4 : integer;
--variable ret : string (1 to 4) := "0000";
variable hex_chr: string (1 to 16) := "0123456789abcdef";
begin
    tmp4 := ival / 16 ** 3;
    tmp3 := (ival mod 16 ** 3) / 16 ** 2;
    tmp2 := (ival mod 16 ** 2) / 16 ** 1;
    tmp1 := ival mod 16 ** 1;
    return hex_chr(tmp4 + 1) & hex_chr(tmp3 + 1) 
        & hex_chr(tmp2 + 1) & hex_chr(tmp1 + 1);
end;

function conv_hex8(ival : integer) return string is
variable tmp1, tmp2 : integer;
variable hex_chr: string (1 to 16) := "0123456789abcdef";
begin
    tmp2 := (ival mod 16 ** 2) / 16 ** 1;
    tmp1 := ival mod 16 ** 1;
    return hex_chr(tmp2 + 1) & hex_chr(tmp1 + 1);
end;

--cycle bit format
--00xxx : exec cycle : T0 > T1 > T2 > T3 > T4 > T5 > T6 > T7 > T0
constant T0 : std_logic_vector (4 downto 0) := "00000";
constant T1 : std_logic_vector (4 downto 0) := "00001";
constant T2 : std_logic_vector (4 downto 0) := "00010";
constant T3 : std_logic_vector (4 downto 0) := "00011";
constant T4 : std_logic_vector (4 downto 0) := "00100";
constant T5 : std_logic_vector (4 downto 0) := "00101";
constant T6 : std_logic_vector (4 downto 0) := "00110";
constant T7 : std_logic_vector (4 downto 0) := "00111";

--01xxx : reset cycle : R0 > R1 > R2 > R3 > R4 > R5 > T0
constant R0 : std_logic_vector (4 downto 0) := "01000";
constant R1 : std_logic_vector (4 downto 0) := "01001";
constant R2 : std_logic_vector (4 downto 0) := "01010";
constant R3 : std_logic_vector (4 downto 0) := "01011";
constant R4 : std_logic_vector (4 downto 0) := "01100";
constant R5 : std_logic_vector (4 downto 0) := "01101";

--10xxx : nmi cycle : N0 > N1 > N2 > N3 > N4 > N5 > T0
constant N0 : std_logic_vector (4 downto 0) := "10000";
constant N1 : std_logic_vector (4 downto 0) := "10001";
constant N2 : std_logic_vector (4 downto 0) := "10010";
constant N3 : std_logic_vector (4 downto 0) := "10011";
constant N4 : std_logic_vector (4 downto 0) := "10100";
constant N5 : std_logic_vector (4 downto 0) := "10101";

--11xxx : irq cycle : I0 > I1 > I2 > I3 > I4 > I5 > T0
constant I0 : std_logic_vector (4 downto 0) := "11000";
constant I1 : std_logic_vector (4 downto 0) := "11001";
constant I2 : std_logic_vector (4 downto 0) := "11010";
constant I3 : std_logic_vector (4 downto 0) := "11011";
constant I4 : std_logic_vector (4 downto 0) := "11100";
constant I5 : std_logic_vector (4 downto 0) := "11101";

constant ERROR_CYCLE : std_logic_vector (4 downto 0) := "11111";

-- SR Flags (bit 7 to bit 0):
--  7   N   ....    Negative
--  6   V   ....    Overflow
--  5   -   ....    ignored
--  4   B   ....    Break
--  3   D   ....    Decimal (use BCD for arithmetics)
--  2   I   ....    Interrupt (IRQ disable)
--  1   Z   ....    Zero
--  0   C   ....    Carry
constant st_N : integer := 7;
constant st_V : integer := 6;
constant st_B : integer := 4;
constant st_D : integer := 3;
constant st_I : integer := 2;
constant st_Z : integer := 1;
constant st_C : integer := 0;

begin

    main_p : process (set_clk, trig_clk, res_n)

procedure fetch_inst is
begin
    d_print(string'("fetch 1"));
    ad_oe_n <= '0';
    pcl_a_oe_n <= '0';
    pch_a_oe_n <= '0';
    inst_we_n <= '0';
    pc_inc_n <= '0';

    --disable the last opration pins.
    x_oe_n <= '1';
    y_oe_n <= '1';
    x_we_n <= '1';
    y_we_n <= '1';
    sp_we_n <= '1';
    sp_push_n <= '1';
    sp_pop_n <= '1';
    r_nw <= '1';
    dbuf_int_oe_n <= '1';
    pch_d_we_n <= '1';
    pcl_a_we_n <= '1';
    dl_al_we_n <= '1';
    dl_al_oe_n <= '1';
    dl_ah_oe_n <= '1';
    pcl_d_we_n <= '1';
    pch_a_we_n <= '1';
    acc_d_we_n <= '1';
    acc_d_oe_n  <= '1';
    stat_bus_nz_n <= '1';
    stat_set_flg_n <= '1';
    stat_alu_we_n <= '1';
    x_ea_oe_n <= '1';
    ea_calc_n <= '1';
    ea_pg_next_n <= '1';
    x_inc_n <= '1';
    x_dec_n <= '1';
    y_inc_n <= '1';
    y_dec_n <= '1';
end;

---common routine for single byte instruction.
procedure single_inst is
begin
    pcl_a_oe_n <= '1';
    pch_a_oe_n <= '1';
    pc_inc_n <= '1';
    next_cycle <= T0;
end  procedure;

procedure fetch_imm is
begin
    d_print("immediate");
    pcl_a_oe_n <= '0';
    pch_a_oe_n <= '0';
    pc_inc_n <= '0';
    --send data from data bus buffer.
    --receiver is instruction dependent.
    dbuf_int_oe_n <= '0';
    next_cycle <= T0;
end  procedure;

procedure set_nz_from_bus is
begin
    --status register n/z bit update.
    stat_dec_oe_n <= '1';
    status_reg <= "10000010";
    stat_bus_nz_n <= '0';
end  procedure;

procedure set_nz_from_alu is
begin
    --status register n/z bit update.
    stat_alu_we_n <= '0';
    stat_dec_oe_n <= '1';
    status_reg <= "10000010";
end  procedure;

--flag on/off instruction
procedure set_flag (int_flg : in integer; val : in std_logic) is
begin
    stat_dec_oe_n <= '1';
    stat_set_flg_n <= '0';
    --specify which to set.
    status_reg(7 downto int_flg + 1) 
        <= (others =>'0');
    status_reg(int_flg - 1 downto 0) 
        <= (others =>'0');
    status_reg(int_flg) <= '1';
    stat_flg <= val;
end  procedure;

--for sec/clc
procedure set_flag0 (val : in std_logic) is
begin
    stat_dec_oe_n <= '1';
    stat_set_flg_n <= '0';
    status_reg <= "00000001";
    stat_flg <= val;
end  procedure;

procedure abs_fetch_low is
begin
    d_print("abs (xy) 2");
    --fetch next opcode (abs low).
    pcl_a_oe_n <= '0';
    pch_a_oe_n <= '0';
    pc_inc_n <= '0';
    --latch abs low data.
    dbuf_int_oe_n <= '0';
    dl_al_we_n <= '0';
    next_cycle <= T2;
end  procedure;

procedure abs_fetch_high is
begin
    d_print("abs (xy) 3");
    dl_al_we_n <= '1';

    --latch abs hi data.
    pc_inc_n <= '0';
    pcl_a_oe_n <= '0';
    pch_a_oe_n <= '0';
    dbuf_int_oe_n <= '0';
    dl_ah_we_n <= '0';
    next_cycle <= T3;
end  procedure;

procedure abs_latch_out is
begin
    --d_print("abs 4");
    pc_inc_n <= '1';
    pcl_a_oe_n <= '1';
    pch_a_oe_n <= '1';
    dl_ah_we_n <= '1';

    --latch > al/ah.
    dl_al_oe_n <= '0';
    dl_ah_oe_n <= '0';
end  procedure;

procedure ea_x_out is
begin
    -----calucurate and output effective addr
    x_ea_oe_n <= '0';
    dl_al_oe_n <= '0';
    dl_ah_oe_n <= '0';
    ea_calc_n <= '0';
end  procedure;

--A.2. internal execution on memory data
procedure a2_absx is
begin
    if exec_cycle = T1 then
        abs_fetch_low;
    elsif exec_cycle = T2 then
        abs_fetch_high;
    elsif exec_cycle = T3 then
        --ea calc & lda
        abs_latch_out;
        ea_x_out;
        dbuf_int_oe_n <= '0';
        --instruction specific operation wriiten in the caller position.
        next_cycle <= T4;
    elsif exec_cycle = T4 then
        if ea_carry = '1' then
            --case page boundary crossed.
            d_print("absx 5 (page boudary crossed.)");
            abs_latch_out;
            ea_x_out;
            dbuf_int_oe_n <= '0';
            --next page.
            ea_pg_next_n <= '0';
            --redo inst.
            next_cycle <= T0;
        else
            --case page boundary not crossed. do the fetch op.
            d_print("absx 5 (fetch)");
            fetch_inst;
            next_cycle <= T1;
        end if;
    end if;
end  procedure;

--A.3. store operation.
procedure a3_abs is
begin
    if exec_cycle = T1 then
        abs_fetch_low;
    elsif exec_cycle = T2 then
        abs_fetch_high;
    elsif exec_cycle = T3 then
        abs_latch_out;
        dbuf_int_oe_n <= '1';
        r_nw <= '0';
        next_cycle <= T0;
    end if;
end  procedure;


    begin

        if (res_n = '0') then
            next_cycle <= R0;
        end if;

        if (set_clk'event and set_clk = '1' and res_n = '1') then
            d_print(string'("-"));

            if exec_cycle = T0 then
                --cycle #1
                fetch_inst;
                next_cycle <= T1;

                ---for debug....
                status_reg <= (others => 'Z');
                stat_dec_oe_n <= '0';

            elsif exec_cycle = T1 or exec_cycle = T2 or exec_cycle = T3 or 
                exec_cycle = T4 or exec_cycle = T5 or exec_cycle = T6 or 
                exec_cycle = T7 then
                --execute inst.

                if exec_cycle = T1 then
                    d_print("decode and execute inst: " 
                            & conv_hex8(conv_integer(instruction)));
                    --disable pin for jmp/abs [xy] page boundary case.
                    dl_al_oe_n <= '1';
                    dl_ah_oe_n <= '1';
                    pcl_a_we_n <= '1';
                    pch_a_we_n <= '1';

                    --grab instruction register data.
                    inst_we_n <= '1';
                end if;

                --imelementation is wriiten in the order of hardware manual
                --appendix A.


                ----------------------------------------
                --A.1. Single byte instruction.
                ----------------------------------------
                if instruction = conv_std_logic_vector(16#0a#, dsize) then
                    --asl acc mode.
                    d_print("asl");

                elsif instruction = conv_std_logic_vector(16#18#, dsize) then
                    d_print("clc");
                    set_flag0 ('0');
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#d8#, dsize) then
                    d_print("cld");

                elsif instruction = conv_std_logic_vector(16#58#, dsize) then
                    d_print("cli");

                elsif instruction = conv_std_logic_vector(16#b8#, dsize) then
                    d_print("clv");

                elsif instruction = conv_std_logic_vector(16#ca#, dsize) then
                    d_print("dex");

                elsif instruction = conv_std_logic_vector(16#88#, dsize) then
                    d_print("dey");
                    y_dec_n <= '0';
                    --set nz bit.
                    set_nz_from_alu ;
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#e8#, dsize) then
                    d_print("inx");
                    x_inc_n <= '0';
                    --set nz bit.
                    set_nz_from_alu ;
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#c8#, dsize) then
                    d_print("iny");

                elsif instruction = conv_std_logic_vector(16#4a#, dsize) then
                    --lsr acc mode
                    d_print("lsr");

                elsif instruction = conv_std_logic_vector(16#ea#, dsize) then
                    d_print("nop");

                elsif instruction = conv_std_logic_vector(16#2a#, dsize) then
                    --rol acc
                    d_print("rol");

                elsif instruction = conv_std_logic_vector(16#38#, dsize) then
                    d_print("sec");
                    set_flag0 ('1');
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#f8#, dsize) then
                    d_print("sed");

                elsif instruction = conv_std_logic_vector(16#78#, dsize) then
                    d_print("sei");
                    set_flag (st_I, '1');
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#aa#, dsize) then
                    d_print("tax");
                    set_nz_from_bus;

                elsif instruction = conv_std_logic_vector(16#a8#, dsize) then
                    d_print("tay");
                    set_nz_from_bus;

                elsif instruction = conv_std_logic_vector(16#ba#, dsize) then
                    d_print("tsx");
                    set_nz_from_bus;

                elsif instruction = conv_std_logic_vector(16#8a#, dsize) then
                    d_print("txa");
                    set_nz_from_bus;

                elsif instruction = conv_std_logic_vector(16#9a#, dsize) then
                    d_print("txs");
                    sp_we_n <= '0';
                    x_oe_n <= '0';
                    set_nz_from_bus;
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#98#, dsize) then
                    d_print("tya");
                    set_nz_from_bus;



                ----------------------------------------
                --A.2. internal execution on memory data
                ----------------------------------------
                elsif instruction  = conv_std_logic_vector(16#69#, dsize) then
                    --imm
                    d_print("adc");

                elsif instruction  = conv_std_logic_vector(16#65#, dsize) then
                    --zp
                    d_print("adc");

                elsif instruction  = conv_std_logic_vector(16#75#, dsize) then
                    --zp, x
                    d_print("adc");

                elsif instruction  = conv_std_logic_vector(16#6d#, dsize) then
                    --abs
                    d_print("adc");

                elsif instruction  = conv_std_logic_vector(16#7d#, dsize) then
                    --abs, x
                    d_print("adc");

                elsif instruction  = conv_std_logic_vector(16#79#, dsize) then
                    --abs, y
                    d_print("adc");

                elsif instruction  = conv_std_logic_vector(16#61#, dsize) then
                    --(indir, x)
                    d_print("adc");

                elsif instruction  = conv_std_logic_vector(16#71#, dsize) then
                    --(indir), y
                    d_print("adc");

                elsif instruction  = conv_std_logic_vector(16#29#, dsize) then
                    --imm
                    d_print("and");

                elsif instruction  = conv_std_logic_vector(16#25#, dsize) then
                    --zp
                    d_print("and");

                elsif instruction  = conv_std_logic_vector(16#35#, dsize) then
                    --zp, x
                    d_print("and");

                elsif instruction  = conv_std_logic_vector(16#2d#, dsize) then
                    --abs
                    d_print("and");

                elsif instruction  = conv_std_logic_vector(16#3d#, dsize) then
                    --abs, x
                    d_print("and");

                elsif instruction  = conv_std_logic_vector(16#39#, dsize) then
                    --abs, y
                    d_print("and");

                elsif instruction  = conv_std_logic_vector(16#21#, dsize) then
                    --(indir, x)
                    d_print("and");

                elsif instruction  = conv_std_logic_vector(16#31#, dsize) then
                    --(indir), y
                    d_print("and");

                elsif instruction  = conv_std_logic_vector(16#24#, dsize) then
                    --zp
                    d_print("bit");

                elsif instruction  = conv_std_logic_vector(16#2c#, dsize) then
                    --abs
                    d_print("bit");

                elsif instruction  = conv_std_logic_vector(16#c9#, dsize) then
                    --imm
                    d_print("cmp");

                elsif instruction  = conv_std_logic_vector(16#c5#, dsize) then
                    --zp
                    d_print("cmp");

                elsif instruction  = conv_std_logic_vector(16#d5#, dsize) then
                    --zp, x
                    d_print("cmp");

                elsif instruction  = conv_std_logic_vector(16#cd#, dsize) then
                    --abs
                    d_print("cmp");

                elsif instruction  = conv_std_logic_vector(16#dd#, dsize) then
                    --abs, x
                    d_print("cmp");

                elsif instruction  = conv_std_logic_vector(16#d9#, dsize) then
                    --abs, y
                    d_print("cmp");

                elsif instruction  = conv_std_logic_vector(16#c1#, dsize) then
                    --(indir, x)
                    d_print("cmp");

                elsif instruction  = conv_std_logic_vector(16#d1#, dsize) then
                    --(indir), y
                    d_print("cmp");

                elsif instruction  = conv_std_logic_vector(16#e0#, dsize) then
                    --imm
                    d_print("cpx");

                elsif instruction  = conv_std_logic_vector(16#e4#, dsize) then
                    --zp
                    d_print("cpx");

                elsif instruction  = conv_std_logic_vector(16#ec#, dsize) then
                    --abs
                    d_print("cpx");

                elsif instruction  = conv_std_logic_vector(16#c0#, dsize) then
                    --imm
                    d_print("cpy");

                elsif instruction  = conv_std_logic_vector(16#c4#, dsize) then
                    --zp
                    d_print("cpy");

                elsif instruction  = conv_std_logic_vector(16#cc#, dsize) then
                    --abs
                    d_print("cpy");

                elsif instruction  = conv_std_logic_vector(16#49#, dsize) then
                    --imm
                    d_print("eor");

                elsif instruction  = conv_std_logic_vector(16#45#, dsize) then
                    --zp
                    d_print("eor");

                elsif instruction  = conv_std_logic_vector(16#55#, dsize) then
                    --zp, x
                    d_print("eor");

                elsif instruction  = conv_std_logic_vector(16#4d#, dsize) then
                    --abs
                    d_print("eor");

                elsif instruction  = conv_std_logic_vector(16#5d#, dsize) then
                    --abs, x
                    d_print("eor");

                elsif instruction  = conv_std_logic_vector(16#59#, dsize) then
                    --abs, y
                    d_print("eor");

                elsif instruction  = conv_std_logic_vector(16#41#, dsize) then
                    --(indir, x)
                    d_print("eor");

                elsif instruction  = conv_std_logic_vector(16#51#, dsize) then
                    --(indir), y
                    d_print("eor");

                elsif instruction  = conv_std_logic_vector(16#a9#, dsize) then
                    --imm
                    d_print("lda");
                    fetch_imm;
                    acc_d_we_n <= '0';
                    set_nz_from_bus;

                elsif instruction  = conv_std_logic_vector(16#a5#, dsize) then
                    --zp
                    d_print("lda");

                elsif instruction  = conv_std_logic_vector(16#b5#, dsize) then
                    --zp, x
                    d_print("lda");

                elsif instruction  = conv_std_logic_vector(16#ad#, dsize) then
                    --abs
                    d_print("lda");

                elsif instruction  = conv_std_logic_vector(16#bd#, dsize) then
                    --abs, x
                    d_print("lda");
                    a2_absx;
                    if exec_cycle = T3 then
                        --lda.
                        acc_d_we_n  <= '0';
                        set_nz_from_bus;
                    elsif exec_cycle = T4 then
                        if ea_carry = '1' then
                            --redo lda
                            acc_d_we_n  <= '0';
                            set_nz_from_bus;
                        end if;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#b9#, dsize) then
                    --abs, y
                    d_print("lda");

                elsif instruction  = conv_std_logic_vector(16#a1#, dsize) then
                    --(indir, x)
                    d_print("lda");

                elsif instruction  = conv_std_logic_vector(16#b1#, dsize) then
                    --(indir), y
                    d_print("lda");

                elsif instruction  = conv_std_logic_vector(16#a2#, dsize) then
                    --imm
                    d_print("ldx");
                    fetch_imm;
                    x_we_n <= '0';
                    set_nz_from_bus;

                elsif instruction  = conv_std_logic_vector(16#a6#, dsize) then
                    --zp
                    d_print("ldx");

                elsif instruction  = conv_std_logic_vector(16#b6#, dsize) then
                    --zp, y
                    d_print("ldx");

                elsif instruction  = conv_std_logic_vector(16#ae#, dsize) then
                    --abs
                    d_print("ldx");

                elsif instruction  = conv_std_logic_vector(16#be#, dsize) then
                    --abs, y
                    d_print("ldx");

                elsif instruction  = conv_std_logic_vector(16#a0#, dsize) then
                    --imm
                    d_print("ldy");
                    fetch_imm;
                    y_we_n <= '0';
                    set_nz_from_bus;

                elsif instruction  = conv_std_logic_vector(16#a4#, dsize) then
                    --zp
                    d_print("ldy");

                elsif instruction  = conv_std_logic_vector(16#b4#, dsize) then
                    --zp, x
                    d_print("ldy");

                elsif instruction  = conv_std_logic_vector(16#ac#, dsize) then
                    --abs
                    d_print("ldy");

                elsif instruction  = conv_std_logic_vector(16#bc#, dsize) then
                    --abs, x
                    d_print("ldy");

                elsif instruction  = conv_std_logic_vector(16#09#, dsize) then
                    --imm
                    d_print("ora");

                elsif instruction  = conv_std_logic_vector(16#05#, dsize) then
                    --zp
                    d_print("ora");

                elsif instruction  = conv_std_logic_vector(16#15#, dsize) then
                    --zp, x
                    d_print("ora");

                elsif instruction  = conv_std_logic_vector(16#0d#, dsize) then
                    --abs
                    d_print("ora");

                elsif instruction  = conv_std_logic_vector(16#1d#, dsize) then
                    --abs, x
                    d_print("ora");

                elsif instruction  = conv_std_logic_vector(16#19#, dsize) then
                    --abs, y
                    d_print("ora");

                elsif instruction  = conv_std_logic_vector(16#01#, dsize) then
                    --(indir, x)
                    d_print("ora");

                elsif instruction  = conv_std_logic_vector(16#11#, dsize) then
                    --(indir), y
                    d_print("ora");

                elsif instruction  = conv_std_logic_vector(16#e9#, dsize) then
                    --imm
                    d_print("sbc");

                elsif instruction  = conv_std_logic_vector(16#e5#, dsize) then
                    --zp
                    d_print("sbc");

                elsif instruction  = conv_std_logic_vector(16#f5#, dsize) then
                    --zp, x
                    d_print("sbc");

                elsif instruction  = conv_std_logic_vector(16#ed#, dsize) then
                    --abs
                    d_print("sbc");

                elsif instruction  = conv_std_logic_vector(16#fd#, dsize) then
                    --abs, x
                    d_print("sbc");

                elsif instruction  = conv_std_logic_vector(16#f9#, dsize) then
                    --abs, y
                    d_print("sbc");

                elsif instruction  = conv_std_logic_vector(16#e1#, dsize) then
                    --(indir, x)
                    d_print("sbc");

                elsif instruction  = conv_std_logic_vector(16#f1#, dsize) then
                    --(indir), y
                    d_print("sbc");



                ----------------------------------------
                ---A.3. store operation.
                ----------------------------------------
                elsif instruction  = conv_std_logic_vector(16#85#, dsize) then
                    --zp
                    d_print("sta");

                elsif instruction  = conv_std_logic_vector(16#95#, dsize) then
                    --zp, x
                    d_print("sta");

                elsif instruction  = conv_std_logic_vector(16#8d#, dsize) then
                    --abs
                    d_print("sta");
                    a3_abs;
                    if exec_cycle = T3 then
                        acc_d_oe_n  <= '0';
                    end if;

                elsif instruction  = conv_std_logic_vector(16#9d#, dsize) then
                    --abs, x
                    d_print("sta");
                    --TODO re-check !!!!
--                    if exec_cycle = T1 then
--                        abs_fetch_low;
--                    elsif exec_cycle = T2 then
--                        abs_fetch_high;
--                    elsif exec_cycle = T3 then
--                        abs_latch_out;
--                        ea_x_out;
--                        next_cycle <= T4;
--                    elsif exec_cycle = T4 then
--                        abs_latch_out;
--                        dbuf_int_oe_n <= '1';
--                        ea_x_out;
--                        ea_pg_next_n <= not ea_carry;
--                        --sta
--                        r_nw <= '0';
--                        acc_d_oe_n  <= '0';
--                        next_cycle <= T0;
--                    end if;

                elsif instruction  = conv_std_logic_vector(16#99#, dsize) then
                    --abs, y
                    d_print("sta");

                elsif instruction  = conv_std_logic_vector(16#81#, dsize) then
                    --(indir, x)
                    d_print("sta");

                elsif instruction  = conv_std_logic_vector(16#91#, dsize) then
                    --(indir), y
                    d_print("sta");

                elsif instruction  = conv_std_logic_vector(16#86#, dsize) then
                    --zp
                    d_print("stx");

                elsif instruction  = conv_std_logic_vector(16#96#, dsize) then
                    --zp, y
                    d_print("stx");

                elsif instruction  = conv_std_logic_vector(16#8e#, dsize) then
                    --abs
                    d_print("stx");

                elsif instruction  = conv_std_logic_vector(16#84#, dsize) then
                    --zp
                    d_print("sty");

                elsif instruction  = conv_std_logic_vector(16#94#, dsize) then
                    --zp, x
                    d_print("sty");

                elsif instruction  = conv_std_logic_vector(16#8c#, dsize) then
                    --abs
                    d_print("sty");


                ----------------------------------------
                ---A.4. read-modify-write operation
                ----------------------------------------
                elsif instruction  = conv_std_logic_vector(16#06#, dsize) then
                    --zp
                    d_print("asl");

                elsif instruction  = conv_std_logic_vector(16#16#, dsize) then
                    --zp, x
                    d_print("asl");

                elsif instruction  = conv_std_logic_vector(16#0e#, dsize) then
                    --abs
                    d_print("asl");

                elsif instruction  = conv_std_logic_vector(16#1e#, dsize) then
                    --abs, x
                    d_print("asl");

                elsif instruction  = conv_std_logic_vector(16#c6#, dsize) then
                    --zp
                    d_print("dec");

                elsif instruction  = conv_std_logic_vector(16#d6#, dsize) then
                    --zp, x
                    d_print("dec");

                elsif instruction  = conv_std_logic_vector(16#ce#, dsize) then
                    --abs
                    d_print("dec");

                elsif instruction  = conv_std_logic_vector(16#de#, dsize) then
                    --abs, x
                    d_print("dec");

                elsif instruction  = conv_std_logic_vector(16#e6#, dsize) then
                    --zp
                    d_print("inc");

                elsif instruction  = conv_std_logic_vector(16#f6#, dsize) then
                    --zp, x
                    d_print("inc");

                elsif instruction  = conv_std_logic_vector(16#ee#, dsize) then
                    --abs
                    d_print("inc");

                elsif instruction  = conv_std_logic_vector(16#fe#, dsize) then
                    --abs, x
                    d_print("inc");

                elsif instruction  = conv_std_logic_vector(16#46#, dsize) then
                    --zp
                    d_print("lsr");

                elsif instruction  = conv_std_logic_vector(16#56#, dsize) then
                    --zp, x
                    d_print("lsr");

                elsif instruction  = conv_std_logic_vector(16#4e#, dsize) then
                    --abs
                    d_print("lsr");

                elsif instruction  = conv_std_logic_vector(16#5e#, dsize) then
                    --abs, x
                    d_print("lsr");

                elsif instruction  = conv_std_logic_vector(16#26#, dsize) then
                    --zp
                    d_print("rol");

                elsif instruction  = conv_std_logic_vector(16#36#, dsize) then
                    --zp, x
                    d_print("rol");

                elsif instruction  = conv_std_logic_vector(16#2e#, dsize) then
                    --abs
                    d_print("rol");

                elsif instruction  = conv_std_logic_vector(16#3e#, dsize) then
                    --abs, x
                    d_print("rol");

                elsif instruction  = conv_std_logic_vector(16#66#, dsize) then
                    --zp
                    d_print("ror");

                elsif instruction  = conv_std_logic_vector(16#76#, dsize) then
                    --zp, x
                    d_print("ror");

                elsif instruction  = conv_std_logic_vector(16#6e#, dsize) then
                    --abs
                    d_print("ror");

                elsif instruction  = conv_std_logic_vector(16#7e#, dsize) then
                    --abs, x
                    d_print("ror");


                ----------------------------------------
                --A.5. miscellaneous oprations.
                ----------------------------------------

                -- A.5.1 push/pull
                elsif instruction = conv_std_logic_vector(16#08#, dsize) then
                    d_print("php");

                elsif instruction = conv_std_logic_vector(16#48#, dsize) then
                    d_print("pha");

                elsif instruction = conv_std_logic_vector(16#28#, dsize) then
                    d_print("plp");

                elsif instruction = conv_std_logic_vector(16#68#, dsize) then
                    d_print("pla");


                ----------------------------------------
                -- A.5.3 jsr
                ----------------------------------------
                elsif instruction = conv_std_logic_vector(16#20#, dsize) then
                    if exec_cycle = T1 then
                        d_print("jsr abs 2");
                        --fetch opcode.
                        pcl_a_oe_n <= '0';
                        pch_a_oe_n <= '0';
                        pc_inc_n <= '0';
                        dbuf_int_oe_n <= '0';
                        --latch adl
                        dl_al_we_n <= '0';
                        next_cycle <= T2;
                    elsif exec_cycle = T2 then
                        d_print("jsr 3");
                        pcl_a_oe_n <= '1';
                        pch_a_oe_n <= '1';
                        pc_inc_n <= '1';
                        dbuf_int_oe_n <= '1';
                        dl_al_we_n <= '1';

                       --push return addr high into stack.
                        sp_push_n <= '0';
                        pch_d_oe_n <= '0';
                        sp_int_a_oe_n <= '0';
                        r_nw <= '0';
                        next_cycle <= T3;
                    elsif exec_cycle = T3 then
                        d_print("jsr 4");
                        pch_d_oe_n <= '1';

                       --push return addr low into stack.
                        sp_push_n <= '0';
                        pcl_d_oe_n <= '0';
                        sp_int_a_oe_n <= '0';
                        r_nw <= '0';

                        next_cycle <= T4;
                    elsif exec_cycle = T4 then
                        d_print("jsr 5");
                        sp_push_n <= '1';
                        pcl_d_oe_n <= '1';
                        sp_int_a_oe_n <= '1';
                        r_nw <= '1';

                        --fetch last op.
                        pcl_a_oe_n <= '0';
                        pch_a_oe_n <= '0';

                        next_cycle <= T5;
                    elsif exec_cycle = T5 then
                        d_print("jsr 6");

                        pcl_a_oe_n <= '1';
                        pch_a_oe_n <= '1';

                        --load/output  pch
                        ad_oe_n <= '1';
                        dl_ah_oe_n <= '0';
                        pch_a_we_n <= '0';

                        --load pcl.
                        dl_al_oe_n <= '0';
                        pcl_a_we_n <= '0';

                        next_cycle <= T0;
                    end if; --if exec_cycle = T1 then

                -- A.5.4 break
                elsif instruction = conv_std_logic_vector(16#00#, dsize) then

                ----------------------------------------
                -- A.5.5 return from interrupt
                ----------------------------------------
                elsif instruction = conv_std_logic_vector(16#40#, dsize) then

                ----------------------------------------
                -- A.5.6 jmp
                ----------------------------------------
                elsif instruction = conv_std_logic_vector(16#4c#, dsize) then
                    --abs
                    if exec_cycle = T1 then
                        d_print("jmp 2");
                        --fetch next opcode (abs low).
                        pcl_a_oe_n <= '0';
                        pch_a_oe_n <= '0';
                        pc_inc_n <= '0';
                        --latch abs low data.
                        dbuf_int_oe_n <= '0';
                        dl_al_we_n <= '0';
                        next_cycle <= T2;
                    elsif exec_cycle = T2 then
                        d_print("jmp 3");
                        dl_al_we_n <= '1';

                        --fetch abs hi
                        pcl_a_oe_n <= '0';
                        pch_a_oe_n <= '0';
                        dbuf_int_oe_n <= '0';
                        dl_ah_we_n <= '0';
                        next_cycle <= T3;
                    elsif exec_cycle = T3 then
                        d_print("jmp done > next fetch");
                        pcl_a_oe_n <= '1';
                        pch_a_oe_n <= '1';
                        dl_ah_we_n <= '1';

                        --latch > al/ah.
                        dl_al_oe_n <= '0';
                        dl_ah_oe_n <= '0';

                        --fetch inst and goto decode next.
                        dbuf_int_oe_n <= '1';
                        pcl_a_we_n <= '0';
                        pch_a_we_n <= '0';
                        inst_we_n <= '0';
                        pc_inc_n <= '0';
                        next_cycle <= T1;
                    end if;

                elsif instruction = conv_std_logic_vector(16#6c#, dsize) then
                    --(indir)


                ----------------------------------------
                -- A.5.7 return from soubroutine
                ----------------------------------------
                elsif instruction = conv_std_logic_vector(16#60#, dsize) then
                    if exec_cycle = T1 then
                        pcl_a_oe_n <= '1';
                        pch_a_oe_n <= '1';
                        pc_inc_n <= '1';

                        --pop stack (decrement only)
                        sp_pop_n <= '0';
                        sp_int_a_oe_n <= '0';

                        next_cycle <= T2;
                    elsif exec_cycle = T2 then
                        d_print("rts 3");
                        --pop pcl
                        sp_int_a_oe_n <= '0';
                        sp_pop_n <= '0';
                        --load lo addr.
                        dbuf_int_oe_n <= '0';
                        pcl_d_we_n <= '0';

                        next_cycle <= T3;
                    elsif exec_cycle = T3 then
                        d_print("rts 4");
                        --stack decrement stop.
                        sp_pop_n <= '1';
                        pcl_d_we_n <= '1';

                        --pop pch
                        sp_int_a_oe_n <= '0';
                        --load hi addr.
                        dbuf_int_oe_n <= '0';
                        pch_d_we_n <= '0';

                        next_cycle <= T4;
                    elsif exec_cycle = T4 then
                        d_print("rts 5");
                        sp_int_a_oe_n <= '1';
                        pch_d_we_n <= '1';
                        dbuf_int_oe_n <= '1';

                        --empty cycle.
                        --complying h/w manual...
                        next_cycle <= T5;
                    elsif exec_cycle = T5 then
                        d_print("rts 6");

                        --increment pc.
                        pc_inc_n <= '0';
                        next_cycle <= T0;
                    end if; --if exec_cycle = T1 then

                ----------------------------------------
                -- A.5.8 branch operations
                ----------------------------------------
                elsif instruction = conv_std_logic_vector(16#90#, dsize) then
                    d_print("bcc");
                elsif instruction = conv_std_logic_vector(16#b0#, dsize) then
                    d_print("bcs");
                elsif instruction = conv_std_logic_vector(16#f0#, dsize) then
                    d_print("beq");
                elsif instruction = conv_std_logic_vector(16#30#, dsize) then
                    d_print("bmi");
                elsif instruction = conv_std_logic_vector(16#d0#, dsize) then
                    d_print("bne");
                elsif instruction = conv_std_logic_vector(16#10#, dsize) then
                    d_print("bpl");
                elsif instruction = conv_std_logic_vector(16#50#, dsize) then
                    d_print("bvc");
                elsif instruction = conv_std_logic_vector(16#70#, dsize) then
                    d_print("bvs");
                else
                    ---unknown instruction!!!!
                end if; --if instruction = conv_std_logic_vector(16#0a#, dsize) 

            elsif exec_cycle = R0 then
                d_print(string'("reset"));

                ad_oe_n <= '1';
                pcl_d_we_n <= '1';
                pcl_a_we_n <= '1';
                pcl_d_oe_n <= '1';
                pcl_a_oe_n <= '1';
                pch_d_we_n <= '1';
                pch_a_we_n <= '1';
                pch_d_oe_n <= '1';
                pch_a_oe_n <= '1';
                pc_inc_n <= '1';
                inst_we_n <= '1';
                dbuf_int_oe_n <= '1';
                dl_al_we_n <= '1';
                dl_ah_we_n <= '1';
                dl_al_oe_n <= '1';
                dl_ah_oe_n <= '1';
                sp_we_n <= '1';
                sp_push_n <= '1';
                sp_pop_n <= '1';
                sp_int_d_oe_n <= '1';
                sp_int_a_oe_n <= '1';
                acc_d_we_n <= '1';
                acc_alu_we_n <= '1';
                acc_d_oe_n <= '1';
                acc_alu_oe_n <= '1';
                x_we_n <= '1';
                x_oe_n <= '1';
                y_we_n <= '1';
                y_oe_n <= '1';
                x_inc_n <= '1';
                x_dec_n <= '1';
                y_inc_n <= '1';
                y_dec_n <= '1';

                stat_dec_oe_n <= '1';
                stat_bus_oe_n <= '1';
                stat_set_flg_n <= '1';
                stat_flg <= '1';
                stat_bus_all_n <= '1';
                stat_bus_nz_n <= '1';
                stat_alu_we_n <= '1';
                x_ea_oe_n <= '1';
                y_ea_oe_n <= '1';
                ea_calc_n <= '1';
                ea_zp_n <= '1';
                ea_pg_next_n <= '1';

                next_cycle <= R1;
            elsif exec_cycle = R1 then
                next_cycle <= R2;

            elsif exec_cycle = R2 then
                next_cycle <= R3;

            elsif exec_cycle = R3 then
                next_cycle <= R4;

            elsif exec_cycle = R4 then
                next_cycle <= R5;
                
            elsif exec_cycle = R5 then
                next_cycle <= T0;

            end if; --if exec_cycle = T0 then

        end if; --if (set_clk'event and set_clk = '1') 

    end process;

end rtl;

