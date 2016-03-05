----------------------------
---- 6502 ALU implementation
----------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.conv_std_logic_vector;
use work.motonesfpga_common.all;

entity alu is 
    generic (   dsize : integer := 8
            );
    port (  clk             : in std_logic;
            pcl_inc_n       : in std_logic;
            pch_inc_n       : in std_logic;
            sp_oe_n         : in std_logic;
            sp_push_n       : in std_logic;
            sp_pop_n        : in std_logic;
            abs_xy_n        : in std_logic;
            pg_next_n       : in std_logic;
            zp_n            : in std_logic;
            zp_xy_n         : in std_logic;
            rel_calc_n      : in std_logic;
            indir_n         : in std_logic;
            indir_x_n       : in std_logic;
            indir_y_n       : in std_logic;
            arith_en_n      : in std_logic;
            instruction     : in std_logic_vector (dsize - 1 downto 0);
            exec_cycle      : in std_logic_vector (5 downto 0);
            int_d_bus       : inout std_logic_vector (dsize - 1 downto 0);
            acc_out         : in std_logic_vector (dsize - 1 downto 0);
            index_bus       : in std_logic_vector (dsize - 1 downto 0);
            bal             : in std_logic_vector (dsize - 1 downto 0);
            bah             : in std_logic_vector (dsize - 1 downto 0);
            addr_back       : out std_logic_vector (dsize - 1 downto 0);
            acc_in          : out std_logic_vector (dsize - 1 downto 0);
            abl             : out std_logic_vector (dsize - 1 downto 0);
            abh             : out std_logic_vector (dsize - 1 downto 0);
            pcl_inc_carry   : out std_logic;
            ea_carry        : out std_logic;
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

component d_flip_flop_bit
    port (  
            clk     : in std_logic;
            res_n   : in std_logic;
            set_n   : in std_logic;
            we_n    : in std_logic;
            d       : in std_logic;
            q       : out std_logic
        );
end component;

component tri_state_buffer
    generic (
            dsize : integer := 8
            );
    port (  
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;

component address_calculator
    generic (   dsize : integer := 8
            );
    port ( 
            sel         : in std_logic_vector (1 downto 0);
            addr1       : in std_logic_vector (dsize - 1 downto 0);
            addr2       : in std_logic_vector (dsize - 1 downto 0);
            addr_out    : out std_logic_vector (dsize - 1 downto 0);
            carry_in    : in std_logic;
            carry_out   : out std_logic
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

--------- signals for address calucuration ----------
signal al_buf_we_n : std_logic;
signal ah_buf_we_n : std_logic;
signal tmp_buf_we_n : std_logic;

signal al_reg_in : std_logic_vector (dsize - 1 downto 0);
signal ah_reg_in : std_logic_vector (dsize - 1 downto 0);
signal tmp_reg_in : std_logic_vector (dsize - 1 downto 0);
signal al_reg : std_logic_vector (dsize - 1 downto 0);
signal ah_reg : std_logic_vector (dsize - 1 downto 0);
signal tmp_reg : std_logic_vector (dsize - 1 downto 0);


signal a_sel : std_logic_vector (1 downto 0);
signal addr1 : std_logic_vector (dsize - 1 downto 0);
signal addr2 : std_logic_vector (dsize - 1 downto 0);
signal addr_out : std_logic_vector (dsize - 1 downto 0);

signal addr_c_in : std_logic;
signal addr_c : std_logic;
signal addr_c_reg : std_logic;

signal pcl_carry_reg_in : std_logic;

----------- signals for arithmatic ----------
signal sel : std_logic_vector (3 downto 0);
signal d1 : std_logic_vector (dsize - 1 downto 0);
signal d2 : std_logic_vector (dsize - 1 downto 0);
signal d_out : std_logic_vector (dsize - 1 downto 0);
signal alu_out : std_logic_vector (dsize - 1 downto 0);

signal n : std_logic;
signal z : std_logic;
signal c : std_logic;
signal v : std_logic;

signal arith_buf_we_n : std_logic;
signal arith_buf_oe_n : std_logic;
signal arith_reg_in : std_logic_vector (dsize - 1 downto 0);
signal arith_reg : std_logic_vector (dsize - 1 downto 0);
signal arith_reg_out : std_logic_vector (dsize - 1 downto 0);
signal d_oe_n : std_logic;

begin
    ----------------------------------------
     -- address calucurator instances ----
    ----------------------------------------
    al_dff : d_flip_flop generic map (dsize) 
            port map(clk, '1', '1', al_buf_we_n, al_reg_in, al_reg);
    ah_dff : d_flip_flop generic map (dsize) 
            port map(clk, '1', '1', ah_buf_we_n, ah_reg_in, ah_reg);
    tmp_dff : d_flip_flop generic map (dsize) 
            port map(clk, '1', '1', tmp_buf_we_n, tmp_reg_in, tmp_reg);

    --pcl carry flag set.
    pcl_carry_reg_in <= addr_c when pcl_inc_n = '0' else
                '0';

    pch_carry_dff_bit : d_flip_flop_bit 
            port map(clk, '1', '1', 
                    '0', pcl_carry_reg_in, pcl_inc_carry);

    addr_calc_inst : address_calculator generic map (dsize)
            port map (a_sel, addr1, addr2, addr_out, addr_c_in, addr_c);

    ea_carry_dff_bit : d_flip_flop_bit 
            port map(clk, '1', '1', 
                    '0', addr_c, addr_c_reg);

    ----------------------------------------
     -- arithmatic operation instances ----
    ----------------------------------------
    arith_dff : d_flip_flop generic map (dsize) 
            port map(clk, '1', '1', arith_buf_we_n, arith_reg_in, arith_reg);
    arith_buf : tri_state_buffer generic map (dsize)
            port map (arith_buf_oe_n, arith_reg, arith_reg_out);

    alu_inst : alu_core generic map (dsize)
            port map (sel, d1, d2, alu_out, carry_in, n, z, c, v);
    alu_buf : tri_state_buffer generic map (dsize)
            port map (d_oe_n, alu_out, d_out);

    -------------------------------
    ------ alu main process -------
    -------------------------------
    alu_p : process (
                    clk, 
                    ---for address calucuration
                    pcl_inc_n, pch_inc_n, sp_oe_n, sp_push_n, sp_pop_n,
                    abs_xy_n, pg_next_n, zp_n, zp_xy_n, rel_calc_n, 
                    indir_n, indir_x_n, indir_y_n, 
                    index_bus, bal, bah,

                    --for arithmatic operation.
                    arith_en_n,
                    instruction, exec_cycle, int_d_bus, acc_out, 
                    carry_in, n, z, c, v
                    )

constant ADDR_ADC    : std_logic_vector (1 downto 0) := "00";
constant ADDR_INC    : std_logic_vector (1 downto 0) := "01";
constant ADDR_DEC    : std_logic_vector (1 downto 0) := "10";
constant ADDR_SIGNED_ADD : std_logic_vector (1 downto 0) := "11";

constant ALU_AND    : std_logic_vector (3 downto 0) := "0000";
constant ALU_EOR    : std_logic_vector (3 downto 0) := "0001";
constant ALU_OR     : std_logic_vector (3 downto 0) := "0010";
constant ALU_BIT    : std_logic_vector (3 downto 0) := "0011";
constant ALU_ADC    : std_logic_vector (3 downto 0) := "0100";
constant ALU_SBC    : std_logic_vector (3 downto 0) := "0101";
constant ALU_CMP    : std_logic_vector (3 downto 0) := "0110";
constant ALU_ASL    : std_logic_vector (3 downto 0) := "0111";
constant ALU_LSR    : std_logic_vector (3 downto 0) := "1000";
constant ALU_ROL    : std_logic_vector (3 downto 0) := "1001";
constant ALU_ROR    : std_logic_vector (3 downto 0) := "1010";
constant ALU_INC    : std_logic_vector (3 downto 0) := "1011";
constant ALU_DEC    : std_logic_vector (3 downto 0) := "1100";

---for indirect addressing.
constant T0 : std_logic_vector (5 downto 0) := "000000";
constant T1 : std_logic_vector (5 downto 0) := "000001";
constant T2 : std_logic_vector (5 downto 0) := "000010";
constant T3 : std_logic_vector (5 downto 0) := "000011";
constant T4 : std_logic_vector (5 downto 0) := "000100";
constant T5 : std_logic_vector (5 downto 0) := "000101";

procedure output_d_bus is
begin
    arith_buf_we_n <= '0';
    arith_buf_oe_n <= '0';
    d_oe_n <= '0';
    arith_reg_in <= d_out;
    if (clk = '0') then
        int_d_bus <= d_out;
    else
        int_d_bus <= arith_reg_out;
    end if;
end  procedure;

procedure set_nz is
begin
    negative <= n;
    zero <= z;
end procedure;

    begin

    -------------------------------
    ----- address calcuration -----
    -------------------------------
    if (pcl_inc_n = '0') then
        ea_carry <= '0';
        a_sel <= ADDR_INC;
        addr1 <= bal;
        addr_back <= addr_out;

        --keep the value in the cycle
        al_buf_we_n <= '0';
        al_reg_in <= bal;
        if (instruction = "01001100") then
            ---exceptional case: only jmp instruction 
            abl <= bal;
        else
            if (clk = '0') then
                abl <= bal;
            else
                abl <= al_reg;
            end if;
        end if;
        abh <= bah;

    elsif (pch_inc_n = '0') then
        ea_carry <= '0';
        a_sel <= ADDR_INC;
        addr1 <= bah;
        addr_back <= addr_out;

        --inc pch cycle is not fetch cycle.
        --it is special cycle.
        abl <= bal;
        abh <= bah;

    elsif (sp_oe_n = '0') then
        --stack operation...
        abh <= "00000001";
        ea_carry <= '0';

        if (sp_push_n /= '0' and sp_pop_n /= '0') then
            abl <= bal;
        elsif (sp_pop_n = '0') then
            --case pop
            a_sel <= ADDR_INC;
            addr1 <= bal;
            addr_back <= addr_out;

            al_buf_we_n <= '0';
            al_reg_in <= bal;
            if (clk = '0') then
                abl <= bal;
            else
                abl <= al_reg;
            end if;
        else
            ---case push
            a_sel <= ADDR_DEC;
            addr1 <= bal;
            addr_back <= addr_out;

            al_buf_we_n <= '0';
            al_reg_in <= bal;
            if (clk = '0') then
                abl <= bal;
            else
                abl <= al_reg;
            end if;
        end if;
    elsif (zp_n = '0') then
        ea_carry <= '0';
        if (zp_xy_n <= '0') then
            a_sel <= ADDR_ADC;
            addr1 <= bal;
            addr2 <= index_bus;
            addr_c_in <= '0';

            abh <= "00000000";
            abl <= addr_out;
        else
            abh <= "00000000";
            abl <= bal;
        end if;

    elsif (abs_xy_n = '0') then
        if (pg_next_n = '0') then
            a_sel <= ADDR_INC;
            addr1 <= bah;
            ea_carry <= '0';

            al_buf_we_n <= '1';
            abh <= addr_out;
            ---al is in the al_reg.
            abl <= al_reg;
        else
            a_sel <= ADDR_ADC;
            addr1 <= bal;
            addr2 <= index_bus;
            addr_c_in <= '0';
            ea_carry <= addr_c;

            ---keep al for page crossed case
            al_buf_we_n <= '0';
            al_reg_in <= addr_out;
            abh <= bah;
            abl <= addr_out;
        end if;

    elsif (rel_calc_n = '0') then
        if (pg_next_n = '0') then
            if (int_d_bus(7) = '1') then
                ---backward relative branch
                a_sel <= ADDR_DEC;
            else
                ---forward relative branch
                a_sel <= ADDR_INC;
            end if;
            ---addr1 is pch.`
            addr1 <= bah;
            ---rel val is on the d_bus.
            addr_back <= addr_out;
            ea_carry <= '0'; 

            --keep the value in the cycle
            ah_buf_we_n <= '0';
            ah_reg_in <= addr_out;
            abh <= addr_out;
            --al no change.
            abl <= bal;
        else
            a_sel <= ADDR_SIGNED_ADD;
            ---addr1 is pcl.`
            addr1 <= bal;
            ---rel val is on the d_bus.
            addr2 <= int_d_bus;
            addr_back <= addr_out;
            addr_c_in <= '0';
            ea_carry <= addr_c_reg;

            --keep the value in the cycle
            al_buf_we_n <= '0';
            al_reg_in <= addr_out;
            abh <= bah;
            abl <= addr_out;
        end if;
    elsif (indir_n = '0') then
        abh <= bah;
        --get next address.
        addr1 <= bal;
        a_sel <= ADDR_INC;
        abl <= addr_out;

        --TODO: must handle page crossing case...
        ea_carry <= addr_c;

    elsif (indir_x_n = '0') then
        if (exec_cycle = T2) then
            ---input is IAL, but this cycle doesn't do anything....
            abh <= "00000000";
            abl <= bal;

            --save base addr.
            tmp_buf_we_n <= '0';
            tmp_reg_in <= bal;
        elsif (exec_cycle = T3) then

            ---add x reg.
            a_sel <= ADDR_ADC;
            addr1 <= tmp_reg;
            addr2 <= index_bus;
            addr_c_in <= '0';

            --save base addr.
            tmp_buf_we_n <= '0';
            tmp_reg_in <= addr_out;

            --output @IAL+x
            abh <= "00000000";
            abl <= addr_out;

            ---save BAL.
            al_buf_we_n <= '0';
            al_reg_in <= int_d_bus;

        elsif (exec_cycle = T4) then
            al_buf_we_n <= '1';
            tmp_buf_we_n <= '1';

            ---increment.
            a_sel <= ADDR_INC;
            addr1 <= tmp_reg;

            --output @IAL+x
            abh <= "00000000";
            abl <= addr_out;

            ---save BAH.
            ah_buf_we_n <= '0';
            ah_reg_in <= int_d_bus;
        elsif (exec_cycle = T5) then
            ah_buf_we_n <= '1';

            --output ah/al reg.
            abh <= ah_reg;
            abl <= al_reg;
        end if; -- if (exec_cycle = T2) then

    elsif (indir_y_n = '0') then

        if (exec_cycle = T2) then
            ---input is IAL.
            abh <= "00000000";
            abl <= bal;

            ---save BAL.
            al_buf_we_n <= '0';
            al_reg_in <= int_d_bus;
            ea_carry <= '0';

            --get next address (IAL + 1)
            a_sel <= ADDR_INC;
            addr1 <= bal;
            tmp_buf_we_n <= '0';
            tmp_reg_in <= addr_out;

        elsif (exec_cycle = T3) then
            al_buf_we_n <= '1';
            tmp_buf_we_n <= '1';

            abh <= "00000000";

            --input is IAL + 1
            abl <= tmp_reg;

            ---save BAH.
            ah_buf_we_n <= '0';
            ah_reg_in <= int_d_bus;
            ea_carry <= addr_c;

        elsif (exec_cycle = T4) then
            ---add y reg.
            a_sel <= ADDR_ADC;

            --bal from al_reg.
            addr1 <= al_reg;
            addr2 <= index_bus;
            addr_c_in <= '0';
            ea_carry <= addr_c;

            --bah from ah_reg
            abh <= ah_reg;
            abl <= addr_out;

            ---save the address.
            al_buf_we_n <= '0';
            al_reg_in <= addr_out;
            tmp_buf_we_n <= '0';
            tmp_reg_in <= ah_reg;
        elsif (exec_cycle = T5) then
            al_buf_we_n <= '1';
            tmp_buf_we_n <= '1';
            ea_carry <= '0';
            a_sel <= ADDR_INC;
            addr1 <= tmp_reg;
            ---next page.
            abh <= addr_out;
            abl <= al_reg;
        else
            al_buf_we_n <= '1';
            ah_buf_we_n <= '1';
            tmp_buf_we_n <= '1';
            ea_carry <= '0';
        end if; -- if (exec_cycle = T2) then
    else
        al_buf_we_n <= '1';
        ah_buf_we_n <= '1';
        tmp_buf_we_n <= '1';
        ea_carry <= '0';

        abl <= bal;
        abh <= bah;

        ----addr_back is always bal for jmp/jsr instruction....
        -----TODO must check later if it's ok.
        addr_back <= bal;
    end if; --if (pcl_inc_n = '0') then

    -------------------------------
    ---- arithmatic operations-----
    -------------------------------
    if (arith_en_n = '0') then

        if instruction = conv_std_logic_vector(16#ca#, dsize) then
            --d_print("dex");
            sel <= ALU_DEC;
            d1 <= index_bus;
            set_nz;
            output_d_bus;

        elsif instruction = conv_std_logic_vector(16#88#, dsize) then
            --d_print("dey");
            sel <= ALU_DEC;
            d1 <= index_bus;
            set_nz;
            output_d_bus;

        elsif instruction = conv_std_logic_vector(16#e8#, dsize) then
            --d_print("inx");
            sel <= ALU_INC;
            d1 <= index_bus;
            set_nz;
            output_d_bus;

        elsif instruction = conv_std_logic_vector(16#c8#, dsize) then
            --d_print("iny");
            sel <= ALU_INC;
            d1 <= index_bus;
            set_nz;
            output_d_bus;

        elsif instruction = conv_std_logic_vector(16#0a#, dsize) then
            --d_print("asl");
            sel <= ALU_ASL;
            d1 <= acc_out;
            set_nz;
            carry_out <= c;
            output_d_bus;

        elsif instruction = conv_std_logic_vector(16#2a#, dsize) then
            --rol acc.
            sel <= ALU_ROL;
            d1 <= acc_out;
            set_nz;
            carry_out <= c;
            output_d_bus;

        elsif instruction = conv_std_logic_vector(16#4a#, dsize) then
            --lsr acc.
            sel <= ALU_LSR;
            d1 <= acc_out;
            set_nz;
            carry_out <= c;
            output_d_bus;

        elsif instruction = conv_std_logic_vector(16#6a#, dsize) then
            --ror acc.
            sel <= ALU_ROR;
            d1 <= acc_out;
            set_nz;
            carry_out <= c;
            output_d_bus;

        --instruction is aaabbbcc format.
        --aaa=opcode
        --bbb=addr mode
        --000	#immediate
        --001	zero page
        --010	accumulator
        --011	absolute
        --101	zero page,X
        --111	absolute,X
        --cc=optional field.
        elsif instruction (1 downto 0) = "01" then
            if instruction (7 downto 5) = "000" then
                --d_print("ora");
                sel <= ALU_OR;
                d1 <= acc_out;
                d2 <= int_d_bus;
                d_oe_n <= '0';
                acc_in <= d_out;
                set_nz;

            elsif instruction (7 downto 5) = "001" then
                --d_print("and");
                sel <= ALU_AND;
                d1 <= acc_out;
                d2 <= int_d_bus;
                d_oe_n <= '0';
                acc_in <= d_out;
                set_nz;

            elsif instruction (7 downto 5) = "010" then
                --d_print("eor");
                sel <= ALU_EOR;
                d1 <= acc_out;
                d2 <= int_d_bus;
                d_oe_n <= '0';
                acc_in <= d_out;
                set_nz;

            elsif instruction (7 downto 5) = "011" then
                --d_print("adc");
                sel <= ALU_ADC;
                d1 <= acc_out;
                d2 <= int_d_bus;
                d_oe_n <= '0';

                acc_in <= d_out;
                set_nz;
                carry_out <= c;
                overflow <= v;

            elsif instruction (7 downto 5) = "110" then
                --d_print("cmp");
                --cmpare A - M.
                sel <= ALU_CMP;
                d1 <= acc_out;
                d2 <= int_d_bus;
                set_nz;
                carry_out <= c;

            elsif instruction (7 downto 5) = "111" then
                --d_print("sbc");
                sel <= ALU_SBC;
                d1 <= acc_out;
                d2 <= int_d_bus;
                d_oe_n <= '0';

                acc_in <= d_out;
                set_nz;
                carry_out <= c;
                overflow <= v;

            end if; --if instruction (7 downto 5) = "000" then

        elsif instruction (1 downto 0) = "10" then

            --this group is all memory to memory instruction (except for stx/ldx).
            --memory to memory operation takes two cycles.
            --first is write original data 
            --second is write modified data

            --001	zero page
            --011	absolute
            --101	zero page,X
            --111	absolute,X
            if ((exec_cycle = T2 and instruction (4 downto 2) = "001") or 
                (exec_cycle = T3 and instruction (4 downto 2) = "011") or 
                (exec_cycle = T3 and instruction (4 downto 2) = "101") or 
                (exec_cycle = T4 and instruction (4 downto 2) = "111")) then
                arith_buf_we_n <= '0';
                arith_reg_in <= int_d_bus;

            elsif ((exec_cycle = T3 and instruction (4 downto 2) = "001") or 
                (exec_cycle = T4 and instruction (4 downto 2) = "011") or 
                (exec_cycle = T4 and instruction (4 downto 2) = "101") or 
                (exec_cycle = T5 and instruction (4 downto 2) = "111")) then
                --first cycle. keep input variable.
                --d_print("inc first.");
                arith_buf_we_n <= '1';

                arith_buf_oe_n <= '1';
                d_oe_n <= '1';

                d1 <= arith_reg;
            else
                --second cycle read from register, output modified data.
                --d_print("inc second...");
                arith_buf_we_n <= '1';
                arith_buf_oe_n <= '0';
                d_oe_n <= '0';

                int_d_bus <= d_out;
            end if;

            if instruction (7 downto 5) = "000" then
                --d_print("asl");
                sel <= ALU_ASL;
                set_nz;
                carry_out <= c;

            elsif instruction (7 downto 5) = "001" then
                --d_print("rol");
                sel <= ALU_ROL;
                set_nz;
                carry_out <= c;

            elsif instruction (7 downto 5) = "010" then
                --d_print("lsr");
                sel <= ALU_LSR;
                set_nz;
                carry_out <= c;

            elsif instruction (7 downto 5) = "011" then
                --d_print("ror");
                sel <= ALU_ROR;
                set_nz;
                carry_out <= c;

            elsif instruction (7 downto 5) = "110" then
                --d_print("dec");
                sel <= ALU_DEC;
                set_nz;

            elsif instruction (7 downto 5) = "111" then
                --d_print("alu inc");
                sel <= ALU_INC;
                set_nz;

            end if; --if instruction (7 downto 5) = "000" then

        elsif instruction (1 downto 0) = "00" then
            if instruction (7 downto 5) = "001" then
                --d_print("bit");
                sel <= ALU_BIT;
                d1 <= acc_out;
                d2 <= int_d_bus;
                set_nz;
                overflow <= v;
            elsif instruction (7 downto 5) = "110" then
                --d_print("cpy");
                sel <= ALU_CMP;
                d1 <= index_bus;
                d2 <= int_d_bus;
                set_nz;
                carry_out <= c;

            elsif instruction (7 downto 5) = "111" then
               -- d_print("cpx");
                sel <= ALU_CMP;
                d1 <= index_bus;
                d2 <= int_d_bus;
                set_nz;
                carry_out <= c;

            end if; --if instruction (7 downto 5) = "001" then
        end if; --if instruction = conv_std_logic_vector(16#ca#, dsize) 
    else
        --d_print("no arith");
        d_oe_n <= '1';
        arith_buf_we_n <= '1';
        arith_buf_oe_n <= '1';
        int_d_bus <= (others => 'Z');
    end if; -- if (arith_en_n = '0') then

    end process;

end rtl;

-----------------------------------------
---------- Address calculator------------
-----------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity address_calculator is 
    generic (   dsize : integer := 8
            );
    port ( 
            sel         : in std_logic_vector (1 downto 0);
            addr1       : in std_logic_vector (dsize - 1 downto 0);
            addr2       : in std_logic_vector (dsize - 1 downto 0);
            addr_out    : out std_logic_vector (dsize - 1 downto 0);
            carry_in    : in std_logic;
            carry_out   : out std_logic
    );
end address_calculator;

architecture rtl of address_calculator is

constant ADDR_ADC    : std_logic_vector (1 downto 0) := "00";
constant ADDR_INC    : std_logic_vector (1 downto 0) := "01";
constant ADDR_DEC    : std_logic_vector (1 downto 0) := "10";
constant ADDR_SIGNED_ADD : std_logic_vector (1 downto 0) := "11";

begin

    alu_p : process (sel, addr1, addr2, carry_in)
    variable res : std_logic_vector (dsize downto 0);

    begin
    if sel = ADDR_ADC then
        res := ('0' & addr1) + ('0' & addr2) + carry_in;
        addr_out <= res(dsize - 1 downto 0);
        carry_out <= res(dsize);

    elsif sel = ADDR_SIGNED_ADD then
        res := ('0' & addr1) + ('0' & addr2);
        addr_out <= res(dsize - 1 downto 0);
--        if (addr2(dsize - 1) = '0') then
--            ---positive value add.
--            if (res(dsize) = '1') then
--                carry_out <= '1';
--            else
--                carry_out <= '0';
--            end if;
--        else
--            ---negative value add.
--            if (res(dsize) = '0') then
--                carry_out <= '1';
--            else
--                carry_out <= '0';
--            end if;
--        end if;
        -->>>simplified above.
        if ((addr2(dsize - 1) xor res(dsize)) = '1') then
            carry_out <= '1';
        else
            carry_out <= '0';
        end if;

    elsif sel = ADDR_INC then
        res := ('0' & addr1) + "000000001";
        addr_out <= res(dsize - 1 downto 0);
        carry_out <= res(dsize);
    elsif sel = ADDR_DEC then
        res := ('0' & addr1) - "000000001";
        addr_out <= res(dsize - 1 downto 0);
        carry_out <= res(dsize);
    end if;
    end process;

end rtl;


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

constant ALU_AND    : std_logic_vector (3 downto 0) := "0000";
constant ALU_EOR    : std_logic_vector (3 downto 0) := "0001";
constant ALU_OR     : std_logic_vector (3 downto 0) := "0010";
constant ALU_BIT    : std_logic_vector (3 downto 0) := "0011";
constant ALU_ADC    : std_logic_vector (3 downto 0) := "0100";
constant ALU_SBC    : std_logic_vector (3 downto 0) := "0101";
constant ALU_CMP    : std_logic_vector (3 downto 0) := "0110";
constant ALU_ASL    : std_logic_vector (3 downto 0) := "0111";
constant ALU_LSR    : std_logic_vector (3 downto 0) := "1000";
constant ALU_ROL    : std_logic_vector (3 downto 0) := "1001";
constant ALU_ROR    : std_logic_vector (3 downto 0) := "1010";
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
    if  (data = "00000000") then
        zero <= '1';
    else
        zero <= '0';
    end if;
end procedure;

    begin
    if sel = ALU_AND then
        res(dsize - 1 downto 0) := d1 and d2;
        set_n(res(dsize - 1 downto 0));
        set_z(res(dsize - 1 downto 0));
        d_out <= res(dsize - 1 downto 0);

    elsif sel = ALU_EOR then
        res(dsize - 1 downto 0) := d1 xor d2;
        set_n(res(dsize - 1 downto 0));
        set_z(res(dsize - 1 downto 0));
        d_out <= res(dsize - 1 downto 0);

    elsif sel = ALU_OR then
        res(dsize - 1 downto 0) := d1 or d2;
        set_n(res(dsize - 1 downto 0));
        set_z(res(dsize - 1 downto 0));
        d_out <= res(dsize - 1 downto 0);

    elsif sel = ALU_BIT then
        --transfer bit 7 and 6  of memory data to n, v flag.
        negative <= d2(7);
        overflow <= d2(6);
        ----zero bit after A and M.
        res(dsize - 1 downto 0) := d1 and d2;
        set_z(res(dsize - 1 downto 0));

    elsif sel = ALU_ADC then
        res := ('0' & d1) + ('0' & d2) + carry_in;
        d_out <= res(dsize - 1 downto 0);
        carry_out <= res(dsize);
        if ((d1(dsize - 1) = d2(dsize - 1)) 
            and (d1(dsize - 1) /= res(dsize - 1))) then
            overflow <= '1';
        else
            overflow <= '0';
        end if;
        set_n(res(dsize - 1 downto 0));
        set_z(res(dsize - 1 downto 0));

    elsif sel = ALU_SBC then
        ---A - M - ~C -> A
        res := ('0' & d1) - ('0' & d2) - not carry_in;
        d_out <= res(dsize - 1 downto 0);

        --c Set if unsigned borrow not required; cleared if unsigned borrow.
        carry_out <= not res(dsize);
        --v Set if signed borrow required; cleared if no signed borrow.
        if ((d1(dsize - 1) /= d2(dsize - 1)) 
            and (d1(dsize - 1) /= res(dsize - 1))) then
            overflow <= '1';
        else
            overflow <= '0';
        end if;
        set_n(res(dsize - 1 downto 0));
        set_z(res(dsize - 1 downto 0));

    elsif sel = ALU_CMP then
        res := ('0' & d1) - ('0' & d2);
        if (d1 >= d2) then
            carry_out <= '1';
        else
            carry_out <= '0';
        end if;
        set_n(res(dsize - 1 downto 0));
        set_z(res(dsize - 1 downto 0));

    elsif sel = ALU_ASL then
        res(dsize - 1 downto 1) := d1(dsize - 2 downto 0);
        res(0) := '0';

        d_out <= res(dsize - 1 downto 0);
        set_n(res(dsize - 1 downto 0));
        set_z(res(dsize - 1 downto 0));
        carry_out <= d1(dsize - 1);

    elsif sel = ALU_LSR then
        res(dsize - 1) := '0';
        res(dsize - 2 downto 0) := d1(dsize - 1 downto 1);

        d_out <= res(dsize - 1 downto 0);
        set_n(res(dsize - 1 downto 0));
        set_z(res(dsize - 1 downto 0));
        carry_out <= d1(0);

    elsif sel = ALU_ROL then
        res(dsize - 1 downto 1) := d1(dsize - 2 downto 0);
        res(0) := carry_in;

        d_out <= res(dsize - 1 downto 0);
        set_n(res(dsize - 1 downto 0));
        set_z(res(dsize - 1 downto 0));
        carry_out <= d1(7);

    elsif sel = ALU_ROR then
        res(dsize - 1) := carry_in;
        res(dsize - 2 downto 0) := d1(dsize - 1 downto 1);

        d_out <= res(dsize - 1 downto 0);
        set_n(res(dsize - 1 downto 0));
        set_z(res(dsize - 1 downto 0));
        carry_out <= d1(0);

    elsif sel = ALU_INC then
        res := ('0' & d1) + "000000001";
        d_out <= res(dsize - 1 downto 0);
        set_n(res(dsize - 1 downto 0));
        set_z(res(dsize - 1 downto 0));

    elsif sel = ALU_DEC then
        res := ('0' & d1) - "000000001";
        d_out <= res(dsize - 1 downto 0);
        set_n(res(dsize - 1 downto 0));
        set_z(res(dsize - 1 downto 0));

    end if;

    end process;

end rtl;

