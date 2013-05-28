library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.conv_std_logic_vector;
--use ieee.std_logic_arith.all;
use std.textio.all;

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
            pcl_d_i_n       : out std_logic;
            pcl_d_o_n       : out std_logic;
            pcl_a_o_n       : out std_logic;
            pch_d_i_n       : out std_logic;
            pch_d_o_n       : out std_logic;
            pch_a_o_n       : out std_logic;
            pc_inc_n        : out std_logic;
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

type dec_status is (reset0, reset1, reset2, reset3, reset4, reset5, 
                    fetch, 
                    sei,
                    nop);


begin

    main_p : process (set_clk, trig_clk, res_n)
    variable cur_stat : dec_status;
    begin
        if (res_n'event and res_n = '0') then
            cur_stat := reset0;
        else
            if (set_clk'event and set_clk = '1') then
                ---one byte instruction decoding.
                if instruction = conv_std_logic_vector(16#78#, dsize) then
                    cur_stat := sei;
                    --pc_inc_n <= '0';
                end if;

                case cur_stat is
                    when reset0 => 
                    when fetch => 
                        pcl_a_o_n <= '0';
                        pch_a_o_n <= '0';
                        r_nw <= '1';
                        d_print(string'("fetch 0"));
                    when sei => 
                        pcl_a_o_n <= '1';
                        pch_a_o_n <= '1';
                        pc_inc_n <= '1';
                        d_print(string'("sei 0"));
                    when others => null;
                end case;
            end if;

            if (trig_clk'event and trig_clk = '1') then

                case cur_stat is
                    when reset0 => 
                        cur_stat := reset1;
                    when reset1 => 
                        cur_stat := reset2;
                    when reset2 => 
                        cur_stat := reset3;
                    when reset3 => 
                        cur_stat := reset4;
                    when reset4 => 
                        cur_stat := reset5;
                    when reset5 => 
                        cur_stat := fetch;
                    when fetch => 
                        d_print(string'("fetch 1"));
                    when sei => 
                        cur_stat := fetch;
                        d_print(string'("sei 1"));
                        pc_inc_n <= '0';
                    when others => 
                        null;
                end case;
            end if;
        end if;
    end process;

end rtl;

