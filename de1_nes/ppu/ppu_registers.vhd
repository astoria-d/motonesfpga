--------------------------------
----------shift registers -----
--------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity shift_register is 
    generic (
        dsize : integer := 8;
        shift : integer := 1
    );
    port (  clk         : in std_logic;
            rst_n       : in std_logic;
            ce_n        : in std_logic;
            we_n        : in std_logic;
            d           : in std_logic_vector(dsize - 1 downto 0);
            q           : out std_logic_vector(dsize - 1 downto 0)
    );
end shift_register;

architecture rtl of shift_register is

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

signal dff_we_n : std_logic;
signal q_out : std_logic_vector(dsize - 1 downto 0);
signal df_in : std_logic_vector(dsize - 1 downto 0);

begin

    q <= q_out;
    dff_we_n <= ce_n and we_n;
    dff_inst : d_flip_flop generic map (dsize)
            port map (clk, rst_n, '1', dff_we_n, df_in, q_out);

    clk_p : process (clk, we_n, ce_n, d) 
    begin
        if (we_n = '0') then
            df_in <= d;
        elsif (ce_n = '0') then
            df_in (dsize - 1 downto dsize - shift) <= (others => '0');
            df_in (dsize - shift - 1  downto 0) <= 
                q_out(dsize - 1 downto shift);
        end if;
    end process;

end rtl;

-------------------------------
-- LS373 transparent D-latch---
-------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity ls373 is 
    port (  clk         : in std_logic;
            ale         : in std_logic;
            vram_a      : in std_logic_vector (13 downto 8);
            vram_ad     : in std_logic_vector (7 downto 0);
            v_addr      : out std_logic_vector (13 downto 0)
            );
end ls373;

architecture rtl of ls373 is

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

signal d_in : std_logic_vector(13 downto 0);
signal q_out : std_logic_vector(13 downto 0);
signal ale_n : std_logic;

begin
    d_in <= vram_a & vram_ad;
    out_reg_inst : d_flip_flop generic map (14)
            port map (clk, '1', '1', ale_n, d_in, q_out);
    tsb_inst : tri_state_buffer generic map (14)
            port map (ale, q_out, v_addr);
end rtl;

