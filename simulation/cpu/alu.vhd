----------------------------
---- 6502 ALU implementation
----------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
--use ieee.std_logic_arith.all;

entity alu is 
    generic (   dsize : integer := 8
            );
    port (  clk             : in std_logic;
            alu_en_n        : in std_logic;
            instruction     : in std_logic_vector (dsize - 1 downto 0);
            int_d_bus       : inout std_logic_vector (dsize - 1 downto 0);
            acc_out         : in std_logic_vector (dsize - 1 downto 0);
            acc_in          : out std_logic_vector (dsize - 1 downto 0);
            carry_in        : in std_logic;
            negative        : out std_logic;
            zero            : out std_logic;
            carry_out       : out std_logic;
            overflow        : out std_logic
    );
end alu;

architecture rtl of alu is

procedure d_print(msg : string) is
use std.textio.all;
use ieee.std_logic_textio.all;
variable out_l : line;
begin
    write(out_l, msg);
    writeline(output, out_l);
end  procedure;

begin

    alu_p : process (alu_en_n, instruction, acc_out, int_d_bus, carry_in)
    variable res : std_logic_vector (dsize - 1 downto 0);

procedure set_n (data : in std_logic_vector (dsize - 1 downto 0)) is
begin
    if (data(7) = '1') then
        negative <= '1';
    else
        negative <= '0';
    end if;
end procedure;

procedure set_z (data : in std_logic_vector (dsize - 1 downto 0)) is
begin
    if  (data(7) or data(6) or data(5) or data(4) or 
        data(3) or data(2) or data(1) or data(0)) = '0' then
        zero <= '1';
    else
        zero <= '0';
    end if;
end procedure;

    begin
    if (alu_en_n = '0') then
            --instruction is aaabbbcc format.
            if instruction (1 downto 0) = "01" then
                if instruction (7 downto 5) = "000" then
                    d_print("ora");
                elsif instruction (7 downto 5) = "001" then
                    d_print("and");
                elsif instruction (7 downto 5) = "010" then
                    d_print("eor");
                elsif instruction (7 downto 5) = "011" then
                    d_print("adc");
                elsif instruction (7 downto 5) = "110" then
                    d_print("cmp");
                    --cmpare A - M.
                    --set n/z/c flag
                    res := acc_out - int_d_bus;
                    set_n(res);
                    set_z(res);
                    --carry flag set when acc >= mem, namely res is positive.
                    if (acc_out >= int_d_bus) then
                        carry_out <= '1';
                    else
                        carry_out <= '0';
                    end if;

                    --no register update.
                    int_d_bus <= (others => 'Z');
                    acc_in <= (others => 'Z');
                    overflow <= 'Z';

                elsif instruction (7 downto 5) = "111" then
                    d_print("sbc");
                end if;
            elsif instruction (1 downto 0) = "10" then
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
                end if;
            elsif instruction (1 downto 0) = "00" then
                if instruction (7 downto 5) = "001" then
                    d_print("bit");
                elsif instruction (7 downto 5) = "010" then
                    d_print("jmp");
                elsif instruction (7 downto 5) = "011" then
                    d_print("jmp");
                elsif instruction (7 downto 5) = "100" then
                    d_print("sty");
                elsif instruction (7 downto 5) = "101" then
                    d_print("ldy");
                elsif instruction (7 downto 5) = "110" then
                    d_print("cpy");
                elsif instruction (7 downto 5) = "111" then
                    d_print("cpx");
                end if; --if instruction (7 downto 5) = "001" then
            end if; --if instruction (1 downto 0) = "01"
    else
        int_d_bus <= (others => 'Z');
        acc_in <= (others => 'Z');
        negative <= 'Z';
        zero <= 'Z';
        carry_out <= 'Z';
        overflow <= 'Z';
    end if; --if (alu_en_n = '') then
    end process;

end rtl;


----------------------------------------
---- 6502 effective address calucurator
----------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity effective_adder is 
    generic (   dsize : integer := 8
            );
    port (  
            ea_calc_n       : in std_logic;
            zp_n            : in std_logic;
            pg_next_n       : in std_logic;
            base_l          : in std_logic_vector (dsize - 1 downto 0);
            base_h          : in std_logic_vector (dsize - 1 downto 0);
            index           : in std_logic_vector (dsize - 1 downto 0);
            ah_bus          : out std_logic_vector (dsize - 1 downto 0);
            al_bus          : out std_logic_vector (dsize - 1 downto 0);
            carry           : out std_logic
    );
end effective_adder;

architecture rtl of effective_adder is

signal adc_work : std_logic_vector (dsize downto 0);

begin
    adc_work <= ('0' & base_l) + ('0' & index);
    carry <= adc_work(dsize) when ea_calc_n = '0' else
            'Z';
    --if not calc effective adder, pass through input.
    al_bus <= adc_work(dsize - 1 downto 0) when ea_calc_n = '0' else
            base_l;

    ah_bus <= "00000000" when zp_n = '0' else
            base_h + '1' when ea_calc_n = '0' and pg_next_n = '0' else
            base_h;

end rtl;

