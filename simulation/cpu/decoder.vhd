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
            y_we_n          : out std_logic;
            y_oe_n          : out std_logic;
            y_ea_oe_n       : out std_logic;
            ea_calc_n       : out std_logic;
            ea_zp_n         : out std_logic;
            ea_pg_next_n    : out std_logic;
            ea_carry        : in  std_logic;
            stat_dec_we_n   : out std_logic;
            stat_dec_oe_n   : out std_logic;
            stat_bus_we_n   : out std_logic;
            stat_bus_oe_n   : out std_logic;
            r_nw            : out std_logic
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


type addr_mode is ( ad_imm,
                    ad_acc,
                    ad_zp, ad_zpx, ad_zpy,
                    ad_abs, ad_absx, ad_absy,
                    ad_indir_x, ad_indir_y,
                    ad_unknown);

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

---case instruction consists of aaabbbcc form,
---return addressing mode for each opcode.
function decode_addr_mode (instruction : in std_logic_vector (dsize - 1 downto 0))
     return addr_mode is
begin
    if instruction (1 downto 0) = "01" then
        if instruction (4 downto 2) = "000" then
            --(zero page,X)
            return ad_indir_x;
        elsif instruction (4 downto 2) = "001" then
            return  ad_zp;
        elsif instruction (4 downto 2) = "010" then
            return  ad_imm;
        elsif instruction (4 downto 2) = "011" then
            return  ad_abs;
        elsif instruction (4 downto 2) = "100" then
            --(zero page),Y
            return ad_indir_y;
        elsif instruction (4 downto 2) = "101" then
            return  ad_zpx;
        elsif instruction (4 downto 2) = "110" then
            return  ad_absy;
        elsif instruction (4 downto 2) = "111" then
            return  ad_absx;
        end if;
    elsif instruction (1 downto 0) = "10" then
        --d_print("cc=10");
        --bbb is 000, 001, 010, 011, 101, 111 only.
        if instruction (4 downto 2) = "000" then
            return  ad_imm;
        elsif instruction (4 downto 2) = "001" then
            return  ad_zp;
        elsif instruction (4 downto 2) = "010" then
            return  ad_acc;
        elsif instruction (4 downto 2) = "011" then
            return  ad_abs;
        elsif instruction (4 downto 2) = "101" then
            return  ad_zpx;
        elsif instruction (4 downto 2) = "111" then
            return  ad_absx;
        else
            return  ad_unknown;
        end if;

    elsif instruction (1 downto 0) = "00" then
        --d_print("cc=00 group...");
        ---bbb part is 000, 001, 011, 101, 111 only.
        if instruction (4 downto 2) = "000" then
            return  ad_imm;
        elsif instruction (4 downto 2) = "001" then
            return  ad_zp;
        elsif instruction (4 downto 2) = "011" then
            return  ad_abs;
        elsif instruction (4 downto 2) = "101" then
            return  ad_zpx;
        elsif instruction (4 downto 2) = "111" then
            return  ad_absx;
        else
            return  ad_unknown;
        end if;
    else
        return  ad_unknown;
    end if; --if instruction (1 downto 0) = "01" then
end  function;

begin

    main_p : process (set_clk, trig_clk, res_n)
    variable single_inst : boolean;
    variable status_reg_old : std_logic_vector(dsize - 1 downto 0);
    variable cur_mode : addr_mode;
    begin

        if (res_n = '0') then
            next_cycle <= R0;
        end if;

        if (set_clk'event and set_clk = '1' and res_n = '1') then
            d_print(string'("-"));

            if exec_cycle = R0 then
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
                stat_dec_we_n <= '1';
                stat_dec_oe_n <= '1';
                stat_bus_we_n <= '1';
                stat_bus_oe_n <= '1';
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

            elsif exec_cycle = T0 then
                --cycle #1
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
                stat_dec_we_n <= '1';
                stat_bus_we_n <= '1';
                pch_d_we_n <= '1';
                pcl_a_we_n <= '1';
                dl_al_we_n <= '1';
                dl_al_oe_n <= '1';
                dl_ah_oe_n <= '1';
                pcl_d_we_n <= '1';
                pch_a_we_n <= '1';
                acc_d_we_n <= '1';
                acc_d_oe_n  <= '1';
                x_ea_oe_n <= '1';
                ea_calc_n <= '1';
                ea_pg_next_n <= '1';

                next_cycle <= T1;

                ---for debug....
                status_reg <= (others => 'Z');
                stat_dec_oe_n <= '0';

            elsif exec_cycle = T1 then
                --cycle #2
                d_print("decode and execute inst: " 
                        & conv_hex8(conv_integer(instruction)));

                --disable pin for jmp/abs [xy] page boundary case.
                dl_al_oe_n <= '1';
                dl_ah_oe_n <= '1';
                pcl_a_we_n <= '1';
                pch_a_we_n <= '1';

                --grab instruction register data.
                inst_we_n <= '1';

                ---single byte instruction.
                single_inst := false;

                if instruction = conv_std_logic_vector(16#8a#, dsize) then
                    single_inst := true;
                    d_print("txa");
                elsif instruction = conv_std_logic_vector(16#9a#, dsize) then
                    single_inst := true;
                    d_print("txs");
                    sp_we_n <= '0';
                    x_oe_n <= '0';
                elsif instruction = conv_std_logic_vector(16#aa#, dsize) then
                    single_inst := true;
                    d_print("tax");
                elsif instruction = conv_std_logic_vector(16#ba#, dsize) then
                    single_inst := true;
                    d_print("tsx");
                elsif instruction = conv_std_logic_vector(16#ca#, dsize) then
                    single_inst := true;
                    d_print("dex");
                elsif instruction = conv_std_logic_vector(16#ea#, dsize) then
                    single_inst := true;
                    d_print("nop");
                elsif instruction = conv_std_logic_vector(16#08#, dsize) then
                    single_inst := true;
                    d_print("php");
                elsif instruction = conv_std_logic_vector(16#28#, dsize) then
                    single_inst := true;
                    d_print("plp");
                elsif instruction = conv_std_logic_vector(16#48#, dsize) then
                    single_inst := true;
                    d_print("pha");
                elsif instruction = conv_std_logic_vector(16#68#, dsize) then
                    single_inst := true;
                    d_print("pla");
                elsif instruction = conv_std_logic_vector(16#88#, dsize) then
                    single_inst := true;
                    d_print("dey");
                elsif instruction = conv_std_logic_vector(16#a8#, dsize) then
                    single_inst := true;
                    d_print("tay");
                elsif instruction = conv_std_logic_vector(16#c8#, dsize) then
                    single_inst := true;
                    d_print("iny");
                elsif instruction = conv_std_logic_vector(16#e8#, dsize) then
                    single_inst := true;
                    d_print("inx");
                elsif instruction = conv_std_logic_vector(16#18#, dsize) then
                    single_inst := true;
                    d_print("clc");
                elsif instruction = conv_std_logic_vector(16#38#, dsize) then
                    single_inst := true;
                    d_print("sec");
                elsif instruction = conv_std_logic_vector(16#58#, dsize) then
                    single_inst := true;
                    d_print("cli");
                elsif instruction = conv_std_logic_vector(16#78#, dsize) then
                    single_inst := true;
                    d_print("sei");
                    status_reg_old := status_reg;
                    stat_dec_oe_n <= '1';
                    stat_dec_we_n <= '0';
                    status_reg(7 downto st_I + 1) 
                        <= status_reg_old (7 downto st_I + 1);
                    status_reg(st_I - 1 downto 0) 
                        <= status_reg_old (st_I - 1 downto 0);
                    status_reg(st_I) <= '1';
                elsif instruction = conv_std_logic_vector(16#98#, dsize) then
                    single_inst := true;
                    d_print("tya");
                elsif instruction = conv_std_logic_vector(16#b8#, dsize) then
                    single_inst := true;
                    d_print("clv");
                elsif instruction = conv_std_logic_vector(16#d8#, dsize) then
                    single_inst := true;
                    d_print("cld");
                elsif instruction = conv_std_logic_vector(16#f8#, dsize) then
                    single_inst := true;
                    d_print("sed");
                end if;

                if single_inst then
                    next_cycle <= T0;
                    pcl_a_oe_n <= '1';
                    pch_a_oe_n <= '1';
                    pc_inc_n <= '1';
                else

                    if instruction = conv_std_logic_vector(16#00#, dsize) then
                        d_print("brk");
                    elsif instruction = conv_std_logic_vector(16#20#, dsize) then
                        d_print("jsr abs 2");
                        --fetch opcode.
                        pcl_a_oe_n <= '0';
                        pch_a_oe_n <= '0';
                        pc_inc_n <= '0';
                        dbuf_int_oe_n <= '0';
                        --latch adl
                        dl_al_we_n <= '0';
                        next_cycle <= T2;

                    elsif instruction = conv_std_logic_vector(16#40#, dsize) then
                        d_print("40");
                    elsif instruction = conv_std_logic_vector(16#60#, dsize) then
                        d_print("rts 2");
                        pcl_a_oe_n <= '1';
                        pch_a_oe_n <= '1';
                        pc_inc_n <= '1';

                        --pop stack (decrement only)
                        sp_pop_n <= '0';
                        sp_int_a_oe_n <= '0';

                        next_cycle <= T2;
                    elsif instruction (4 downto 0) = "10000" then
                        ---conditional branch instruction..

                    else
                        ---instruction consists of aaabbbcc form.

                        ---addressing mode identifier
                        cur_mode := decode_addr_mode(instruction);

                        if cur_mode = ad_imm then
                            d_print("immediate");
                            pcl_a_oe_n <= '0';
                            pch_a_oe_n <= '0';
                            pc_inc_n <= '0';
                            --send data from data bus buffer.
                            --receiver is instruction dependent.
                            dbuf_int_oe_n <= '0';
                            next_cycle <= T0;
                        elsif cur_mode = ad_acc then
                        elsif cur_mode = ad_zp then
                        elsif cur_mode = ad_zpx then
                        elsif cur_mode = ad_zpy then
                        elsif cur_mode = ad_abs or 
                            cur_mode = ad_absx or cur_mode = ad_absy then
                            d_print("abs (xy) 2");
                            --fetch next opcode (abs low).
                            pcl_a_oe_n <= '0';
                            pch_a_oe_n <= '0';
                            pc_inc_n <= '0';
                            --latch abs low data.
                            dbuf_int_oe_n <= '0';
                            dl_al_we_n <= '0';
                            next_cycle <= T2;
                        elsif cur_mode = ad_indir_x then
                        elsif cur_mode = ad_indir_y then
                        else
                            assert false 
                                report ("unknow addressing mode.") severity failure;
                            next_cycle <= ERROR_CYCLE;
                        end if; --if cur_mode = ad_imm then

                        if (cur_mode = ad_imm) then
                            if instruction (1 downto 0) = "01" then
                                --d_print("cc=01");

                                if instruction (7 downto 5) = "000" then
                                    d_print("ora");
                                elsif instruction (7 downto 5) = "001" then
                                    d_print("and");
                                elsif instruction (7 downto 5) = "010" then
                                    d_print("eor");
                                elsif instruction (7 downto 5) = "011" then
                                    d_print("adc");
                                elsif instruction (7 downto 5) = "100" then
                                    if (cur_mode = ad_imm) then
                                        d_print("sta");
                                    end if;
                                elsif instruction (7 downto 5) = "101" then
                                    d_print("lda");
                                    acc_d_we_n <= '0';
                                    --status register n/z bit update.
                                    stat_dec_oe_n <= '1';
                                    status_reg <= "10000010";
                                    stat_bus_we_n <= '0';
                                elsif instruction (7 downto 5) = "110" then
                                    d_print("cmp");
                                elsif instruction (7 downto 5) = "111" then
                                    d_print("sbc");
                                else
                                    assert false 
                                        report ("unknow instruction") severity failure;
                                    next_cycle <= ERROR_CYCLE;
                                end if;
                            elsif instruction (1 downto 0) = "10" then
                                --d_print("cc=10");

                                if instruction (7 downto 5) = "000" then
                                    d_print("asl");
                                elsif instruction (7 downto 5) = "001" then
                                    d_print("rol");
                                elsif instruction (7 downto 5) = "010" then
                                    d_print("lsr");
                                elsif instruction (7 downto 5) = "011" then
                                    d_print("ror");
                                elsif instruction (7 downto 5) = "100" then
                                    d_print("stx");
                                elsif instruction (7 downto 5) = "101" then
                                    d_print("ldx");
                                    x_we_n <= '0';
                                    --status register n/z bit update.
                                    stat_dec_oe_n <= '1';
                                    status_reg <= "10000010";
                                    stat_bus_we_n <= '0';
                                elsif instruction (7 downto 5) = "110" then
                                    d_print("dec");
                                elsif instruction (7 downto 5) = "111" then
                                    d_print("inc");
                                else
                                    assert false 
                                        report ("unknow instruction") severity failure;
                                    next_cycle <= ERROR_CYCLE;
                                end if;

                            elsif instruction (1 downto 0) = "00" then
                                --d_print("cc=00 group...");

                                if instruction (7 downto 5) = "001" then
                                    d_print("bit");
                                elsif instruction (7 downto 5) = "010" then
                                    --jmp always absolute addressing
                                    null;
                                elsif instruction (7 downto 5) = "011" then
                                    --d_print("jmp (abs) 2");
                                    null;
                                elsif instruction (7 downto 5) = "100" then
                                    d_print("sty");
                                elsif instruction (7 downto 5) = "101" then
                                    d_print("ldy");
                                    y_we_n <= '0';
                                    --status register n/z bit update.
                                    stat_dec_oe_n <= '1';
                                    status_reg <= "10000010";
                                    stat_bus_we_n <= '0';
                                elsif instruction (7 downto 5) = "110" then
                                    d_print("cpy");
                                elsif instruction (7 downto 5) = "111" then
                                    d_print("cpx");
                                else
                                    assert false 
                                        report ("unknow instruction") severity failure;
                                    next_cycle <= ERROR_CYCLE;
                                end if; --if instruction (7 downto 5) = "001" then
                            end if; --if instruction (1 downto 0) = "01"
                        end if; --if (cur_mode = ad_imm)
                    end if; --if instruction = conv_std_logic_vector(16#00#, dsize) 
                end if; --if single_inst

            elsif exec_cycle = T2 then
                --cycle #3
                if instruction = conv_std_logic_vector(16#00#, dsize) then

                elsif instruction = conv_std_logic_vector(16#20#, dsize) then
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
                elsif instruction = conv_std_logic_vector(16#40#, dsize) then
                elsif instruction = conv_std_logic_vector(16#60#, dsize) then
                        d_print("rts 3");
                        --pop pcl
                        sp_int_a_oe_n <= '0';
                        sp_pop_n <= '0';
                        --load lo addr.
                        dbuf_int_oe_n <= '0';
                        pcl_d_we_n <= '0';

                        next_cycle <= T3;
                elsif instruction (4 downto 0) = "10000" then
                    ---conditional branch instruction..
                else
                    
                    if cur_mode = ad_abs or
                        cur_mode = ad_absx or cur_mode = ad_absy then
                        d_print("abs (xy) 3");
                        dl_al_we_n <= '1';

                        --latch abs hi data.
                        if instruction /= "01001100" then
                            ---case not jmp, increment pc.
                            pc_inc_n <= '0';
                        end if;
                        pcl_a_oe_n <= '0';
                        pch_a_oe_n <= '0';
                        dbuf_int_oe_n <= '0';
                        dl_ah_we_n <= '0';
                        next_cycle <= T3;
                    end if; --if cur_mode = ad_abs then

                    if instruction (1 downto 0) = "00" then
                        if instruction (7 downto 5) = "010" then
                        --jmp
                        end if; --if instruction (7 downto 5) = "010" then
                    elsif instruction (1 downto 0) = "01" then
                        if instruction (7 downto 5) = "100" then
                            --d_print("sta");
                            next_cycle <= T3;
                        end if;
                    end if; --if instruction (1 downto 0) = "00" then
                end if; --if instruction = conv_std_logic_vector(16#00#, dsize)

            elsif exec_cycle = T3 then
                --cycle #4
                if instruction = conv_std_logic_vector(16#00#, dsize) then
                elsif instruction = conv_std_logic_vector(16#20#, dsize) then
                    d_print("jsr 4");
                    pch_d_oe_n <= '1';

                   --push return addr low into stack.
                    sp_push_n <= '0';
                    pcl_d_oe_n <= '0';
                    sp_int_a_oe_n <= '0';
                    r_nw <= '0';

                    next_cycle <= T4;
                elsif instruction = conv_std_logic_vector(16#40#, dsize) then
                elsif instruction = conv_std_logic_vector(16#60#, dsize) then
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
                elsif instruction (4 downto 0) = "10000" then
                    ---conditional branch instruction..
                else
                    if cur_mode = ad_abs then
                        --d_print("abs 4");
                        pc_inc_n <= '1';
                        pcl_a_oe_n <= '1';
                        pch_a_oe_n <= '1';
                        dbuf_int_oe_n <= '1';
                        dl_ah_we_n <= '1';

                        --latch > al/ah.
                        dl_al_oe_n <= '0';
                        dl_ah_oe_n <= '0';

                        if instruction = "01001100" then
                            ---for jmp inst.
                            next_cycle <= T1;
                        else
                            next_cycle <= T0;
                        end if;
                    elsif cur_mode = ad_absx then
                        --d_print("absx 4");
                        pc_inc_n <= '1';
                        pcl_a_oe_n <= '1';
                        pch_a_oe_n <= '1';
                        dbuf_int_oe_n <= '1';
                        dl_ah_we_n <= '1';

                        -----calucurate and output effective addr
                        x_ea_oe_n <= '0';
                        dl_al_oe_n <= '0';
                        dl_ah_oe_n <= '0';
                        ea_calc_n <= '0';

                        next_cycle <= T4;
                    end if; --if cur_mode = ad_abs then

                    if cur_mode = ad_abs or cur_mode = ad_absx then
                        if instruction (1 downto 0) = "00" then
                            if instruction (7 downto 5) = "010" then
                                d_print("jmp > decode");
                                --jmp this cycle is same as fetch.
                                --pcl/pch from ad bus.
                                pcl_a_we_n <= '0';
                                pch_a_we_n <= '0';
                                inst_we_n <= '0';
                                pc_inc_n <= '0';
                            end if;
                        elsif instruction (1 downto 0) = "01" then
                            if instruction (7 downto 5) = "100" then
                                if cur_mode = ad_abs then
                                    d_print("sta 4");
                                    --output acc memory..
                                    r_nw <= '0';
                                    acc_d_oe_n  <= '0';
                                end if;
                            elsif instruction (7 downto 5) = "101" then
                                d_print("lda 4");
                                --if page boundary is crossed, redo in the next cycle.
                                r_nw <= '1';
                                dbuf_int_oe_n <= '0';
                                acc_d_we_n  <= '0';
                            end if;
                        end if; --instruction (1 downto 0) = "00" 
                    end if ; --if cur_mode = ad_absx then
                end if; --if instruction = conv_std_logic_vector(16#00#, dsize) 

            elsif exec_cycle = T4 then
                --cycle #5
                if instruction = conv_std_logic_vector(16#00#, dsize) then
                elsif instruction = conv_std_logic_vector(16#20#, dsize) then
                    d_print("jsr 5");
                    sp_push_n <= '1';
                    pcl_d_oe_n <= '1';
                    sp_int_a_oe_n <= '1';
                    r_nw <= '1';

                    --fetch last op.
                    pcl_a_oe_n <= '0';
                    pch_a_oe_n <= '0';

                    next_cycle <= T5;

                elsif instruction = conv_std_logic_vector(16#40#, dsize) then
                elsif instruction = conv_std_logic_vector(16#60#, dsize) then
                    d_print("rts 5");
                    sp_int_a_oe_n <= '1';
                    pch_d_we_n <= '1';
                    dbuf_int_oe_n <= '1';

                    --empty cycle.
                    --complying h/w manual...
                    next_cycle <= T5;
                elsif instruction (4 downto 0) = "10000" then
                    ---conditional branch instruction..
                else
                    if cur_mode = ad_absx then
                        if ea_carry = '1' then
                            --case page boundary crossed.
                            d_print("absx 5 (page boudary crossed.)");
                            x_ea_oe_n <= '0';
                            dl_al_oe_n <= '0';
                            dl_ah_oe_n <= '0';
                            ea_calc_n <= '0';
                            ea_pg_next_n <= '0';
                            next_cycle <= T0;
                        else
                            --case page boundary not crossed. do the fetch op.
                            d_print("absx 5 (fetch)");
                            x_ea_oe_n <= '1';
                            dl_al_oe_n <= '1';
                            dl_ah_oe_n <= '1';
                            ea_calc_n <= '1';

                            --disable last operation pin.
                            acc_d_we_n  <= '1';

                            --fetch inst.
                            ad_oe_n <= '0';
                            pcl_a_oe_n <= '0';
                            pch_a_oe_n <= '0';
                            inst_we_n <= '0';
                            pc_inc_n <= '0';
                            next_cycle <= T1;
                        end if;
                    end if;

                    if cur_mode = ad_absx then
                        --case page boundary is crossed
                        if instruction (1 downto 0) = "00" then
                        elsif instruction (1 downto 0) = "01" then
                            if instruction (7 downto 5) = "100" then
                                d_print("sta 5");
                                --output acc memory..
                                r_nw <= '0';
                                acc_d_oe_n  <= '0';
                            elsif instruction (7 downto 5) = "101" then
                                if ea_carry = '1' then
                                    --redo for page next.
                                    d_print("lda 5");
                                    acc_d_we_n  <= '0';
                                end if;
                            end if;
                        end if; --instruction (1 downto 0) = "00" 
                    end if; --if cur_mode = ad_absx and ea_carry = '1'
                end if; --if instruction = conv_std_logic_vector(16#00#, dsize) 
 
            elsif exec_cycle = T5 then
                --cycle #6
                if instruction = conv_std_logic_vector(16#00#, dsize) then
                elsif instruction = conv_std_logic_vector(16#20#, dsize) then
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
                elsif instruction = conv_std_logic_vector(16#40#, dsize) then
                elsif instruction = conv_std_logic_vector(16#60#, dsize) then
                    d_print("rts 6");

                    --increment pc.
                    pc_inc_n <= '0';
                    next_cycle <= T0;
                elsif instruction (4 downto 0) = "10000" then
                    ---conditional branch instruction..
                else
                    if instruction (1 downto 0) = "00" then
                    end if; --instruction (1 downto 0) = "00" 
                end if; --if instruction = conv_std_logic_vector(16#00#, dsize) 

            elsif exec_cycle = ERROR_CYCLE then
                ---stop decoding... > CPU stop.
            else
                --assert false 
                --    report ("unknow status") severity failure;
                next_cycle <= ERROR_CYCLE;
            end if; --if exec_cycle = R0 then
        end if; --if (set_clk'event and set_clk = '1') 

    end process;

end rtl;

