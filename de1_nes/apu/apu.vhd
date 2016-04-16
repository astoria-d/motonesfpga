library ieee;
use ieee.std_logic_1164.all;

entity apu is 
    port (  clk         : in std_logic;
            ce_n        : in std_logic;
            rst_n       : in std_logic;
            r_nw        : inout std_logic;
            cpu_addr    : inout std_logic_vector (15 downto 0);
            cpu_d       : inout std_logic_vector (7 downto 0);
            rdy         : out std_logic
    );
end apu;

architecture rtl of apu is


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

component counter_register
    generic (
        dsize       : integer := 8;
        inc         : integer := 1
    );
    port (  clk         : in std_logic;
            rst_n       : in std_logic;
            ce_n        : in std_logic;
            we_n        : in std_logic;
            d           : in std_logic_vector(dsize - 1 downto 0);
            q           : out std_logic_vector(dsize - 1 downto 0)
    );
end component;

constant dsize     : integer := 8;
constant OAM_DMA   : std_logic_vector(4 downto 0) := "10100";
constant OAM_JP1   : std_logic_vector(4 downto 0) := "10110";
constant OAM_JP2   : std_logic_vector(4 downto 0) := "10111";

--oamaddr=0x2003
constant OAMADDR   : std_logic_vector(15 downto 0) := "0010000000000011";
--oamdata=0x2004
constant OAMDATA   : std_logic_vector(15 downto 0) := "0010000000000100";

signal clk_n            : std_logic;

signal oam_data         : std_logic_vector (dsize - 1 downto 0);

signal oam_bus_ce_n     : std_logic;

signal dma_addr         : std_logic_vector (dsize * 2 - 1 downto 0);
signal dma_cnt_ce_n     : std_logic_vector(0 downto 0);
signal dma_cnt_ce       : std_logic;
signal dma_start_n      : std_logic;
signal dma_end_n        : std_logic;
signal dma_process_n    : std_logic;
signal dma_rst_n        : std_logic;
signal dma_status_we_n  : std_logic;
signal dma_status       : std_logic_vector(1 downto 0);
signal dma_next_status  : std_logic_vector(1 downto 0);

constant DMA_ST_IDLE    : std_logic_vector(1 downto 0) := "00";
constant DMA_ST_SETUP   : std_logic_vector(1 downto 0) := "01";
constant DMA_ST_PROCESS : std_logic_vector(1 downto 0) := "10";

begin

    clk_n <= not clk;

    dma_rst_n <= not dma_process_n;

    dma_l_up_inst : counter_register generic map (1, 1)
            port map (clk_n, dma_rst_n, dma_process_n, '1', (others => '0'), dma_cnt_ce_n);

    dma_cnt_ce <= not dma_cnt_ce_n(0);
    dma_l_inst : counter_register generic map (dsize, 1)
            port map (clk, dma_rst_n, dma_cnt_ce, '1', (others => '0'), 
                                                dma_addr(dsize - 1 downto 0));
    dma_h_inst : d_flip_flop generic map(dsize)
            port map (clk_n, '1', '1', dma_start_n, cpu_d, 
                                                dma_addr(dsize * 2 - 1 downto dsize));

    dma_status_inst : d_flip_flop generic map(2)
            port map (clk_n, rst_n, '1', dma_status_we_n, dma_next_status, dma_status);

    dma_val_inst : d_flip_flop generic map(dsize)
            port map (clk_n, rst_n, '1', dma_process_n, cpu_d, oam_data);

    --apu register access process
    reg_set_p : process (rst_n, ce_n, r_nw, cpu_addr, cpu_d)
    begin
        if (rst_n = '0') then
--            cpu_d <= (others => 'Z');
            dma_start_n <= '1';
        elsif (rising_edge(clk)) then
--            if (ce_n = '0') then
--                if (r_nw = '0') then
--                    --apu write
--                    cpu_d <= (others => 'Z');
--                    if (cpu_addr(4 downto 0) = OAM_DMA) then
--                        dma_start_n <= '0';
--                    else
--                        dma_start_n <= '1';
--                    end if;
--                elsif (r_nw = '1') then
--                    dma_start_n <= '1';
--                    
--                    --joy pad read
--                    if (cpu_addr(4 downto 0) = OAM_JP1) then
--                        cpu_d <= (others => '0');
--                    elsif (cpu_addr(4 downto 0) = OAM_JP2) then
--                        cpu_d <= (others => '0');
--                    else
--                        --return dummy zero vale.
--                        cpu_d <= (others => '0');
--                    end if;
--                end if;
--            else
--                cpu_d <= (others => 'Z');
--                dma_start_n <= '1';
--            end if; --if (ce_n = '0') 
        end if; --if (rst_n = '0') then
    end process;

    --dma operation process
    dma_p : process (rst_n, clk)
    begin
        if (rst_n = '0') then
            dma_next_status <= DMA_ST_IDLE;
            dma_status_we_n <= '1';
            dma_end_n <= '1';
            dma_process_n <= '1';
            cpu_addr <= (others => 'Z');
            cpu_d <= (others => 'Z');
            r_nw <= 'Z';
        elsif (rising_edge(clk)) then
--            if (dma_status = DMA_ST_IDLE) then
--                if (dma_start_n = '0') then
--                    dma_status_we_n <= '0';
--                    dma_next_status <= DMA_ST_SETUP;
--                end if;
--                dma_process_n <= '1';
--                dma_end_n <= '1';
--                cpu_addr <= (others => 'Z');
--                cpu_d <= (others => 'Z');
--                r_nw <= 'Z';
--            elsif (dma_status = DMA_ST_SETUP) then
--                cpu_addr <= OAMADDR;
--                cpu_d <= (others => '0');
--                r_nw <= '0';
--                dma_next_status <= DMA_ST_PROCESS;
--            elsif (dma_status = DMA_ST_PROCESS) then
--                if (dma_addr(dsize - 1 downto 0) = "11111111" and dma_cnt_ce_n(0) = '1') then
--                    dma_status_we_n <= '0';
--                    dma_next_status <= DMA_ST_IDLE;
--                    dma_end_n <= '0';
--                else
--                    dma_status_we_n <= '1';
--                    dma_process_n <= '0';
--                    dma_end_n <= '1';
--                end if;
--
--                if (dma_cnt_ce_n(0) = '0') then
--                    r_nw <= '1';
--                    cpu_addr <= dma_addr;
--                    cpu_d <= (others => 'Z');
--                elsif (dma_cnt_ce_n(0) = '1') then
--                    r_nw <= '0';
--                    cpu_addr <= OAMDATA;
--                    cpu_d <= oam_data;
--                end if;
--            end if;--if (dma_status = DMA_ST_IDLE) then
        end if;--if (rst_n = '0') then
    end process;

    rdy_p : process (rst_n, clk_n)
    begin
        if (rst_n = '0') then
            rdy <= '1';
        elsif (rising_edge(clk_n)) then
--            if (dma_start_n = '0') then
--                --pull rdy pin down to stop cpu bus accessing.
--                rdy <= '0';
--            elsif (dma_end_n = '0') then
--                --pull rdy pin up to re-enable cpu bus accessing.
--                rdy <= '1';
--            else
--                rdy <= '1';
--            end if;
        end if;
    end process;

end rtl;

