-- ===== ula_fullAdder.vhd =====
library ieee;
use ieee.std_logic_1164.all;

entity fullAdder is
    port (
        x, y, cin : in  std_logic;
        s         : out std_logic;
        cout      : out std_logic
    );
end entity;

architecture rtl of fullAdder is
begin
    s    <= x xor y xor cin;
    cout <= (x and y) or (x and cin) or (y and cin);
end architecture;


-- ===== ula_logicUnit.vhd =====
library ieee;
use ieee.std_logic_1164.all;

--   c = "00" -> AND
--   c = "01" -> OR
--   c = "10" -> XOR
--   c = "11" -> NOR
entity logicUnit is
    port (
        x, y : in  std_logic;
        c    : in  std_logic_vector(1 downto 0);
        res  : out std_logic
    );
end entity;

architecture rtl of logicUnit is
begin
    with c select
        res <= (x and y) when "00",
               (x or  y) when "01",
               (x xor y) when "10",
               (x nor y) when others;
end architecture;


-- ===== ula_1bit.vhd =====
library ieee;
use ieee.std_logic_1164.all;

entity ula_1bit is
    port (
        a, b, cin : in  std_logic;
        control   : in  std_logic_vector(2 downto 0);
        outi      : out std_logic;
        cout      : out std_logic
    );
end entity;

architecture rtl of ula_1bit is
    signal b_in   : std_logic;
    signal soma   : std_logic;
    signal logica : std_logic;
begin
    b_in <= b xor control(0);

    FA : entity work.fullAdder
        port map (x => a, y => b_in, cin => cin, s => soma, cout => cout);

    LU : entity work.logicUnit
        port map (x => a, y => b, c => control(1 downto 0), res => logica);

    outi <= soma when control(2) = '0' else logica;
end architecture;

-- ===== ula_32bits.vhd =====
library ieee;
use ieee.std_logic_1164.all;

entity ula_32bits is
port(
    a, b      : in  std_logic_vector(31 downto 0);
    control   : in  std_logic_vector( 2 downto 0);
    outi      : out std_logic_vector(31 downto 0);
    cout      : out std_logic;
    cout30    : out std_logic);  -- carry que entra no bit 31, usado no overflow
end ula_32bits;
architecture behv1 of ula_32bits is
component ula_1bit is
port(
    a, b, cin : in  std_logic;
    control   : in  std_logic_vector(2 downto 0);
    outi, cout: out std_logic
);
end component;

signal carry : std_logic_vector(32 downto 0);
begin
    carry(0) <= control(0);

    GEN_ULA : for i in 0 to 31 generate
        U : ula_1bit
            port map (
                a       => a(i),
                b       => b(i),
                cin     => carry(i),
                control => control,
                outi    => outi(i),
                cout    => carry(i+1)
            );
    end generate;

    cout   <= carry(32);
    cout30 <= carry(31);
end behv1;

-- ===== ula_flags.vhd =====
library ieee;
use ieee.std_logic_1164.all;

entity flags is
port(
    c_out31      : in  std_logic;
    c_out30      : in  std_logic;
    ula_out      : in  std_logic_vector(31 downto 0);
    flag_neg     : out std_logic;
    flag_zero    : out std_logic;
    flag_overflow: out std_logic
);
end flags;

architecture behv1 of flags is
begin
    flag_neg <= ula_out(31);

    flag_zero <= '1' when ula_out = x"00000000" else '0';

    flag_overflow <= c_out31 xor c_out30;
end behv1;

-- ===== ula.vhd =====
library ieee;
use ieee.std_logic_1164.all;
-------------------------------------------------
--   control = "000" -> ADD
--   control = "001" -> SUB
--   control = "100" -> AND
--   control = "101" -> OR
--   control = "110" -> XOR
--   control = "111" -> NOR
entity ULA is
  port (
    A             : in  std_logic_vector(31 downto 0);
    B             : in  std_logic_vector(31 downto 0);
    control       : in  std_logic_vector(2 downto 0);
    result        : out std_logic_vector(31 downto 0);
    flag_neg      : out std_logic;
    flag_zero     : out std_logic;
    flag_overflow : out std_logic
  );
end entity ULA;
-------------------------------------------------
architecture behv1 of ULA is
component ula_32bits is
port(
    a, b      : in  std_logic_vector(31 downto 0);
    control   : in  std_logic_vector( 2 downto 0);
    outi      : out std_logic_vector(31 downto 0);
    cout      : out std_logic;
    cout30    : out std_logic);
end component;

component flags is
port(
    c_out31      : in  std_logic;
    c_out30      : in  std_logic;
    ula_out      : in  std_logic_vector(31 downto 0);
    flag_neg     : out std_logic;
    flag_zero    : out std_logic;
    flag_overflow: out std_logic
);
end component;

signal res    : std_logic_vector(31 downto 0);
signal c31    : std_logic;
signal c30    : std_logic;
begin
    U_ULA32 : ula_32bits
        port map (
            a       => A,
            b       => B,
            control => control,
            outi    => res,
            cout    => c31,
            cout30  => c30
        );

    U_FLAGS : flags
        port map (
            c_out31       => c31,
            c_out30       => c30,
            ula_out       => res,
            flag_neg      => flag_neg,
            flag_zero     => flag_zero,
            flag_overflow => flag_overflow
        );

    result <= res;
end behv1;


