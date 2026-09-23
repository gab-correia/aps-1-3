library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- KEY(0): executa a instrucao atual e avanca o cnt
-- KEY(1): reset (zera cnt e banco de registradores)
-- LEDR  : ula_out(9 downto 0) da instrucao atual
-- HEX0  : cnt em hexadecimal
entity toplevel_mips is
    port (
        CLOCK_50 : in  std_logic;
        KEY      : in  std_logic_vector(3 downto 0);
        SW       : in  std_logic_vector(9 downto 0);
        LEDR     : out std_logic_vector(9 downto 0);
        HEX0     : out std_logic_vector(6 downto 0)
    );
end entity toplevel_mips;

architecture behv1 of toplevel_mips is
    signal step      : std_logic;
    signal reset     : std_logic;
    signal cnt       : unsigned(3 downto 0) := (others => '0');
    signal instr     : std_logic_vector(31 downto 0);
    signal rd_src    : std_logic;
    signal wr_enable : std_logic;
    signal ula_src2  : std_logic_vector(1 downto 0);
    signal ula_op    : std_logic_vector(2 downto 0);
    signal ula_out   : std_logic_vector(31 downto 0);
begin
    step  <= not KEY(0);
    reset <= not KEY(1);

    process(step, reset)
    begin
        if reset = '1' then
            cnt <= (others => '0');
        elsif rising_edge(step) then
            cnt <= cnt + 1;
        end if;
    end process;

    -- programa
    -- I-type: rd_src='1' (escreve em rt), ula_src2="01" sign ext / "10" zero ext
    -- R-type: rd_src='0' (escreve em rd), ula_src2="00" (B = rt)
    -- ula_op: 000 ADD, 001 SUB, 100 AND, 101 OR, 110 XOR, 111 NOR
    process(cnt)
    begin
        instr     <= (others => '0');
        rd_src    <= '0';
        wr_enable <= '1';
        ula_src2  <= "00";
        ula_op    <= "000";
        case to_integer(cnt) is
            when 0 =>  -- addi $1, $0, 5       LEDR = 0000000101
                instr <= x"20010005"; rd_src <= '1'; ula_src2 <= "01"; ula_op <= "000";
            when 1 =>  -- addi $2, $0, 3       LEDR = 0000000011
                instr <= x"20020003"; rd_src <= '1'; ula_src2 <= "01"; ula_op <= "000";
            when 2 =>  -- add  $3, $1, $2      LEDR = 0000001000 (8)
                instr <= x"00221820"; ula_op <= "000";
            when 3 =>  -- sub  $4, $1, $2      LEDR = 0000000010 (2)
                instr <= x"00222022"; ula_op <= "001";
            when 4 =>  -- and  $5, $1, $2      LEDR = 0000000001 (1)
                instr <= x"00222824"; ula_op <= "100";
            when 5 =>  -- or   $6, $1, $2      LEDR = 0000000111 (7)
                instr <= x"00223025"; ula_op <= "101";
            when 6 =>  -- xor  $7, $1, $2      LEDR = 0000000110 (6)
                instr <= x"00223826"; ula_op <= "110";
            when 7 =>  -- nor  $8, $1, $2      LEDR = 1111111000 (~7)
                instr <= x"00224027"; ula_op <= "111";
            when 8 =>  -- ori  $9, $0, 0x3F0   LEDR = 1111110000
                instr <= x"340903F0"; rd_src <= '1'; ula_src2 <= "10"; ula_op <= "101";
            when 9 =>  -- addi $10, $0, -1     LEDR = 1111111111
                instr <= x"200AFFFF"; rd_src <= '1'; ula_src2 <= "01"; ula_op <= "000";
            when 10 => -- add  $11, $3, $4     LEDR = 0000001010 (8 + 2)
                instr <= x"00645820"; ula_op <= "000";
            when others => -- nada             LEDR = 0000000000
                wr_enable <= '0';
        end case;
    end process;

    AM : entity work.arith_machine
        port map (
            instr     => instr,
            rd_src    => rd_src,
            wr_enable => wr_enable,
            ula_src2  => ula_src2,
            ula_op    => ula_op,
            clk       => step,
            reset     => reset,
            overflow  => open,
            zero      => open,
            negative  => open,
            ula_out   => ula_out
        );

    LEDR <= ula_out(9 downto 0);

    -- 7 segmentos ativo em 0 (gfedcba)
    process(cnt)
    begin
        case cnt is
            when x"0" => HEX0 <= "1000000";
            when x"1" => HEX0 <= "1111001";
            when x"2" => HEX0 <= "0100100";
            when x"3" => HEX0 <= "0110000";
            when x"4" => HEX0 <= "0011001";
            when x"5" => HEX0 <= "0010010";
            when x"6" => HEX0 <= "0000010";
            when x"7" => HEX0 <= "1111000";
            when x"8" => HEX0 <= "0000000";
            when x"9" => HEX0 <= "0010000";
            when x"A" => HEX0 <= "0001000";
            when x"B" => HEX0 <= "0000011";
            when x"C" => HEX0 <= "1000110";
            when x"D" => HEX0 <= "0100001";
            when x"E" => HEX0 <= "0000110";
            when others => HEX0 <= "0001110";  -- F
        end case;
    end process;
end architecture behv1;
