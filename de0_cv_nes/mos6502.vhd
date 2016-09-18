library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.conv_std_logic_vector;

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
    --jsr
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

type cpu_state_array    is array (0 to 255) of cpu_main_state;
constant inst_decode_rom : cpu_state_array := (
  --00          01          02          03          04          05          06          07
    ST_INV,     ST_A24_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A22_T1,  ST_A41_T1,  ST_INV,
  --08          09          0a          0b          0c          0d          0e          0f
    ST_A51_T1,  ST_A21_T1,  ST_A1_T1,   ST_INV,     ST_INV,     ST_A23_T1,  ST_A42_T1,  ST_INV,
  --10          11          12          13          14          15          16          17
    ST_A58_T1,  ST_A27_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A26_T1,  ST_A43_T1,  ST_INV,
  --18          19          1a          1b          1c          1d          1e          1f
    ST_A1_T1,   ST_A25_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A25_T1,  ST_A44_T1,  ST_INV,
  --20          21          22          23          24          25          26          27
    ST_A53_T1,  ST_A24_T1,  ST_INV,     ST_INV,     ST_A22_T1,  ST_A22_T1,  ST_A41_T1,  ST_INV,
  --28          29          2a          2b          2c          2d          2e          2f
    ST_A52_T1,  ST_A21_T1,  ST_A1_T1,   ST_INV,     ST_A23_T1,  ST_A23_T1,  ST_A42_T1,  ST_INV,
  --30          31          32          33          34          35          36          37
    ST_A58_T1,  ST_A27_T1,  ST_INV,     ST_INV,     ST_A26_T1,  ST_A26_T1,  ST_A43_T1,  ST_INV,
  --38          39          3a          3b          3c          3d          3e          3f
    ST_A1_T1,   ST_A25_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A25_T1,  ST_A44_T1,  ST_INV,
  --40          41          42          43          44          45          46          47
    ST_A55_T1,  ST_A24_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A22_T1,  ST_A41_T1,  ST_INV,
  --48          49          4a          4b          4c          4d          4e          4f
    ST_A51_T1,  ST_A21_T1,  ST_A1_T1,   ST_INV,     ST_A561_T1, ST_A23_T1,  ST_A42_T1,  ST_INV,
  --50          51          52          53          54          55          56          57
    ST_A58_T1,  ST_A27_T1,  ST_INV,     ST_INV,     ST_A26_T1,  ST_INV,     ST_A43_T1,  ST_INV,
  --58          59          5a          5b          5c          5d          5e          5f
    ST_A1_T1,   ST_A25_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A25_T1,  ST_A44_T1,  ST_INV,
  --60          61          62          63          64          65          66          67
    ST_A57_T1,  ST_A24_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A22_T1,  ST_A41_T1,  ST_INV,
  --68          69          6a          6b          6c          6d          6e          6f
    ST_A52_T1,  ST_A21_T1,  ST_A1_T1,   ST_INV,     ST_A562_T1, ST_A23_T1,  ST_A42_T1,  ST_INV,
  --70          71          72          73          74          75          76          77
    ST_A58_T1,  ST_A27_T1,  ST_INV,     ST_INV,     ST_A26_T1,  ST_INV,     ST_A43_T1,  ST_INV,
  --78          79          7a          7b          7c          7d          7e          7f
    ST_A1_T1,   ST_A25_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A25_T1,  ST_A44_T1,  ST_INV,
  --80          81          82          83          84          85          86          87
    ST_INV,     ST_A33_T1,  ST_INV,     ST_INV,     ST_A31_T1,  ST_A31_T1,  ST_A31_T1,  ST_INV,
  --88          89          8a          8b          8c          8d          8e          8f
    ST_A1_T1,   ST_INV,     ST_A1_T1,   ST_INV,     ST_A32_T1,  ST_A32_T1,  ST_A32_T1,  ST_INV,
  --90          91          92          93          94          95          96          97
    ST_A58_T1,  ST_A36_T1,  ST_INV,     ST_INV,     ST_A35_T1,  ST_A35_T1,  ST_A35_T1,  ST_INV,
  --98          99          9a          9b          9c          9d          9e          9f
    ST_A1_T1,   ST_A34_T1,  ST_A1_T1,   ST_INV,     ST_INV,     ST_A34_T1,  ST_INV,     ST_INV,
  --a0          a1          a2          a3          a4          a5          a6          a7
    ST_A21_T1,  ST_A24_T1,  ST_A21_T1,  ST_INV,     ST_A22_T1,  ST_A22_T1,  ST_A22_T1,  ST_INV,
  --a8          a9          aa          ab          ac          ad          ae          af
    ST_A1_T1,   ST_A21_T1,  ST_A1_T1,   ST_INV,     ST_A23_T1,  ST_A23_T1,  ST_A23_T1,  ST_INV,
  --b0          b1          b2          b3          b4          b5          b6          b7
    ST_A58_T1,  ST_A27_T1,  ST_INV,     ST_A26_T1,  ST_A26_T1,  ST_A26_T1,  ST_INV,     ST_INV,
  --b8          b9          ba          bb          bc          bd          be          bf
    ST_A1_T1,   ST_A25_T1,  ST_A1_T1,   ST_INV,     ST_A25_T1,  ST_A25_T1,  ST_A25_T1,  ST_INV,
  --c0          c1          c2          c3          c4          c5          c6          c7
    ST_A21_T1,  ST_A24_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A22_T1,  ST_A41_T1,  ST_INV,
  --c8          c9          ca          cb          cc          cd          ce          cf
    ST_A1_T1,   ST_A21_T1,  ST_A1_T1,   ST_INV,     ST_A23_T1,  ST_A23_T1,  ST_A42_T1,  ST_INV,
  --d0          d1          d2          d3          d4          d5          d6          d7
    ST_A58_T1,  ST_A27_T1,  ST_INV,     ST_INV,     ST_A26_T1,  ST_INV,     ST_A43_T1,  ST_INV,
  --d8          d9          da          db          dc          dd          de          df
    ST_A1_T1,   ST_A25_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A25_T1,  ST_A44_T1,  ST_INV,
  --e0          e1          e2          e3          e4          e5          e6          e7
    ST_A21_T1,  ST_A24_T1,  ST_INV,     ST_INV,     ST_A22_T1,  ST_A22_T1,  ST_A41_T1,  ST_INV,
  --e8          e9          ea          eb          ec          ed          ee          ef
    ST_A1_T1,   ST_A21_T1,  ST_A1_T1,   ST_INV,     ST_A23_T1,  ST_A23_T1,  ST_A42_T1,  ST_INV,
  --f0          f1          f2          f3          f4          f5          f6          f7
    ST_A58_T1,  ST_A27_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A26_T1,  ST_A43_T1,  ST_INV,
  --f8          f9          fa          fb          fc          fd          fe          ff
    ST_A1_T1,   ST_A25_T1,  ST_INV,     ST_INV,     ST_INV,     ST_A25_T1,  ST_A44_T1,  ST_INV
);

--        Flags (bit 7 to bit 0):
--        N   ....    Negative
--        V   ....    Overflow
--        -   ....    ignored   -- always 1 for NES 6502
--        B   ....    Break
--        D   ....    Decimal (use BCD for arithmetics)     -- not supported. always 0.
--        I   ....    Interrupt (IRQ disable)
--        Z   ....    Zero
--        C   ....    Carry
constant FL_N   : integer := 7;
constant FL_V   : integer := 6;
constant FL_I   : integer := 2;
constant FL_Z   : integer := 1;
constant FL_C   : integer := 0;

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

--tmp flag reg.
signal reg_tmp_carry    : std_logic;
signal reg_tmp_ovf      : std_logic;
signal reg_tmp_condition    : std_logic;
signal reg_tmp_pg_crossed   : std_logic;

--tmp address reg.
signal reg_tmp_l    : std_logic_vector (7 downto 0);
signal reg_tmp_h    : std_logic_vector (7 downto 0);

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

    --fixed length sub status change (0 - 31 because cpu clock is 1/32 of base clock).
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
    tx_next_main_stat_p : process (pi_rst_n, reg_main_state, reg_sub_state,
                                   reg_inst, reg_tmp_condition, reg_tmp_pg_crossed)

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
                    --abs xy move to next only when page crossed.
                    if (reg_tmp_pg_crossed = '1') then
                        reg_main_next_state <= ST_A25_T4;
                    else
                        reg_main_next_state <= ST_CM_T0;
                    end if;
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
                    --indir, y move to next only when page crossed.
                    if (reg_tmp_pg_crossed = '1') then
                        reg_main_next_state <= ST_A27_T5;
                    else
                        reg_main_next_state <= ST_CM_T0;
                    end if;
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
                    if (reg_tmp_condition = '1') then
                        --condition met. move to branch state.
                        reg_main_next_state <= ST_A58_T2;
                    else
                        --condition not met. goto next inst fetch.
                        reg_main_next_state <= ST_CM_T0;
                    end if;
                else
                    reg_main_next_state <= reg_main_state;
                end if;
            when ST_A58_T2 =>
                if (reg_sub_state = ST_SUB73) then
                    if (reg_tmp_pg_crossed = '1') then
                        --page crossed. move to next.
                        reg_main_next_state <= ST_A58_T2;
                    else
                        --page not crossed. move to next inst fetch.
                        reg_main_next_state <= ST_CM_T0;
                    end if;
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


    po_r_nw     <= reg_r_nw;
    po_addr     <= reg_addr;
    pio_d_io    <= reg_d_out;

    --addressing general process...
    --pc, io bus, r/w, instruction regs...
    ad_general_p : process (pi_rst_n, pi_base_clk)

    --address calcuratin w/ carry.
    variable calc_adl   : std_logic_vector(8 downto 0);

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
            reg_d_in    <= (others => '0');
            reg_r_nw    <= 'Z';
            reg_tmp_pg_crossed  <= '0';
            calc_adl    := (others => '0');
        elsif (rising_edge(pi_base_clk)) then

            --general input data register.
            reg_d_in    <= pio_d_io;
            
            --i/o data bus state change.
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
                --init pg crossing flag.
                reg_tmp_pg_crossed <= '0';
                calc_adl    := (others => '0');

                if (reg_sub_state = ST_SUB00) then
                    --fetch next.
                    reg_addr    <= reg_pc_h & reg_pc_l;
                    reg_d_out   <= (others => 'Z');
                    reg_r_nw    <= '1';
                elsif (reg_sub_state = ST_SUB30) then
                    --update instruction register.
                    reg_inst    <= reg_d_in;
                elsif (reg_sub_state = ST_SUB70) then
                    --pc move next.
                    pc_inc;
                end if;
            --fetch and move next case.
            elsif (reg_main_state = ST_A21_T1 or
                reg_main_state = ST_A22_T1 or
                reg_main_state = ST_A23_T1 or
                reg_main_state = ST_A23_T2 or
                reg_main_state = ST_A24_T1 or
                reg_main_state = ST_A25_T1 or
                reg_main_state = ST_A25_T2 or
                reg_main_state = ST_A26_T1 or
                reg_main_state = ST_A27_T1 or
                reg_main_state = ST_A31_T1 or
                reg_main_state = ST_A32_T1 or
                reg_main_state = ST_A32_T2 or
                reg_main_state = ST_A33_T1 or
                reg_main_state = ST_A34_T1 or
                reg_main_state = ST_A34_T2 or
                reg_main_state = ST_A35_T1 or
                reg_main_state = ST_A36_T1 or
                reg_main_state = ST_A41_T1 or
                reg_main_state = ST_A42_T1 or
                reg_main_state = ST_A42_T2 or
                reg_main_state = ST_A43_T1 or
                reg_main_state = ST_A44_T1 or
                reg_main_state = ST_A44_T2 or
                reg_main_state = ST_A53_T1 or
                reg_main_state = ST_A561_T1 or
                reg_main_state = ST_A562_T1 or
                reg_main_state = ST_A57_T1 or
                reg_main_state = ST_A58_T1) then
                if (reg_sub_state = ST_SUB00) then
                    --fetch next.
                    reg_addr    <= reg_pc_h & reg_pc_l;
                    reg_d_out   <= (others => 'Z');
                    reg_r_nw    <= '1';
                elsif (reg_sub_state = ST_SUB70) then
                    --pc move next.
                    pc_inc;
                end if;

            --intermediate cycles..
            elsif (reg_main_state = ST_A24_T2 or
                reg_main_state = ST_A26_T2 or
                reg_main_state = ST_A33_T2 or
                reg_main_state = ST_A35_T2 or
                reg_main_state = ST_A27_T2 or
                reg_main_state = ST_A36_T2
                ) then
                --zp xy
                --ind, x
                -->>discarded cycle.
                --ind, y
                --ial cycle.
                reg_addr    <= "00000000" & reg_idl_l;
                reg_d_out   <= (others => 'Z');
                reg_r_nw    <= '1';
            elsif (reg_main_state = ST_A24_T3 or
                reg_main_state = ST_A33_T3) then
                --ind, x
                --bal + x cycle.
                reg_addr    <= "00000000" & (reg_idl_l + reg_x);
                reg_d_out   <= (others => 'Z');
                reg_r_nw    <= '1';
            elsif (reg_main_state = ST_A24_T4 or
                reg_main_state = ST_A33_T4) then
                --ind, x
                --bal + x + 1 cycle.
                reg_addr    <= "00000000" & (reg_idl_l + reg_x + 1);
                reg_d_out   <= (others => 'Z');
                reg_r_nw    <= '1';
            elsif (reg_main_state = ST_A25_T3 or
                reg_main_state = ST_A34_T3) then
                --abs xy
                --(discarded cycle for store inst..)
                if (reg_inst(1 downto 0) = "01") then
                    if (reg_inst(4 downto 2) = "110") then
                        --abs y
                        reg_addr    <= reg_idl_h & (reg_idl_l + reg_y);
                    elsif (reg_inst(4 downto 2) = "111") then
                        --abs x
                        reg_addr    <= reg_idl_h & (reg_idl_l + reg_x);
                    end if; 
                elsif (reg_inst = conv_std_logic_vector(16#be#, 8)) then
                    --abs y
                    --ldx
                    reg_addr    <= reg_idl_h & (reg_idl_l + reg_y);
                elsif (reg_inst = conv_std_logic_vector(16#bc#, 8)) then
                    --abs x
                    --ldy
                    reg_addr    <= reg_idl_h & (reg_idl_l + reg_x);
                elsif (reg_inst = conv_std_logic_vector(16#9d#, 8)) then
                    --sta, x
                    reg_addr    <= reg_idl_h & (reg_idl_l + reg_x);
                    calc_adl    := ("0" & reg_idl_l) + ("0" & reg_x);
                elsif (reg_inst = conv_std_logic_vector(16#99#, 8)) then
                    --sta, y
                    reg_addr    <= reg_idl_h & (reg_idl_l + reg_y);
                    calc_adl    := ("0" & reg_idl_l) + ("0" & reg_y);
                end if;
                reg_d_out   <= (others => 'Z');
                reg_r_nw    <= '1';

                reg_tmp_pg_crossed <= calc_adl(8);
            elsif (reg_main_state = ST_A27_T3 or
                reg_main_state = ST_A36_T3) then
                --ind, y
                --ial + 1 cycle.
                reg_addr    <= "00000000" & (reg_idl_l + 1);
                reg_d_out   <= (others => 'Z');
                reg_r_nw    <= '1';
            elsif (reg_main_state = ST_A27_T4 or
                reg_main_state = ST_A36_T4) then
                --ind, y
                --bal + y cycle.
                reg_addr    <= reg_tmp_h & (reg_tmp_l + reg_y);
                reg_d_out   <= (others => 'Z');
                reg_r_nw    <= '1';
                calc_adl    := ("0" & reg_tmp_l) + ("0" & reg_y);
                reg_tmp_pg_crossed <= calc_adl(8);


           --a2 instructions.
            elsif (reg_main_state = ST_A22_T2 or
                reg_main_state = ST_A23_T3 or
                reg_main_state = ST_A24_T5 or
                reg_main_state = ST_A25_T4 or
                reg_main_state = ST_A26_T3 or
                reg_main_state = ST_A27_T5
            ) then
                --execute cycle.
                reg_d_out   <= (others => 'Z');
                reg_r_nw    <= '1';

                --address bus out.
                if (reg_main_state = ST_A22_T2) then
                    --zp
                    reg_addr    <= "00000000" & reg_idl_l;

                elsif (reg_main_state = ST_A23_T3) then
                    --abs
                    reg_addr    <= reg_idl_h & reg_idl_l;

                elsif (reg_main_state = ST_A24_T5) then
                    --ind, x
                    reg_addr    <= reg_tmp_h & reg_tmp_l;

                elsif (reg_main_state = ST_A25_T4) then
                    --abs xy
                    if (reg_inst(1 downto 0) = "01") then
                        if (reg_inst(4 downto 2) = "110") then
                            --abs y
                            reg_addr    <= (reg_idl_h + reg_tmp_pg_crossed) & (reg_idl_l + reg_y);
                        elsif (reg_inst(4 downto 2) = "111") then
                            --abs x
                            reg_addr    <= (reg_idl_h + reg_tmp_pg_crossed) & (reg_idl_l + reg_x);
                        end if; 
                    elsif (reg_inst = conv_std_logic_vector(16#be#, 8)) then
                        --abs y
                        --ldx
                        reg_addr    <= (reg_idl_h + reg_tmp_pg_crossed) & (reg_idl_l + reg_y);
                    elsif (reg_inst = conv_std_logic_vector(16#bc#, 8)) then
                        --abs x
                        --ldy
                        reg_addr    <= (reg_idl_h + reg_tmp_pg_crossed) & (reg_idl_l + reg_x);
                    end if; 

                elsif (reg_main_state = ST_A26_T3) then
                    --zp xy
                    if (reg_inst(1 downto 0) = "01") then
                        if (reg_inst(4 downto 2) = "101") then
                            --zp x
                            reg_addr    <= "00000000" & (reg_idl_l + reg_x);
                        end if; 
                    elsif (reg_inst = conv_std_logic_vector(16#b6#, 8)) then
                        --zp y
                        --ldx
                        reg_addr    <= "00000000" & (reg_idl_l + reg_y);
                    elsif (reg_inst = conv_std_logic_vector(16#b4#, 8)) then
                        --zp y
                        --ldy
                        reg_addr    <= "00000000" & (reg_idl_l + reg_x);
                    end if; 

                elsif (reg_main_state = ST_A27_T5) then
                    --ind y
                    reg_addr    <= (reg_tmp_h + reg_tmp_pg_crossed) & (reg_tmp_l + reg_y);
                end if;

           --a3 instructions.
           --sta, stx, sty
            elsif (reg_main_state = ST_A31_T2 or
                reg_main_state = ST_A32_T3 or
                reg_main_state = ST_A33_T5 or
                reg_main_state = ST_A34_T4 or
                reg_main_state = ST_A35_T3 or
                reg_main_state = ST_A36_T5
            ) then
                --store cycle.
                --data out
                if (reg_inst(1 downto 0) = "01" and reg_inst(7 downto 5) = "100") then
                    --sta
                    reg_d_out   <= reg_acc;
                elsif (reg_inst(1 downto 0) = "10" and reg_inst(7 downto 5) = "100") then
                    --stx
                    reg_d_out   <= reg_x;
                elsif (reg_inst(1 downto 0) = "00" and reg_inst(7 downto 5) = "100") then
                    --sty
                    reg_d_out   <= reg_y;
                end if;

                --rw ctrl
                if (reg_sub_state = ST_SUB32 or
                    reg_sub_state = ST_SUB33 or
                    reg_sub_state = ST_SUB40 or
                    reg_sub_state = ST_SUB41
                    ) then
                    reg_r_nw    <= '0';
                else
                    reg_r_nw    <= 'Z';
                end if;

                --address bus out.
                if (reg_main_state = ST_A31_T2) then
                    --zp
                    reg_addr    <= "00000000" & reg_idl_l;

                elsif (reg_main_state = ST_A32_T3) then
                    --abs
                    reg_addr    <= reg_idl_h & reg_idl_l;

                elsif (reg_main_state = ST_A33_T5) then
                    --ind, x
                    reg_addr    <= reg_tmp_h & reg_tmp_l;

                elsif (reg_main_state = ST_A34_T4) then
                    --abs xy
                    if (reg_inst = conv_std_logic_vector(16#9d#, 8)) then
                        --sta, x
                        reg_addr    <= (reg_idl_h + reg_tmp_pg_crossed) & (reg_idl_l + reg_x);
                    elsif (reg_inst = conv_std_logic_vector(16#99#, 8)) then
                        --sta, y
                        reg_addr    <= (reg_idl_h + reg_tmp_pg_crossed) & (reg_idl_l + reg_y);
                    end if;

                elsif (reg_main_state = ST_A35_T3) then
                    --zp xy
                    --sta and sty has index x access,
                    --stx has index y access.
                    if (reg_inst = conv_std_logic_vector(16#95#, 8) or --sta
                        reg_inst = conv_std_logic_vector(16#94#, 8) --sty
                    ) then
                        reg_addr    <= "00000000" & (reg_idl_l + reg_x);
                    elsif (reg_inst = conv_std_logic_vector(16#96#, 8)) then
                        --stx
                        reg_addr    <= "00000000" & (reg_idl_l + reg_y);
                    end if;

                elsif (reg_main_state = ST_A36_T5) then
                    --ind y
                    reg_addr    <= (reg_tmp_h + reg_tmp_pg_crossed) & (reg_tmp_l + reg_y);
                end if;

            --jsr.
            elsif (reg_main_state = ST_A53_T2) then
                --sp out (discarded.)
                reg_addr    <= "00000001" & reg_sp;
                reg_d_out   <= (others => 'Z');
                reg_r_nw    <= '1';
            elsif (reg_main_state = ST_A53_T3) then
                --push pch
                reg_addr    <= "00000001" & reg_sp;
                reg_d_out   <= reg_pc_h;
                if (reg_sub_state = ST_SUB32 or
                    reg_sub_state = ST_SUB33 or
                    reg_sub_state = ST_SUB40 or
                    reg_sub_state = ST_SUB41
                    ) then
                    reg_r_nw    <= '0';
                else
                    reg_r_nw    <= 'Z';
                end if;
            elsif (reg_main_state = ST_A53_T4) then
                --push pcl
                reg_addr    <= "00000001" & reg_sp;
                reg_d_out   <= reg_pc_l;
                if (reg_sub_state = ST_SUB32 or
                    reg_sub_state = ST_SUB33 or
                    reg_sub_state = ST_SUB40 or
                    reg_sub_state = ST_SUB41
                    ) then
                    reg_r_nw    <= '0';
                else
                    reg_r_nw    <= 'Z';
                end if;
            elsif (reg_main_state = ST_A53_T5) then
                if (reg_sub_state = ST_SUB00) then
                    --fetch next.
                    reg_addr    <= reg_pc_h & reg_pc_l;
                    reg_d_out   <= (others => 'Z');
                    reg_r_nw    <= '1';
                elsif (reg_sub_state = ST_SUB70) then
                    --go to sub-routine addr.
                    reg_pc_l    <= reg_idl_l;
                    reg_pc_h    <= reg_idl_h;
                end if;

           --jmp.
            elsif (reg_main_state = ST_A561_T2) then
                if (reg_sub_state = ST_SUB00) then
                    --fetch next.
                    reg_addr    <= reg_pc_h & reg_pc_l;
                    reg_d_out   <= (others => 'Z');
                    reg_r_nw    <= '1';
                elsif (reg_sub_state = ST_SUB70) then
                    reg_pc_l    <= reg_idl_l;
                    reg_pc_h    <= reg_idl_h;
                end if;

           --rts.
            elsif (reg_main_state = ST_A57_T2) then
                --sp out (discarded.)
                reg_addr    <= "00000001" & reg_sp;
                reg_d_out   <= (others => 'Z');
                reg_r_nw    <= '1';
            elsif (reg_main_state = ST_A57_T3) then
                --pull pcl
                if (reg_sub_state = ST_SUB00) then
                    reg_addr    <= "00000001" & reg_sp;
                    reg_d_out   <= (others => 'Z');
                    reg_r_nw    <= '1';
                elsif (reg_sub_state = ST_SUB70) then
                    reg_pc_l    <= reg_d_in;
                end if;
            elsif (reg_main_state = ST_A57_T4) then
                --pull pch
                if (reg_sub_state = ST_SUB00) then
                    reg_addr    <= "00000001" & reg_sp;
                    reg_d_out   <= (others => 'Z');
                    reg_r_nw    <= '1';
                elsif (reg_sub_state = ST_SUB70) then
                    reg_pc_h    <= reg_d_in;
                end if;
            elsif (reg_main_state = ST_A57_T5) then
                --pc out (discarded.)
                if (reg_sub_state = ST_SUB00) then
                    reg_addr    <= reg_pc_h & reg_pc_l;
                    reg_d_out   <= (others => 'Z');
                    reg_r_nw    <= '1';
                elsif (reg_sub_state = ST_SUB70) then
                    reg_pc_l    <= reg_pc_l + 1;
                end if;

           --conditional branch.
            elsif (reg_main_state = ST_A58_T2) then
                if (reg_sub_state = ST_SUB10) then
                    calc_adl    := ("0" & reg_pc_l) + ("0" & reg_idl_l);
                    reg_tmp_pg_crossed <= calc_adl(8);

                    reg_pc_l    <= calc_adl(7 downto 0);
                    reg_addr    <= reg_pc_h & calc_adl(7 downto 0);
                    reg_d_out   <= (others => 'Z');
                    reg_r_nw    <= '1';
                end if;

            --page crossed.
            elsif (reg_main_state = ST_A58_T3) then
                if (reg_sub_state = ST_SUB10) then
                    reg_pc_l    <= reg_pc_h + "1";
                    reg_addr    <= (reg_pc_h + "1") & reg_pc_l;
                    reg_d_out   <= (others => 'Z');
                    reg_r_nw    <= '1';
                end if;
            end if;--if (reg_main_state = ST_RS_T0) then
        end if;--if (pi_rst_n = '0') then
    end process;

    --internal data latch...
    --fetch first and second operand.
    idl_p : process (pi_rst_n, pi_base_clk)
    begin
        if (pi_rst_n = '0') then
            reg_idl_l <= (others => '0');
            reg_idl_h <= (others => '0');
            reg_tmp_l <= (others => '0');
            reg_tmp_h <= (others => '0');
        elsif (rising_edge(pi_base_clk)) then
            if (reg_main_state = ST_A21_T1 or
                reg_main_state = ST_A22_T1 or
                reg_main_state = ST_A23_T1 or
                reg_main_state = ST_A24_T1 or
                reg_main_state = ST_A25_T1 or
                reg_main_state = ST_A26_T1 or
                reg_main_state = ST_A27_T1 or
                reg_main_state = ST_A31_T1 or
                reg_main_state = ST_A32_T1 or
                reg_main_state = ST_A33_T1 or
                reg_main_state = ST_A34_T1 or
                reg_main_state = ST_A35_T1 or
                reg_main_state = ST_A36_T1 or
                reg_main_state = ST_A41_T1 or
                reg_main_state = ST_A42_T1 or
                reg_main_state = ST_A43_T1 or
                reg_main_state = ST_A44_T1 or
                reg_main_state = ST_A53_T1 or
                reg_main_state = ST_A561_T1 or
                reg_main_state = ST_A562_T1 or
                reg_main_state = ST_A58_T1) then
                if (reg_sub_state = ST_SUB30) then
                    --get low data from rom.
                    reg_idl_l <= reg_d_in;
                end if;
            elsif (reg_main_state = ST_A23_T2 or
                reg_main_state = ST_A25_T2 or
                reg_main_state = ST_A32_T2 or
                reg_main_state = ST_A34_T2 or
                reg_main_state = ST_A42_T2 or
                reg_main_state = ST_A44_T2 or
                reg_main_state = ST_A53_T5 or
                reg_main_state = ST_A561_T2 or
                reg_main_state = ST_A562_T2) then
                if (reg_sub_state = ST_SUB30) then
                    --get high data from rom.
                    reg_idl_h <= reg_d_in;
                end if;
            elsif (reg_main_state = ST_A33_T3 or
                reg_main_state = ST_A36_T2
                ) then
                --a33 indr, x
                --a33 indr, y
                if (reg_sub_state = ST_SUB30) then
                    reg_tmp_l <= reg_d_in;
                end if;
            elsif (reg_main_state = ST_A33_T4 or
                reg_main_state = ST_A36_T3
                ) then
                --a33 indr, x
                --a33 indr, y
                if (reg_sub_state = ST_SUB30) then
                    reg_tmp_h <= reg_d_in;
                end if;
            end if;--if (reg_main_state = ST_RS_T0)
        end if;--if (pi_rst_n = '0') then
    end process;

    --stack pointer...
    sp_p : process (pi_rst_n, pi_base_clk)
    begin
        if (pi_rst_n = '0') then
            reg_sp <= (others => '0');
        elsif (rising_edge(pi_base_clk)) then
            if (reg_main_state = ST_A1_T1) then
                --txs inst.
                if (reg_inst = conv_std_logic_vector(16#9a#, 8)) then
                    reg_sp <= reg_idl_l;
                end if;
            elsif (reg_main_state = ST_A51_T2 or
                reg_main_state = ST_A53_T3 or
                reg_main_state = ST_A53_T4) then
                --push, jsr.
                if (reg_sub_state = ST_SUB70) then
                    reg_sp <= reg_sp - 1;
                end if;
            elsif (reg_main_state = ST_A52_T2 or
                reg_main_state = ST_A57_T2 or
                reg_main_state = ST_A57_T3 or
                reg_main_state = ST_A57_T4) then
                --pull, rts.
                if (reg_sub_state = ST_SUB70) then
                    reg_sp <= reg_sp + 1;
                end if;
            end if;--if (reg_main_state = ST_RS_T0)
        end if;--if (pi_rst_n = '0') then
    end process;

    --calcuration process...
    --update acc, x, y, status registers.
    calc_p : process (pi_rst_n, pi_base_clk)

    variable calc_res : std_logic_vector (8 downto 0);
procedure update_status (
    d       : in std_logic_vector(7 downto 0);
    set_n   : in integer range 0 to 1;
    set_z   : in integer range 0 to 1;
    set_c   : in integer range 0 to 1
) is
begin
    if (set_n = 1) then
        if (d(7) = '1') then
            reg_status(FL_N) <= '1';
        else
            reg_status(FL_N) <= '0';
        end if;
    end if;
    if (set_z = 1) then
        if (d = "00000000") then
            reg_status(FL_Z) <= '1';
        else
            reg_status(FL_Z) <= '0';
        end if;
    end if;
    if (set_c = 1) then
        reg_status(FL_C) <= reg_tmp_carry;
    end if;
end;

procedure set_condition_result (
    flg   : in integer range 0 to 7;
    chk_val : in std_logic
) is
begin
    if (reg_status(flg) = chk_val) then
        reg_tmp_condition <= '1';
    else
        reg_tmp_condition <= '0';
    end if;
end;

    begin
        --Most instructions that explicitly reference memory locations have bit patterns of the form aaabbbcc.
        if (pi_rst_n = '0') then
            reg_acc <= (others => '0');
            reg_x <= (others => '0');
            reg_y <= (others => '0');
            reg_status <= (others => '0');
            reg_tmp_carry <= '0';
            reg_tmp_ovf <= '0';
            reg_tmp_condition <= '0';
        elsif (rising_edge(pi_base_clk)) then
            --not used status pin initialize (to avoid latches).
            reg_status(5 downto 3) <= "000";

            --a1 instructions...
            --asl   dex     nop     tax     tya
            --clc   dey     rol     tay
            --cld   inx     sec     tsx
            --cli   iny     sed     txa
            --clv   lsr     sei     txs
            if (reg_main_state = ST_CM_T0) then
                --init flag regs..
                reg_tmp_carry <= '0';
                reg_tmp_ovf <= '0';
                reg_tmp_condition <= '0';
            elsif (reg_main_state = ST_A1_T1) then
                --update reg
                if (reg_sub_state = ST_SUB30) then
                    --case cc=01
                    if (reg_inst(1 downto 0) = "01") then
                        if (reg_inst(7 downto 5) = "000") then
                            --asl
                            reg_acc <= reg_acc(6 downto 0) & "0";
                            reg_tmp_carry <= reg_acc(7);
                        elsif (reg_inst(7 downto 5) = "001") then
                            --rol
                            reg_acc <= reg_acc(6 downto 0) & reg_status(FL_C);
                            reg_tmp_carry <= reg_acc(7);
                        elsif (reg_inst(7 downto 5) = "010") then
                            --lsr
                            reg_acc <= "0" & reg_acc(7 downto 1);
                            reg_tmp_carry <= reg_acc(0);
                        elsif (reg_inst(7 downto 5) = "011") then
                            --ror
                            reg_acc <= reg_status(FL_C) & reg_acc(7 downto 1);
                            reg_tmp_carry <= reg_acc(0);
                        elsif (reg_inst(7 downto 5) = "110") then
                            --dec
                            reg_acc <= reg_acc - 1;
                        elsif (reg_inst(7 downto 5) = "111") then
                            --inc
                            reg_acc <= reg_acc + 1;
                        end if;
                    elsif (reg_inst = conv_std_logic_vector(16#88#, 8)) then
                        --dey
                        reg_y <= reg_y - 1;
                    elsif (reg_inst = conv_std_logic_vector(16#a8#, 8)) then
                        --tay
                        reg_y <= reg_acc;
                    elsif (reg_inst = conv_std_logic_vector(16#c8#, 8)) then
                        --iny
                        reg_y <= reg_y + 1;
                    elsif (reg_inst = conv_std_logic_vector(16#e8#, 8)) then
                        --inx
                        reg_x <= reg_x + 1;
                    elsif (reg_inst = conv_std_logic_vector(16#18#, 8)) then
                        --clc
                        reg_status(FL_C) <= '0';
                    elsif (reg_inst = conv_std_logic_vector(16#38#, 8)) then
                        --sec
                        reg_status(FL_C) <= '1';
                    elsif (reg_inst = conv_std_logic_vector(16#58#, 8)) then
                        --cli
                        reg_status(FL_I) <= '0';
                    elsif (reg_inst = conv_std_logic_vector(16#78#, 8)) then
                        --sei
                        reg_status(FL_I) <= '1';
                    elsif (reg_inst = conv_std_logic_vector(16#98#, 8)) then
                        --tya
                        reg_acc <= reg_y;
                    elsif (reg_inst = conv_std_logic_vector(16#b8#, 8)) then
                        --clv
                        reg_status(FL_V) <= '0';
                    elsif (reg_inst = conv_std_logic_vector(16#8a#, 8)) then
                        --txa
                        reg_acc <= reg_y;
                    elsif (reg_inst = conv_std_logic_vector(16#aa#, 8)) then
                        --tax
                        reg_x <= reg_acc;
                    elsif (reg_inst = conv_std_logic_vector(16#ba#, 8)) then
                        --tsx
                        reg_x <= reg_sp;
                    elsif (reg_inst = conv_std_logic_vector(16#ca#, 8)) then
                        --dex
                        reg_x <= reg_x - 1;
                    elsif (reg_inst = conv_std_logic_vector(16#ea#, 8)) then
                        --nop
                        --do nothing...
                    end if;

                --update status reg
                elsif (reg_sub_state = ST_SUB31) then
                    --case cc=01
                    if (reg_inst(1 downto 0) = "01") then
                        if (reg_inst(7 downto 5) = "000") then
                            --asl
                            update_status(reg_acc, 1, 1, 1);
                        elsif (reg_inst(7 downto 5) = "001") then
                            --rol
                            update_status(reg_acc, 1, 1, 1);
                        elsif (reg_inst(7 downto 5) = "010") then
                            --lsr
                            update_status(reg_acc, 0, 1, 1);
                        elsif (reg_inst(7 downto 5) = "011") then
                            --ror
                            update_status(reg_acc, 1, 1, 1);
                        elsif (reg_inst(7 downto 5) = "110") then
                            --dec
                            update_status(reg_acc, 1, 1, 0);
                        elsif (reg_inst(7 downto 5) = "111") then
                            --inc
                            update_status(reg_acc, 1, 1, 0);
                        end if;
                    elsif (reg_inst = conv_std_logic_vector(16#88#, 8)) then
                        --dey
                        update_status(reg_y, 1, 1, 0);
                    elsif (reg_inst = conv_std_logic_vector(16#a8#, 8)) then
                        --tay
                        update_status(reg_y, 1, 1, 0);
                    elsif (reg_inst = conv_std_logic_vector(16#c8#, 8)) then
                        --iny
                        update_status(reg_y, 1, 1, 0);
                    elsif (reg_inst = conv_std_logic_vector(16#e8#, 8)) then
                        --inx
                        update_status(reg_x, 1, 1, 0);
                    elsif (reg_inst = conv_std_logic_vector(16#98#, 8)) then
                        --tya
                        update_status(reg_acc, 1, 1, 0);
                    elsif (reg_inst = conv_std_logic_vector(16#8a#, 8)) then
                        --txa
                        update_status(reg_acc, 1, 1, 0);
                    elsif (reg_inst = conv_std_logic_vector(16#9a#, 8)) then
                        --txs
                        update_status(reg_sp, 1, 1, 0);
                    elsif (reg_inst = conv_std_logic_vector(16#aa#, 8)) then
                        --tax
                        update_status(reg_x, 1, 1, 0);
                    elsif (reg_inst = conv_std_logic_vector(16#ba#, 8)) then
                        --tsx
                        update_status(reg_x, 1, 1, 0);
                    elsif (reg_inst = conv_std_logic_vector(16#ca#, 8)) then
                        --dex
                        update_status(reg_x, 1, 1, 0);
                    elsif (reg_inst = conv_std_logic_vector(16#ea#, 8)) then
                        --nop
                        --do nothing...
                    end if;
                end if;--if (reg_sub_state = ST_SUB30) then

            --a2 instructions...
            --adc   cmp     eor     ldy
            --and   cpx     lda     ora
            --bit   cpy     ldx     sbc
            elsif (reg_main_state = ST_A21_T1 or
                reg_main_state = ST_A22_T2 or
                reg_main_state = ST_A23_T3 or
                reg_main_state = ST_A24_T5 or
                reg_main_state = ST_A25_T4 or
                reg_main_state = ST_A25_T3 or
                reg_main_state = ST_A26_T3 or
                reg_main_state = ST_A27_T5) then
                
                --update reg
                if (reg_sub_state = ST_SUB30) then
                    --case cc=01
                    if (reg_inst(1 downto 0) = "01") then
                        if (reg_inst(7 downto 5) = "000") then
                            --ora
                            reg_acc <= (reg_acc or reg_d_in);
                        elsif (reg_inst(7 downto 5) = "001") then
                            --and
                            reg_acc <= (reg_acc and reg_d_in);
                        elsif (reg_inst(7 downto 5) = "010") then
                            --eor
                            reg_acc <= (reg_acc xor reg_d_in);
                        elsif (reg_inst(7 downto 5) = "011") then
                            --adc
                            calc_res := ("0" & reg_acc) + ("0" & reg_d_in) + reg_status(FL_C);
                            reg_tmp_carry <= calc_res(8);
                            if ((reg_acc(7) = reg_d_in(7)) and (reg_acc(7) /= calc_res(7))) then
                                reg_tmp_ovf <= '1';
                            else
                                reg_tmp_ovf <= '0';
                            end if;
                            reg_acc <= calc_res(7 downto 0);
                        elsif (reg_inst(7 downto 5) = "101") then
                            --lda
                            reg_acc <= reg_d_in;
                        elsif (reg_inst(7 downto 5) = "110") then
                            --cmp
                            --do nothing.
                        elsif (reg_inst(7 downto 5) = "111") then
                            --sbc
                            ---A - M - ~C -> A
                            calc_res := ("0" & reg_acc) - ("0" & reg_d_in) - not reg_status(FL_C);

                            --c Set if unsigned borrow not required; cleared if unsigned borrow.
                            reg_tmp_carry <= not calc_res(7);
                            --v Set if signed borrow required; cleared if no signed borrow.
                            if ((reg_acc(7) /= reg_d_in(7)) and (reg_acc(7) /= calc_res(7))) then
                                reg_tmp_ovf <= '1';
                            else
                                reg_tmp_ovf <= '0';
                            end if;
                            reg_acc <= calc_res(7 downto 0);
                        end if;
                    --case cc=10
                    elsif (reg_inst(1 downto 0) = "10") then
                        if (reg_inst(7 downto 5) = "101") then
                            --ldx
                            reg_x <= reg_d_in;
                        end if;
                    --case cc=00
                    elsif (reg_inst(1 downto 0) = "00") then
                        if (reg_inst(7 downto 5) = "001") then
                            --bit
                            --do nothing.
                        elsif (reg_inst(7 downto 5) = "101") then
                            --ldy
                            reg_y <= reg_d_in;
                        elsif (reg_inst(7 downto 5) = "110") then
                            --cpy
                            --do nothing.
                        elsif (reg_inst(7 downto 5) = "111") then
                            --cpx
                            --do nothing.
                        end if;
                    end if;

                --update status reg
                elsif (reg_sub_state = ST_SUB31) then
                    --case cc=01
                    if (reg_inst(1 downto 0) = "01") then
                        if (reg_inst(7 downto 5) = "000") then
                            --ora
                            update_status(reg_x, 1, 1, 0);
                        elsif (reg_inst(7 downto 5) = "001") then
                            --and
                            update_status(reg_x, 1, 1, 0);
                        elsif (reg_inst(7 downto 5) = "010") then
                            --eor
                            update_status(reg_x, 1, 1, 0);
                        elsif (reg_inst(7 downto 5) = "011") then
                            --adc
                            update_status(reg_x, 1, 1, 1);
                            reg_status(FL_V) <= reg_tmp_ovf;
                        elsif (reg_inst(7 downto 5) = "101") then
                            --lda
                            update_status(reg_x, 1, 1, 0);
                        elsif (reg_inst(7 downto 5) = "110") then
                            --cmp
                            calc_res := (("0" & reg_acc) - ("0" & reg_d_in));
                            if (reg_acc >= reg_d_in) then
                                reg_status(FL_C) <= '1';
                            else
                                reg_status(FL_C) <= '0';
                            end if;
                            if (calc_res(7) = '1') then
                                reg_status(FL_N) <= '1';
                            else
                                reg_status(FL_N) <= '0';
                            end if;
                            if (calc_res = "000000000") then
                                reg_status(FL_Z) <= '1';
                            else
                                reg_status(FL_Z) <= '0';
                            end if;
                        elsif (reg_inst(7 downto 5) = "111") then
                            --sbc
                            update_status(reg_x, 1, 1, 1);
                            reg_status(FL_V) <= reg_tmp_ovf;
                        end if;
                    --case cc=10
                    elsif (reg_inst(1 downto 0) = "10") then
                        if (reg_inst(7 downto 5) = "101") then
                            --ldx
                            update_status(reg_x, 1, 1, 0);
                        end if;
                    --case cc=00
                    elsif (reg_inst(1 downto 0) = "00") then
                        if (reg_inst(7 downto 5) = "001") then
                            --bit
                            calc_res(7 downto 0) := (reg_acc and reg_d_in);
                            reg_status(FL_N) <= reg_d_in(7);
                            reg_status(FL_V) <= reg_d_in(6);
                            if (calc_res(7 downto 0) = "00000000") then
                                reg_status(FL_Z) <= '1';
                            else
                                reg_status(FL_Z) <= '0';
                            end if;
                        elsif (reg_inst(7 downto 5) = "101") then
                            --ldy
                            update_status(reg_x, 1, 1, 0);
                        elsif (reg_inst(7 downto 5) = "110") then
                            --cpy
                            calc_res := (("0" & reg_y) - ("0" & reg_d_in));
                            if (reg_y >= reg_d_in) then
                                reg_status(FL_C) <= '1';
                            else
                                reg_status(FL_C) <= '0';
                            end if;
                            if (calc_res(7) = '1') then
                                reg_status(FL_N) <= '1';
                            else
                                reg_status(FL_N) <= '0';
                            end if;
                            if (calc_res = "000000000") then
                                reg_status(FL_Z) <= '1';
                            else
                                reg_status(FL_Z) <= '0';
                            end if;
                        elsif (reg_inst(7 downto 5) = "111") then
                            --cpx
                            calc_res := (("0" & reg_x) - ("0" & reg_d_in));
                            if (reg_x >= reg_d_in) then
                                reg_status(FL_C) <= '1';
                            else
                                reg_status(FL_C) <= '0';
                            end if;
                            if (calc_res(7) = '1') then
                                reg_status(FL_N) <= '1';
                            else
                                reg_status(FL_N) <= '0';
                            end if;
                            if (calc_res = "000000000") then
                                reg_status(FL_Z) <= '1';
                            else
                                reg_status(FL_Z) <= '0';
                            end if;
                        end if;
                    end if;
                end if;--if (reg_sub_state = ST_SUB30) then

            --a5 instructions...
            --plp, pla
            elsif (reg_main_state = ST_A52_T3) then
                --update reg
                if (reg_sub_state = ST_SUB30) then
                    if (reg_inst = conv_std_logic_vector(16#28#, 8)) then
                        --plp
                        reg_status <= reg_d_in;
                    elsif (reg_inst = conv_std_logic_vector(16#68#, 8)) then
                        --pla
                        reg_acc <= reg_d_in;
                    end if;

                --update status reg
                elsif (reg_sub_state = ST_SUB31) then
                    if (reg_inst = conv_std_logic_vector(16#68#, 8)) then
                        --pla
                        update_status(reg_acc, 1, 1, 0);
                    end if;
                end if;--if (reg_sub_state = ST_SUB30) then

            --a58 branch inst.
            --bcc   bne
            --bcs   bpl
            --beq   bvc
            --bmi   bvs
            elsif (reg_main_state = ST_A58_T1) then
                if (reg_sub_state = ST_SUB30) then
                    if (reg_inst = conv_std_logic_vector(16#90#, 8)) then
                        --bcc
                        set_condition_result(FL_C, '0');

                    elsif (reg_inst = conv_std_logic_vector(16#b0#, 8)) then
                        --bcs
                        set_condition_result(FL_C, '1');

                    elsif (reg_inst = conv_std_logic_vector(16#f0#, 8)) then
                        --beq
                        set_condition_result(FL_Z, '1');

                    elsif (reg_inst = conv_std_logic_vector(16#30#, 8)) then
                        --bmi
                        set_condition_result(FL_N, '1');

                    elsif (reg_inst = conv_std_logic_vector(16#d0#, 8)) then
                        --bne
                        set_condition_result(FL_Z, '0');

                    elsif (reg_inst = conv_std_logic_vector(16#10#, 8)) then
                        --bpl
                        set_condition_result(FL_N, '0');

                    elsif (reg_inst = conv_std_logic_vector(16#50#, 8)) then
                        --bvc
                        set_condition_result(FL_V, '0');

                    elsif (reg_inst = conv_std_logic_vector(16#70#, 8)) then
                        --bvs
                        set_condition_result(FL_V, '1');
                    end if;
                end if;
            end if;--if (reg_main_state = ST_A21_T1 or...
        end if;--if (pi_rst_n = '0') then
    end process;

end rtl;

