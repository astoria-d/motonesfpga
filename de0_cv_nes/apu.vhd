library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.conv_std_logic_vector;

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

---cpu timing synchronization.
constant CP_ST0   : integer := 4;

--APU memory map:
--0x4000-0x401F (5 bits.)
constant OAM_DMA   : std_logic_vector(4 downto 0) := "10100";
constant OAM_JP1   : std_logic_vector(4 downto 0) := "10110";
constant OAM_JP2   : std_logic_vector(4 downto 0) := "10111";

type dma_state is (
    idle,
    reg_set,
    dma_init,
    rd_data,
    wr_data,
    dma_end
);

signal reg_dma_addr     : std_logic_vector (7 downto 0);
signal reg_dma_cnt      : integer range 0 to 256;

signal reg_dma_cur_state      : dma_state;
signal reg_dma_next_state     : dma_state;

signal reg_cpu_oe_n     : std_logic;
signal reg_cpu_we_n     : std_logic;
signal reg_cpu_addr     : std_logic_vector (15 downto 0);
signal reg_cpu_out      : std_logic_vector (7 downto 0);
signal reg_rdy          : std_logic;

        --sprite i/f
signal reg_spr_ce_n     : std_logic;
signal reg_spr_rd_n     : std_logic;
signal reg_spr_wr_n     : std_logic;
signal reg_spr_addr     : std_logic_vector (7 downto 0);
signal reg_spr_data     : std_logic_vector (7 downto 0);

begin

    --apu port access.
    apu_set_p : process (pi_rst_n, pi_base_clk)
    begin
        if (pi_rst_n = '0') then
            reg_dma_addr    <= (others => '0');
        elsif (rising_edge(pi_base_clk)) then
            if (pi_cpu_en(CP_ST0) = '1' and pi_ce_n = '0' and pio_we_n = '0') then
                if (pio_cpu_addr(4 downto 0) = OAM_DMA) then
                    reg_dma_addr    <= pio_cpu_d;
                end if;
            end if;--if (pi_cpu_en(CP_ST0) = '1' and pi_ce_n = '0') then
        end if;--if (pi_rst_n = '0') then
    end process;


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
    dma_stat_p : process (reg_dma_cur_state, pi_cpu_en, pi_rnd_en, 
                            pi_ce_n, pio_we_n, pio_cpu_addr, reg_dma_cnt)
    begin
        case reg_dma_cur_state is
            when idle =>
                if (pi_cpu_en(CP_ST0) = '1' and pi_ce_n = '0' and pio_we_n = '0' and
                    pio_cpu_addr(4 downto 0) = OAM_DMA) then
                    reg_dma_next_state <= reg_set;
                else
                    reg_dma_next_state <= reg_dma_cur_state;
                end if;
            when reg_set =>
                if (pi_cpu_en(0) = '1') then
                    reg_dma_next_state <= dma_init;
                else
                    reg_dma_next_state <= reg_dma_cur_state;
                end if;
            when dma_init =>
                if (pi_cpu_en(0) = '1') then
                    reg_dma_next_state <= rd_data;
                else
                    reg_dma_next_state <= reg_dma_cur_state;
                end if;
            when rd_data =>
                if (pi_rnd_en(0) = '1') then
                    reg_dma_next_state <= wr_data;
                else
                    reg_dma_next_state <= reg_dma_cur_state;
                end if;
            when wr_data =>
                if (pi_rnd_en(0) = '1') then
                    if (reg_dma_cnt = 255) then
                        reg_dma_next_state <= dma_end;
                    else
                        reg_dma_next_state <= rd_data;
                    end if;
                else
                    reg_dma_next_state <= reg_dma_cur_state;
                end if;
            when dma_end =>
                if (pi_cpu_en(0) = '1') then
                    reg_dma_next_state <= idle;
                else
                    reg_dma_next_state <= reg_dma_cur_state;
                end if;
        end case;
    end process;

    po_rdy         <= reg_rdy;

    --dma copy count process.
    dma_cnt_p : process (pi_rst_n, pi_base_clk)
    begin
        if (pi_rst_n = '0') then
            reg_dma_cnt <= 0;
            reg_rdy <= '1';
        elsif (rising_edge(pi_base_clk)) then
            if (reg_dma_cur_state = dma_init) then
                reg_dma_cnt <= 0;
            elsif (reg_dma_cur_state = wr_data and pi_rnd_en(0) = '1') then
                reg_dma_cnt <= reg_dma_cnt + 1;
            end if;

            --cpu ready flag set.
            if (reg_dma_cur_state = reg_set) then
                reg_rdy <= '0';
            elsif (reg_dma_cur_state = dma_end) then
                reg_rdy <= '1';
            end if;
        end if;--if (pi_rst_n = '0') then
    end process;

    pio_oe_n       <= reg_cpu_oe_n;
    pio_we_n       <= reg_cpu_we_n;
    pio_cpu_addr   <= reg_cpu_addr;
    pio_cpu_d      <= reg_cpu_out;

    po_spr_ce_n    <= reg_spr_ce_n;
    po_spr_rd_n    <= reg_spr_rd_n;
    po_spr_wr_n    <= reg_spr_wr_n;
    po_spr_addr    <= reg_spr_addr;
    po_spr_data    <= reg_spr_data;

    dma_main_p : process (pi_rst_n, pi_base_clk)
    begin
        if (pi_rst_n = '0') then

            --cpu i/f
            reg_cpu_oe_n    <= 'Z';
            reg_cpu_we_n    <= 'Z';
            reg_cpu_addr    <= (others => 'Z');
            reg_cpu_out     <= (others => 'Z');

            --sprite i/f
            reg_spr_ce_n    <= 'Z';
            reg_spr_rd_n    <= 'Z';
            reg_spr_wr_n    <= 'Z';
            reg_spr_addr    <= (others => 'Z');
            reg_spr_data    <= (others => 'Z');
        elsif (rising_edge(pi_base_clk)) then
            if (reg_dma_cur_state = idle) then
                --cpu i/f
                reg_cpu_oe_n    <= 'Z';
                reg_cpu_we_n    <= 'Z';
                reg_cpu_addr    <= (others => 'Z');
                reg_cpu_out     <= (others => 'Z');

                --sprite i/f
                reg_spr_ce_n    <= 'Z';
                reg_spr_rd_n    <= 'Z';
                reg_spr_wr_n    <= 'Z';
                reg_spr_addr    <= (others => 'Z');
                reg_spr_data    <= (others => 'Z');
            elsif (reg_dma_cur_state = dma_init) then
                reg_cpu_oe_n    <= '0';
                reg_cpu_we_n    <= '1';
                reg_spr_ce_n    <= '0';
                reg_spr_rd_n    <= '1';
                reg_spr_wr_n    <= '1';
            elsif (reg_dma_cur_state = rd_data) then
                reg_cpu_addr    <= reg_dma_addr & conv_std_logic_vector(reg_dma_cnt, 8);
                reg_spr_wr_n    <= '1';
                reg_spr_addr    <= conv_std_logic_vector(reg_dma_cnt, 8);
                reg_spr_data    <= pio_cpu_d;
            elsif (reg_dma_cur_state = wr_data) then
                if (pi_rnd_en(1) = '1') then
                    reg_spr_wr_n    <= '0';
                else
                    reg_spr_wr_n    <= '1';
                end if;
            elsif (reg_dma_cur_state = dma_end) then
                reg_cpu_oe_n    <= 'Z';
                reg_cpu_we_n    <= 'Z';
                reg_cpu_addr    <= (others => 'Z');
                reg_cpu_out     <= (others => 'Z');
                reg_spr_ce_n    <= 'Z';
                reg_spr_rd_n    <= 'Z';
                reg_spr_wr_n    <= 'Z';
                reg_spr_addr    <= (others => 'Z');
                reg_spr_data    <= (others => 'Z');
            end if;
        end if;--if (pi_rst_n = '0') then
    end process;

end rtl;
