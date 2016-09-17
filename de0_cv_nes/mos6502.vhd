library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

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
    --imm
    ST_A21_T1,
    --zp
    ST_A22_T1, ST_A22_T2,
    --abs
    ST_A23_T1, ST_A23_T2, ST_A23_T3,
    --indir, x
    ST_A24_T1, ST_A24_T2, ST_A24_T3, ST_A24_T4, ST_A24_T5,
    --abs xy
    ST_A25_T1, ST_A25_T2, ST_A25_T3, ST_A25_T4,
    --zp xy
    ST_A26_T1, ST_A26_T2, ST_A26_T3,
    --indir, y
    ST_A27_T1, ST_A27_T2, ST_A27_T3, ST_A27_T4, ST_A27_T5,

    --store op.
    --zp
    ST_A31_T1, ST_A31_T2,
    --abs
    ST_A32_T1, ST_A32_T2, ST_A32_T3,
    --indir, x
    ST_A33_T1, ST_A33_T2, ST_A33_T3, ST_A33_T4, ST_A33_T5,
    --abs xy
    ST_A34_T1, ST_A34_T2, ST_A34_T3, ST_A34_T4,
    --zp xy
    ST_A35_T1, ST_A35_T2, ST_A35_T3,
    --indir, y
    ST_A36_T1, ST_A36_T2, ST_A36_T3, ST_A36_T4, ST_A36_T5,

    --memory to memory op.
    --zp
    ST_A41_T1, ST_A41_T2, ST_A41_T3, ST_A41_T4,
    --abs
    ST_A42_T1, ST_A42_T2, ST_A42_T3, ST_A42_T4, ST_A42_T5,
    --zp x
    ST_A43_T1, ST_A43_T2, ST_A43_T3, ST_A43_T4, ST_A43_T5,
    --abs x
    ST_A44_T1, ST_A44_T2, ST_A44_T3, ST_A44_T4, ST_A44_T5, ST_A44_T6, 

    --misc operation.
    --push
    ST_A51_T1, ST_A51_T2,
    --pull
    ST_A52_T1, ST_A52_T2, ST_A52_T3,
    --jmp
    ST_A53_T1, ST_A53_T2, ST_A53_T3,ST_A53_T4, ST_A53_T5,
    --rti
    ST_A55_T1, ST_A55_T2, ST_A55_T3, ST_A55_T4, ST_A55_T5,
    --jmp abs
    ST_A561_T1, ST_A561_T2,
    --jmp indir
    ST_A562_T1, ST_A562_T2, ST_A562_T3, ST_A562_T4,
    --rts
    ST_A57_T1, ST_A57_T2, ST_A57_T3, ST_A57_T4, ST_A57_T5,
    --branch
    ST_A58_T1, ST_A58_T2, ST_A58_T3,

    --reset vector.
    ST_RS_T0, ST_RS_T1, ST_RS_T2, ST_RS_T3, ST_RS_T4, ST_RS_T5, ST_RS_T6, ST_RS_T7,

    --invalid state
    ST_INV
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

--Most instructions that explicitly reference memory locations have bit patterns of the form aaabbbcc. 
--The aaa and cc bits determine the opcode, and the bbb bits determine the addressing mode.
type cpu_state_array    is array (0 to 255) of cpu_main_state;
constant inst_decode_rom : cpu_state_array := (
    --00 - 07
    ST_INV,     ST_A24_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A22_T1,  ST_INV,     ST_INV,
    --08 - 0f
    ST_INV,     ST_A21_T1,  ST_A1_T1,   ST_INV,     ST_INV,     ST_A23_T1,  ST_INV,     ST_INV,
    --10 - 17
    ST_INV,     ST_A27_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A26_T1,  ST_INV,     ST_INV,
    --18 - 1f
    ST_A1_T1,   ST_A25_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A25_T1,  ST_INV,     ST_INV,
    --20 - 27
    ST_INV,     ST_A24_T1,  ST_INV,     ST_INV,     ST_A22_T1,  ST_A22_T1,  ST_INV,     ST_INV,
    --28 - 2f
    ST_INV,     ST_A21_T1,  ST_A1_T1,   ST_INV,     ST_A23_T1,  ST_A23_T1,  ST_INV,     ST_INV,
    --30 - 37
    ST_INV,     ST_A27_T1,  ST_INV,     ST_INV,     ST_A26_T1,  ST_INV,     ST_INV,     ST_INV,
    --38 - 3f
    ST_A1_T1,   ST_A25_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A25_T1,  ST_INV,     ST_INV,
    --40 - 47
    ST_INV,     ST_A24_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A22_T1,  ST_INV,     ST_INV,
    --48 - 4f
    ST_INV,     ST_A21_T1,  ST_A1_T1,   ST_INV,     ST_INV,     ST_A23_T1,  ST_INV,     ST_INV,
    --50 - 57
    ST_INV,     ST_A27_T1,  ST_INV,     ST_INV,     ST_A26_T1,  ST_INV,     ST_INV,     ST_INV,
    --58 - 5f
    ST_A1_T1,   ST_A25_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A25_T1,  ST_INV,     ST_INV,
    --60 - 67
    ST_INV,     ST_A24_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A22_T1,  ST_INV,     ST_INV,
    --68 - 6f
    ST_INV,     ST_A21_T1,  ST_A1_T1,   ST_INV,     ST_INV,     ST_A23_T1,  ST_INV,     ST_INV,
    --70 - 77
    ST_INV,     ST_A27_T1,  ST_INV,     ST_INV,     ST_A26_T1,  ST_INV,     ST_INV,     ST_INV,
    --78 - 7f
    ST_A1_T1,   ST_A25_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A25_T1,  ST_INV,     ST_INV,
    --80 - 87
    ST_INV,     ST_INV,     ST_INV,     ST_INV,     ST_INV,     ST_INV,     ST_INV,     ST_INV,
    --88 - 8f
    ST_A1_T1,   ST_INV,     ST_A1_T1,   ST_INV,     ST_INV,     ST_INV,     ST_INV,     ST_INV,
    --90 - 97
    ST_INV,     ST_INV,     ST_INV,     ST_INV,     ST_INV,     ST_INV,     ST_INV,     ST_INV,
    --98 - 9f
    ST_A1_T1,   ST_INV,     ST_A1_T1,   ST_INV,     ST_INV,     ST_INV,     ST_INV,     ST_INV,
    --a0 - a7
    ST_A21_T1,  ST_A24_T1,  ST_A21_T1,  ST_INV,     ST_A22_T1,  ST_A22_T1,  ST_A22_T1,  ST_INV,
    --a8 - af
    ST_A1_T1,   ST_A21_T1,  ST_A1_T1,   ST_INV,     ST_A23_T1,  ST_A23_T1,  ST_A23_T1,  ST_INV,
    --b0 - b7
    ST_INV,     ST_A27_T1,  ST_INV,     ST_A26_T1,  ST_A26_T1,  ST_A26_T1,  ST_INV,     ST_INV,
    --b8 - bf
    ST_A1_T1,   ST_A25_T1,  ST_A1_T1,   ST_INV,     ST_A25_T1,  ST_A25_T1,  ST_A25_T1,  ST_INV,
    --c0 - c7
    ST_A21_T1,  ST_A24_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A22_T1,  ST_INV,     ST_INV,
    --c8 - cf
    ST_A1_T1,   ST_A21_T1,  ST_A1_T1,   ST_INV,     ST_A23_T1,  ST_A23_T1,  ST_INV,     ST_INV,
    --d0 - d7
    ST_INV,     ST_A27_T1,  ST_INV,     ST_INV,     ST_A26_T1,  ST_INV,     ST_INV,     ST_INV,
    --d8 - df
    ST_A1_T1,   ST_A25_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A25_T1,  ST_INV,     ST_INV,
    --e0 - e7
    ST_A21_T1,  ST_A24_T1,  ST_INV,     ST_INV,     ST_A22_T1,  ST_A22_T1,  ST_INV,     ST_INV,
    --e8 - ef
    ST_A1_T1,   ST_A21_T1,  ST_A1_T1,   ST_INV,     ST_A23_T1,  ST_A23_T1,  ST_INV,     ST_INV,
    --f0 - f7
    ST_INV,     ST_A27_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A26_T1,  ST_INV,     ST_INV,
    --f8 - ff
    ST_A1_T1,   ST_A25_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A25_T1,  ST_INV,     ST_INV
);

signal reg_main_state           : cpu_main_state;
signal reg_main_next_state      : cpu_main_state;
signal reg_sub_state            : cpu_sub_state;
signal reg_sub_next_state       : cpu_sub_state;

--6502 register definition...
signal reg_inst     : std_logic_vector (7 downto 0);
signal reg_acc      : std_logic_vector (7 downto 0);
signal reg_x        : std_logic_vector (7 downto 0);
signal reg_y        : std_logic_vector (7 downto 0);
signal reg_idl_l    : std_logic_vector (7 downto 0);
signal reg_idl_h    : std_logic_vector (7 downto 0);
signal reg_sp       : std_logic_vector (7 downto 0);
signal reg_status   : std_logic_vector (7 downto 0);
signal reg_pc_l     : std_logic_vector (7 downto 0);
signal reg_pc_h     : std_logic_vector (7 downto 0);

--bus i/o reg.
signal reg_r_nw     : std_logic;
signal reg_addr     : std_logic_vector (15 downto 0);
signal reg_d_in     : std_logic_vector (7 downto 0);
signal reg_d_out    : std_logic_vector (7 downto 0);


begin
    --state transition process...
    set_stat_p : process (pi_rst_n, pi_base_clk)
    begin
        if (pi_rst_n = '0') then
            reg_main_state <= ST_IDLE;
            reg_sub_state <= ST_SUB00;
        elsif (rising_edge(pi_base_clk)) then
            reg_main_state <= reg_main_next_state;
            reg_sub_state <= reg_sub_next_state;
        end if;--if (pi_rst_n = '0') then
    end process;

    --state change to next.
    tx_next_sub_stat_p : process (reg_sub_state, pi_cpu_en)
    begin
        case reg_sub_state is
            when ST_SUB00 =>
                if (pi_cpu_en(0) = '1') then
                    reg_sub_next_state <= ST_SUB01;
                else
                    reg_sub_next_state <= reg_sub_state;
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
    tx_next_main_stat_p : process (reg_main_state, reg_sub_state, pi_rst_n)

    begin
        case reg_main_state is
            -----idle...
            when ST_IDLE =>
                if (pi_rst_n = '0') then
                    reg_main_next_state <= reg_main_state;
                else
                    reg_main_next_state <= ST_RS_T0;
                end if;
            -----reset...
            when ST_RS_T0 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_RS_T1;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_RS_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_RS_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_RS_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_RS_T3;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_RS_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_RS_T4;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_RS_T4 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_RS_T5;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_RS_T5 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_RS_T6;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_RS_T6 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_RS_T7;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_RS_T7 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;

            --instruction fetch
            when ST_CM_T0 =>
                if (reg_sub_state = ST_SUB73) then
                    ---instruction decode next state.
                    reg_main_next_state <= inst_decode_rom(conv_integer(reg_inst));
                else
                    reg_main_next_state <= reg_main_state;
                end if;

            --A1 inst.(single byte)
            when ST_A1_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;

            --A2 inst.
            when ST_A21_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A22_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A22_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A22_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A23_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A23_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A23_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A23_T3;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A23_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A24_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A24_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A24_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A24_T3;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A24_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A24_T4;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A24_T4 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A24_T5;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A24_T5 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A25_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A25_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A25_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A25_T3;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A25_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A25_T4;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A25_T4 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A26_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A26_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A26_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A26_T3;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A26_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A27_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A27_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A27_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A27_T3;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A27_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A27_T4;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A27_T4 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A27_T5;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A27_T5 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;

            --A3 inst.
            when ST_A31_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A31_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A31_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A32_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A32_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A32_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A32_T3;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A32_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A33_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A33_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A33_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A33_T3;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A33_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A33_T4;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A33_T4 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A33_T5;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A33_T5 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A34_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A34_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A34_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A34_T3;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A34_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A34_T4;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A34_T4 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A35_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A35_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A35_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A35_T3;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A35_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A36_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A36_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A36_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A36_T3;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A36_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A36_T4;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A36_T4 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A36_T5;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A36_T5 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;


            --A4 inst.
            when ST_A41_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A41_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A41_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A41_T3;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A41_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A41_T4;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A41_T4 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A42_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A42_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A42_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A42_T3;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A42_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A42_T4;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A42_T4 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A42_T5;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A42_T5 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A43_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A43_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A43_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A43_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A43_T4;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A43_T4 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A43_T5;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A43_T5 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A44_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A44_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A44_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A44_T3;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A44_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A44_T4;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A44_T4 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A44_T5;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A44_T5 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A44_T6;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A44_T6 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;


            --A5 inst.
            when ST_A51_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A51_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A51_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A52_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A52_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A52_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A52_T3;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A52_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A53_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A53_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A53_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A53_T3;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A53_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A53_T4;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A53_T4 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A53_T5;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A53_T5 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A55_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A55_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A55_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A55_T3;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A55_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A55_T4;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A55_T4 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A55_T5;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A55_T5 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A561_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A561_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A561_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A562_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A562_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A562_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A562_T3;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A562_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A562_T4;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A562_T4 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A57_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A57_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A57_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A57_T3;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A57_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A57_T4;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A57_T4 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A57_T5;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A57_T5 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A58_T1 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A58_T2;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A58_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_A58_T3;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A58_T3 =>
                if (reg_sub_state = ST_SUB73) then
                    reg_main_next_state <= ST_CM_T0;
                else
                    reg_main_next_state <= reg_main_state;
                end if;

            when ST_INV =>
                ---failed to decode next...
                    reg_main_next_state <= reg_main_state;
--            ---not ready yet...
--            when others =>
--                reg_main_next_state <= reg_main_state;
        end case;
    end process;

    --addressing general process...
    --pc, io bus, r/w, instruction regs...
    ad_general_p : process (pi_rst_n, pi_base_clk)

procedure pc_inc is
begin
    if (reg_pc_l = "11111111") then
        --pch page next.
        reg_pc_l    <= "00000000";
        reg_pc_h    <= reg_pc_h + 1;
    else
        reg_pc_l    <= reg_pc_l + 1;
    end if;
end;

    begin
        if (pi_rst_n = '0') then
            reg_pc_l    <= (others => '0');
            reg_pc_h    <= (others => '0');
            reg_inst    <= (others => '0');
            reg_addr    <= (others => 'Z');
            reg_d_out   <= (others => 'Z');
            reg_r_nw    <= 'Z';
        elsif (rising_edge(pi_base_clk)) then
            if (reg_main_state = ST_RS_T0) then
                reg_pc_l    <= (others => '0');
                reg_pc_h    <= (others => '0');
                reg_inst    <= (others => '0');
                reg_addr    <= (others => '0');
                reg_d_out   <= (others => 'Z');
                reg_r_nw    <= '1';
            elsif (reg_main_state = ST_RS_T3) then
                --dummy sp out 1.
                reg_addr    <= "11111111" & reg_sp;
                reg_d_out   <= (others => 'Z');
                reg_r_nw    <= '0';
            elsif (reg_main_state = ST_RS_T4) then
                --dummy sp out 2.
                reg_addr    <= "11111111" & (reg_sp - 1);
                reg_d_out   <= (others => 'Z');
                reg_r_nw    <= '0';
            elsif (reg_main_state = ST_RS_T5) then
                --dummy sp out 3.
                reg_addr    <= "11111111" & (reg_sp - 2);
                reg_d_out   <= (others => 'Z');
                reg_r_nw    <= '0';
            elsif (reg_main_state = ST_RS_T6) then
                --reset vector low...
                reg_addr    <= "1111111111111100";
                reg_d_out   <= (others => 'Z');
                reg_r_nw    <= '1';
                reg_pc_l    <= reg_d_in;
            elsif (reg_main_state = ST_RS_T7) then
                --reset vector high...
                reg_addr    <= "1111111111111101";
                reg_d_out   <= (others => 'Z');
                reg_r_nw    <= '1';
                reg_pc_h    <= reg_d_in;
            elsif (reg_main_state = ST_CM_T0) then
                if (reg_sub_state = ST_SUB00) then
                    reg_addr    <= reg_pc_h & reg_pc_l;
                    reg_d_out   <= (others => 'Z');
                    reg_r_nw    <= '1';
                elsif (reg_sub_state = ST_SUB30) then
                    reg_inst    <= reg_d_in;
                elsif (reg_sub_state = ST_SUB70) then
                    pc_inc;
                end if;
            end if;
        end if;--if (pi_rst_n = '0') then
    end process;

    po_r_nw     <= reg_r_nw;
    po_addr     <= reg_addr;
    pio_d_io    <= reg_d_out;
    reg_d_in    <= pio_d_io;

end rtl;

