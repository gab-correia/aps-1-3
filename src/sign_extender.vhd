library ieee;
use ieee.std_logic_1164.all;

entity sign_extender is
    port (
        a : in  std_logic_vector(15 downto 0);
        y : out std_logic_vector(31 downto 0)
    );
end entity sign_extender;

architecture behv1 of sign_extender is
begin
    y <= (31 downto 16 => a(15)) & a;
end architecture behv1;
