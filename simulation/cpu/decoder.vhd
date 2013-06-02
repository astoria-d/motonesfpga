library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.conv_std_logic_vector;
--use ieee.std_logic_arith.all;
use std.textio.all;
use ieee.std_logic_textio.all;
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
            status_reg      : in std_logic_vector (dsize - 1 downto 0);
            pcl_we_n        : out std_logic;
            pcl_d_oe_n      : out std_logic;
            pcl_a_oe_n      : out std_logic;
            pch_we_n        : out std_logic;
            pch_d_oe_n      : out std_logic;
            pch_a_oe_n      : out std_logic;
            pc_inc_n        : out std_logic;
            inst_we_n       : out std_logic;
            inst_oe_n       : out std_logic;
            dbuf_int_oe_n   : out std_logic;
            dbuf_ext_oe_n   : out std_logic;
            dbuf_int_we_n   : out std_logic;
            dbuf_ext_we_n   : out std_logic;
            x_we_n          : out std_logic;
            x_oe_n          : out std_logic;
            y_we_n          : out std_logic;
            y_oe_n          : out std_logic;
            r_nw            : out std_logic
        );
end decoder;

architecture rtl of decoder is

procedure d_print(msg : string) is
variable out_l : line;
begin
    write(out_l, msg);
    writeline(output, out_l);
end  procedure;

procedure d_print(msg : string; sig : std_logic_vector) is
variable out_l : line;
begin
    write(out_l, msg);
    write(out_l, sig);
    writeline(output, out_l);
end  procedure;

procedure d_print(msg : string; ival : integer) is
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
--    d_print("hex_chr");
--    d_print("ival: ", ival);
--    d_print("tmp4: ", tmp4);
--    d_print("tmp3: ", tmp3);
--    d_print("tmp2: ", tmp2);
--    d_print("tmp1: ", tmp1);

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


type dec_status is (reset0, reset1, reset2, reset3, reset4, reset5, 
                    fetch, decode, 
                    exec0, exec1, exec2, exec3, exec4, exec5, 
                    unknown_stat);

type addr_mode is ( ad_imp,
                    ad_imm,
                    ad_acc, 
                    ad_zp0, ad_zp1,
                    ad_zpx0, ad_zpx1,
                    ad_zpy0, ad_zpy1,
                    ad_abs0, ad_abs1, ad_abs2, 
                    ad_absx0, ad_absx1, ad_absx2, 
                    ad_absy0, ad_absy1, ad_absy2,
                    ad_indx_indir0, ad_indx_indir1, 
                        ad_indx_indir2, ad_indx_indir3, ad_indx_indir4, 
                    ad_indir_indx0, ad_indir_indx1, ad_indir_indx2, 
                        ad_indir_indx3, ad_indir_indx4,
                    ad_unknown);

signal cur_status : dec_status;
signal cur_mode : addr_mode;

begin

    main_p : process (set_clk, trig_clk, res_n)
    variable single_inst : boolean;
    begin
        if (res_n'event and res_n = '0') then
            d_print(string'("reset"));
            cur_status <= reset0;
            dbuf_int_oe_n <= '0';
            dbuf_ext_we_n <= '0';
            dbuf_ext_oe_n <= '1';
            dbuf_int_we_n <= '1';
            x_we_n <= '1';
            x_oe_n <= '1';
            y_we_n <= '1';
            y_oe_n <= '1';
        end if;

        if (set_clk'event and set_clk = '1') then
            d_print(string'("-"));

            case cur_status is
                when reset0 => 
                    cur_status <= reset1;
                when reset1 => 
                    cur_status <= reset2;
                when reset2 => 
                    cur_status <= reset3;
                when reset3 => 
                    cur_status <= reset4;
                when reset4 => 
                    cur_status <= reset5;
                when reset5 => 
                    cur_status <= fetch;
                when fetch => 
                    d_print(string'("fetch"));
                    pcl_a_oe_n <= '0';
                    pch_a_oe_n <= '0';
                    inst_we_n <= '0';
                    inst_oe_n <= '0';
                    x_we_n <= '1';
                    r_nw <= '1';
                    pc_inc_n <= '0';
                    cur_status <= decode;
                when unknown_stat => 
                    assert false 
                        report ("unknow status") severity failure;
                when others => 
                    null;
            end case; --case cur_status



            if cur_status = decode then
                d_print("decode inst: " & conv_hex8(conv_integer(instruction)));

                ---single byte instruction.
                single_inst := false;

                if instruction = conv_std_logic_vector(16#8a#, dsize) then
                    single_inst := true;
                    d_print("txa");
                elsif instruction = conv_std_logic_vector(16#9a#, dsize) then
                    single_inst := true;
                    d_print("txs");
                    --sp <= reg_x;
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
                    --status_reg(st_I) <= '1';
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
                    cur_status <= fetch;
                    cur_mode <= ad_imp;
                    pcl_a_oe_n <= '1';
                    pch_a_oe_n <= '1';
                    pc_inc_n <= '1';
                else

                    ---instruction consists of aaabbbcc form.
                    if instruction (1 downto 0) = "01" then
                        --d_print("cc=01");

                        ---bbb part format
                        if instruction (4 downto 2) = "000" or 
                            instruction (4 downto 2) = "001" or 
                            instruction (4 downto 2) = "010" or 
                            instruction (4 downto 2) = "011" or 
                            instruction (4 downto 2) = "100" or 
                            instruction (4 downto 2) = "101" or 
                            instruction (4 downto 2) = "110" or 
                            instruction (4 downto 2) = "111" then

                            if instruction (7 downto 5) = "000" then
                                d_print("ora");
                            elsif instruction (7 downto 5) = "001" then
                                d_print("and");
                            elsif instruction (7 downto 5) = "010" then
                                d_print("eor");
                            elsif instruction (7 downto 5) = "011" then
                                d_print("adc");
                            elsif instruction (7 downto 5) = "100" then
                                d_print("sta");
                            elsif instruction (7 downto 5) = "101" then
                                d_print("lda");
                            elsif instruction (7 downto 5) = "110" then
                                d_print("cmp");
                            elsif instruction (7 downto 5) = "111" then
                                d_print("sbc");
                            else
                                assert false 
                                    report ("unknow instruction") severity failure;
                            end if;
                        end if;
                    elsif instruction (1 downto 0) = "10" then
                        --d_print("cc=10");

                        if instruction (4 downto 2) = "000" then
                            cur_mode <= ad_imm;
                            d_print("immediate");
                            pcl_a_oe_n <= '0';
                            pch_a_oe_n <= '0';
                            pc_inc_n <= '0';
                            inst_we_n <= '1';
                            cur_status <= fetch;
                            x_we_n <= '0';
                        elsif instruction (4 downto 2) = "001" then
                            cur_mode <= ad_zp0;
                        elsif instruction (4 downto 2) = "010" then
                            cur_mode <= ad_acc;
                        elsif instruction (4 downto 2) = "011" then
                            cur_mode <= ad_abs0;
                        elsif instruction (4 downto 2) = "101" then
                            cur_mode <= ad_zpx0;
                        elsif instruction (4 downto 2) = "111" then
                            cur_mode <= ad_absx0;
                        else
                            cur_mode <= ad_unknown;
                            assert false 
                                report ("unknow addr mode") severity failure;
                        end if;

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
                        elsif instruction (7 downto 5) = "110" then
                            d_print("dec");
                        elsif instruction (7 downto 5) = "111" then
                            d_print("inc");
                        else
                            assert false 
                                report ("unknow instruction") severity failure;
                        end if;

                    elsif instruction (1 downto 0) = "00" then
                        --d_print("cc=00 group...");

                        if instruction (4 downto 0) = "10000" then
                            ---conditional branch instruction..
                        elsif instruction = conv_std_logic_vector(16#00#, dsize) then
                            d_print("brk");
                        elsif instruction = conv_std_logic_vector(16#20#, dsize) then
                            d_print("jsr abs");
                        elsif instruction = conv_std_logic_vector(16#40#, dsize) then
                            d_print("40");
                        elsif instruction = conv_std_logic_vector(16#60#, dsize) then
                            d_print("60");
                        
                            
                        ---bbb part format
                        else
                            if instruction (4 downto 2) = "000" then
                                cur_mode <= ad_imm;
                                d_print("immediate");
                                pcl_a_oe_n <= '0';
                                pch_a_oe_n <= '0';
                                pc_inc_n <= '0';
                                cur_status <= exec0;
                            elsif instruction (4 downto 2) = "001" then
                                cur_mode <= ad_zp0;
                            elsif instruction (4 downto 2) = "011" then
                                cur_mode <= ad_abs0;
                                d_print("abs");
                                pcl_a_oe_n <= '0';
                                pch_a_oe_n <= '0';
                                pc_inc_n <= '0';
                                cur_status <= exec0;
                            elsif instruction (4 downto 2) = "101" then
                                cur_mode <= ad_zpx0;
                            elsif instruction (4 downto 2) = "111" then
                                cur_mode <= ad_absx0;
                            else
                                cur_mode <= ad_unknown;
                                assert false 
                                    report ("unknow addr mode") severity failure;
                            end if;

                            if instruction (7 downto 5) = "001" then
                                d_print("bit");
                            elsif instruction (7 downto 5) = "010" then
                                d_print("jmp");
                            elsif instruction (7 downto 5) = "011" then
                                d_print("jmp (abs)");
                            elsif instruction (7 downto 5) = "100" then
                                d_print("sty");
                            elsif instruction (7 downto 5) = "101" then
                                d_print("ldy");
                            elsif instruction (7 downto 5) = "110" then
                                d_print("cpy");
                            elsif instruction (7 downto 5) = "111" then
                                d_print("cpx");
                            else
                                assert false 
                                    report ("unknow instruction") severity failure;
                            end if;
                        end if; --if instruction (4 downto 0) = "10000"
                    end if; --if instruction (1 downto 0) = "01"

                end if; --if single_inst

            elsif cur_status = exec0 then
                if instruction (1 downto 0) = "00" then
                    if instruction (4 downto 2) = "011" then
                    --abs0
--                        addr <= pc;
--                        pc <= pc + 1;
--                        input_data_latch <= dbus_buffer;
--                        cur_status <= exec1;
                    end if;
                end if;
            end if; --if cur_status = decode 

        end if; --if (set_clk'event and set_clk = '1') 

        if (trig_clk'event and trig_clk = '1') then
            --d_print("_");
            case cur_status is
                when exec0 => 
                    if instruction (1 downto 0) = "01" then
                    elsif instruction (1 downto 0) = "10" then
                        if instruction (4 downto 2) = "000" then
                        --immediate
                            if instruction (7 downto 5) = "101" then
                            --ldx
                                --reg_x <= dbus_buffer;
                                --cur_status <= fetch;
                            end if;
                        end if;
                    end if; --if instruction (1 downto 0) = "01"
                when exec1 => 
                    if instruction (1 downto 0) = "00" then
                        if instruction (4 downto 2) = "011" then
                        --abs
                            if instruction (7 downto 5) = "010" then
                            --jmp
--                                pc <= dbus_buffer & input_data_latch;
--                                addr <= dbus_buffer & input_data_latch;
--                                cur_status <= fetch;
                            end if;
                        end if;
                    end if;
                when others => 
                    null;
            end case; --case cur_status
        end if; --if (trigger_clk'event and trigger_clk = '1')

    end process;

end rtl;

