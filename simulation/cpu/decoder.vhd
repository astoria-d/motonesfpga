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
                    fetch, exec, 
                    sei,
                    ldx1, ldx2, ldx3,
                    jmp1, jmp2, jmp3, jmp4,
                    nop,
                    unknown_stat
                    );

signal cur_status : dec_status;

begin

    main_p : process (set_clk, trig_clk, res_n)
    begin
        if (res_n'event and res_n = '0') then
            d_print(string'("reset"));
            cur_status <= reset0;
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
                    r_nw <= '1';
                    pc_inc_n <= '0';
                    cur_status <= exec;
                when exec => 
                    d_print(string'(" exec and decode "), conv_integer(instruction));
                    ---one byte instruction decoding.
                    if instruction = conv_std_logic_vector(16#78#, dsize) then
                        --0x78 = 120
                        d_print(string'("   sei"));
                        pcl_a_oe_n <= '1';
                        pch_a_oe_n <= '1';
                        pc_inc_n <= '1';
                        ---set flag operation here.
                        cur_status <= fetch;
                    elsif instruction = conv_std_logic_vector(16#a2#, dsize) then
                        --0xa2 = 162 
                        d_print(string'("   ldx 0"));
                        pcl_a_oe_n <= '0';
                        pch_a_oe_n <= '0';
                        pc_inc_n <= '0';
                        ---load X operation here.
                        cur_status <= fetch;
                    elsif instruction = conv_std_logic_vector(16#9a#, dsize) then
                        --0x9a = 154
                        d_print(string'("   txs"));
                        pcl_a_oe_n <= '1';
                        pch_a_oe_n <= '1';
                        pc_inc_n <= '1';
                        cur_status <= fetch;
                    elsif instruction = conv_std_logic_vector(16#4c#, dsize) then
                        --0x4c = 76
                        cur_status <= jmp1;
                        d_print(string'("   jmp 0"));
                        pc_inc_n <= '0';
                        pcl_a_oe_n <= '0';
                        pch_a_oe_n <= '0';
                        cur_status <= jmp1;

                    else
                        cur_status <= unknown_stat;
                        d_print(string'("unknown inst."));
                        pc_inc_n <= '1';
                        pcl_a_oe_n <= '1';
                        pch_a_oe_n <= '1';
                    end if;

                when ldx1 => 
                    d_print(string'("   ldx 1"));
                    cur_status <= unknown_stat;
                when jmp1 => 
                    d_print(string'("   jmp 1"));
                    pc_inc_n <= '0';
                    pcl_a_oe_n <= '1';
                    pch_a_oe_n <= '1';
                    cur_status <= fetch;
                when jmp2 => 
                    d_print(string'("   jmp 2"));

                when others => null;
                    d_print(string'("unknown status."));
                    cur_status <= unknown_stat;
            end case;
        end if;

    end process;

end rtl;

