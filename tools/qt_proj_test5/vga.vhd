-------------------------------------------------------------
-------------------------------------------------------------
-------------- VGA RGB Output Control w/ SDRAM --------------
-------------------------------------------------------------
-------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;
use ieee.std_logic_arith.conv_std_logic_vector;
use work.motonesfpga_common.all;

entity vga_ctl is 
    port (  ppu_clk     : in std_logic;
            sdram_clk   : in std_logic;
            vga_clk     : in std_logic;
            rst_n       : in std_logic;
            pos_x       : in std_logic_vector (8 downto 0);
            pos_y       : in std_logic_vector (8 downto 0);
            nes_r       : in std_logic_vector (3 downto 0);
            nes_g       : in std_logic_vector (3 downto 0);
            nes_b       : in std_logic_vector (3 downto 0);
            h_sync_n    : out std_logic;
            v_sync_n    : out std_logic;
            r           : out std_logic_vector(3 downto 0);
            g           : out std_logic_vector(3 downto 0);
            b           : out std_logic_vector(3 downto 0);

            --SDRAM Signals
            wbs_adr_i	:	out std_logic_vector (21 downto 0);		--Address (Bank, Row, Col)
            wbs_dat_i	:	out std_logic_vector (15 downto 0);		--Data In (16 bits)
            wbs_we_i	:	out std_logic;							--Write Enable
            wbs_tga_i	:	out std_logic_vector (7 downto 0);		--Address Tag : Read/write burst length-1 (0 represents 1 word, FF represents 256 words)
            wbs_cyc_i	:	out std_logic;							--Cycle Command from interface
            wbs_stb_i	:	out std_logic;							--Strobe Command from interface
            wbs_dat_o	:	in std_logic_vector (15 downto 0);		--Data Out (16 bits)
            wbs_stall_o	:	in std_logic;							--Slave is not ready to receive new data
            wbs_err_o	:	in std_logic;							--Error flag: OOR Burst. Burst length is greater that 256-column address
            wbs_ack_o	:	in std_logic 							--When Read Burst: DATA bus must be valid in this cycle
    );
end vga_ctl;

architecture rtl of vga_ctl is

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


--------- screen constant -----------
constant VGA_W          : integer := 640;
constant VGA_H          : integer := 480;
constant VGA_W_MAX      : integer := 800;
constant VGA_H_MAX      : integer := 525;
constant H_SP           : integer := 95;
constant H_BP           : integer := 48;
constant H_FP           : integer := 15;
constant V_SP           : integer := 2;
constant V_BP           : integer := 33;
constant V_FP           : integer := 10;

constant NES_W          : integer := 256;
constant NES_H          : integer := 240;


--------- signal declaration -----------
signal vga_x        : std_logic_vector (9 downto 0);
signal vga_y        : std_logic_vector (9 downto 0);
signal x_res_n      : std_logic;
signal y_res_n      : std_logic;
signal y_en_n       : std_logic;

signal cnt_clk      : std_logic;
signal mem_cnt      : std_logic_vector (4 downto 0);

signal count5_res_n  : std_logic;
signal count5        : std_logic_vector(2 downto 0);
signal nes_x_en_n    : std_logic;
signal nes_x         : std_logic_vector(7 downto 0);

signal dram_col_we_n  : std_logic;
signal dram_col       : std_logic_vector(15 downto 0);

signal pos_x_we_n       : std_logic;
signal pos_x_old        : std_logic_vector(8 downto 0);
signal nes_x_we_n       : std_logic;
signal nes_x_old        : std_logic_vector(7 downto 0);

type sdram_write_status is (sw_idle, sw_write, sw_write_ack);
type sdram_read_status is (sr_idle, sr_read_wait, sr_read, sr_read_ack);

signal sw_state : sdram_write_status;
signal sr_state : sdram_read_status;
constant SDRAM_READ_WAIT_CNT : integer := 10;


---DE1 base clock 50 MHz
---motones sim project uses following clock.
--cpu clock = base clock / 24 = 2.08 MHz (480 ns / cycle)
--ppu clock = base clock / 8
--vga clock = base clock / 2
--sdram clock = 135 MHz

begin

    cnt_clk <= not vga_clk;
    x_inst : counter_register generic map (10, 1)
            port map (cnt_clk , x_res_n, '0', '1', (others => '0'), vga_x);

    pos_x_old_inst: d_flip_flop generic map (9)
        port map (sdram_clk, rst_n, '1', pos_x_we_n, pos_x, pos_x_old);

    nes_x_old_inst: d_flip_flop generic map (8)
        port map (sdram_clk, rst_n, '1', nes_x_we_n, nes_x, nes_x_old);
        
    y_inst : counter_register generic map (10, 1)
            port map (cnt_clk , y_res_n, y_en_n, '1', (others => '0'), vga_y);
    mem_cnt_inst : counter_register generic map (5, 1)
            port map (sdram_clk , x_res_n, '0', '1', (others => '0'), mem_cnt);

    count5_inst : counter_register generic map (3, 1)
            port map (cnt_clk, count5_res_n, '0', '1', (others => '0'), count5);

    nes_x_inst : counter_register generic map (8, 1)
            port map (vga_clk, x_res_n, nes_x_en_n, '1', (others => '0'), nes_x);
            
    col_inst : d_flip_flop generic map (16)
        port map (sdram_clk, rst_n, '1', dram_col_we_n, wbs_dat_o, dram_col);
        
    dram_p : process (rst_n, sdram_clk)
variable sr_read_ok : std_logic;
variable wait_cnt : integer;
    begin
        if (rst_n = '0') then
            
            wbs_adr_i	<= (others => '0');
            wbs_dat_i	<= (others => '0');
            wbs_we_i	<= '0';
            wbs_tga_i	<= (others => '0');
            wbs_cyc_i	<= '0';
            wbs_stb_i	<= '0';

            sr_read_ok := '0';
            pos_x_we_n <= '1';
            nes_x_we_n <= '1';
            sw_state <= sw_idle;
            sr_state <= sr_idle;
            wait_cnt := SDRAM_READ_WAIT_CNT;
            
        elsif (rising_edge(sdram_clk)) then
        
            --write to sdram
            case sw_state is
            when sw_idle =>
                if (pos_x < conv_std_logic_vector(NES_W, 9) and 
                    pos_y < conv_std_logic_vector(NES_H, 9) and 
                    pos_x /= pos_x_old and sr_state = sr_idle) then
                --if (mem_cnt = conv_std_logic_vector(1, 5)) then
                    sw_state <= sw_write;
                    sr_read_ok := '0';
                    pos_x_we_n <= '0';

                    wbs_adr_i <= "000000" & pos_x(7 downto 0) & pos_y(7 downto 0);
                    wbs_dat_i <= "0000" & nes_r & nes_g & nes_b;
                    --wbs_dat_i <= (others => '1');
                end if;

            when sw_write =>
                pos_x_we_n <= '1';
                sw_state <= sw_write_ack;

                wbs_we_i <= '1';
                wbs_cyc_i <= '1';
                wbs_stb_i <= '1';
                wbs_tga_i <= conv_std_logic_vector(0, 8);
            when sw_write_ack =>
                sw_state <= sw_idle;
                sr_read_ok := '1';
                wait_cnt := SDRAM_READ_WAIT_CNT;
            end case;
                
--                --write to sdram
--                if (mem_cnt = conv_std_logic_vector(2, 4)) then
--                    wbs_adr_i <= "000000" & pos_x(7 downto 0) & pos_y(7 downto 0);
--                    wbs_dat_i <= "0000" & nes_r & nes_g & nes_b;
--                elsif (mem_cnt = conv_std_logic_vector(3, 4)) then
--                    wbs_we_i <= '1';
--                    wbs_cyc_i <= '1';
--                    wbs_stb_i <= '1';
--                    wbs_tga_i <= conv_std_logic_vector(0, 8);
--
--                elsif (mem_cnt = conv_std_logic_vector(4, 4)) then
--                    --wbs_adr_i <= "0000" & pos_x & pos_y;
--                    --wbs_dat_i <= "0000" & nes_r & nes_g & nes_b;
--                    --wbs_dat_i <= "0000101000001111";
--                end if;

            --read from sdram
            if (vga_x <=conv_std_logic_vector(VGA_W , 10) 
                and vga_y <=conv_std_logic_vector(VGA_H, 10)) then

                --read from sdram
                case sr_state is
                when sr_idle =>
                    if (nes_x /= nes_x_old and sr_read_ok = '1') then
                    --if (mem_cnt = conv_std_logic_vector(5, 5)) then
                        if (wait_cnt = 0) then
                            sr_state <= sr_read;
                        else
                            sr_state <= sr_read_wait;
                        end if;
                        wbs_adr_i <= "000000" & nes_x & vga_y(8 downto 1);
                        wbs_cyc_i <= '0';
                        wbs_stb_i <= '0';
                        nes_x_we_n <= '0';
                    end if;
                    dram_col_we_n <= '1';
                when sr_read_wait =>
                    wait_cnt := wait_cnt - 1;
                    if (wait_cnt = 0) then
                        sr_state <= sr_read;
                    end if;
                when sr_read =>
                    wbs_we_i <= '0';
                    wbs_cyc_i <= '1';
                    wbs_stb_i <= '1';
                    wbs_tga_i <= conv_std_logic_vector(0, 8);
                    nes_x_we_n <= '1';
                    sr_state <= sr_read_ack;
                when sr_read_ack =>
                    dram_col_we_n <= '0';
                    sr_state <= sr_idle;
                end case;
                
--                if (mem_cnt > conv_std_logic_vector(4, 4) and 
--                        mem_cnt <= conv_std_logic_vector(15, 4)) then
--                    --read wait cycle
--                    wbs_adr_i <= "000000" & nes_x & vga_y(8 downto 1);
--                    wbs_cyc_i <= '0';
--                    wbs_stb_i <= '0';
--                elsif (mem_cnt <= conv_std_logic_vector(0, 4)) then
--                    --read
--                    wbs_we_i <= '0';
--                    wbs_cyc_i <= '1';
--                    wbs_stb_i <= '1';
--                    wbs_tga_i <= conv_std_logic_vector(0, 8);
--                end if;
            else
                sr_state <= sr_idle;
            end if;

--            if (mem_cnt = conv_std_logic_vector(1, 4)) then
--                dram_col_we_n <= '0';
--            else
--                dram_col_we_n <= '1';
--            end if;
        
        end if;
    end process;

    dram_latch_p : process (rst_n, vga_clk)
    begin
        if (rst_n = '0') then
            nes_x_en_n <= '1';
            
        elsif (falling_edge(vga_clk)) then

            if (count5 = "001" or count5 = "011") then
                nes_x_en_n <= '0';
            else
                nes_x_en_n <= '1';
            end if;
        end if;
    end process;

    vga_out_p : process (rst_n, vga_clk)
    begin
        if (rst_n = '0') then
            h_sync_n <= '0';
            v_sync_n <= '0';
            x_res_n <= '0';
            y_res_n <= '0';
            count5_res_n <= '0';
            
            r<=(others => '0');
            g<=(others => '0');
            b<=(others => '0');
            
        elsif (rising_edge(vga_clk)) then
            --xmax = 799
            if (vga_x = conv_std_logic_vector(VGA_W_MAX, 10)) then
                x_res_n <= '0';
                y_en_n <= '0';
                --ymax=524
                if (vga_y = conv_std_logic_vector(VGA_H_MAX, 10)) then
                    y_res_n <= '0';
                else
                    y_res_n <= '1';
                end if;
            else
                x_res_n <= '1';
                y_en_n <= '1';
                y_res_n <= '1';
            end if;
            
            --sync signal assert.
            if (vga_x >= conv_std_logic_vector((VGA_W + H_FP) , 10) and 
                vga_x < conv_std_logic_vector((VGA_W + H_FP + H_SP) , 10)) then
                h_sync_n <= '0';
            else
                h_sync_n <= '1';
            end if;

            if (vga_y >= conv_std_logic_vector((VGA_H + V_FP) , 10) and 
                vga_y < conv_std_logic_vector((VGA_H + V_FP + V_SP) , 10)) then
                v_sync_n <= '0';
            else
                v_sync_n <= '1';
            end if;

            if (vga_y <=conv_std_logic_vector((VGA_H) , 10)) then
                if (vga_x < conv_std_logic_vector((VGA_W) , 10)) then
                    r<= dram_col(11 downto 8);
                    g<= dram_col(7 downto 4);
                    b<= dram_col(3 downto 0);
--                    r<= "1111";
--                    g<= "0000";
--                    b<= "0000";
                else
                    r<=(others => '0');
                    g<=(others => '0');
                    b<=(others => '0');
                end if;
            else
                r<=(others => '0');
                g<=(others => '0');
                b<=(others => '0');
            end if;
            
            if (vga_x = conv_std_logic_vector(VGA_W_MAX, 10)) then
                count5_res_n <= '0';
            elsif (count5 = "100") then
                count5_res_n <= '0';
            else
                count5_res_n <= '1';
            end if;

        end if;
    end process;

end rtl;



-------------------------------------------------------------
-------------------------------------------------------------
----------------- Dummy PPU image generator -----------------
-------------------------------------------------------------
-------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.conv_std_logic_vector;

entity dummy_ppu is 
    port (  ppu_clk     : in std_logic;
            rst_n       : in std_logic;
            pos_x       : buffer std_logic_vector (8 downto 0);
            pos_y       : buffer std_logic_vector (8 downto 0);
            nes_r       : buffer std_logic_vector (3 downto 0);
            nes_g       : buffer std_logic_vector (3 downto 0);
            nes_b       : buffer std_logic_vector (3 downto 0)
    );
end dummy_ppu;


architecture rtl of dummy_ppu is

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

signal x_res_n, y_res_n, y_en_n : std_logic;
signal cnt_clk : std_logic;
signal frame_en_n : std_logic;


signal frame_cnt : std_logic_vector(7 downto 0);

begin

    cnt_clk <= not ppu_clk;
    x_inst : counter_register generic map (9, 1)
            port map (cnt_clk , x_res_n, '0', '1', (others => '0'), pos_x);
    y_inst : counter_register generic map (9, 1)
            port map (cnt_clk , y_res_n, y_en_n, '1', (others => '0'), pos_y);

    frame_cnt_inst : counter_register generic map (8, 1)
            port map (cnt_clk , rst_n, frame_en_n, '1', (others => '0'), frame_cnt);

    
    p_write : process (rst_n, ppu_clk)
    begin
        if (rst_n = '0') then
            x_res_n <= '0';
            y_res_n <= '0';
            frame_en_n <= '1';
            nes_r <= (others => '0');
            nes_g <= (others => '0');
            nes_b <= (others => '0');
        elsif (rising_edge(ppu_clk)) then
            --xmax = 340
            if (pos_x = conv_std_logic_vector(340, 9)) then
                x_res_n <= '0';
                y_en_n <= '0';
                --ymax=261
                if (pos_y = conv_std_logic_vector(261, 9)) then
                    y_res_n <= '0';
                    frame_en_n <= '0';
                else
                    frame_en_n <= '1';
                    y_res_n <= '1';
                end if;
            else
                frame_en_n <= '1';
                x_res_n <= '1';
                y_en_n <= '1';
                y_res_n <= '1';
            end if;
            
--            nes_b <= pos_y (7 downto 4);
--            nes_g <= pos_x (5 downto 2);
--            nes_r <= pos_x(7 downto 4);
            --nes_r <= pos_x (3) & pos_x (3) & pos_x (3) & pos_x (3);
            if (pos_x <= conv_std_logic_vector(64, 9)) then
                nes_r <= "1111";
                nes_g <= "0000";
                nes_b <= "0000";
            elsif (pos_x <= conv_std_logic_vector(128, 9)) then
                nes_r <= "1100";
                nes_g <= "1111";
                nes_b <= "0000";
            elsif (pos_x <= conv_std_logic_vector(192, 9)) then
                nes_r <= "0011";
                nes_g <= "1111";
                nes_b <= "1111";
            else
                nes_r <= "1010";
                nes_g <= "0011";
                nes_b <= "1100";
            end if;
        
        end if;
    end process;
end rtl;
