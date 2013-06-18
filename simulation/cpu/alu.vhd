-----------------------------------------
------------- ALU Core -----------------
-----------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

----d1 = acc
----d2 = memory
entity alu_core is 
    generic (   dsize : integer := 8
            );
    port ( 
            sel         : in std_logic_vector (3 downto 0);
            d1          : in std_logic_vector (dsize - 1 downto 0);
            d2          : in std_logic_vector (dsize - 1 downto 0);
            d_out       : out std_logic_vector (dsize - 1 downto 0);
            carry_in    : in std_logic;
            negative    : out std_logic;
            zero        : out std_logic;
            carry_out   : out std_logic;
            overflow    : out std_logic
    );
end alu_core;

architecture rtl of alu_core is

procedure d_print(msg : string) is
use std.textio.all;
use ieee.std_logic_textio.all;
variable out_l : line;
begin
    write(out_l, msg);
    writeline(output, out_l);
end  procedure;

constant ALU_AND    : std_logic_vector (3 downto 0) := "0000";
constant ALU_EOR    : std_logic_vector (3 downto 0) := "0001";
constant ALU_OR     : std_logic_vector (3 downto 0) := "0010";
constant ALU_BIT    : std_logic_vector (3 downto 0) := "0011";
constant ALU_ADC    : std_logic_vector (3 downto 0) := "0100";
constant ALU_SBC    : std_logic_vector (3 downto 0) := "0101";
constant ALU_CMP    : std_logic_vector (3 downto 0) := "0110";
constant ALU_SL     : std_logic_vector (3 downto 0) := "0111";
constant ALU_SR     : std_logic_vector (3 downto 0) := "1000";
constant ALU_RL     : std_logic_vector (3 downto 0) := "1001";
constant ALU_RR     : std_logic_vector (3 downto 0) := "1010";
constant ALU_INC    : std_logic_vector (3 downto 0) := "1011";
constant ALU_DEC    : std_logic_vector (3 downto 0) := "1100";

begin

    alu_p : process (sel, d1, d2, carry_in)
    variable res : std_logic_vector (dsize downto 0);

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
    if sel = ALU_AND then
        res := d1 and d2;
    elsif sel = ALU_EOR then
        res := d1 xor d2;
    elsif sel = ALU_OR then
        res := d1 or d2;
    elsif sel = ALU_BIT then
        ----
    elsif sel = ALU_ADC then
        res := ('0' & d1) + ('0' & d2) + carry_in;
        d_out <= res(dsize - 1 downto 0);
        carry_out <= res(dsize);
        if ((d1(dsize - 1) = d1(dsize - 1)) 
                            and (d1(dsize - 1) /= res(dsize - 1))) then
            overflow <= '1';
        else
            overflow <= '0';
        end if;

    elsif sel = ALU_SBC then
        ----
    elsif sel = ALU_CMP then
        res := d1 - d2;
    elsif sel = ALU_SL then
        ----
    elsif sel = ALU_SR then
        ----
    elsif sel = ALU_RL then
        ----
    elsif sel = ALU_RR then
        ----
    elsif sel = ALU_INC then
        res := ('0' & d1) + "000000001";
        d_out <= res(dsize - 1 downto 0);
        carry_out <= res(dsize);
    elsif sel = ALU_DEC then
        res := ('0' & d1) - "000000001";
        d_out <= res(dsize - 1 downto 0);
        carry_out <= res(dsize);
    end if;
    set_n(res(dsize - 1 downto 0));
    set_z(res(dsize - 1 downto 0));

    end process;

end rtl;


----------------------------
---- 6502 ALU implementation
----------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity alu is 
    generic (   dsize : integer := 8
            );
    port (  clk             : in std_logic;
            pcl_inc_n       : in std_logic;
            pch_inc_n       : in std_logic;
            sph_oe_n        : in std_logic;
            sp_push_n       : in std_logic;
            abs_ea_n        : in std_logic;
            zp_ea_n         : in std_logic;
            arith_en_n      : in std_logic;
            instruction     : in std_logic_vector (dsize - 1 downto 0);
            int_d_bus       : inout std_logic_vector (dsize - 1 downto 0);
            acc_out         : in std_logic_vector (dsize - 1 downto 0);
            index_bus       : in std_logic_vector (dsize - 1 downto 0);
            bal             : in std_logic_vector (dsize - 1 downto 0);
            bah             : in std_logic_vector (dsize - 1 downto 0);
            alu_res         : out std_logic_vector (dsize - 1 downto 0);
            abl             : out std_logic_vector (dsize - 1 downto 0);
            abh             : out std_logic_vector (dsize - 1 downto 0);
            pcl_inc_carry   : out std_logic;
            carry_in        : in std_logic;
            negative        : out std_logic;
            zero            : out std_logic;
            carry_out       : out std_logic;
            overflow        : out std_logic
    );
end alu;

architecture rtl of alu is

component d_flip_flop
    generic (
            dsize : integer := 8
            );
    port (  
            clk     : in std_logic;
            res_n   : in std_logic;
            set_n   : in std_logic;
            we_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;

component alu_core
    generic (   dsize : integer := 8
            );
    port ( 
            sel         : in std_logic_vector (3 downto 0);
            d1          : in std_logic_vector (dsize - 1 downto 0);
            d2          : in std_logic_vector (dsize - 1 downto 0);
            d_out       : out std_logic_vector (dsize - 1 downto 0);
            carry_in    : in std_logic;
            negative    : out std_logic;
            zero        : out std_logic;
            carry_out   : out std_logic;
            overflow    : out std_logic
    );
end component;

constant ALU_AND    : std_logic_vector (3 downto 0) := "0000";
constant ALU_EOR    : std_logic_vector (3 downto 0) := "0001";
constant ALU_OR     : std_logic_vector (3 downto 0) := "0010";
constant ALU_BIT    : std_logic_vector (3 downto 0) := "0011";
constant ALU_ADC    : std_logic_vector (3 downto 0) := "0100";
constant ALU_SBC    : std_logic_vector (3 downto 0) := "0101";
constant ALU_CMP    : std_logic_vector (3 downto 0) := "0110";
constant ALU_SL     : std_logic_vector (3 downto 0) := "0111";
constant ALU_SR     : std_logic_vector (3 downto 0) := "1000";
constant ALU_RL     : std_logic_vector (3 downto 0) := "1001";
constant ALU_RR     : std_logic_vector (3 downto 0) := "1010";
constant ALU_INC    : std_logic_vector (3 downto 0) := "1011";
constant ALU_DEC    : std_logic_vector (3 downto 0) := "1100";

procedure d_print(msg : string) is
use std.textio.all;
use ieee.std_logic_textio.all;
variable out_l : line;
begin
    write(out_l, msg);
    writeline(output, out_l);
end  procedure;

signal sel : std_logic_vector (3 downto 0);
signal d1 : std_logic_vector (dsize - 1 downto 0);
signal d2 : std_logic_vector (dsize - 1 downto 0);
signal d_out : std_logic_vector (dsize - 1 downto 0);

signal bal_reg : std_logic_vector (dsize - 1 downto 0);
signal bah_reg : std_logic_vector (dsize - 1 downto 0);

signal n : std_logic;
signal z : std_logic;
signal c : std_logic;
signal v : std_logic;
begin

    bal_inst : d_flip_flop generic map (dsize) 
            port map(clk, '1', '1', '0', bal, bal_reg);
    bah_inst : d_flip_flop generic map (dsize) 
            port map(clk, '1', '1', '0', bah, bah_reg);

    alu_inst : alu_core generic map (dsize)
            port map (sel, d1, d2, d_out, carry_in, n, z, c, v);

    alu_p : process (clk, pcl_inc_n, pch_inc_n, abs_ea_n, zp_ea_n, arith_en_n, 
                    instruction, 
                    int_d_bus, acc_out, index_bus, bal, bal, carry_in, d_out, 
                    n, z, c, v)
    begin
    if (pcl_inc_n = '0') then
        sel <= ALU_INC;
        d1 <= bal;
        alu_res <= d_out;
        pcl_inc_carry <= c;

        --keep the value in the cycle
        if (clk = '0') then
            abl <= bal;
        else
            abl <= bal_reg;
        end if;
        abh <= bah;

    elsif (pch_inc_n = '0') then
        sel <= ALU_INC;
        d1 <= bah;
        alu_res <= d_out;
        pcl_inc_carry <= '0';

        --inc pch cycle is not fetch cycle.
        --it is special cycle.
        abl <= bal;
        abh <= bah;

    elsif (sph_oe_n = '0') then
        --stack operation...
        abh <= "00000001";

        if (sp_push_n /= '0') then
            abl <= bal;
        else
            sel <= ALU_DEC;
            d1 <= bal;
            alu_res <= d_out;

            if (clk = '0') then
                abl <= bal;
            else
                abl <= bal_reg;
            end if;
        end if;
    elsif (arith_en_n = '0') then
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
                    sel <= ALU_CMP;
                    d1 <= acc_out;
                    d2 <= int_d_bus;
                    alu_res <= d_out;

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
                elsif instruction (7 downto 5) = "110" then
                    d_print("dec");
                elsif instruction (7 downto 5) = "111" then
                    d_print("inc");
                end if;
            elsif instruction (1 downto 0) = "00" then
                if instruction (7 downto 5) = "001" then
                    d_print("bit");
                elsif instruction (7 downto 5) = "110" then
                    d_print("cpy");
                elsif instruction (7 downto 5) = "111" then
                    d_print("cpx");
                end if; --if instruction (7 downto 5) = "001" then
            end if; --if instruction (1 downto 0) = "01"
    else
        int_d_bus <= (others => 'Z');
        negative <= 'Z';
        zero <= 'Z';
        carry_out <= 'Z';
        overflow <= 'Z';

        abl <= bal;
        abh <= bah;

        ----alu_res is always bal for jsr instruction....
        -----TODO must check later if it's ok.
        alu_res <= bal;
        pcl_inc_carry <= '0';
    end if; --if (pcl_inc_n = '0') then
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


