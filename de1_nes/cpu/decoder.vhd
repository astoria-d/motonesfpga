library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.conv_std_logic_vector;
use ieee.std_logic_unsigned.conv_integer;
use work.motonesfpga_common.all;

entity decoder is 
    generic (dsize : integer := 8);
    port (  
--    signal dbg_ea_carry     : out std_logic;
    
    
            set_clk         : in std_logic;
            trig_clk        : in std_logic;
            res_n           : in std_logic;
            irq_n           : in std_logic;
            nmi_n           : in std_logic;
            rdy             : in std_logic;
            instruction     : in std_logic_vector (dsize - 1 downto 0);
            exec_cycle      : in std_logic_vector (5 downto 0);
            next_cycle      : out std_logic_vector (5 downto 0);
            status_reg      : inout std_logic_vector (dsize - 1 downto 0);
            inst_we_n       : out std_logic;
            ad_oe_n         : out std_logic;
            dbuf_int_oe_n   : out std_logic;
            dl_al_we_n      : out std_logic;
            dl_ah_we_n      : out std_logic;
            dl_al_oe_n      : out std_logic;
            dl_ah_oe_n      : out std_logic;
            dl_dh_oe_n      : out std_logic;
            pcl_inc_n       : out std_logic;
            pch_inc_n       : out std_logic;
            pcl_cmd         : out std_logic_vector(3 downto 0);
            pch_cmd         : out std_logic_vector(3 downto 0);
            sp_cmd          : out std_logic_vector(3 downto 0);
            sp_oe_n         : out std_logic;
            sp_push_n       : out std_logic;
            sp_pop_n        : out std_logic;
            acc_cmd         : out std_logic_vector(3 downto 0);
            x_cmd           : out std_logic_vector(3 downto 0);
            y_cmd           : out std_logic_vector(3 downto 0);
            abs_xy_n        : out std_logic;
            ea_carry        : in  std_logic;
            pg_next_n       : out std_logic;
            zp_n            : out std_logic;
            zp_xy_n         : out std_logic;
            rel_calc_n      : out std_logic;
            indir_n         : out std_logic;
            indir_x_n       : out std_logic;
            indir_y_n       : out std_logic;
            arith_en_n      : out std_logic;
            stat_dec_oe_n   : out std_logic;
            stat_bus_oe_n   : out std_logic;
            stat_set_flg_n  : out std_logic;
            stat_flg        : out std_logic;
            stat_bus_all_n  : out std_logic;
            stat_bus_nz_n   : out std_logic;
            stat_alu_we_n   : out std_logic;
            r_vec_oe_n      : out std_logic;
            n_vec_oe_n      : out std_logic;
            i_vec_oe_n      : out std_logic;
            r_nw            : out std_logic
            ;---for parameter check purpose!!!
            check_bit     : out std_logic_vector(1 to 5)
        );
end decoder;

architecture rtl of decoder is

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

--cycle bit format 
-- bit 5    : pcl increment carry flag
-- bit 4,3  : cycle type: 00 normal, 01 reset , 10 nmi, 11 irq 
-- bit 2-0  : cycle

--00xxx : exec cycle : T0 > T1 > T2 > T3 > T4 > T5 > T6 > T0
constant T0 : std_logic_vector (5 downto 0) := "000000";
constant T1 : std_logic_vector (5 downto 0) := "000001";
constant T2 : std_logic_vector (5 downto 0) := "000010";
constant T3 : std_logic_vector (5 downto 0) := "000011";
constant T4 : std_logic_vector (5 downto 0) := "000100";
constant T5 : std_logic_vector (5 downto 0) := "000101";
constant T6 : std_logic_vector (5 downto 0) := "000110";

--01xxx : reset cycle : R0 > R1 > R2 > R3 > R4 > R5 > T0
constant R0 : std_logic_vector (5 downto 0) := "001000";
constant R1 : std_logic_vector (5 downto 0) := "001001";
constant R2 : std_logic_vector (5 downto 0) := "001010";
constant R3 : std_logic_vector (5 downto 0) := "001011";
constant R4 : std_logic_vector (5 downto 0) := "001100";
constant R5 : std_logic_vector (5 downto 0) := "001101";

--10xxx : nmi cycle : T0 > N1 > N2 > N3 > N4 > N5 > T0
constant N1 : std_logic_vector (5 downto 0) := "010001";
constant N2 : std_logic_vector (5 downto 0) := "010010";
constant N3 : std_logic_vector (5 downto 0) := "010011";
constant N4 : std_logic_vector (5 downto 0) := "010100";
constant N5 : std_logic_vector (5 downto 0) := "010101";

--11xxx : irq cycle : T0 > I1 > I2 > I3 > I4 > I5 > T0
constant I1 : std_logic_vector (5 downto 0) := "011001";
constant I2 : std_logic_vector (5 downto 0) := "011010";
constant I3 : std_logic_vector (5 downto 0) := "011011";
constant I4 : std_logic_vector (5 downto 0) := "011100";
constant I5 : std_logic_vector (5 downto 0) := "011101";

constant ERROR_CYCLE : std_logic_vector (5 downto 0) := "111111";

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

---for pch_inc_n.
signal pch_inc_input : std_logic;

---for nmi handling
signal nmi_handled_n : std_logic;

-- page boundary handling
signal wk_next_cycle      : std_logic_vector (5 downto 0);
signal wk_acc_cmd         : std_logic_vector(3 downto 0);
signal wk_x_cmd           : std_logic_vector(3 downto 0);
signal wk_y_cmd           : std_logic_vector(3 downto 0);
signal wk_stat_alu_we_n   : std_logic;
signal ea_carry_reg       : std_logic;

begin

    ---pc page next is connected to top bit of exec_cycle
    pch_inc_input <= not exec_cycle(5);
    pch_inc_reg : d_flip_flop_bit 
            port map(set_clk, '1', '1', '0', pch_inc_input, pch_inc_n);

    ea_carry_inst: d_flip_flop_bit 
            port map(trig_clk, '1', '1', '0', ea_carry, ea_carry_reg);

    --acc,x,y next cycle is changed when it goes page across.
    --The conditional branch instructions all have the form xxy10000
    next_cycle <= wk_next_cycle;
    acc_cmd <= wk_acc_cmd(3) & '1' & wk_acc_cmd(1) & '1'
                    when ea_carry = '1' and 
                         wk_next_cycle = T0 and instruction(4 downto 0) = "10000" else
               wk_acc_cmd;

    x_cmd <= wk_x_cmd(3) & '1' & wk_x_cmd(1 downto 0)
                when ea_carry = '1' and 
                         wk_next_cycle = T0 and instruction(4 downto 0) = "10000" else
             wk_x_cmd;
    y_cmd <= wk_y_cmd(3) & '1' & wk_y_cmd(1 downto 0)
                when ea_carry = '1' and 
                         wk_next_cycle = T0 and instruction(4 downto 0) = "10000" else
             wk_y_cmd;
    stat_alu_we_n <= '1' when ea_carry = '1' and 
                         wk_next_cycle = T0 and instruction(4 downto 0) = "10000" else
                     wk_stat_alu_we_n;

    main_p : process (set_clk, res_n, nmi_n)

-------------------------------------------------------------
-------------------------------------------------------------
----------------------- comon routines ----------------------
-------------------------------------------------------------
-------------------------------------------------------------

----------gate_cmd format
------3 : front port oe_n
------2 : front port we_n
------1 : back port oe_n
------0 : back port we_n
procedure front_oe (signal cmd : out std_logic_vector(3 downto 0); 
    val : in std_logic) is
begin
    cmd(3) <= val;
end;
procedure front_we (signal cmd : out std_logic_vector(3 downto 0); 
    val : in std_logic) is
begin
    cmd(2) <= val;
end;
procedure back_oe (signal cmd : out std_logic_vector(3 downto 0); 
    val : in std_logic) is
begin
    cmd(1) <= val;
end;
procedure back_we (signal cmd : out std_logic_vector(3 downto 0); 
    val : in std_logic) is
begin
    cmd(0) <= val;
end;

procedure fetch_next is
begin
    pcl_inc_n <= '0';
    back_oe(pcl_cmd, '0');
    back_oe(pch_cmd, '0');
    back_we(pcl_cmd, '0');
    back_we(pch_cmd, '1');
end procedure;

procedure fetch_stop is
begin
    pcl_inc_n <= '1';
    back_oe(pcl_cmd, '1');
    back_oe(pch_cmd, '1');
    back_we(pcl_cmd, '1');
end procedure;

procedure read_status is
begin
    status_reg <= (others => 'Z');
    stat_dec_oe_n <= '0';
end  procedure;

procedure disable_pins is
begin
--following pins are not set in this function.
--            inst_we_n       : out std_logic;
--            ad_oe_n         : out std_logic;
--            dl_al_oe_n      : out std_logic;
--            pcl_inc_n       : out std_logic;
--            pcl_cmd         : out std_logic_vector(3 downto 0);
--            pch_cmd         : out std_logic_vector(3 downto 0);
--            r_nw            : out std_logic

    --disable the last opration pins.
    dbuf_int_oe_n <= '1';
    dl_al_we_n <= '1';
    dl_ah_we_n <= '1';
    dl_ah_oe_n <= '1';
    dl_dh_oe_n <= '1';
    sp_cmd <= "1111";
    sp_oe_n <= '1';
    sp_push_n <= '1';
    sp_pop_n <= '1';
    wk_acc_cmd <= "1111";
    wk_x_cmd <= "1111";
    wk_y_cmd <= "1111";

    abs_xy_n <= '1';
    pg_next_n <= '1';
    zp_n <= '1';
    zp_xy_n <= '1';
    rel_calc_n <= '1';
    indir_n <= '1';
    indir_x_n <= '1';
    indir_y_n <= '1';
    arith_en_n <= '1';

    read_status;
    stat_bus_oe_n <= '1';
    stat_set_flg_n <= '1';
    stat_flg <= '1';
    stat_bus_all_n <= '1';
    stat_bus_nz_n <= '1';
    wk_stat_alu_we_n <= '1';

    r_vec_oe_n <= '1';
    n_vec_oe_n <= '1';
    i_vec_oe_n <= '1';

end  procedure;

procedure fetch_inst (inc_pcl : in std_logic) is
begin
    if instruction = conv_std_logic_vector(16#4c#, dsize) then
        --if prior cycle is jump instruction, 
        --fetch opcode from where the latch is pointing to.

        --latch > al.
        dl_al_oe_n <= '0';
        pcl_cmd <= "1110";
    else
        --fetch opcode and pcl increment.
        pcl_cmd <= "1100";
        dl_al_oe_n <= '1';
    end if;

    ad_oe_n <= '0';
    pch_cmd <= "1101";
    inst_we_n <= '0';
    pcl_inc_n <= inc_pcl;
    r_nw <= '1';

    d_print(string'("fetch 1"));
end  procedure;

---T0 cycle routine 
---(along with the page boundary condition, the last 
---cycle is bypassed and slided to T0.)
procedure t0_cycle is
begin
    disable_pins;
    if (nmi_n = '0' and nmi_handled_n = '1') then
        --start nmi handling...
        fetch_inst('1');
        wk_next_cycle <= N1;
    else
        fetch_inst('0');
        wk_next_cycle <= T1;
    end if;
end  procedure;

---common routine for single byte instruction.
procedure single_inst is
begin
    fetch_stop;
    wk_next_cycle <= T0;
end  procedure;

procedure fetch_imm is
begin
    d_print("immediate");
    fetch_next;
    --send data from data bus buffer.
    --receiver is instruction dependent.
    dbuf_int_oe_n <= '0';
    wk_next_cycle <= T0;
end  procedure;

procedure set_nz_from_bus is
begin
    --status register n/z bit update.
    stat_bus_nz_n <= '0';
end  procedure;

procedure set_zc_from_alu is
begin
    --status register n/z bit update.
    wk_stat_alu_we_n <= '0';
    stat_dec_oe_n <= '1';
    status_reg <= "00000011";
end  procedure;

procedure set_nz_from_alu is
begin
    --status register n/z/c bit update.
    wk_stat_alu_we_n <= '0';
    stat_dec_oe_n <= '1';
    status_reg <= "10000010";
end  procedure;

procedure set_nzc_from_alu is
begin
    --status register n/z/c bit update.
    wk_stat_alu_we_n <= '0';
    stat_dec_oe_n <= '1';
    status_reg <= "10000011";
end  procedure;

procedure set_nvz_from_alu is
begin
    --status register n/z/v bit update.
    wk_stat_alu_we_n <= '0';
    stat_dec_oe_n <= '1';
    status_reg <= "11000010";
end  procedure;

procedure set_nvzc_from_alu is
begin
    wk_stat_alu_we_n <= '0';
    stat_dec_oe_n <= '1';
    status_reg <= "11000011";
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

procedure fetch_low is
begin
    d_print("fetch low 2");
    --fetch next opcode (abs low).
    fetch_next;
    --latch abs low data.
    dbuf_int_oe_n <= '0';
    dl_al_we_n <= '0';
    wk_next_cycle <= T2;
end  procedure;

procedure abs_fetch_high is
begin
    d_print("abs (xy) 3");
    dl_al_we_n <= '1';

    --latch abs hi data.
    fetch_next;
    dbuf_int_oe_n <= '0';
    dl_ah_we_n <= '0';
    wk_next_cycle <= T3;
end  procedure;

procedure abs_latch_out is
begin
    --d_print("abs 4");
    dl_ah_we_n <= '1';
    fetch_stop;

    --latch > al/ah.
    dl_al_oe_n <= '0';
    dl_ah_oe_n <= '0';
end  procedure;

procedure ea_x_out is
begin
    -----calucurate and output effective addr
    back_oe(wk_x_cmd, '0');
    abs_xy_n <= '0';
end  procedure;

procedure ea_y_out is
begin
    back_oe(wk_y_cmd, '0');
    abs_xy_n <= '0';
end  procedure;

--A.2. internal execution on memory data

procedure a2_zp is
begin
    if exec_cycle = T1 then
        fetch_low;
    elsif exec_cycle = T2 then
        fetch_stop;
        dbuf_int_oe_n <= '0';
        dl_al_we_n <= '1';

        --calc zp.
        dl_al_oe_n <= '0';
        zp_n <= '0';
        wk_next_cycle <= T0;
    end if;
end  procedure;

procedure a2_abs is
begin
    if exec_cycle = T1 then
        fetch_low;
    elsif exec_cycle = T2 then
        abs_fetch_high;
    elsif exec_cycle = T3 then
        abs_latch_out;
        dbuf_int_oe_n <= '0';
        wk_next_cycle <= T0;
    end if;
end  procedure;

procedure a2_page_next is
begin
    --close open gate if page boundary crossed.
    back_we(wk_acc_cmd, '1');
    front_we(wk_acc_cmd, '1');
    front_we(wk_x_cmd, '1');
    front_we(wk_y_cmd, '1');
    wk_stat_alu_we_n <= '1';
end  procedure;

procedure a2_abs_xy (is_x : in boolean) is
begin
    if exec_cycle = T1 then
        fetch_low;
    elsif exec_cycle = T2 then
        abs_fetch_high;
    elsif exec_cycle = T3 then
        --ea calc & lda
        pg_next_n <= '1';
        abs_latch_out;
        if (is_x = true) then
            ea_x_out;
        else
            ea_y_out;
        end if;
        dbuf_int_oe_n <= '0';

        wk_next_cycle <= T0;
        d_print("absx step 1");
    elsif (exec_cycle = T0 and ea_carry_reg = '1') then
        --case page boundary crossed.
        --redo inst.
        d_print("absx 5 (page boudary crossed.)");
        --next page.
        pg_next_n <= '0';
        wk_next_cycle <= T0;
    end if;
end  procedure;

procedure a2_zp_xy (is_x : in boolean) is
begin
    if exec_cycle = T1 then
        fetch_low;
    elsif exec_cycle = T2 then
        fetch_stop;
        --output BAL only
        dbuf_int_oe_n <= '0';
        dl_al_we_n <= '1';

        --calc zp.
        dl_al_oe_n <= '0';
        zp_n <= '0';
        wk_next_cycle <= T3;
    elsif exec_cycle = T3 then
        --t3 zp, xy 
        zp_xy_n <= '0';
        if (is_x = true) then
            back_oe(wk_x_cmd, '0');
        else
            back_oe(wk_y_cmd, '0');
        end if;
        wk_next_cycle <= T0;
    end if;
end  procedure;

procedure a2_indir_y is
begin
    if exec_cycle = T1 then
        fetch_low;
        --get IAL
        dl_al_we_n <= '0';

    elsif exec_cycle = T2 then
        fetch_stop;
        dl_al_we_n <= '1';

        ---address is 00:IAL
        --output BAL @IAL
        indir_y_n <= '0';
        dl_al_oe_n <= '0';
        dbuf_int_oe_n <= '0';
        wk_next_cycle <= T3;

    elsif exec_cycle = T3 then
        indir_y_n <= '0';
        dl_al_oe_n <= '0';
        --output BAH @IAL+1
        dbuf_int_oe_n <= '0';
        wk_next_cycle <= T4;

    elsif exec_cycle = T4 then
        dl_al_oe_n <= '1';
        dbuf_int_oe_n <= '1';

        --add index y.
        pg_next_n <= '1';
        back_oe(wk_y_cmd, '0');
        indir_y_n <= '0';
        dbuf_int_oe_n <= '0';

        if (ea_carry = '1') then
            wk_next_cycle <= T5;
        else
            wk_next_cycle <= T0;
        end if;
    elsif (exec_cycle = T5) then
        --case page boundary crossed.
        --redo inst.
        d_print("(indir), y (page boudary crossed.)");
        --next page.
        pg_next_n <= '0';
        wk_next_cycle <= T0;
    end if;
end  procedure;

procedure a2_indir_x is
begin
    if exec_cycle = T1 then
        fetch_low;
        --get IAL
        dl_al_we_n <= '0';

    elsif exec_cycle = T2 then
        fetch_stop;
        dl_al_we_n <= '1';

        ---address is 00:IAL
        --output BAL @IAL, but cycle #2 is discarded
        indir_x_n <= '0';
        dl_al_oe_n <= '0';
        wk_next_cycle <= T3;

    elsif exec_cycle = T3 then
        indir_x_n <= '0';
        dl_al_oe_n <= '1';

        --output BAH @IAL+x
        dbuf_int_oe_n <= '0';
        back_oe(wk_x_cmd, '0');
        wk_next_cycle <= T4;

    elsif exec_cycle = T4 then
        indir_x_n <= '0';

        --output BAH @IAL+x+1
        dbuf_int_oe_n <= '0';
        back_oe(wk_x_cmd, '0');

        wk_next_cycle <= T5;
    elsif (exec_cycle = T5) then
        indir_x_n <= '0';
        wk_next_cycle <= T0;
    end if;
end  procedure;

--A.3. store operation.

procedure a3_zp is
begin
    if exec_cycle = T1 then
        fetch_low;
    elsif exec_cycle = T2 then
        fetch_stop;
        dbuf_int_oe_n <= '1';
        dl_al_we_n <= '1';

        --calc zp.
        dl_al_oe_n <= '0';
        zp_n <= '0';
        r_nw <= '0';
        wk_next_cycle <= T0;
    end if;
end  procedure;

procedure a3_zp_xy (is_x : in boolean) is
begin
    if exec_cycle = T1 then
        fetch_low;
    elsif exec_cycle = T2 then
        fetch_stop;
        dbuf_int_oe_n <= '1';
        dl_al_we_n <= '1';

        --calc zp.
        dl_al_oe_n <= '0';
        zp_n <= '0';
        wk_next_cycle <= T3;
    elsif exec_cycle = T3 then
        --calc zp + index.
        dl_al_oe_n <= '0';
        zp_n <= '0';
        zp_xy_n <= '0';
        if (is_x = true) then
            back_oe(wk_x_cmd, '0');
        else
            back_oe(wk_y_cmd, '0');
        end if;

        --write data
        r_nw <= '0';
        wk_next_cycle <= T0;
    end if;
end  procedure;

procedure a3_abs is
begin
    if exec_cycle = T1 then
        fetch_low;
    elsif exec_cycle = T2 then
        abs_fetch_high;
    elsif exec_cycle = T3 then
        abs_latch_out;
        dbuf_int_oe_n <= '1';
        r_nw <= '0';
        wk_next_cycle <= T0;
    end if;
end  procedure;

procedure a3_abs_xy (is_x : in boolean) is
begin
    if exec_cycle = T1 then
        fetch_low;
    elsif exec_cycle = T2 then
        abs_fetch_high;
    elsif exec_cycle = T3 then
        --ea calc & lda
        pg_next_n <= '1';
        abs_latch_out;
        dbuf_int_oe_n <= '1';
        if (is_x = true) then
            ea_x_out;
        else
            ea_y_out;
        end if;
        wk_next_cycle <= T4;
    elsif exec_cycle = T4 then
        if (ea_carry_reg = '1') then
            pg_next_n <= '0';
        else
            pg_next_n <= '1';
        end if;
        abs_latch_out;
        if (is_x = true) then
            ea_x_out;
        else
            ea_y_out;
        end if;
        r_nw <= '0';
        wk_next_cycle <= T0;
    end if;
end  procedure;


procedure a3_indir_y is
begin
    if exec_cycle = T1 then
        fetch_low;
        --get IAL
        dl_al_we_n <= '0';

    elsif exec_cycle = T2 then
        fetch_stop;
        dl_al_we_n <= '1';

        ---address is 00:IAL
        --output BAL @IAL
        indir_y_n <= '0';
        dl_al_oe_n <= '0';
        dbuf_int_oe_n <= '0';
        wk_next_cycle <= T3;

    elsif exec_cycle = T3 then
        indir_y_n <= '0';
        dl_al_oe_n <= '0';
        --output BAH @IAL+1
        dbuf_int_oe_n <= '0';
        wk_next_cycle <= T4;

    elsif exec_cycle = T4 then
        dl_al_oe_n <= '1';
        dbuf_int_oe_n <= '1';

        --add index y.
        pg_next_n <= '1';
        back_oe(wk_y_cmd, '0');
        indir_y_n <= '0';
        wk_next_cycle <= T5;

    elsif exec_cycle = T5 then
        --page handling.
        back_oe(wk_y_cmd, '1');
        indir_y_n <= '0';
        
        --ea_carry reg is suspicious. timing is not garanteed...
        if (ea_carry_reg = '1') then
            pg_next_n <= '0';
        else
            pg_next_n <= '1';
        end if;
        r_nw <= '0';
        wk_next_cycle <= T0;
    end if;
end  procedure;

procedure a3_indir_x is
begin
    if exec_cycle = T1 then
        fetch_low;
        --get IAL
        dl_al_we_n <= '0';

    elsif exec_cycle = T2 then
        fetch_stop;
        dl_al_we_n <= '1';

        ---address is 00:IAL
        --output BAL @IAL, but cycle #2 is discarded
        indir_x_n <= '0';
        dl_al_oe_n <= '0';
        wk_next_cycle <= T3;

    elsif exec_cycle = T3 then
        indir_x_n <= '0';
        dl_al_oe_n <= '1';

        --output BAH @IAL+x
        dbuf_int_oe_n <= '0';
        back_oe(wk_x_cmd, '0');
        wk_next_cycle <= T4;

    elsif exec_cycle = T4 then
        indir_x_n <= '0';

        --output BAH @IAL+x+1
        dbuf_int_oe_n <= '0';
        back_oe(wk_x_cmd, '0');

        wk_next_cycle <= T5;
    elsif (exec_cycle = T5) then
        indir_x_n <= '0';
        dbuf_int_oe_n <= '1';
        r_nw <= '0';
        wk_next_cycle <= T0;
    end if;
end  procedure;

---A.4. read-modify-write operation

procedure a4_zp is
begin
    if exec_cycle = T1 then
        fetch_low;
    elsif exec_cycle = T2 then
        fetch_stop;
        dl_al_we_n <= '1';

        --t2 cycle read and,
        dl_al_oe_n <= '0';
        zp_n <= '0';
        --keep data in the alu reg.
        arith_en_n <= '0';
        dbuf_int_oe_n <= '0';
        wk_next_cycle <= T3;
    elsif exec_cycle = T3 then
        --t3 fix alu internal register.
        dl_al_oe_n <= '0';
        zp_n <= '0';
        arith_en_n <= '0';
        dbuf_int_oe_n <= '1';
        wk_next_cycle <= T4;
    elsif exec_cycle = T4 then
        --t5 cycle writes modified value.
        dl_al_oe_n <= '0';
        zp_n <= '0';
        r_nw <= '0';
        arith_en_n <= '0';
        wk_next_cycle <= T0;
    end if;
end  procedure;

procedure a4_zp_x is
begin
    if exec_cycle = T1 then
        fetch_low;
    elsif exec_cycle = T2 then
        fetch_stop;
        dbuf_int_oe_n <= '1';
        dl_al_we_n <= '1';

        --t2 cycle read bal only.
        dl_al_oe_n <= '0';
        zp_n <= '0';
        wk_next_cycle <= T3;
    elsif exec_cycle = T3 then
        --t3 cycle read bal + x
        dl_al_oe_n <= '0';
        zp_n <= '0';
        zp_xy_n <= '0';
        back_oe(wk_x_cmd, '0');

        --keep data in the alu reg.
        arith_en_n <= '0';
        dbuf_int_oe_n <= '0';

        wk_next_cycle <= T4;
    elsif exec_cycle = T4 then
        dl_al_oe_n <= '0';
        zp_n <= '0';
        zp_xy_n <= '0';
        back_oe(wk_x_cmd, '0');

        --fix alu internal register.
        arith_en_n <= '0';
        dbuf_int_oe_n <= '1';
        wk_next_cycle <= T5;
    elsif exec_cycle = T5 then
        dbuf_int_oe_n <= '1';

        --t5 cycle writes modified value.
        dl_al_oe_n <= '0';
        zp_n <= '0';
        zp_xy_n <= '0';
        back_oe(wk_x_cmd, '0');
        r_nw <= '0';
        arith_en_n <= '0';
        wk_next_cycle <= T0;
    end if;
end  procedure;


procedure a4_abs is
begin
    if exec_cycle = T1 then
        fetch_low;
    elsif exec_cycle = T2 then
        abs_fetch_high;
    elsif exec_cycle = T3 then
        abs_latch_out;

        --keep data in the alu reg.
        arith_en_n <= '0';
        dbuf_int_oe_n <= '0';
        wk_next_cycle <= T4;
    elsif exec_cycle = T4 then
        abs_latch_out;

        --fix alu internal register.
        arith_en_n <= '0';
        dbuf_int_oe_n <= '1';
        wk_next_cycle <= T5;
    elsif exec_cycle = T5 then
        dbuf_int_oe_n <= '1';

        --t5 cycle writes modified value.
        r_nw <= '0';
        arith_en_n <= '0';
        wk_next_cycle <= T0;
    end if;
end  procedure;

procedure a4_abs_x is
begin
    if exec_cycle = T1 then
        fetch_low;
    elsif exec_cycle = T2 then
        abs_fetch_high;
    elsif exec_cycle = T3 then
        --T3 cycle discarded.
        pg_next_n <= '1';
        abs_latch_out;
        ea_x_out;
        dbuf_int_oe_n <= '0';
        wk_next_cycle <= T4;

    elsif exec_cycle = T4 then
        abs_latch_out;
        ea_x_out;
        if (ea_carry_reg = '1') then
            pg_next_n <= '0';
        else
            pg_next_n <= '1';
        end if;

        --keep data in the alu reg.
        arith_en_n <= '0';
        dbuf_int_oe_n <= '0';
        wk_next_cycle <= T5;

    elsif exec_cycle = T5 then
        --fix alu internal register.
        arith_en_n <= '0';
        dbuf_int_oe_n <= '1';
        wk_next_cycle <= T6;

    elsif exec_cycle = T6 then
        --t5 cycle writes modified value.
        r_nw <= '0';
        arith_en_n <= '0';
        wk_next_cycle <= T0;

    end if;
end  procedure;


-- A.5.1 push stack
procedure a51_push is
begin
    if exec_cycle = T1 then
        fetch_stop;
        wk_next_cycle <= T2;
    elsif exec_cycle = T2 then
        back_oe(sp_cmd, '0');
        back_we(sp_cmd, '0');
        sp_push_n <= '0';
        sp_oe_n <= '0';
        r_nw <= '0';
        wk_next_cycle <= T0;
    end if;
end procedure;

-- A.5.2 pull stack
procedure a52_pull is
begin
    if exec_cycle = T1 then
        fetch_stop;
        wk_next_cycle <= T2;

    elsif exec_cycle = T2 then
        --stack decrement first.
        back_oe(sp_cmd, '0');
        back_we(sp_cmd, '0');
        sp_pop_n <= '0';
        sp_oe_n <= '0';
        wk_next_cycle <= T3;

    elsif exec_cycle = T3 then
        sp_pop_n <= '1';
        back_we(sp_cmd, '1');

        ---pop data from stack.
        back_oe(sp_cmd, '0');
        sp_oe_n <= '0';
        dbuf_int_oe_n <= '0';
        wk_next_cycle <= T0;
    end if;
end procedure;


-- A.5.8 branch operations

procedure a58_branch (int_flg : in integer; br_cond : in std_logic) is
begin
    if exec_cycle = T1 then
        fetch_next;
        if status_reg(int_flg) = br_cond then
            d_print("get rel");

            --latch rel value.
            dbuf_int_oe_n <= '0';
            dl_ah_we_n <= '0';
            wk_next_cycle <= T2;
        else
            d_print("no branch");
            wk_next_cycle <= T0;
        end if;
    elsif exec_cycle = T2 then
        d_print("rel ea");
        fetch_stop;
        dbuf_int_oe_n <= '1';
        dl_ah_we_n <= '1';

        --calc relative addr.
        rel_calc_n <= '0';
        pg_next_n <= '1';
        dl_dh_oe_n <= '0';
        back_oe(pcl_cmd, '0');
        back_oe(pch_cmd, '0');
        back_we(pcl_cmd, '0');

        wk_next_cycle <= T0;
    elsif (exec_cycle = T0 and ea_carry = '1') then
        d_print("page crossed.");
        --page crossed. adh calc.
        back_we(pcl_cmd, '1');
        back_oe(pcl_cmd, '0');
        back_oe(pch_cmd, '0');
        back_we(pch_cmd, '0');
        dl_dh_oe_n <= '0';

        rel_calc_n <= '0';
        pg_next_n <= '0';
        wk_next_cycle <= T0;
    end if;
end  procedure;

-------------------------------------------------------------
-------------------------------------------------------------
---------------- main state machine start.... ---------------
-------------------------------------------------------------
-------------------------------------------------------------
    begin

        if (res_n = '0') then
            --prevent status revister from broken.
            stat_dec_oe_n <= '0';
            stat_bus_oe_n <= '1';
            stat_set_flg_n <= '1';
            stat_flg <= '1';
            stat_bus_all_n <= '1';
            stat_bus_nz_n <= '1';
            wk_stat_alu_we_n <= '1';

            --pc l/h is reset vector.
            pcl_cmd <= "1110";
            pch_cmd <= "1110";
            wk_next_cycle <= R0;

        elsif (rising_edge(set_clk)) then
            d_print(string'("-"));

            if (nmi_n = '1') then
                --nmi handle flag reset.
                nmi_handled_n <= '1';
            end if;
            
            if rdy = '0' then
                --case dma is runnting.
                disable_pins;
                inst_we_n <= '1';
                ad_oe_n <= '1';
                dl_al_oe_n <= '1';
                pcl_inc_n <= '1';
                pcl_cmd <= "1111";
                pch_cmd <= "1111";
                r_nw <= 'Z';
            elsif (exec_cycle = T0 and ea_carry = '0') then
                --cycle #1
                t0_cycle;

            elsif exec_cycle = T1 or exec_cycle = T2 or exec_cycle = T3 or 
                exec_cycle = T4 or exec_cycle = T5 or exec_cycle = T6 or 
                (exec_cycle = T0 and ea_carry = '1') then
                --execute inst.

                ---asyncronous page change might happen.
                back_we(pch_cmd, '1');

                if exec_cycle = T1 then
                    d_print("decode and execute inst: " 
                            & conv_hex8(conv_integer(instruction)));
                    --disable pin for jmp instruction 
                    dl_al_oe_n <= '1';
                    back_we(pcl_cmd, '1');
                    front_we(pch_cmd, '1');

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
                    arith_en_n <= '0';
                    back_oe(wk_acc_cmd, '0');
                    front_we(wk_acc_cmd, '0');
                    set_nzc_from_alu;
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#18#, dsize) then
                    d_print("clc");
                    set_flag0 ('0');
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#d8#, dsize) then
                    d_print("cld");
                    set_flag (st_D, '0');
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#58#, dsize) then
                    d_print("cli");
                    set_flag (st_I, '0');
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#b8#, dsize) then
                    d_print("clv");
                    set_flag (st_V, '0');
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#ca#, dsize) then
                    d_print("dex");
                    arith_en_n <= '0';
                    back_oe(wk_x_cmd, '0');
                    front_we(wk_x_cmd, '0');
                    --set nz bit.
                    set_nz_from_bus;
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#88#, dsize) then
                    d_print("dey");
                    arith_en_n <= '0';
                    back_oe(wk_y_cmd, '0');
                    front_we(wk_y_cmd, '0');
                    --set nz bit.
                    set_nz_from_bus;
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#e8#, dsize) then
                    d_print("inx");
                    arith_en_n <= '0';
                    back_oe(wk_x_cmd, '0');
                    front_we(wk_x_cmd, '0');
                    --set nz bit.
                    set_nz_from_bus;
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#c8#, dsize) then
                    d_print("iny");
                    arith_en_n <= '0';
                    back_oe(wk_y_cmd, '0');
                    front_we(wk_y_cmd, '0');
                    set_nz_from_bus;
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#4a#, dsize) then
                    --lsr acc mode
                    d_print("lsr");
                    arith_en_n <= '0';
                    back_oe(wk_acc_cmd, '0');
                    front_we(wk_acc_cmd, '0');
                    set_zc_from_alu;
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#ea#, dsize) then
                    d_print("nop");
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#2a#, dsize) then
                    --rol acc
                    d_print("rol");
                    arith_en_n <= '0';
                    back_oe(wk_acc_cmd, '0');
                    front_we(wk_acc_cmd, '0');
                    set_nzc_from_alu;
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#6a#, dsize) then
                    --ror acc
                    d_print("ror");
                    arith_en_n <= '0';
                    back_oe(wk_acc_cmd, '0');
                    front_we(wk_acc_cmd, '0');
                    set_nzc_from_alu;
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#38#, dsize) then
                    d_print("sec");
                    set_flag0 ('1');
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#f8#, dsize) then
                    d_print("sed");
                    set_flag (st_D, '1');
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#78#, dsize) then
                    d_print("sei");
                    set_flag (st_I, '1');
                    single_inst;

                elsif instruction = conv_std_logic_vector(16#aa#, dsize) then
                    d_print("tax");
                    set_nz_from_bus;
                    single_inst;
                    front_oe(wk_acc_cmd, '0');
                    front_we(wk_x_cmd, '0');

                elsif instruction = conv_std_logic_vector(16#a8#, dsize) then
                    d_print("tay");
                    set_nz_from_bus;
                    single_inst;
                    front_oe(wk_acc_cmd, '0');
                    front_we(wk_y_cmd, '0');

                elsif instruction = conv_std_logic_vector(16#ba#, dsize) then
                    d_print("tsx");
                    set_nz_from_bus;
                    single_inst;
                    front_oe(sp_cmd, '0');
                    front_we(wk_x_cmd, '0');

                elsif instruction = conv_std_logic_vector(16#8a#, dsize) then
                    d_print("txa");
                    set_nz_from_bus;
                    single_inst;
                    front_oe(wk_x_cmd, '0');
                    front_we(wk_acc_cmd, '0');

                elsif instruction = conv_std_logic_vector(16#9a#, dsize) then
                    d_print("txs");
                    set_nz_from_bus;
                    single_inst;
                    front_oe(wk_x_cmd, '0');
                    front_we(sp_cmd, '0');

                elsif instruction = conv_std_logic_vector(16#98#, dsize) then
                    d_print("tya");
                    set_nz_from_bus;
                    single_inst;
                    front_oe(wk_y_cmd, '0');
                    front_we(wk_acc_cmd, '0');



                ----------------------------------------
                --A.2. internal execution on memory data
                ----------------------------------------
                elsif instruction  = conv_std_logic_vector(16#69#, dsize) then
                    --imm
                    d_print("adc");
                    fetch_imm;
                    arith_en_n <= '0';
                    back_oe(wk_acc_cmd, '0');
                    back_we(wk_acc_cmd, '0');
                    set_nvzc_from_alu;

                elsif instruction  = conv_std_logic_vector(16#65#, dsize) then
                    --zp
                    d_print("adc");
                    a2_zp;
                    if exec_cycle = T2 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nvzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#75#, dsize) then
                    --zp, x
                    d_print("adc");
                    a2_zp_xy(true);
                    if exec_cycle = T3 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nvzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#6d#, dsize) then
                    --abs
                    d_print("adc");
                    a2_abs;
                    if exec_cycle = T3 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nvzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#7d#, dsize) then
                    --abs, x
                    d_print("adc");
                    a2_abs_xy(true);
                    if exec_cycle = T3 or exec_cycle = T0 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nvzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#79#, dsize) then
                    --abs, y
                    d_print("adc");
                    a2_abs_xy(false);
                    if exec_cycle = T3 or exec_cycle = T0 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nvzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#61#, dsize) then
                    --(indir, x)
                    d_print("adc");
                    a2_indir_x;
                    if exec_cycle = T5 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nvzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#71#, dsize) then
                    --(indir), y
                    d_print("adc");
                    a2_indir_y;
                    if exec_cycle = T4 or exec_cycle = T0 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nvzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#29#, dsize) then
                    --imm
                    d_print("and");
                    fetch_imm;
                    arith_en_n <= '0';
                    back_oe(wk_acc_cmd, '0');
                    back_we(wk_acc_cmd, '0');
                    set_nz_from_alu;

                elsif instruction  = conv_std_logic_vector(16#25#, dsize) then
                    --zp
                    d_print("and");
                    a2_zp;
                    if exec_cycle = T2 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#35#, dsize) then
                    --zp, x
                    d_print("and");
                    a2_zp_xy(true);
                    if exec_cycle = T3 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#2d#, dsize) then
                    --abs
                    d_print("and");
                    a2_abs;
                    if exec_cycle = T3 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#3d#, dsize) then
                    --abs, x
                    d_print("and");
                    a2_abs_xy(true);
                    if exec_cycle = T3 or exec_cycle = T0 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#39#, dsize) then
                    --abs, y
                    d_print("and");
                    a2_abs_xy(false);
                    if exec_cycle = T3 or exec_cycle = T0 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#21#, dsize) then
                    --(indir, x)
                    d_print("and");
                    a2_indir_x;
                    if exec_cycle = T5 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#31#, dsize) then
                    --(indir), y
                    d_print("and");
                    a2_indir_y;
                    if exec_cycle = T4 or exec_cycle = T0 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#24#, dsize) then
                    --zp
                    d_print("bit");
                    a2_zp;
                    if exec_cycle = T2 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        set_nvz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#2c#, dsize) then
                    --abs
                    d_print("bit");
                    a2_abs;
                    if exec_cycle = T3 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        set_nvz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#c9#, dsize) then
                    --imm
                    d_print("cmp");
                    fetch_imm;
                    arith_en_n <= '0';
                    back_oe(wk_acc_cmd, '0');
                    set_nzc_from_alu;

                elsif instruction  = conv_std_logic_vector(16#c5#, dsize) then
                    --zp
                    d_print("cmp");
                    a2_zp;
                    if exec_cycle = T2 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#d5#, dsize) then
                    --zp, x
                    d_print("cmp");
                    a2_zp_xy(true);
                    if exec_cycle = T3 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#cd#, dsize) then
                    --abs
                    d_print("cmp");
                    a2_abs;
                    if exec_cycle = T3 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#dd#, dsize) then
                    --abs, x
                    d_print("cmp");
                    a2_abs_xy(true);
                    if exec_cycle = T3 or exec_cycle = T0 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#d9#, dsize) then
                    --abs, y
                    d_print("cmp");
                    a2_abs_xy(false);
                    if exec_cycle = T3 or exec_cycle = T0 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#c1#, dsize) then
                    --(indir, x)
                    d_print("cmp");
                    a2_indir_x;
                    if exec_cycle = T5 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#d1#, dsize) then
                    --(indir), y
                    d_print("cmp");
                    a2_indir_y;
                    if exec_cycle = T4 or exec_cycle = T0 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#e0#, dsize) then
                    --imm
                    d_print("cpx");
                    fetch_imm;
                    arith_en_n <= '0';
                    back_oe(wk_x_cmd, '0');
                    set_nzc_from_alu;

                elsif instruction  = conv_std_logic_vector(16#e4#, dsize) then
                    --zp
                    d_print("cpx");
                    a2_zp;
                    if exec_cycle = T2 then
                        arith_en_n <= '0';
                        back_oe(wk_x_cmd, '0');
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#ec#, dsize) then
                    --abs
                    d_print("cpx");
                    a2_abs;
                    if exec_cycle = T3 then
                        arith_en_n <= '0';
                        back_oe(wk_x_cmd, '0');
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#c0#, dsize) then
                    --imm
                    d_print("cpy");
                    fetch_imm;
                    arith_en_n <= '0';
                    back_oe(wk_y_cmd, '0');
                    set_nzc_from_alu;

                elsif instruction  = conv_std_logic_vector(16#c4#, dsize) then
                    --zp
                    d_print("cpy");
                    a2_zp;
                    if exec_cycle = T2 then
                        arith_en_n <= '0';
                        back_oe(wk_y_cmd, '0');
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#cc#, dsize) then
                    --abs
                    d_print("cpy");
                    a2_abs;
                    if exec_cycle = T3 then
                        arith_en_n <= '0';
                        back_oe(wk_y_cmd, '0');
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#49#, dsize) then
                    --imm
                    d_print("eor");
                    fetch_imm;
                    arith_en_n <= '0';
                    back_oe(wk_acc_cmd, '0');
                    back_we(wk_acc_cmd, '0');
                    set_nz_from_alu;

                elsif instruction  = conv_std_logic_vector(16#45#, dsize) then
                    --zp
                    d_print("eor");
                    a2_zp;
                    if exec_cycle = T2 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#55#, dsize) then
                    --zp, x
                    d_print("eor");
                    a2_zp_xy(true);
                    if exec_cycle = T3 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#4d#, dsize) then
                    --abs
                    d_print("eor");
                    a2_abs;
                    if exec_cycle = T3 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#5d#, dsize) then
                    --abs, x
                    d_print("eor");
                    a2_abs_xy(true);
                    if exec_cycle = T3 or exec_cycle = T0 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#59#, dsize) then
                    --abs, y
                    d_print("eor");
                    a2_abs_xy(false);
                    if exec_cycle = T3 or exec_cycle = T0 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#41#, dsize) then
                    --(indir, x)
                    d_print("eor");
                    a2_indir_x;
                    if exec_cycle = T5 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#51#, dsize) then
                    --(indir), y
                    d_print("eor");
                    a2_indir_y;
                    if exec_cycle = T4 or exec_cycle = T0 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#a9#, dsize) then
                    --imm
                    d_print("lda");
                    fetch_imm;
                    front_we(wk_acc_cmd, '0');
                    set_nz_from_bus;

                elsif instruction  = conv_std_logic_vector(16#a5#, dsize) then
                    --zp
                    d_print("lda");
                    a2_zp;
                    if exec_cycle = T2 then
                        front_we(wk_acc_cmd, '0');
                        set_nz_from_bus;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#b5#, dsize) then
                    --zp, x
                    d_print("lda");
                    a2_zp_xy(true);
                    if exec_cycle = T3 then
                        front_we(wk_acc_cmd, '0');
                        set_nz_from_bus;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#ad#, dsize) then
                    --abs
                    d_print("lda");
                    a2_abs;
                    if exec_cycle = T3 then
                        set_nz_from_bus;
                        front_we(wk_acc_cmd, '0');
                    end if;

                elsif instruction  = conv_std_logic_vector(16#bd#, dsize) then
                    --abs, x
                    d_print("lda");
                    a2_abs_xy(true);
                    if exec_cycle = T3 or exec_cycle = T0 then
                        --lda.
                        front_we(wk_acc_cmd, '0');
                        set_nz_from_bus;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#b9#, dsize) then
                    --abs, y
                    d_print("lda");
                    a2_abs_xy(false);
                    if exec_cycle = T3 or exec_cycle = T0 then
                        --lda.
                        front_we(wk_acc_cmd, '0');
                        set_nz_from_bus;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#a1#, dsize) then
                    --(indir, x)
                    d_print("lda");
                    a2_indir_x;
                    if exec_cycle = T5 then
                        front_we(wk_acc_cmd, '0');
                        set_nz_from_bus;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#b1#, dsize) then
                    --(indir), y
                    d_print("lda");
                    a2_indir_y;
                    if exec_cycle = T4 or exec_cycle = T0 then
                        --lda.
                        front_we(wk_acc_cmd, '0');
                        set_nz_from_bus;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#a2#, dsize) then
                    --imm
                    d_print("ldx");
                    fetch_imm;
                    set_nz_from_bus;
                    front_we(wk_x_cmd, '0');

                elsif instruction  = conv_std_logic_vector(16#a6#, dsize) then
                    --zp
                    d_print("ldx");
                    a2_zp;
                    if exec_cycle = T2 then
                        front_we(wk_x_cmd, '0');
                        set_nz_from_bus;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#b6#, dsize) then
                    --zp, y
                    d_print("ldx");
                    a2_zp_xy(false);
                    if exec_cycle = T3 then
                        front_we(wk_x_cmd, '0');
                        set_nz_from_bus;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#ae#, dsize) then
                    --abs
                    d_print("ldx");
                    a2_abs;
                    if exec_cycle = T3 then
                        set_nz_from_bus;
                        front_we(wk_x_cmd, '0');
                    end if;

                elsif instruction  = conv_std_logic_vector(16#be#, dsize) then
                    --abs, y
                    d_print("ldx");
                    a2_abs_xy(false);
                    if exec_cycle = T3 or exec_cycle = T0 then
                        front_we(wk_x_cmd, '0');
                        set_nz_from_bus;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#a0#, dsize) then
                    --imm
                    d_print("ldy");
                    fetch_imm;
                    set_nz_from_bus;
                    front_we(wk_y_cmd, '0');

                elsif instruction  = conv_std_logic_vector(16#a4#, dsize) then
                    --zp
                    d_print("ldy");
                    a2_zp;
                    if exec_cycle = T2 then
                        front_we(wk_y_cmd, '0');
                        set_nz_from_bus;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#b4#, dsize) then
                    --zp, x
                    d_print("ldy");
                    a2_zp_xy(true);
                    if exec_cycle = T3 then
                        front_we(wk_y_cmd, '0');
                        set_nz_from_bus;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#ac#, dsize) then
                    --abs
                    d_print("ldy");
                    a2_abs;
                    if exec_cycle = T3 then
                        set_nz_from_bus;
                        front_we(wk_y_cmd, '0');
                    end if;

                elsif instruction  = conv_std_logic_vector(16#bc#, dsize) then
                    --abs, x
                    d_print("ldy");
                    a2_abs_xy(true);
                    if exec_cycle = T3 or exec_cycle = T0 then
                        set_nz_from_bus;
                        front_we(wk_y_cmd, '0');
                    end if;

                elsif instruction  = conv_std_logic_vector(16#09#, dsize) then
                    --imm
                    d_print("ora");
                    fetch_imm;
                    arith_en_n <= '0';
                    back_oe(wk_acc_cmd, '0');
                    back_we(wk_acc_cmd, '0');
                    set_nz_from_alu;

                elsif instruction  = conv_std_logic_vector(16#05#, dsize) then
                    --zp
                    d_print("ora");
                    a2_zp;
                    if exec_cycle = T2 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#15#, dsize) then
                    --zp, x
                    d_print("ora");
                    a2_zp_xy(true);
                    if exec_cycle = T3 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#0d#, dsize) then
                    --abs
                    d_print("ora");
                    a2_abs;
                    if exec_cycle = T3 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#1d#, dsize) then
                    --abs, x
                    d_print("ora");
                    a2_abs_xy(true);
                    if exec_cycle = T3 or exec_cycle = T0 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#19#, dsize) then
                    --abs, y
                    d_print("ora");
                    a2_abs_xy(false);
                    if exec_cycle = T3 or exec_cycle = T0 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#01#, dsize) then
                    --(indir, x)
                    d_print("ora");
                    a2_indir_x;
                    if exec_cycle = T5 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#11#, dsize) then
                    --(indir), y
                    d_print("ora");
                    a2_indir_y;
                    if exec_cycle = T4 or exec_cycle = T0 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nz_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#e9#, dsize) then
                    --imm
                    d_print("sbc");
                    fetch_imm;
                    arith_en_n <= '0';
                    back_oe(wk_acc_cmd, '0');
                    back_we(wk_acc_cmd, '0');
                    set_nvzc_from_alu;

                elsif instruction  = conv_std_logic_vector(16#e5#, dsize) then
                    --zp
                    d_print("sbc");
                    a2_zp;
                    if exec_cycle = T2 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nvzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#f5#, dsize) then
                    --zp, x
                    d_print("sbc");
                    a2_zp_xy(true);
                    if exec_cycle = T3 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nvzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#ed#, dsize) then
                    --abs
                    d_print("sbc");
                    a2_abs;
                    if exec_cycle = T3 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nvzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#fd#, dsize) then
                    --abs, x
                    d_print("sbc");
                    a2_abs_xy(true);
                    if exec_cycle = T3 or exec_cycle = T0 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nvzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#f9#, dsize) then
                    --abs, y
                    d_print("sbc");
                    a2_abs_xy(false);
                    if exec_cycle = T3 or exec_cycle = T0 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nvzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#e1#, dsize) then
                    --(indir, x)
                    d_print("sbc");
                    a2_indir_x;
                    if exec_cycle = T5 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nvzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#f1#, dsize) then
                    --(indir), y
                    d_print("sbc");
                    a2_indir_y;
                    if exec_cycle = T4 or exec_cycle = T0 then
                        arith_en_n <= '0';
                        back_oe(wk_acc_cmd, '0');
                        back_we(wk_acc_cmd, '0');
                        set_nvzc_from_alu;
                    end if;



                ----------------------------------------
                ---A.3. store operation.
                ----------------------------------------
                elsif instruction  = conv_std_logic_vector(16#85#, dsize) then
                    --zp
                    d_print("sta");
                    a3_zp;
                    if exec_cycle = T2 then
                        front_oe(wk_acc_cmd, '0');
                    end if;

                elsif instruction  = conv_std_logic_vector(16#95#, dsize) then
                    --zp, x
                    d_print("sta");
                    a3_zp_xy(true);
                    if exec_cycle = T2 then
                        front_oe(wk_acc_cmd, '0');
                    end if;

                elsif instruction  = conv_std_logic_vector(16#8d#, dsize) then
                    --abs
                    d_print("sta");
                    a3_abs;
                    if exec_cycle = T3 then
                        front_oe(wk_acc_cmd, '0');
                    end if;

                elsif instruction  = conv_std_logic_vector(16#9d#, dsize) then
                    --abs, x
                    d_print("sta");
                    a3_abs_xy (true);
                    if exec_cycle = T4 then
                        front_oe(wk_acc_cmd, '0');
                    end if;

                elsif instruction  = conv_std_logic_vector(16#99#, dsize) then
                    --abs, y
                    d_print("sta");
                    a3_abs_xy (false);
                    if exec_cycle = T4 then
                        front_oe(wk_acc_cmd, '0');
                    end if;

                elsif instruction  = conv_std_logic_vector(16#81#, dsize) then
                    --(indir, x)
                    d_print("sta");
                    a3_indir_x;
                    if exec_cycle = T5 then
                        front_oe(wk_acc_cmd, '0');
                    end if;

                elsif instruction  = conv_std_logic_vector(16#91#, dsize) then
                    --(indir), y
                    d_print("sta");
                    a3_indir_y;
                    if exec_cycle = T5 then
                        front_oe(wk_acc_cmd, '0');
                    end if;

                elsif instruction  = conv_std_logic_vector(16#86#, dsize) then
                    --zp
                    d_print("stx");
                    a3_zp;
                    if exec_cycle = T2 then
                        front_oe(wk_x_cmd, '0');
                    end if;

                elsif instruction  = conv_std_logic_vector(16#96#, dsize) then
                    --zp, y
                    d_print("stx");
                    a3_zp_xy(false);
                    if exec_cycle = T2 then
                        front_oe(wk_x_cmd, '0');
                    end if;

                elsif instruction  = conv_std_logic_vector(16#8e#, dsize) then
                    --abs
                    d_print("stx");
                    a3_abs;
                    if exec_cycle = T3 then
                        front_oe(wk_x_cmd, '0');
                    end if;

                elsif instruction  = conv_std_logic_vector(16#84#, dsize) then
                    --zp
                    d_print("sty");
                    a3_zp;
                    if exec_cycle = T2 then
                        front_oe(wk_y_cmd, '0');
                    end if;

                elsif instruction  = conv_std_logic_vector(16#94#, dsize) then
                    --zp, x
                    d_print("sty");
                    a3_zp_xy(true);
                    if exec_cycle = T2 then
                        front_oe(wk_y_cmd, '0');
                    end if;

                elsif instruction  = conv_std_logic_vector(16#8c#, dsize) then
                    --abs
                    d_print("sty");
                    a3_abs;
                    if exec_cycle = T3 then
                        front_oe(wk_y_cmd, '0');
                    end if;


                ----------------------------------------
                ---A.4. read-modify-write operation
                ----------------------------------------
                elsif instruction  = conv_std_logic_vector(16#06#, dsize) then
                    --zp
                    d_print("asl");
                    a4_zp;
                    if exec_cycle = T4 then
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#16#, dsize) then
                    --zp, x
                    d_print("asl");
                    a4_zp_x;
                    if exec_cycle = T5 then
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#0e#, dsize) then
                    --abs
                    d_print("asl");
                    a4_abs;
                    if exec_cycle = T5 then
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#1e#, dsize) then
                    --abs, x
                    d_print("asl");
                    a4_abs_x;
                    if exec_cycle = T6 then
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#c6#, dsize) then
                    --zp
                    d_print("dec");
                    a4_zp;
                    if exec_cycle = T4 then
                        set_nz_from_bus;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#d6#, dsize) then
                    --zp, x
                    d_print("dec");
                    a4_zp_x;
                    if exec_cycle = T5 then
                        set_nz_from_bus;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#ce#, dsize) then
                    --abs
                    d_print("dec");
                    a4_abs;
                    if exec_cycle = T5 then
                        set_nz_from_bus;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#de#, dsize) then
                    --abs, x
                    d_print("dec");
                    a4_abs_x;
                    if exec_cycle = T6 then
                        set_nz_from_bus;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#e6#, dsize) then
                    --zp
                    d_print("inc");
                    a4_zp;
                    if exec_cycle = T4 then
                        set_nz_from_bus;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#f6#, dsize) then
                    --zp, x
                    d_print("inc");
                    a4_zp_x;
                    if exec_cycle = T5 then
                        set_nz_from_bus;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#ee#, dsize) then
                    --abs
                    d_print("inc");
                    a4_abs;
                    if exec_cycle = T5 then
                        set_nz_from_bus;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#fe#, dsize) then
                    --abs, x
                    d_print("inc");
                    a4_abs_x;
                    if exec_cycle = T6 then
                        set_nz_from_bus;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#46#, dsize) then
                    --zp
                    d_print("lsr");
                    a4_zp;
                    if exec_cycle = T4 then
                        set_zc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#56#, dsize) then
                    --zp, x
                    d_print("lsr");
                    a4_zp_x;
                    if exec_cycle = T5 then
                        set_zc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#4e#, dsize) then
                    --abs
                    d_print("lsr");
                    a4_abs;
                    if exec_cycle = T5 then
                        set_zc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#5e#, dsize) then
                    --abs, x
                    d_print("lsr");
                    a4_abs_x;
                    if exec_cycle = T6 then
                        set_zc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#26#, dsize) then
                    --zp
                    d_print("rol");
                    a4_zp;
                    if exec_cycle = T4 then
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#36#, dsize) then
                    --zp, x
                    d_print("rol");
                    a4_zp_x;
                    if exec_cycle = T5 then
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#2e#, dsize) then
                    --abs
                    d_print("rol");
                    a4_abs;
                    if exec_cycle = T5 then
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#3e#, dsize) then
                    --abs, x
                    d_print("rol");
                    a4_abs_x;
                    if exec_cycle = T6 then
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#66#, dsize) then
                    --zp
                    d_print("ror");
                    a4_zp;
                    if exec_cycle = T4 then
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#76#, dsize) then
                    --zp, x
                    d_print("ror");
                    a4_zp_x;
                    if exec_cycle = T5 then
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#6e#, dsize) then
                    --abs
                    d_print("ror");
                    a4_abs;
                    if exec_cycle = T5 then
                        set_nzc_from_alu;
                    end if;

                elsif instruction  = conv_std_logic_vector(16#7e#, dsize) then
                    --abs, x
                    d_print("ror");
                    a4_abs_x;
                    if exec_cycle = T6 then
                        set_nzc_from_alu;
                    end if;


                ----------------------------------------
                --A.5. miscellaneous oprations.
                ----------------------------------------

                -- A.5.1 push/pull
                elsif instruction = conv_std_logic_vector(16#08#, dsize) then
                    d_print("php");
                    a51_push;
                    if exec_cycle = T2 then
                        stat_bus_oe_n <= '0';
                    end if;

                elsif instruction = conv_std_logic_vector(16#48#, dsize) then
                    d_print("pha");
                    a51_push;
                    if exec_cycle = T2 then
                        front_oe(wk_acc_cmd, '0');
                    end if;

                elsif instruction = conv_std_logic_vector(16#28#, dsize) then
                    d_print("plp");
                    a52_pull;
                    if exec_cycle = T3 then
                        stat_dec_oe_n <= '1';
                        stat_bus_all_n <= '0';
                    end if;

                elsif instruction = conv_std_logic_vector(16#68#, dsize) then
                    d_print("pla");
                    a52_pull;
                    if exec_cycle = T3 then
                        front_we(wk_acc_cmd, '0');
                        set_nz_from_bus;
                    end if;


                ----------------------------------------
                -- A.5.3 jsr
                ----------------------------------------
                elsif instruction = conv_std_logic_vector(16#20#, dsize) then
                    if exec_cycle = T1 then
                        d_print("jsr abs 2");
                        --fetch opcode.
                        fetch_next;
                        dbuf_int_oe_n <= '0';
                        --latch adl
                        dl_al_we_n <= '0';
                        wk_next_cycle <= T2;
                    elsif exec_cycle = T2 then
                        d_print("jsr 3");
                        fetch_stop;
                        dbuf_int_oe_n <= '1';
                        dl_al_we_n <= '1';

                       --push return addr high into stack.
                        sp_push_n <= '0';
                        sp_oe_n <= '0';
                        front_oe(pch_cmd, '0');
                        back_oe(sp_cmd, '0');
                        back_we(sp_cmd, '0');
                        r_nw <= '0';
                        wk_next_cycle <= T3;
                    elsif exec_cycle = T3 then
                        d_print("jsr 4");
                        front_oe(pch_cmd, '1');

                       --push return addr low into stack.
                        sp_push_n <= '0';
                        sp_oe_n <= '0';
                        front_oe(pcl_cmd, '0');
                        back_oe(sp_cmd, '0');
                        back_we(sp_cmd, '0');
                        r_nw <= '0';

                        wk_next_cycle <= T4;
                    elsif exec_cycle = T4 then
                        d_print("jsr 5");
                        sp_push_n <= '1';
                        sp_oe_n <= '1';
                        front_oe(pcl_cmd, '1');
                        back_oe(sp_cmd, '1');
                        back_we(sp_cmd, '1');
                        r_nw <= '1';

                        --fetch last op.
                        back_oe(pch_cmd, '0');
                        back_oe(pcl_cmd, '0');
                        dbuf_int_oe_n <= '0';
                        dl_ah_we_n <= '0';

                        wk_next_cycle <= T5;
                    elsif exec_cycle = T5 then
                        d_print("jsr 6");

                        back_oe(pch_cmd, '1');
                        back_oe(pcl_cmd, '1');
                        dbuf_int_oe_n <= '1';
                        dl_ah_we_n <= '1';

                        --load/output  pch
                        ad_oe_n <= '1';
                        dl_dh_oe_n <= '0';
                        front_we(pch_cmd, '0');

                        --load pcl.
                        dl_al_oe_n <= '0';
                        back_we(pcl_cmd, '0');

                        wk_next_cycle <= T0;
                    end if; --if exec_cycle = T1 then

                -- A.5.4 break
                elsif instruction = conv_std_logic_vector(16#00#, dsize) then

                ----------------------------------------
                -- A.5.5 return from interrupt
                ----------------------------------------
                elsif instruction = conv_std_logic_vector(16#40#, dsize) then
                    if exec_cycle = T1 then
                        d_print("rti 2");
                        fetch_stop;

                        --pop stack (decrement only)
                        back_oe(sp_cmd, '0');
                        back_we(sp_cmd, '0');
                        sp_pop_n <= '0';
                        sp_oe_n <= '0';

                        wk_next_cycle <= T2;
                    elsif exec_cycle = T2 then
                        d_print("rti 3");

                        --pop p (status)
                        back_oe(sp_cmd, '0');
                        back_we(sp_cmd, '0');
                        sp_pop_n <= '0';
                        sp_oe_n <= '0';

                        --load status reg
                        stat_dec_oe_n <= '1';
                        dbuf_int_oe_n <= '0';
                        stat_bus_all_n <= '0';

                        wk_next_cycle <= T3;
                    elsif exec_cycle = T3 then
                        d_print("rti 4");
                        stat_bus_all_n <= '1';

                        --pop pcl
                        back_oe(sp_cmd, '0');
                        back_we(sp_cmd, '0');
                        sp_pop_n <= '0';
                        sp_oe_n <= '0';

                        --load lo addr.
                        dbuf_int_oe_n <= '0';
                        front_we(pcl_cmd, '0');

                        wk_next_cycle <= T4;
                    elsif exec_cycle = T4 then
                        d_print("rti 5");
                        --stack decrement stop.
                        back_we(sp_cmd, '1');
                        sp_pop_n <= '1';
                        front_we(pcl_cmd, '1');

                        --pop pch
                        back_oe(sp_cmd, '0');
                        sp_oe_n <= '0';
                        --load hi addr.
                        dbuf_int_oe_n <= '0';
                        front_we(pch_cmd, '0');

                        wk_next_cycle <= T5;
                    elsif exec_cycle = T5 then
                        d_print("rti 6");
                        back_oe(sp_cmd, '1');
                        sp_oe_n <= '1';
                        --load hi addr.
                        dbuf_int_oe_n <= '1';
                        front_we(pch_cmd, '1');

                        --increment pc.
                        wk_next_cycle <= T0;
                    end if; --if exec_cycle = T1 then

                ----------------------------------------
                -- A.5.6 jmp
                ----------------------------------------
                elsif instruction = conv_std_logic_vector(16#4c#, dsize) then
                    --abs
                    if exec_cycle = T1 then
                        d_print("jmp 2");
                        --fetch next opcode (abs low).
                        fetch_next;

                        --latch abs low data.
                        dbuf_int_oe_n <= '0';
                        dl_al_we_n <= '0';
                        wk_next_cycle <= T2;
                    elsif exec_cycle = T2 then
                        d_print("jmp 3");
                        dl_al_we_n <= '1';

                        --fetch abs hi
                        fetch_next;

                        --latch  in dlh
                        dbuf_int_oe_n <= '0';
                        dl_ah_we_n <= '0';
                        ---load pch.
                        front_we(pch_cmd, '0');

                        wk_next_cycle <= T0;
                    end if;

                elsif instruction = conv_std_logic_vector(16#6c#, dsize) then
                    --jmp (indir)
                    if exec_cycle = T1 then
                        d_print("jmp 2");
                        --fetch next opcode (abs low).
                        fetch_next;

                        --latch abs low data.
                        dbuf_int_oe_n <= '0';
                        dl_al_we_n <= '0';
                        wk_next_cycle <= T2;
                    elsif exec_cycle = T2 then
                        d_print("jmp 3");
                        dl_al_we_n <= '1';

                        --fetch abs hi
                        fetch_next;

                        --latch  in dlh
                        dbuf_int_oe_n <= '0';
                        dl_ah_we_n <= '0';
                        wk_next_cycle <= T3;

                    elsif exec_cycle = T3 then
                        fetch_stop;
                        dl_ah_we_n <= '1';

                        --IAH/IAL > ADL
                        dl_ah_oe_n <= '0';
                        dl_al_oe_n <= '0';
                        front_we(pcl_cmd, '0');
                        wk_next_cycle <= T4;

                    elsif exec_cycle = T4 then
                        dl_ah_oe_n <= '0';
                        dl_al_oe_n <= '0';
                        front_we(pcl_cmd, '1');

                        --IAH/IAL+1 > ADH
                        front_we(pch_cmd, '0');
                        indir_n <= '0';

                        wk_next_cycle <= T0;

                    end if;


                ----------------------------------------
                -- A.5.7 return from soubroutine
                ----------------------------------------
                elsif instruction = conv_std_logic_vector(16#60#, dsize) then
                    if exec_cycle = T1 then
                        d_print("rts 2");
                        fetch_stop;

                        --pop stack (decrement only)
                        back_oe(sp_cmd, '0');
                        back_we(sp_cmd, '0');
                        sp_pop_n <= '0';
                        sp_oe_n <= '0';

                        wk_next_cycle <= T2;
                    elsif exec_cycle = T2 then
                        d_print("rts 3");

                        --pop pcl
                        back_oe(sp_cmd, '0');
                        back_we(sp_cmd, '0');
                        sp_pop_n <= '0';
                        sp_oe_n <= '0';

                        --load lo addr.
                        dbuf_int_oe_n <= '0';
                        front_we(pcl_cmd, '0');

                        wk_next_cycle <= T3;
                    elsif exec_cycle = T3 then
                        d_print("rts 4");
                        --stack decrement stop.
                        back_we(sp_cmd, '1');
                        sp_pop_n <= '1';
                        front_we(pcl_cmd, '1');

                        --pop pch
                        back_oe(sp_cmd, '0');
                        sp_oe_n <= '0';
                        --load hi addr.
                        dbuf_int_oe_n <= '0';
                        front_we(pch_cmd, '0');

                        wk_next_cycle <= T4;
                    elsif exec_cycle = T4 then
                        d_print("rts 5");
                        back_oe(sp_cmd, '1');
                        sp_oe_n <= '1';
                        --load hi addr.
                        dbuf_int_oe_n <= '1';
                        front_we(pch_cmd, '1');
                        --empty cycle.
                        --complying h/w manual...
                        wk_next_cycle <= T5;
                    elsif exec_cycle = T5 then
                        d_print("rts 6");

                        --increment pc.
                        fetch_next;
                        wk_next_cycle <= T0;
                    end if; --if exec_cycle = T1 then

                ----------------------------------------
                -- A.5.8 branch operations
                ----------------------------------------
                elsif instruction = conv_std_logic_vector(16#90#, dsize) then
                    d_print("bcc");
                    a58_branch (st_C, '0');

                elsif instruction = conv_std_logic_vector(16#b0#, dsize) then
                    d_print("bcs");
                    a58_branch (st_C, '1');

                elsif instruction = conv_std_logic_vector(16#f0#, dsize) then
                    d_print("beq");
                    a58_branch (st_Z, '1');

                elsif instruction = conv_std_logic_vector(16#30#, dsize) then
                    d_print("bmi");
                    a58_branch (st_N, '1');

                elsif instruction = conv_std_logic_vector(16#d0#, dsize) then
                    d_print("bne");
                    a58_branch (st_Z, '0');

                elsif instruction = conv_std_logic_vector(16#10#, dsize) then
                    d_print("bpl");
                    a58_branch (st_N, '0');

                elsif instruction = conv_std_logic_vector(16#50#, dsize) then
                    d_print("bvc");
                    a58_branch (st_V, '0');

                elsif instruction = conv_std_logic_vector(16#70#, dsize) then
                    d_print("bvs");
                    a58_branch (st_V, '1');

                else
                    ---unknown instruction!!!!
                    assert false 
                        report "======== unknow instruction " 
                            & conv_hex8(conv_integer(instruction)) 
                        severity failure;
                end if; --if instruction = conv_std_logic_vector(16#0a#, dsize) 

            elsif exec_cycle = R0 then
                d_print(string'("reset"));

                --initialize port...
                inst_we_n <= '1';
                ad_oe_n <= '1';
                dbuf_int_oe_n <= '1';
                dl_al_we_n <= '1';
                dl_ah_we_n <= '1';
                dl_al_oe_n <= '1';
                dl_ah_oe_n <= '1';
                dl_dh_oe_n <= '1';
                pcl_inc_n <= '1';
                pcl_cmd <= "1111";
                pch_cmd <= "1111";
                sp_cmd <= "1111";
                sp_oe_n <= '1';
                sp_push_n <= '1';
                sp_pop_n <= '1';
                wk_acc_cmd <= "1111";
                wk_x_cmd <= "1111";
                wk_y_cmd <= "1111";

                abs_xy_n <= '1';
                pg_next_n <= '1';
                zp_n <= '1';
                zp_xy_n <= '1';
                rel_calc_n <= '1';
                indir_n <= '1';
                indir_x_n <= '1';
                indir_y_n <= '1';
                arith_en_n <= '1';

                stat_dec_oe_n <= '0';
                stat_bus_oe_n <= '1';
                stat_set_flg_n <= '1';
                stat_flg <= '1';
                stat_bus_all_n <= '1';
                stat_bus_nz_n <= '1';
                wk_stat_alu_we_n <= '1';

                r_vec_oe_n <= '1';
                n_vec_oe_n <= '1';
                i_vec_oe_n <= '1';
                nmi_handled_n <= '1';
                r_nw <= '1';

                wk_next_cycle <= R1;
            elsif exec_cycle = R1 or exec_cycle = N1 then
                pcl_cmd <= "1111";
                pcl_inc_n <= '1';
                inst_we_n <= '1';
                dl_al_oe_n <= '1';

                --push pch.
                d_print("R1");
                ad_oe_n <= '0';
                sp_push_n <= '0';
                sp_oe_n <= '0';
                pch_cmd <= "0111";
                --front_oe(pch_cmd, '0');
                back_oe(sp_cmd, '0');
                back_we(sp_cmd, '0');
                r_nw <= '0';

                if exec_cycle = R1 then
                    wk_next_cycle <= R2;
                elsif exec_cycle = N1 then
                    wk_next_cycle <= N2;
                end if;

            elsif exec_cycle = R2 or exec_cycle = N2 then
                front_oe(pch_cmd, '1');

               --push pcl.
                sp_push_n <= '0';
                sp_oe_n <= '0';
                front_oe(pcl_cmd, '0');
                back_oe(sp_cmd, '0');
                back_we(sp_cmd, '0');
                r_nw <= '0';

                if exec_cycle = R2 then
                    wk_next_cycle <= R3;
                elsif exec_cycle = N2 then
                    wk_next_cycle <= N3;
                end if;

            elsif exec_cycle = R3 or exec_cycle = N3 then
                front_oe(pcl_cmd, '1');

               --push status.
                sp_push_n <= '0';
                sp_oe_n <= '0';
                stat_bus_oe_n <= '0';
                back_oe(sp_cmd, '0');
                back_we(sp_cmd, '0');
                r_nw <= '0';

                if exec_cycle = R3 then
                    wk_next_cycle <= R4;
                elsif exec_cycle = N3 then
                    wk_next_cycle <= N4;
                end if;

            elsif exec_cycle = R4 or exec_cycle = N4 then
                stat_bus_oe_n <= '1';
                sp_push_n <= '1';
                sp_oe_n <= '1';
                front_oe(pcl_cmd, '1');
                back_oe(sp_cmd, '1');
                back_we(sp_cmd, '1');

                --fetch reset vector low
                r_nw <= '1';
                dbuf_int_oe_n <= '0';
                front_we(pcl_cmd, '0');
                dl_al_oe_n <= '1';
                dl_ah_oe_n <= '1';

                if exec_cycle = R4 then
                    r_vec_oe_n <= '0';
                    n_vec_oe_n <= '1';
                    wk_next_cycle <= R5;
                elsif exec_cycle = N4 then
                    r_vec_oe_n <= '1';
                    n_vec_oe_n <= '0';
                    wk_next_cycle <= N5;
                end if;
                
            elsif exec_cycle = R5 or exec_cycle = N5 then
                front_we(pcl_cmd, '1');

                --fetch reset vector hi
                r_nw <= '1';
                dbuf_int_oe_n <= '0';
                front_we(pch_cmd, '0');
                indir_n <= '0';

                if exec_cycle = N5 then
                    nmi_handled_n <= '0';
                end if;
                --start execute cycle.
                wk_next_cycle <= T0;

            elsif exec_cycle(5) = '1' then
                ---pc increment and next page.
                d_print(string'("pch next page..."));
                --pcl stop increment
                pcl_inc_n <= '1';
                back_we(pcl_cmd, '1');

                if ('0' & exec_cycle(4 downto 0) = T0 and
                    instruction = conv_std_logic_vector(16#4c#, dsize) ) then
                    --jmp instruction t0 cycle discards pch increment.
                    back_we(pch_cmd, '1');
                    front_we(pch_cmd, '1');
                else
                    --pch increment
                    back_we(pch_cmd, '0');
                    back_oe(pch_cmd, '0');
                end if;

                if ('0' & exec_cycle(4 downto 0) = T0) then
                    --do the t0 identical routine.
                    disable_pins;
                    inst_we_n <= '1';
                    r_nw <= '1';

                elsif ('0' & exec_cycle(4 downto 0) = T1) then
                    --if fetch cycle, preserve instrution register
                    inst_we_n <= '1';

                elsif ('0' & exec_cycle(4 downto 0) = T2) then
                    --disable previous we_n gate.
                    --t1 cycle is fetch low oprand.
                    dl_al_we_n <= '1';
                    dl_ah_we_n <= '1';
                elsif ('0' & exec_cycle(4 downto 0) = T3) then
                    --t2 cycle is fetch high oprand.
                    dl_ah_we_n <= '1';
                end if;

            end if; --if rdy = '0' then

        end if; -- if (res_n = '0') then

    end process;

end rtl;

