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

---cpu main state:
type cpu_main_state is (
    --common state. idle and inst fetch.
    ST_IDLE,
    ST_CM_T0,

    --single byte inst execute.
    ST_A1_T1,

    --mem data operation
    ST_A21_T1,
    ST_A22_T1, ST_A22_T2,
    ST_A23_T1, ST_A23_T2, ST_A23_T3,
    ST_A24_T1, ST_A24_T2, ST_A24_T3, ST_A24_T4, ST_A24_T5,
    ST_A25_T1, ST_A25_T2, ST_A25_T3, ST_A25_T4,
    ST_A26_T1, ST_A26_T2, ST_A26_T3,
    ST_A27_T1, ST_A27_T2, ST_A27_T3, ST_A27_T4, ST_A27_T5,

    --store op.
    ST_A31_T1, ST_A31_T2,
    ST_A32_T1, ST_A32_T2, ST_A32_T3,
    ST_A33_T1, ST_A33_T2, ST_A33_T3, ST_A33_T4, ST_A33_T5,
    ST_A34_T1, ST_A34_T2, ST_A34_T3, ST_A34_T4,
    ST_A35_T1, ST_A35_T2, ST_A35_T3,
    ST_A36_T1, ST_A36_T2, ST_A36_T3, ST_A36_T4, ST_A36_T5,

    --memory to memory op.
    ST_A41_T1, ST_A41_T2, ST_A41_T3, ST_A41_T4,
    ST_A42_T1, ST_A42_T2, ST_A42_T3, ST_A42_T4, ST_A42_T5,
    ST_A43_T1, ST_A43_T2, ST_A43_T3, ST_A43_T4, ST_A43_T5,
    ST_A44_T1, ST_A44_T2, ST_A44_T3, ST_A44_T4, ST_A44_T5, ST_A44_T6, 

    --misc operation.
    ST_A51_T1, ST_A51_T2,
    ST_A52_T1, ST_A52_T2, ST_A52_T3,
    ST_A53_T1, ST_A53_T2, ST_A53_T3,ST_A53_T4, ST_A53_T5,
    ST_A55_T1, ST_A55_T2, ST_A55_T3, ST_A55_T4, ST_A55_T5,
    ST_A561_T1, ST_A561_T2,
    ST_A562_T1, ST_A562_T2, ST_A562_T3, ST_A562_T4,
    ST_A57_T1, ST_A57_T2, ST_A57_T3, ST_A57_T4, ST_A57_T5,
    ST_A58_T1, ST_A58_T2, ST_A58_T3,

    --reset vector.
    ST_RS_T0, ST_RS_T1, ST_RS_T2, ST_RS_T3, ST_RS_T4, ST_RS_T5, ST_RS_T6
    );

--cpu sub state.
--1 cpu clock is split into 8 state.
--1 cpu clock = 32 x base clock.
type cpu_sub_state is (
    ST_SUB00, ST_SUB01, ST_SUB02, ST_SUB03,
    ST_SUB10, ST_SUB11, ST_SUB12, ST_SUB13,
    ST_SUB20, ST_SUB21, ST_SUB22, ST_SUB23,
    ST_SUB30, ST_SUB31, ST_SUB32, ST_SUB33,
    ST_SUB40, ST_SUB41, ST_SUB42, ST_SUB43,
    ST_SUB50, ST_SUB51, ST_SUB52, ST_SUB53,
    ST_SUB60, ST_SUB61, ST_SUB62, ST_SUB63,
    ST_SUB70, ST_SUB71, ST_SUB72, ST_SUB73
    );

signal reg_main_cur_state      : cpu_main_state;
signal reg_main_next_state     : cpu_main_state;
signal reg_sub_cur_state      : cpu_sub_state;
signal reg_sub_next_state     : cpu_sub_state;

signal reg_r_nw     : std_logic;
signal reg_addr     : std_logic_vector (15 downto 0);
signal reg_d_in     : std_logic_vector (7 downto 0);
signal reg_d_out    : std_logic_vector (7 downto 0);


begin
    --state transition process...
    set_stat_p : process (pi_rst_n, pi_base_clk)
    begin
        if (pi_rst_n = '0') then
            reg_main_cur_state <= ST_IDLE;
            reg_sub_cur_state <= ST_SUB00;
        elsif (rising_edge(pi_base_clk)) then
            reg_main_cur_state <= reg_main_next_state;
            reg_sub_cur_state <= reg_sub_next_state;
        end if;--if (pi_rst_n = '0') then
    end process;

    --state change to next.
    tx_next_sub_stat_p : process (reg_sub_cur_state, pi_cpu_en)
    begin
        case reg_sub_cur_state is
            when ST_SUB00 =>
                if (pi_cpu_en(0) = '1') then
                    reg_sub_next_state <= ST_SUB01;
                else
                    reg_sub_next_state <= reg_sub_cur_state;
                end if;
            when ST_SUB01 =>
                reg_sub_next_state <= ST_SUB02;
            when ST_SUB02 =>
                reg_sub_next_state <= ST_SUB03;
            when ST_SUB03 =>
                reg_sub_next_state <= ST_SUB10;
            when ST_SUB10 =>
                reg_sub_next_state <= ST_SUB11;
            when ST_SUB11 =>
                reg_sub_next_state <= ST_SUB12;
            when ST_SUB12 =>
                reg_sub_next_state <= ST_SUB13;
            when ST_SUB13 =>
                reg_sub_next_state <= ST_SUB20;
            when ST_SUB20 =>
                reg_sub_next_state <= ST_SUB21;
            when ST_SUB21 =>
                reg_sub_next_state <= ST_SUB22;
            when ST_SUB22 =>
                reg_sub_next_state <= ST_SUB23;
            when ST_SUB23 =>
                reg_sub_next_state <= ST_SUB30;
            when ST_SUB30 =>
                reg_sub_next_state <= ST_SUB31;
            when ST_SUB31 =>
                reg_sub_next_state <= ST_SUB32;
            when ST_SUB32 =>
                reg_sub_next_state <= ST_SUB33;
            when ST_SUB33 =>
                reg_sub_next_state <= ST_SUB40;
            when ST_SUB40 =>
                reg_sub_next_state <= ST_SUB41;
            when ST_SUB41 =>
                reg_sub_next_state <= ST_SUB42;
            when ST_SUB42 =>
                reg_sub_next_state <= ST_SUB43;
            when ST_SUB43 =>
                reg_sub_next_state <= ST_SUB50;
            when ST_SUB50 =>
                reg_sub_next_state <= ST_SUB51;
            when ST_SUB51 =>
                reg_sub_next_state <= ST_SUB52;
            when ST_SUB52 =>
                reg_sub_next_state <= ST_SUB53;
            when ST_SUB53 =>
                reg_sub_next_state <= ST_SUB60;
            when ST_SUB60 =>
                reg_sub_next_state <= ST_SUB61;
            when ST_SUB61 =>
                reg_sub_next_state <= ST_SUB62;
            when ST_SUB62 =>
                reg_sub_next_state <= ST_SUB63;
            when ST_SUB63 =>
                reg_sub_next_state <= ST_SUB70;
            when ST_SUB70 =>
                reg_sub_next_state <= ST_SUB71;
            when ST_SUB71 =>
                reg_sub_next_state <= ST_SUB72;
            when ST_SUB72 =>
                reg_sub_next_state <= ST_SUB73;
            when ST_SUB73 =>
                reg_sub_next_state <= ST_SUB00;
        end case;
    end process;

    --state change to next.
    tx_next_main_stat_p : process (reg_main_cur_state, reg_sub_cur_state, pi_rst_n)

---fake docode function...
variable test_index : integer range 0 to 26 := 0;
variable next_inst_state : cpu_main_state;

procedure get_next_inst_state is
begin
    if (test_index <= 25) then
        test_index := test_index + 1;
    else
        test_index := 1;
    end if;
    
    if (test_index = 1) then
        next_inst_state := ST_A1_T1;
    elsif (test_index = 2) then
        next_inst_state := ST_A22_T1;
    elsif (test_index = 3) then
        next_inst_state := ST_A23_T1;
    elsif (test_index = 4) then
        next_inst_state := ST_A24_T1;
    elsif (test_index = 5) then
        next_inst_state := ST_A25_T1;
    elsif (test_index = 6) then
        next_inst_state := ST_A26_T1;
    elsif (test_index = 7) then
        next_inst_state := ST_A27_T1;
    elsif (test_index = 8) then
        next_inst_state := ST_A31_T1;
    elsif (test_index = 9) then
        next_inst_state := ST_A32_T1;
    elsif (test_index = 10) then
        next_inst_state := ST_A33_T1;
    elsif (test_index = 11) then
        next_inst_state := ST_A34_T1;
    elsif (test_index = 12) then
        next_inst_state := ST_A35_T1;
    elsif (test_index = 13) then
        next_inst_state := ST_A36_T1;
    elsif (test_index = 14) then
        next_inst_state := ST_A41_T1;
    elsif (test_index = 15) then
        next_inst_state := ST_A42_T1;
    elsif (test_index = 16) then
        next_inst_state := ST_A43_T1;
    elsif (test_index = 17) then
        next_inst_state := ST_A44_T1;
    elsif (test_index = 18) then
        next_inst_state := ST_A51_T1;
    elsif (test_index = 19) then
        next_inst_state := ST_A52_T1;
    elsif (test_index = 20) then
        next_inst_state := ST_A53_T1;
    elsif (test_index = 21) then
        next_inst_state := ST_A55_T1;
    elsif (test_index = 22) then
        next_inst_state := ST_A561_T1;
    elsif (test_index = 23) then
        next_inst_state := ST_A562_T1;
    elsif (test_index = 24) then
        next_inst_state := ST_A57_T1;
    elsif (test_index = 25) then
        next_inst_state := ST_A58_T1;
    else
        next_inst_state := ST_IDLE;
    end if;
end;

    begin
        case reg_main_cur_state is
            -----idle...
            when ST_IDLE =>
                if (pi_rst_n = '0') then
                    reg_main_next_state <= reg_main_cur_state;
                else
                    reg_main_next_state <= ST_RS_T0;
                end if;
            -----reset...
            when ST_RS_T0 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_RS_T1;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_RS_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_RS_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_RS_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_RS_T3;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_RS_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_RS_T4;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_RS_T4 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_RS_T5;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_RS_T5 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_RS_T6;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_RS_T6 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;

            --instruction fetch
            when ST_CM_T0 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    get_next_inst_state;
                    reg_main_next_state <= next_inst_state;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;

            --A1 inst.(single byte)
            when ST_A1_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;

            --A2 inst.
            when ST_A21_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A22_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A22_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A22_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A23_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A23_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A23_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A23_T3;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A23_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A24_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A24_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A24_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A24_T3;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A24_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A24_T4;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A24_T4 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A24_T5;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A24_T5 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A25_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A25_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A25_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A25_T3;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A25_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A25_T4;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A25_T4 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A26_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A26_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A26_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A26_T3;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A26_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A27_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A27_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A27_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A27_T3;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A27_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A27_T4;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A27_T4 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A27_T5;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A27_T5 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;

            --A3 inst.
            when ST_A31_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A31_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A31_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A32_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A32_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A32_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A32_T3;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A32_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A33_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A33_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A33_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A33_T3;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A33_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A33_T4;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A33_T4 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A33_T5;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A33_T5 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A34_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A34_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A34_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A34_T3;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A34_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A34_T4;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A34_T4 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A35_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A35_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A35_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A35_T3;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A35_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A36_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A36_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A36_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A36_T3;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A36_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A36_T4;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A36_T4 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A36_T5;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A36_T5 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;


            --A4 inst.
            when ST_A41_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A41_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A41_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A41_T3;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A41_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A41_T4;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A41_T4 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A42_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A42_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A42_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A42_T3;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A42_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A42_T4;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A42_T4 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A42_T5;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A42_T5 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A43_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A43_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A43_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A43_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A43_T4;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A43_T4 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A43_T5;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A43_T5 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A44_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A44_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A44_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A44_T3;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A44_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A44_T4;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A44_T4 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A44_T5;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A44_T5 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A44_T6;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A44_T6 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;


            --A5 inst.
            when ST_A51_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A51_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A51_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A52_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A52_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A52_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A52_T3;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A52_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A53_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A53_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A53_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A53_T3;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A53_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A53_T4;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A53_T4 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A53_T5;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A53_T5 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A55_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A55_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A55_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A55_T3;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A55_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A55_T4;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A55_T4 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A55_T5;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A55_T5 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A561_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A561_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A561_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A562_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A562_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A562_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A562_T3;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A562_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A562_T4;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A562_T4 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A57_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A57_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A57_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A57_T3;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A57_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A57_T4;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A57_T4 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A57_T5;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A57_T5 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A58_T1 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A58_T2;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A58_T2 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_A58_T3;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;
            when ST_A58_T3 =>
                if (reg_sub_cur_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_cur_state;
                end if;

--            ---not ready yet...
--            when others =>
--                reg_main_next_state <= reg_main_cur_state;
        end case;
    end process;

    po_r_nw     <= reg_r_nw;
    po_addr     <= reg_addr;
    pio_d_io    <= reg_d_out;
    reg_d_in    <= pio_d_io;

end rtl;

