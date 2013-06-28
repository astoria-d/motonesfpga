library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;
use ieee.std_logic_arith.conv_std_logic_vector;

entity vga_ctl is 
    port (  vga_clk     : in std_logic;
            rst_n       : in std_logic;
            pos_x       : in std_logic_vector (8 downto 0);
            pos_y       : in std_logic_vector (8 downto 0);
            nes_r       : in std_logic_vector (3 downto 0);
            nes_g       : in std_logic_vector (3 downto 0);
            nes_b       : in std_logic_vector (3 downto 0);
            h_sync      : out std_logic;
            v_sync      : out std_logic;
            r           : out std_logic_vector(3 downto 0);
            g           : out std_logic_vector(3 downto 0);
            b           : out std_logic_vector(3 downto 0)
    );
end vga_ctl;

architecture rtl of vga_ctl is

component counter_register
    generic (
        dsize : integer := 8
    );
    port (  clk         : in std_logic;
            rst_n       : in std_logic;
            ce_n        : in std_logic;
            q           : out std_logic_vector(dsize - 1 downto 0)
    );
end component;

constant COLOR_SIZE         : integer := 12;
constant VGA_SIZE           : integer := 10;

constant VGA_W    : integer := 640;
constant VGA_H    : integer := 480;
constant VGA_W_MAX    : integer := 800;
constant VGA_H_MAX    : integer := 525;
constant H_FP    : integer := 16;
constant H_SP    : integer := 96;
constant H_BP    : integer := 48;
constant V_FP    : integer := 10;
constant V_SP    : integer := 2;
constant V_BP    : integer := 33;

subtype bit_data is std_logic_vector (COLOR_SIZE -1 downto 0);
type bit_array is array (0 to 256*256 - 1) of bit_data;
signal nes_screen : bit_array := (others => (others => '0'));

signal vga_en_n      : std_logic;
signal vga_x_res_n   : std_logic;
signal vga_y_en_n    : std_logic;
signal vga_y_res_n   : std_logic;
signal vga_x            : std_logic_vector(VGA_SIZE - 1 downto 0);
signal vga_y            : std_logic_vector(VGA_SIZE - 1 downto 0);

begin

    p_write : process (pos_x, pos_y)
    begin
        if (pos_x(8) = '0' and pos_y(8) = '0') then
            nes_screen(conv_integer(pos_x(7 downto 0) & pos_y(7 downto 0))) <= 
                nes_r & nes_g & nes_b;
        end if;
    end process;

    vga_en_n <= '0';
    vga_x_inst : counter_register generic map (VGA_SIZE)
            port map (vga_clk, vga_x_res_n, vga_en_n, vga_x);
    vga_y_inst : counter_register generic map (VGA_SIZE)
            port map (vga_clk, vga_y_res_n, vga_y_en_n, vga_y);


    p_vga_out : process (rst_n, vga_clk)
    begin
        if (rst_n = '0') then
            vga_x_res_n <= '0';
            vga_y_res_n <= '0';
        else
            if (vga_clk'event) then
                --x pos reset.
                if (vga_clk = '1' and 
                        vga_x = conv_std_logic_vector(VGA_W_MAX, VGA_SIZE)) then
                    vga_x_res_n <= '0';

                    --y pos reset.
                    if (vga_y = conv_std_logic_vector(VGA_H_MAX, VGA_SIZE)) then
                        vga_y_res_n <= '0';
                    else
                        vga_y_res_n <= '1';
                    end if;
                else
                    vga_x_res_n <= '1';
                    vga_y_res_n <= '1';
                end if;
            end if; --if (vga_clk'event) then

            if (vga_clk'event and vga_clk = '0') then
                --y pos increment.
                if (vga_x = conv_std_logic_vector(VGA_W_MAX, VGA_SIZE)) then
                    vga_y_en_n <= '0';
                else
                    vga_y_en_n <= '1';
                end if;
            end if; --if (vga_clk'event) then

            if (vga_clk'event and vga_clk = '1') then
                -- fp = 16, sp = 96, bp = 48.
                if (vga_x >= conv_std_logic_vector(VGA_W + H_FP, VGA_SIZE) and 
                    vga_x < conv_std_logic_vector(VGA_W + H_FP + H_SP, VGA_SIZE)) then
                    h_sync <= '0';
                else
                    h_sync <= '1';
                end if;

                if (vga_y >= conv_std_logic_vector(VGA_H + V_FP, VGA_SIZE) and 
                    vga_y < conv_std_logic_vector(VGA_H + V_FP + V_SP, VGA_SIZE)) then
                    v_sync <= '0';
                else
                    v_sync <= '1';
                end if;
            end if; --if (vga_clk'event and vga_clk = '1') then

        end if;--if (rst_n = '0') then
    end process;
end rtl;




-------------------------------------------------------
-------------------------------------------------------
-----------  dummy vga outpu device. ------------------
-------------------------------------------------------
-------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.conv_integer;

entity vga_device is 
        port (  
            vga_clk     : in std_logic;
            h_sync      : in std_logic;
            v_sync      : in std_logic;
            r           : in std_logic_vector(3 downto 0);
            g           : in std_logic_vector(3 downto 0);
            b           : in std_logic_vector(3 downto 0)
            );
end vga_device;

architecture rtl of vga_device is


begin

end rtl;

