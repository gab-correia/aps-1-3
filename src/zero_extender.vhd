library ieee;
use ieee.std_logic_1164.all;

entity zero_extender is
    port (
        a : in  std_logic_vector(15 downto 0);
        y : out std_logic_vector(31 downto 0)
    );
end entity zero_extender;

architecture behv1 of zero_extender is
begin
    y <= x"0000" & a;
end architecture behv1;
