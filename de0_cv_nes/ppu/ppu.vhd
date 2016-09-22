library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ppu is 
    port (
                pi_rst_n       : in std_logic;
                pi_base_clk    : in std_logic;
                pi_cpu_en      : in std_logic_vector (7 downto 0);
                pi_ce_n        : in std_logic;
                pi_oe_n        : in std_logic;
                pi_we_n        : in std_logic;
                pi_cpu_addr    : in std_logic_vector (2 downto 0);
                pio_cpu_d      : inout std_logic_vector (7 downto 0);
                po_vblank_n    : out std_logic;

                po_v_ce_n       : out std_logic;
                po_v_rd_n       : out std_logic;
                po_v_wr_n       : out std_logic;
                po_v_addr       : out std_logic_vector (13 downto 0);
                pio_v_data      : inout std_logic_vector (7 downto 0);

                po_plt_ce_n     : out std_logic;
                po_plt_rd_n     : out std_logic;
                po_plt_wr_n     : out std_logic;
                po_plt_addr     : out std_logic_vector (4 downto 0);
                pio_plt_data    : inout std_logic_vector (7 downto 0);

                po_spr_ce_n     : out std_logic;
                po_spr_rd_n     : out std_logic;
                po_spr_wr_n     : out std_logic;
                po_spr_addr     : out std_logic_vector (7 downto 0);
                po_spr_data     : out std_logic_vector (7 downto 0);

                po_ppu_ctrl        : out std_logic_vector (7 downto 0);
                po_ppu_mask        : out std_logic_vector (7 downto 0);
                pi_ppu_status      : in std_logic_vector (7 downto 0);
                po_ppu_scroll_x    : out std_logic_vector (7 downto 0);
                po_ppu_scroll_y    : out std_logic_vector (7 downto 0)
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

--ppu ctl reg flag.
constant PPUVAI     : integer := 2;  --vram address increment
constant PPUNEN     : integer := 7;  --nmi enable

--ppu status reg flag.
constant ST_VBL     : integer := 7;  --vblank

---cpu timing synchronization.
constant CP_ST0   : integer := 4;
constant CP_ST1   : integer := (CP_ST0 + 1) mod 8;
constant CP_ST2   : integer := (CP_ST0 + 2) mod 8;
constant CP_ST3   : integer := (CP_ST0 + 3) mod 8;
constant CP_ST4   : integer := (CP_ST0 + 4) mod 8;

signal reg_ppu_ctrl         : std_logic_vector (7 downto 0);
signal reg_ppu_mask         : std_logic_vector (7 downto 0);
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

signal reg_v_ce_n       : std_logic;
signal reg_v_rd_n       : std_logic;
signal reg_v_wr_n       : std_logic;
signal reg_v_addr       : std_logic_vector (13 downto 0);
signal reg_v_data       : std_logic_vector (7 downto 0);

signal reg_plt_ce_n       : std_logic;

signal reg_spr_ce_n       : std_logic;
signal reg_spr_rd_n       : std_logic;
signal reg_spr_wr_n       : std_logic;
signal reg_spr_addr       : std_logic_vector (7 downto 0);
signal reg_spr_data       : std_logic_vector (7 downto 0);

signal reg_out_cpu_d    : std_logic_vector (7 downto 0);
signal reg_vblank_n     : std_logic;

begin

    --set control regs for renderer.
    po_ppu_ctrl        <= reg_ppu_ctrl;
    po_ppu_mask        <= reg_ppu_mask;
    po_ppu_scroll_x    <= reg_ppu_scroll_x;
    po_ppu_scroll_y    <= reg_ppu_scroll_y;

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
            if (pi_cpu_en(CP_ST0) = '1' and pi_ce_n = '0' and pi_we_n = '0') then
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
            end if;--if (pi_cpu_en(CP_ST0) = '1' and pi_ce_n = '0') then
        end if;--if (pi_rst_n = '0') then
    end process;

    --vram output signal...
    po_v_ce_n       <= reg_v_ce_n;
    po_v_rd_n       <= reg_v_rd_n;
    po_v_wr_n       <= reg_v_wr_n;
    po_v_addr       <= reg_v_addr;
    pio_v_data      <= reg_v_data;

    po_plt_ce_n     <= reg_plt_ce_n;
    po_plt_rd_n     <= reg_v_rd_n;
    po_plt_wr_n     <= reg_v_wr_n;
    po_plt_addr     <= reg_v_addr(4 downto 0);
    pio_plt_data    <= reg_v_data;

    --vram access state machine (state transition)...
    ac_set_stat_p : process (pi_rst_n, pi_base_clk)
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
    vac_next_stat_p : process (reg_v_cur_state, pi_cpu_en, pi_ce_n, pi_we_n, pi_cpu_addr)
    begin
        case reg_v_cur_state is
            when idle =>
                if (pi_cpu_en(CP_ST0) = '1' and pi_ce_n = '0' and pi_we_n = '0' and pi_cpu_addr = PPUDATA) then
                    reg_v_next_state <= reg_set;
                else
                    reg_v_next_state <= reg_v_cur_state;
                end if;
            when reg_set =>
                if (pi_cpu_en(CP_ST1) = '1') then
                    reg_v_next_state <= reg_out;
                else
                    reg_v_next_state <= reg_v_cur_state;
                end if;
            when reg_out =>
                if (pi_cpu_en(CP_ST2) = '1') then
                    reg_v_next_state <= mem_write;
                else
                    reg_v_next_state <= reg_v_cur_state;
                end if;
            when mem_write =>
                if (pi_cpu_en(CP_ST3) = '1') then
                    reg_v_next_state <= write_end;
                else
                    reg_v_next_state <= reg_v_cur_state;
                end if;
            when write_end =>
                if (pi_cpu_en(CP_ST4) = '1') then
                    reg_v_next_state <= complete;
                else
                    reg_v_next_state <= reg_v_cur_state;
                end if;
            when complete =>
                    reg_v_next_state <= idle;
        end case;
    end process;

    --main vram access state machine...
    vac_main_stat_p : process (reg_v_cur_state, reg_ppu_addr, reg_ppu_data)
    begin
        case reg_v_cur_state is
            when idle =>
                reg_v_ce_n      <= 'Z';
                reg_v_rd_n      <= 'Z';
                reg_v_wr_n      <= 'Z';
                reg_v_addr      <= (others => 'Z');
                reg_v_data      <= (others => 'Z');
                reg_plt_ce_n    <= 'Z';
            when reg_set =>
                --register is set in set_ppu_p process.
                reg_v_ce_n      <= '1';
                reg_v_rd_n      <= '1';
                reg_v_wr_n      <= '1';
                reg_v_addr    <= (others => 'Z');
                reg_v_data    <= (others => 'Z');
                reg_plt_ce_n    <= '1';
            when reg_out =>
                if (reg_ppu_addr(13 downto 8) = "111111") then
                    reg_v_ce_n      <= '1';
                    reg_plt_ce_n    <= '0';
                else
                    reg_plt_ce_n    <= '1';
                    reg_v_ce_n      <= '0';
                end if;
                reg_v_rd_n      <= '1';
                reg_v_wr_n      <= '1';
                reg_v_addr    <= reg_ppu_addr;
                reg_v_data    <= reg_ppu_data;
            when mem_write =>
                if (reg_ppu_addr(13 downto 8) = "111111") then
                    reg_v_ce_n      <= '1';
                    reg_plt_ce_n    <= '0';
                else
                    reg_plt_ce_n    <= '1';
                    reg_v_ce_n      <= '0';
                end if;
                reg_v_rd_n      <= '1';
                reg_v_wr_n      <= '0';
                reg_v_addr    <= reg_ppu_addr;
                reg_v_data    <= reg_ppu_data;
            when write_end =>
                if (reg_ppu_addr(13 downto 8) = "111111") then
                    reg_v_ce_n      <= '1';
                    reg_plt_ce_n    <= '0';
                else
                    reg_plt_ce_n    <= '1';
                    reg_v_ce_n      <= '0';
                end if;
                reg_v_rd_n      <= '1';
                reg_v_wr_n      <= '1';
                reg_v_addr    <= reg_ppu_addr;
                reg_v_data    <= reg_ppu_data;
            when complete =>
                reg_v_ce_n      <= '1';
                reg_v_rd_n      <= '1';
                reg_v_wr_n      <= '1';
                reg_v_addr    <= (others => 'Z');
                reg_v_data    <= (others => 'Z');
                reg_plt_ce_n    <= '1';
        end case;
    end process;

    --sprite output signal...
    po_spr_ce_n     <= reg_spr_ce_n;
    po_spr_rd_n     <= reg_spr_rd_n;
    po_spr_wr_n     <= reg_spr_wr_n;
    po_spr_addr     <= reg_spr_addr;
    po_spr_data     <= reg_spr_data;

    --sprite state change to next.
    sac_next_stat_p : process (reg_spr_cur_state, pi_cpu_en, pi_ce_n, pi_we_n, pi_cpu_addr)
    begin
        case reg_spr_cur_state is
            when idle =>
                if (pi_cpu_en(CP_ST0) = '1' and pi_ce_n = '0' and pi_we_n = '0' and pi_cpu_addr = OAMDATA) then
                    reg_spr_next_state <= reg_set;
                else
                    reg_spr_next_state <= reg_spr_cur_state;
                end if;
            when reg_set =>
                if (pi_cpu_en(CP_ST1) = '1') then
                    reg_spr_next_state <= reg_out;
                else
                    reg_spr_next_state <= reg_spr_cur_state;
                end if;
            when reg_out =>
                if (pi_cpu_en(CP_ST2) = '1') then
                    reg_spr_next_state <= mem_write;
                else
                    reg_spr_next_state <= reg_spr_cur_state;
                end if;
            when mem_write =>
                if (pi_cpu_en(CP_ST3) = '1') then
                    reg_spr_next_state <= write_end;
                else
                    reg_spr_next_state <= reg_spr_cur_state;
                end if;
            when write_end =>
                if (pi_cpu_en(CP_ST4) = '1') then
                    reg_spr_next_state <= complete;
                else
                    reg_spr_next_state <= reg_spr_cur_state;
                end if;
            when complete =>
                    reg_spr_next_state <= idle;
        end case;
    end process;

    --main sprite access state machine...
    sac_main_stat_p : process (reg_spr_cur_state, reg_oam_addr, reg_oam_data)
    begin
        case reg_spr_cur_state is
            when idle =>
                reg_spr_ce_n    <= 'Z';
                reg_spr_rd_n    <= 'Z';
                reg_spr_wr_n    <= 'Z';
                reg_spr_addr    <= (others => 'Z');
                reg_spr_data    <= (others => 'Z');
            when reg_set =>
                --register is set in set_ppu_p process.
                reg_spr_ce_n    <= '1';
                reg_spr_rd_n    <= '1';
                reg_spr_wr_n    <= '1';
                reg_spr_addr    <= (others => 'Z');
                reg_spr_data    <= (others => 'Z');
            when reg_out =>
                reg_spr_ce_n    <= '0';
                reg_spr_rd_n    <= '1';
                reg_spr_wr_n    <= '1';
                reg_spr_addr    <= reg_oam_addr;
                reg_spr_data    <= reg_oam_data;
            when mem_write =>
                reg_spr_ce_n    <= '0';
                reg_spr_rd_n    <= '1';
                reg_spr_wr_n    <= '0';
                reg_spr_addr    <= reg_oam_addr;
                reg_spr_data    <= reg_oam_data;
            when write_end =>
                reg_spr_ce_n    <= '1';
                reg_spr_rd_n    <= '1';
                reg_spr_wr_n    <= '1';
                reg_spr_addr    <= reg_oam_addr;
                reg_spr_data    <= reg_oam_data;
            when complete =>
                reg_spr_ce_n    <= '1';
                reg_spr_rd_n    <= '1';
                reg_spr_wr_n    <= '1';
                reg_spr_addr    <= (others => 'Z');
                reg_spr_data    <= (others => 'Z');
        end case;
    end process;

    pio_cpu_d <= reg_out_cpu_d;

    --cpu out process..
    get_ppu_p : process (pi_rst_n, pi_base_clk)
    begin
        if (pi_rst_n = '0') then
            reg_out_cpu_d <= (others => 'Z');
        elsif (rising_edge(pi_base_clk)) then
            if (pi_cpu_en(CP_ST0) = '1' and pi_ce_n = '0' and pi_oe_n = '0') then
                if (pi_cpu_addr = PPUSTATUS) then
                    reg_out_cpu_d <= pi_ppu_status;
                end if;
            elsif (pi_ce_n = '1') then
                reg_out_cpu_d <= (others => 'Z');
            end if;--if (pi_cpu_en(CP_ST0) = '1' and pi_ce_n = '0') then
        end if;--if (pi_rst_n = '0') then
    end process;

    po_vblank_n <= reg_vblank_n;

    --nmi signal process..
    nmi_p : process (pi_rst_n, pi_base_clk)
    begin
        if (pi_rst_n = '0') then
            reg_vblank_n <= '1';
        elsif (rising_edge(pi_base_clk)) then
            if (reg_ppu_mask(PPUNEN) = '1' and pi_ppu_status(ST_VBL) = '1') then
                reg_vblank_n <= '0';
            else
                reg_vblank_n <= '1';
            end if;--if (pi_cpu_en(CP_ST0) = '1' and pi_ce_n = '0') then
        end if;--if (pi_rst_n = '0') then
    end process;

end rtl;
