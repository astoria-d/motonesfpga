library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity alu is 
    port (  d1, d2, mode    : in std_logic_vector (7 downto 0);
            q               : out std_logic_vector (7 downto 0);
            cry_in          : in std_logic;
            cry_out         : out std_logic;
            neg, ovf, zero  :   out std_logic
        );
end alu;

architecture rtl of alu is
    component alu_adc
        port (  d1, d2      : in std_logic_vector (7 downto 0);
                q           : out std_logic_vector (7 downto 0);
                cry_in          : in std_logic;
                cry_out         : out std_logic;
                neg, ovf, zero  : out std_logic
                );
    end component;

    component alu_and
        port (  d1, d2      : in std_logic_vector (7 downto 0);
                q           : out std_logic_vector (7 downto 0);
                neg, zero   : out std_logic
                );
    end component;

    signal adc_out : std_logic_vector (7 downto 0);
    signal adc_cry_out, adc_n, adc_v, adc_z : std_logic;
    signal and_out : std_logic_vector (7 downto 0);
    signal and_n, and_z : std_logic;

begin
    adc_port : alu_adc port map (d1, d2, adc_out, cry_in, 
            adc_cry_out, adc_n, adc_v, adc_z);
    and_port : alu_and port map (d1, d2, and_out, and_n, and_z);

    p : process (adc_out, adc_cry_out, adc_n, adc_v, adc_z, and_out, and_n, and_z)
    begin
    -- mode is form of  "aaabbbcc"
    if mode(1 downto 0) = "01" then
    -- case cc == 01
        case mode(7 downto 5) is
            when "011" =>
              ---case adc.
                q <= adc_out;
                neg <= adc_n;
                ovf <= adc_v;
                zero <= adc_z;
                cry_out <= adc_cry_out;
            when "001" =>
              ---case and.
                q <= and_out;
                neg <= and_n;
                zero <= and_z;
            when others =>
                null;
        end case;
    elsif mode(1 downto 0) = "10" then
    -- case cc == 10
    elsif mode(1 downto 0) = "00" then
    -- case cc == 00
    else
        null;
    end if;

    end process;

end rtl;

