library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity alu is 
    port (  a, b, m     : in std_logic_vector (7 downto 0);
            o           : out std_logic_vector (7 downto 0);
            cin         : in std_logic;
            cout        : out std_logic;
            n, v, z     :   out std_logic;
            reset       :   out std_logic
        );
end alu;

architecture rtl of alu is
    component alu_adc
        port (  a, b    : in std_logic_vector (7 downto 0);
                sum       : out std_logic_vector (7 downto 0);
                cin         : in std_logic;
                cout        : out std_logic;
                n, v, z : out std_logic
                );
    end component;
    component alu_and
        port (  a, b    : in std_logic_vector (7 downto 0);
                and_o     : out std_logic_vector (7 downto 0);
                n, z    : out std_logic
                );
    end component;
    signal adc_o : std_logic_vector (7 downto 0);
    signal adc_cout, adc_n, adc_v, adc_z : std_logic;
    signal and_o : std_logic_vector (7 downto 0);
    signal and_n, and_z : std_logic;
begin
    adc_port : alu_adc port map (a, b, adc_o, cin, adc_cout, adc_n, adc_v, adc_z);
    and_port : alu_and port map (a, b, and_o, and_n, and_z);

    p : process (a, b, m, cin, adc_o, and_o)
    begin
    -- m is form of  "aaabbbcc"
    if m(1 downto 0) = "01" then
    -- case cc == 01
        case m(7 downto 5) is
            when "011" =>
              ---case adc.
                o <= adc_o;
                n <= adc_n;
                v <= adc_v;
                z <= adc_z;
                cout <= adc_cout;
            when "001" =>
              ---case and.
                o <= and_o;
                n <= and_n;
                z <= and_z;
            when others =>
                reset <= '1';
        end case;
    elsif m(1 downto 0) = "10" then
    -- case cc == 10
    elsif m(1 downto 0) = "00" then
    -- case cc == 00
    else
        reset <= '1';
    end if;

    end process;

end rtl;

