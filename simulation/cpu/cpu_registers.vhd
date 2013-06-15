
----------------------------------------
--- program counter register declaration
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.conv_std_logic_vector;

entity pc is 
    generic (
            dsize : integer := 8;
            reset_addr : integer := 0
            );
    port (  
            clk             : in std_logic;
            res_n           : in std_logic;
            pc_type         : in std_logic;     --'0' pcl, '1' pch
            dbus_we_n       : in std_logic;
            abus_we_n       : in std_logic;
            dbus_oe_n       : in std_logic;
            abus_oe_n       : in std_logic;
            addr_inc_n      : in std_logic;
            addr_dec_n      : in std_logic;
            add_carry       : out std_logic;
            rel_we_n        : in std_logic;
            rel_calc_n      : in std_logic;
            rel_prev        : out std_logic;
            int_d_bus       : inout std_logic_vector (dsize - 1 downto 0);
            int_a_bus       : inout std_logic_vector (dsize - 1 downto 0)
        );
end pc;

architecture rtl of pc is

component dff
    generic (
            dsize : integer := 8
            );
    port (  
            clk         : in std_logic;
            we_n    : in std_logic;
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;

signal val : std_logic_vector (dsize - 1 downto 0);
signal rel : std_logic_vector (dsize - 1 downto 0);

begin
                ---increment & page moved case.
    int_a_bus <= val + 1 when (abus_oe_n = '0' 
                                and pc_type = '1' and addr_inc_n = '0') else
                val when (abus_oe_n = '0') else
                (others => 'Z');

                ---increment & page moved case.
    int_d_bus <= val + 1 when (dbus_oe_n = '0' 
                                and pc_type = '1' and addr_inc_n = '0') else
                val when (dbus_oe_n = '0') else
                (others => 'Z');

    set_p : process (clk, res_n)
    variable add_val : std_logic_vector(dsize downto 0);
    variable dec_val : std_logic_vector(dsize downto 0);
    begin
        if (clk'event and clk = '1') then

            if (addr_inc_n = '0' and abus_we_n = '0') then
                --case increment & address set
                --for jmp op, abs xy not page crossing case.
                add_val := ('0' & int_a_bus) + 1;
                val <= add_val(dsize - 1 downto 0);
                add_carry <= add_val(dsize);
                rel_prev <= '0';
            elsif (addr_inc_n = '0') then
                add_val := ('0' & val) + 1;
                val <= add_val(dsize - 1 downto 0);
                add_carry <= add_val(dsize);
                rel_prev <= '0';
            elsif (addr_dec_n = '0') then
                dec_val := ('0' & val) - 1;
                val <= dec_val(dsize - 1 downto 0);
                add_carry <= '0';
                rel_prev <= '0';
            elsif (rel_calc_n = '0') then
                add_val := ('0' & val) + ('0' & rel);
                --relative addressing mode is signed operation.
                if (rel(7) = '0') then
                    --add positive
                    add_carry <= add_val(dsize);
                    rel_prev <= '1';
                else
                    --add negative
                    add_carry <= '0';
                    if (add_val(7) = '1') then
                        --negative value > goto preveous page.
                        rel_prev <= '1';
                    else
                        rel_prev <= '0';
                    end if;
                end if;
                val <= add_val(dsize - 1 downto 0);
            elsif (abus_we_n = '0') then
                val <= int_a_bus;
                add_carry <= '0';
                rel_prev <= '0';
            elsif (dbus_we_n = '0') then
                val <= int_d_bus;
                add_carry <= '0';
                rel_prev <= '0';
            else
                rel_prev <= '0';
                add_carry <= '0';
            end if;
        elsif (res_n'event and res_n = '0') then
            val <= conv_std_logic_vector(reset_addr, dsize);
        end if;
    end process;

    rel_dff : dff generic map (dsize) 
                    port map(clk, rel_we_n, '0', int_d_bus, rel);
end rtl;

----------------------------------------
--- normal d-flipflop declaration
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity dff is 
    generic (
            dsize : integer := 8
            );
    port (  
            clk     : in std_logic;
            we_n    : in std_logic;
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end dff;

architecture rtl of dff is
signal val : std_logic_vector (dsize - 1 downto 0);
begin

    process (clk)
    begin
        if ( clk'event and clk = '1'and we_n = '0') then
            val <= d;
        end if;
    end process;

    q <= val when oe_n = '0' else
        (others => 'Z');
end rtl;

----------------------------------------
--- normal data latch declaration
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity latch is 
    generic (
            dsize : integer := 8
            );
    port (  
            clk     : in std_logic;
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end latch;

architecture rtl of latch is
signal val : std_logic_vector (dsize - 1 downto 0);
begin

    process (clk, d)
    begin
        if ( clk = '1') then
            --latch only when clock is high
            val <= d;
        end if;
    end process;

    q <= val when oe_n = '0' else
        (others => 'Z');
end rtl;

----------------------------------------
--- data bus buffer register
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity dbus_buf is 
    generic (
            dsize : integer := 8
            );
    port (  
            clk         : in std_logic;
            r_nw        : in std_logic;
            int_oe_n    : in std_logic;
            int_dbus : inout std_logic_vector (dsize - 1 downto 0);
            ext_dbus : inout std_logic_vector (dsize - 1 downto 0)
        );
end dbus_buf;

architecture rtl of dbus_buf is
component latch
    generic (
            dsize : integer := 8
            );
    port (  
            clk     : in std_logic;
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;

signal rd_clk : std_logic;
signal wr_clk : std_logic;
begin
    rd_clk <= r_nw and clk;
    wr_clk <= (not r_nw) and clk;

    --read from i/o to cpu
    latch_r : latch generic map (dsize) 
                    port map(rd_clk, int_oe_n, ext_dbus, int_dbus);
    --write from cpu to io
    latch_w : latch generic map (dsize) 
                    port map(wr_clk, r_nw, int_dbus, ext_dbus);
end rtl;

----------------------------------------
--- input data latch register
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity input_dl is 
    generic (
            dsize : integer := 8
            );
    port (  
            clk         : in std_logic;
            al_we_n     : in std_logic;
            ah_we_n     : in std_logic;
            al_oe_n     : in std_logic;
            ah_oe_n     : in std_logic;
            int_dbus    : in std_logic_vector (dsize - 1 downto 0);
            ea_al       : out std_logic_vector (dsize - 1 downto 0);
            ea_ah       : out std_logic_vector (dsize - 1 downto 0)
        );
end input_dl;

architecture rtl of input_dl is
component latch
    generic (
            dsize : integer := 8
            );
    port (  
            clk     : in std_logic;
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;
signal ll_clk : std_logic;
signal lh_clk : std_logic;
signal ql : std_logic_vector (dsize - 1 downto 0);
signal qh : std_logic_vector (dsize - 1 downto 0);
begin

    ll_clk <= (not al_we_n) and clk;
    lh_clk <= (not ah_we_n) and clk;
    latch_l : latch generic map (dsize) 
                    port map(ll_clk, '0', int_dbus, ql);
    latch_h : latch generic map (dsize) 
                    port map(lh_clk, '0', int_dbus, qh);

    --tri-state buffer at the output
    ea_al <= ql when al_oe_n = '0' else
         (others =>'Z');
    ea_ah <= qh when ah_oe_n = '0' else
         (others =>'Z');

end rtl;

----------------------------------------
--- stack pointer register
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity sp is 
    generic (
            dsize : integer := 8
            );
    port (  
            clk         : in std_logic;
            we_n        : in std_logic;
            push_n      : in std_logic;
            pop_n       : in std_logic;
            int_d_oe_n  : in std_logic;
            int_a_oe_n  : in std_logic;
            int_dbus    : inout std_logic_vector (dsize - 1 downto 0);
            int_abus_l  : out std_logic_vector (dsize - 1 downto 0);
            int_abus_h  : out std_logic_vector (dsize - 1 downto 0)
        );
end sp;

architecture rtl of sp is
component dff
    generic (
            dsize : integer := 8
            );
    port (  
            clk         : in std_logic;
            we_n    : in std_logic;
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;
signal oe_n : std_logic;
signal dff_we_n : std_logic;
signal q : std_logic_vector (dsize - 1 downto 0);
signal d : std_logic_vector (dsize - 1 downto 0);
signal q_buf : std_logic_vector (dsize - 1 downto 0);

begin
    oe_n <= (int_d_oe_n and int_a_oe_n);
    dff_we_n <= (we_n and push_n and pop_n);
    int_dbus <= q when int_d_oe_n = '0' else
         (others =>'Z');

    ---push: address decrement after push is done.
    ---pop: address increment before pop is done.
    al_p : process (int_a_oe_n, push_n, clk, q_buf, q)
    begin
        if (int_a_oe_n = '0') then
            if (push_n = '0') then
                if (clk = '1') then
                    int_abus_l <= q_buf;
                else
                    int_abus_l <= q;
                end if;
            elsif (pop_n = '0') then
                if (clk = '1') then
                    int_abus_l <= q_buf;
                else
                    int_abus_l <= q;
                end if;
            else
                int_abus_l <= q;
            end if;
        else
            int_abus_l <= (others => 'Z');
        end if;
    end process;

    int_abus_h <= "00000001" when int_a_oe_n = '0' else
         (others =>'Z');
    d <= int_dbus when we_n = '0' else
            (q - 1) when push_n = '0' else
            (q + 1) when pop_n = '0' else
         (others =>'Z');

    dff_inst : dff generic map (dsize) 
                    port map(clk, dff_we_n, oe_n, d, q);
    buf : dff generic map (dsize) 
                    port map(clk, dff_we_n, '0', q, q_buf);
end rtl;


----------------------------------------
--- SR flipflop
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity srff is 
    generic (
            dsize : integer := 8
            );
    port (  
            clk     : in std_logic;
            res_n   : in std_logic;
            set_n   : in std_logic;
            we_n    : in std_logic;
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end srff;

architecture rtl of srff is
signal val : std_logic_vector (dsize - 1 downto 0);
begin

    q <= val when oe_n = '0' else
        (others => 'Z');

    main_p : process (clk, res_n, set_n, d)
    begin
        if ( clk'event and clk = '1'and we_n = '0') then
            val <= d;
        end if;
        if (res_n'event and res_n = '0') then
            val <= (others => '0');
        end if;
        if (set_n = '0') then
            val <= d;
        end if;
    end process;
end rtl;

----------------------------------------
--- status register component
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity processor_status is 
    generic (
            dsize : integer := 8
            );
    port (  
            clk         : in std_logic;
            res_n       : in std_logic;
            dec_oe_n    : in std_logic;
            bus_oe_n    : in std_logic;
            set_flg_n   : in std_logic;
            flg_val     : in std_logic;
            load_bus_all_n : in std_logic;
            load_bus_nz_n  : in std_logic;
            alu_we_n    : in std_logic;
            alu_n       : in std_logic;
            alu_v       : in std_logic;
            alu_z       : in std_logic;
            alu_c       : in std_logic;
            decoder     : inout std_logic_vector (dsize - 1 downto 0);
            int_dbus    : inout std_logic_vector (dsize - 1 downto 0)
        );
end processor_status;

architecture rtl of processor_status is
signal val : std_logic_vector (dsize - 1 downto 0);
begin
    decoder <= val when dec_oe_n = '0' else
                (others => 'Z');
    int_dbus <= val when bus_oe_n = '0' else
                (others => 'Z');
                

    main_p : process (clk, res_n)
    variable tmp : std_logic_vector (dsize - 1 downto 0);
    begin
--        SR Flags (bit 7 to bit 0):
--
--        N   ....    Negative
--        V   ....    Overflow
--        -   ....    ignored
--        B   ....    Break
--        D   ....    Decimal (use BCD for arithmetics)
--        I   ....    Interrupt (IRQ disable)
--        Z   ....    Zero
--        C   ....    Carry
    
      ---only interrupt flag is set on reset.
        if (res_n'event and res_n = '0') then
            val <= "00000100";
        end if;

        if ( clk'event and clk = '1') then
            ---from flag set/clear instructions
            if (set_flg_n = '0') then
                if flg_val = '1' then
                    tmp := (decoder and "11111111");
                else
                    tmp := "00000000";
                end if;
                val <= tmp or (val and not decoder);

            ---status flag set from the data on the internal data bus.
            ---interpret the input data by the decoder input.
            ---load/pop/rti/t[asxy]
            elsif (load_bus_all_n = '0') then
                ---set the data bus data as they are.
                val <= int_dbus;
            elsif (load_bus_nz_n = '0') then
                ---other case: n/z data must be interpreted.
                --n bit.
                if int_dbus(7) = '1' then
                    val (7) <= '1';
                else
                    val (7) <= '0';
                end if;
                --z bit.
                ---nor outputs 1 when all inputs are 0.
                if  (int_dbus(7) or int_dbus(6) or 
                        int_dbus(5) or int_dbus(4) or int_dbus(3) or 
                        int_dbus(2) or int_dbus(1) or int_dbus(0)) = '0' then
                    val (1) <= '1';
                else
                    val (1) <= '0';
                end if;

            ---status set from alu/inx/iny etc.
            elsif (alu_we_n = '0') then
                tmp := val;
                val (5 downto 2) <= tmp (5 downto 2);

                --n bit.
                if (decoder(7) = '1') then
                    val (7) <= alu_n;
                else
                    val (7) <= tmp (7);
                end if;
                --v bit.
                if (decoder(6) = '1') then
                    val (6) <= alu_v;
                else
                    val (6) <= tmp (6);
                end if;
                --z bit.
                if (decoder(1) = '1') then
                    val (1) <= alu_z;
                else
                    val (1) <= tmp (1);
                end if;
                --c bit.
                if (decoder(0) = '1') then
                    val (0) <= alu_c;
                else
                    val (0) <= tmp (0);
                end if;
            end if; --if (set_flg_n = '0') then
        end if;
    end process;
end rtl;


----------------------------------------
--- tri-state buffer
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity tsb is 
    generic (
            dsize : integer := 8
            );
    port (  
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end tsb;

architecture rtl of tsb is
signal val : std_logic_vector (dsize - 1 downto 0);
begin
    q <= d when oe_n = '0' else
        (others => 'Z');
end rtl;


----------------------------------------
--- accumulator
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity accumulator is 
    generic (
            dsize : integer := 8
            );
    port (  
            clk         : in std_logic;
            d_we_n      : in std_logic;
            alu_we_n    : in std_logic;
            d_oe_n      : in std_logic;
            int_dbus    : inout std_logic_vector (dsize - 1 downto 0);
            alu_in      : in std_logic_vector (dsize - 1 downto 0);
            alu_out     : out std_logic_vector (dsize - 1 downto 0)
        );
end accumulator;

architecture rtl of accumulator is
component dff
    generic (
            dsize : integer := 8
            );
    port (  
            clk     : in std_logic;
            we_n    : in std_logic;
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;

signal we_n : std_logic;
signal d : std_logic_vector (dsize - 1 downto 0);
signal q : std_logic_vector (dsize - 1 downto 0);

begin
    we_n <= (d_we_n and alu_we_n);
    d <= int_dbus when d_we_n = '0' else
        alu_in when alu_we_n = '0' else
        (others => 'Z');
    int_dbus <= q when d_oe_n = '0' else
        (others => 'Z');
    alu_out <= q;

    --read from i/o to cpu
    dff_inst : dff generic map (dsize) 
                    port map(clk, we_n, '0', d, q);
end rtl;

----------------------------------------
--- index register x/y
----------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity index_reg is 
    generic (
            dsize : integer := 8
            );
    port (  
            clk         : in std_logic;
            d_we_n      : in std_logic;
            d_oe_n      : in std_logic;
            ea_oe_n     : in std_logic;
            inc_n       : in std_logic;
            dec_n       : in std_logic;
            int_dbus    : inout std_logic_vector (dsize - 1 downto 0);
            ea_bus      : out std_logic_vector (dsize - 1 downto 0);
            n           : out std_logic;
            z           : out std_logic
        );
end index_reg;

architecture rtl of index_reg is
component dff
    generic (
            dsize : integer := 8
            );
    port (  
            clk     : in std_logic;
            we_n    : in std_logic;
            oe_n    : in std_logic;
            d       : in std_logic_vector (dsize - 1 downto 0);
            q       : out std_logic_vector (dsize - 1 downto 0)
        );
end component;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

signal we_n : std_logic;
signal q : std_logic_vector (dsize - 1 downto 0);
signal d : std_logic_vector (dsize - 1 downto 0);

begin
    int_dbus <= q when d_oe_n = '0' else
        (others => 'Z');
    ea_bus <= q when ea_oe_n = '0' else
        (others => 'Z');

    --for inx/iny/dex/dey instructions...
    inc_dec_p : process (clk, int_dbus, inc_n, dec_n)
    variable inc_work : std_logic_vector (dsize downto 0);
    variable dec_work : std_logic_vector (dsize downto 0);
    begin
        inc_work := ('0' & q) + 1;
        dec_work := ('0' & q) - 1;
        if inc_n = '0' then
            d <= inc_work(dsize - 1 downto 0);
            z <= not (inc_work(7) or inc_work(6) or 
                    inc_work(5) or inc_work(4) or inc_work(3) or 
                    inc_work(2) or inc_work(1) or inc_work(0));
            n <= inc_work(dsize);
        elsif dec_n = '0' then
            d <= dec_work(dsize - 1 downto 0);
            z <= not (dec_work(7) or dec_work(6) or 
                dec_work(5) or dec_work(4) or dec_work(3) or 
                dec_work(2) or dec_work(1) or dec_work(0)); 
            n <= dec_work(dsize); 
        else
            d <= int_dbus;
            z <= 'Z';
            n <= 'Z';
        end if;

    end process;

    --read from i/o to cpu
    we_n <= d_we_n and inc_n and dec_n;
    dff_inst : dff generic map (dsize) 
                    port map(clk, we_n, '0', d, q);

end rtl;


