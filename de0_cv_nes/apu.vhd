library ieee;
use ieee.std_logic_1164.all;

entity apu is 
    port (
        pi_rst_n       : in std_logic;
        pi_base_clk    : in std_logic;
        pi_cpu_en      : in std_logic_vector (7 downto 0);
        pi_rnd_en      : in std_logic_vector (3 downto 0);
        pi_ce_n        : in std_logic;

        --cpu i/f
        pio_oe_n       : inout std_logic;
        pio_we_n       : inout std_logic;
        pio_cpu_addr   : inout std_logic_vector (15 downto 0);
        pio_cpu_d      : inout std_logic_vector (7 downto 0);
        po_rdy         : out std_logic;

        --sprite i/f
        po_spr_ce_n    : out std_logic;
        po_spr_rd_n    : out std_logic;
        po_spr_wr_n    : out std_logic;
        po_spr_addr    : out std_logic_vector (7 downto 0);
        po_spr_data    : out std_logic_vector (7 downto 0)
    );
end apu;

architecture rtl of apu is


constant OAM_DMA   : std_logic_vector(4 downto 0) := "10100";
constant OAM_JP1   : std_logic_vector(4 downto 0) := "10110";
constant OAM_JP2   : std_logic_vector(4 downto 0) := "10111";

--oamaddr=0x2003
constant OAMADDR   : std_logic_vector(15 downto 0) := "0010000000000011";
--oamdata=0x2004
constant OAMDATA   : std_logic_vector(15 downto 0) := "0010000000000100";

type dma_state is (
    idle,
    reg_set,
    dma_init,
    rd_data,
    wr_data,
    dma_end
);

signal reg_dma_cur_state      : dma_state;
signal reg_dma_next_state     : dma_state;


signal reg_cpu_oe_n     : std_logic;
signal reg_cpu_we_n     : std_logic;
signal reg_cpu_addr     : std_logic_vector (15 downto 0);
signal reg_cpu_d        : std_logic_vector (7 downto 0);
signal reg_rdy          : std_logic;

        --sprite i/f
signal reg_spr_ce_n     : std_logic;
signal reg_spr_rd_n     : std_logic;
signal reg_spr_wr_n     : std_logic;
signal reg_spr_addr     : std_logic_vector (7 downto 0);
signal reg_spr_data     : std_logic_vector (7 downto 0);

begin

    --state machine (state transition)...
    dma_stat_tx_p : process (pi_rst_n, pi_base_clk)
    begin
        if (pi_rst_n = '0') then
            reg_dma_cur_state <= idle;
        elsif (rising_edge(pi_base_clk)) then
            reg_dma_cur_state <= reg_dma_next_state;
        end if;--if (pi_rst_n = '0') then
    end process;

    --state change to next.
    dma_stat_p : process (reg_dma_cur_state)
    begin
        case reg_dma_cur_state is
            when idle =>
                reg_dma_next_state <= reg_dma_cur_state;
            when reg_set =>
                reg_dma_next_state <= reg_dma_cur_state;
            when dma_init =>
                reg_dma_next_state <= reg_dma_cur_state;
            when rd_data =>
                reg_dma_next_state <= reg_dma_cur_state;
            when wr_data =>
                reg_dma_next_state <= reg_dma_cur_state;
            when dma_end =>
                reg_dma_next_state <= reg_dma_cur_state;
        end case;
    end process;

    pio_oe_n       <= reg_cpu_oe_n;
    pio_we_n       <= reg_cpu_we_n;
    pio_cpu_addr   <= reg_cpu_addr;
    pio_cpu_d      <= reg_cpu_d;
    po_rdy         <= reg_rdy;

    po_spr_ce_n    <= reg_spr_ce_n;
    po_spr_rd_n    <= reg_spr_rd_n;
    po_spr_wr_n    <= reg_spr_wr_n;
    po_spr_addr    <= reg_spr_addr;
    po_spr_data    <= reg_spr_data;

    cpu_out_p : process (pi_rst_n, pi_base_clk)
    begin
        if (pi_rst_n = '0') then
            reg_cpu_oe_n <= 'Z';
            reg_cpu_we_n <= 'Z';
            reg_cpu_addr <= (others => 'Z');
            reg_cpu_d    <= (others => 'Z');
            reg_rdy      <= '1';
        elsif (rising_edge(pi_base_clk)) then
            reg_cpu_oe_n <= 'Z';
            reg_cpu_we_n <= 'Z';
            reg_cpu_addr <= (others => 'Z');
            reg_cpu_d    <= (others => 'Z');
            reg_rdy      <= '1';
        end if;--if (pi_rst_n = '0') then
    end process;

    spr_out_p : process (pi_rst_n, pi_base_clk)
    begin
        if (pi_rst_n = '0') then
            reg_spr_ce_n <= 'Z';
            reg_spr_rd_n <= 'Z';
            reg_spr_wr_n <= 'Z';
            reg_spr_addr <= (others => 'Z');
            reg_spr_data <= (others => 'Z');
        elsif (rising_edge(pi_base_clk)) then
            reg_spr_ce_n <= 'Z';
            reg_spr_rd_n <= 'Z';
            reg_spr_wr_n <= 'Z';
            reg_spr_addr <= (others => 'Z');
            reg_spr_data <= (others => 'Z');
        end if;--if (pi_rst_n = '0') then
    end process;

end rtl;
