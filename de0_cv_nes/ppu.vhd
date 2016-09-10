library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ppu is 
    port (
                pi_rst_n       : in std_logic;
                pi_base_clk    : in std_logic;
                pi_cpu_en      : in std_logic_vector (7 downto 0);
                pi_ce_n        : in std_logic;
                pi_r_nw        : in std_logic;
                pi_cpu_addr    : in std_logic_vector (2 downto 0);
                pio_cpu_d      : inout std_logic_vector (7 downto 0);

                po_rd_n        : out std_logic;
                po_wr_n        : out std_logic;
                po_vram_addr   : out std_logic_vector (13 downto 0);
                pio_vram_data  : inout std_logic_vector (7 downto 0)
    );
end ppu;

architecture rtl of ppu is

constant PPUCTRL   : std_logic_vector(2 downto 0) := "000";
constant PPUMASK   : std_logic_vector(2 downto 0) := "001";
constant PPUSTATUS : std_logic_vector(2 downto 0) := "010";
constant OAMADDR   : std_logic_vector(2 downto 0) := "011";
constant OAMDATA   : std_logic_vector(2 downto 0) := "100";
constant PPUSCROLL : std_logic_vector(2 downto 0) := "101";
constant PPUADDR   : std_logic_vector(2 downto 0) := "110";
constant PPUDATA   : std_logic_vector(2 downto 0) := "111";

signal reg_ppu_ctrl         : std_logic_vector (7 downto 0);
signal reg_ppu_mask         : std_logic_vector (7 downto 0);
signal reg_ppu_status       : std_logic_vector (7 downto 0);
signal reg_oam_addr         : std_logic_vector (7 downto 0);
signal reg_oam_data         : std_logic_vector (7 downto 0);
signal reg_ppu_scroll_x     : std_logic_vector (7 downto 0);
signal reg_ppu_scroll_y     : std_logic_vector (7 downto 0);
signal reg_ppu_addr         : std_logic_vector (13 downto 0);
signal reg_ppu_data         : std_logic_vector (7 downto 0);

type vac_state is (idle, reg_set, reg_out, mem_write, write_end, complete);

signal reg_v_cur_state      : vac_state;
signal reg_v_next_state     : vac_state;
signal reg_spr_cur_state    : vac_state;
signal reg_spr_next_state   : vac_state;

signal reg_rd_n         : std_logic;
signal reg_wr_n         : std_logic;
signal reg_vram_addr    : std_logic_vector (13 downto 0);
signal reg_vram_data    : std_logic_vector (7 downto 0);

begin

    reg_ppu_status <= (others => '0');

    --ppu register set process..
    set_ppu_p : process (pi_rst_n, pi_base_clk)
    variable addr_cnt       : integer range 0 to 1;
    variable addr_set       : integer range 0 to 1;
    variable addr_inc       : integer range 0 to 1;
    variable scr_cnt        : integer range 0 to 1;
    variable scr_set        : integer range 0 to 1;
    variable oam_addr_inc   : integer range 0 to 1;
    begin
        if (pi_rst_n = '0') then
            reg_ppu_ctrl <= (others => '0');
            reg_ppu_mask <= (others => '0');
            reg_oam_addr <= (others => '0');
            reg_oam_data <= (others => '0');
            reg_ppu_scroll_x <= (others => '0');
            reg_ppu_scroll_y <= (others => '0');
            reg_ppu_addr <= (others => '0');
            reg_ppu_data <= (others => '0');
            
            addr_cnt := 0;
            addr_set := 0;
            addr_inc := 0;
            scr_cnt := 0;
            scr_set := 0;
            oam_addr_inc := 0;
        elsif (rising_edge(pi_base_clk)) then
            if (pi_cpu_en(1) = '1' and pi_ce_n = '0' and pi_r_nw = '0') then
                if (pi_cpu_addr = PPUCTRL) then
                    reg_ppu_ctrl <= pio_cpu_d;
                elsif (pi_cpu_addr = PPUMASK) then
                    reg_ppu_mask <= pio_cpu_d;
                elsif (pi_cpu_addr = OAMADDR) then
                    reg_oam_addr <= pio_cpu_d;
                elsif (pi_cpu_addr = OAMDATA) then
                    reg_oam_data <= pio_cpu_d;
                    oam_addr_inc := 1;
                elsif (pi_cpu_addr = PPUSCROLL) then

                    if (scr_set = 0) then
                        if (scr_cnt = 0) then
                            reg_ppu_scroll_x <= pio_cpu_d;
                            scr_cnt := 1;
                        else
                            reg_ppu_scroll_y <= pio_cpu_d;
                            scr_cnt := 0;
                        end if;
                        scr_set := 1;
                    end if;
                elsif (pi_cpu_addr = PPUADDR) then
                    if (addr_set = 0) then
                        if (addr_cnt = 0) then
                            reg_ppu_addr(13 downto 8) <= pio_cpu_d(5 downto 0);
                            addr_cnt := 1;
                        else
                            reg_ppu_addr(7 downto 0) <= pio_cpu_d;
                            addr_cnt := 0;
                        end if;
                        addr_set := 1;
                    end if;
                elsif (pi_cpu_addr = PPUDATA) then
                    reg_ppu_data <= pio_cpu_d;
                    addr_inc := 1;
                end if;
            elsif (pi_ce_n = '1') then
                scr_set := 0;
                addr_set := 0;
                if (addr_inc = 1) then
                    reg_ppu_addr <= reg_ppu_addr + 1;
                    addr_inc := 0;
                end if;
                if (oam_addr_inc = 1) then
                    reg_oam_addr <= reg_oam_addr + 1;
                    oam_addr_inc := 0;
                end if;
            end if;--if (pi_cpu_en(0) = '1' and pi_ce_n = '0') then
        end if;--if (pi_rst_n = '0') then
    end process;

    --ppu register get process..
    get_ppu_p : process (pi_rst_n, pi_base_clk)
    begin
        if (pi_rst_n = '0') then
            pio_cpu_d <= (others => 'Z');
        elsif (rising_edge(pi_base_clk)) then
            if (pi_cpu_en(1) = '1' and pi_ce_n = '0' and pi_r_nw = '1') then
                if (pi_cpu_addr = PPUSTATUS) then
                    pio_cpu_d <= reg_ppu_status;
                end if;
            elsif (pi_ce_n = '1') then
                pio_cpu_d <= (others => 'Z');
            end if;--if (pi_cpu_en(0) = '1' and pi_ce_n = '0') then
        end if;--if (pi_rst_n = '0') then
    end process;

    --vram output signal...
    po_rd_n        <= reg_rd_n;
    po_wr_n        <= reg_wr_n;
    po_vram_addr   <= reg_vram_addr;
    pio_vram_data  <= reg_vram_data;

    --vram access state machine (state transition)...
    vac_set_stat_p : process (pi_rst_n, pi_base_clk)
    begin
        if (pi_rst_n = '0') then
            reg_v_cur_state <= idle;
            reg_spr_cur_state <= idle;
        elsif (rising_edge(pi_base_clk)) then
            reg_v_cur_state <= reg_v_next_state;
            reg_spr_cur_state <= reg_spr_next_state;
        end if;--if (pi_rst_n = '0') then
    end process;

    --state change to next.
    vac_v_next_stat_p : process (reg_v_cur_state, pi_cpu_en, pi_ce_n, pi_r_nw, pi_cpu_addr)
    begin
        case reg_v_cur_state is
            when idle =>
                if (pi_cpu_en(1) = '1' and pi_ce_n = '0' and pi_r_nw = '0' and pi_cpu_addr = PPUDATA) then
                    reg_v_next_state <= reg_set;
                else
                    reg_v_next_state <= reg_v_cur_state;
                end if;
            when reg_set =>
                if (pi_cpu_en(2) = '1' and pi_ce_n = '0' and pi_r_nw = '0' and pi_cpu_addr = PPUDATA) then
                    reg_v_next_state <= reg_out;
                else
                    reg_v_next_state <= reg_v_cur_state;
                end if;
            when reg_out =>
                if (pi_cpu_en(3) = '1' and pi_ce_n = '0' and pi_r_nw = '0' and pi_cpu_addr = PPUDATA) then
                    reg_v_next_state <= mem_write;
                else
                    reg_v_next_state <= reg_v_cur_state;
                end if;
            when mem_write =>
                if (pi_cpu_en(4) = '1' and pi_ce_n = '0' and pi_r_nw = '0' and pi_cpu_addr = PPUDATA) then
                    reg_v_next_state <= write_end;
                else
                    reg_v_next_state <= reg_v_cur_state;
                end if;
            when write_end =>
                if (pi_cpu_en(5) = '1' and pi_ce_n = '0' and pi_r_nw = '0' and pi_cpu_addr = PPUDATA) then
                    reg_v_next_state <= complete;
                else
                    reg_v_next_state <= reg_v_cur_state;
                end if;
            when complete =>
                    reg_v_next_state <= idle;
        end case;
    end process;

    --main vram access state machine...
    vac_v_main_stat_p : process (reg_v_cur_state, reg_ppu_addr, reg_ppu_data)
    begin
        case reg_v_cur_state is
            when idle =>
                reg_rd_n         <= 'Z';
                reg_wr_n         <= 'Z';
                reg_vram_addr    <= (others => 'Z');
                reg_vram_data    <= (others => 'Z');
            when reg_set =>
                --register is set in set_ppu_p process.
                reg_rd_n         <= '1';
                reg_wr_n         <= '1';
                reg_vram_addr    <= (others => 'Z');
                reg_vram_data    <= (others => 'Z');
            when reg_out =>
                reg_rd_n         <= '1';
                reg_wr_n         <= '1';
                reg_vram_addr    <= reg_ppu_addr;
                reg_vram_data    <= reg_ppu_data;
            when mem_write =>
                reg_rd_n         <= '1';
                reg_wr_n         <= '0';
                reg_vram_addr    <= reg_ppu_addr;
                reg_vram_data    <= reg_ppu_data;
            when write_end =>
                reg_rd_n         <= '1';
                reg_wr_n         <= '1';
                reg_vram_addr    <= reg_ppu_addr;
                reg_vram_data    <= reg_ppu_data;
            when complete =>
                reg_rd_n         <= '1';
                reg_wr_n         <= '1';
                reg_vram_addr    <= (others => 'Z');
                reg_vram_data    <= (others => 'Z');
        end case;
    end process;

end rtl;
