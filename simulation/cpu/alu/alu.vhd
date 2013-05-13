library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity alu is 
    port (  a, b, m     : in std_logic_vector (7 downto 0);
            o           : out std_logic_vector (7 downto 0);
            cin         : in std_logic;
            cout        : out std_logic;
            n, v, z     :   out std_logic
        );
end alu;

architecture rtl of alu is
    component adc
        port (  a, b    : in std_logic_vector (7 downto 0);
                sum       : out std_logic_vector (7 downto 0);
                cin         : in std_logic;
                cout        : out std_logic;
                n, v, z : out std_logic
                );
    end component;
    signal adc_o : std_logic_vector (7 downto 0);
    signal adc_cout, adc_n, adc_v, adc_z : std_logic;
begin
    adc_port : adc port map (a, b, adc_o, cin, adc_cout, adc_n, adc_v, adc_z);

    o <= adc_o when (m(7 downto 5) = "011") else
         --adc_o when (m(7 downto 5) = "011") else
        "ZZZZZZZZ";
    n <= adc_n when (m(7 downto 5) = "011") else
         --adc_o when (m(7 downto 5) = "011") else
        'Z';
    v <= adc_v when (m(7 downto 5) = "011") else
         --adc_o when (m(7 downto 5) = "011") else
        'Z';
    z <= adc_z when (m(7 downto 5) = "011") else
         --adc_o when (m(7 downto 5) = "011") else
        'Z';
    cout <=    adc_cout when (m(7 downto 5) = "011") else
         --adc_o when (m(7 downto 5) = "011") else
        'Z';

--    p : process (a, b, m, cin)
--    begin
----    if m(7 downto 5) = "011" then
----        ---case adc.
----        n <= adc_n;
----        v <= adc_v;
----        z <= adc_z;
----        cout <= adc_cout;
----    end if;
--
--    case m(7 downto 5) is
--        when "011" =>
            ---case adc.
--            o <= adc_o;
--            n <= adc_n;
--            v <= adc_v;
--            z <= adc_z;
--            cout <= adc_cout;
--        when others =>
--            o <= "ZZZZZZZZ";
--            n <= 'Z';
--            v <= 'Z';
--            z <= 'Z';
--            cout <= 'Z';
--    end case;
--    end process;

end rtl;

