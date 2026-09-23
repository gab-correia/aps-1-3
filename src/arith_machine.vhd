library ieee;
use ieee.std_logic_1164.all;

entity arith_machine is
port(
  instr     : in  std_logic_vector(31 downto 0);
  rd_src    : in  std_logic;
  wr_enable : in  std_logic;
  ula_src2  : in  std_logic_vector(1 downto 0);
  ula_op    : in  std_logic_vector(2 downto 0);
  clk       : in  std_logic;
  reset     : in  std_logic;
  overflow  : out std_logic;
  zero      : out std_logic;
  negative  : out std_logic;
  ula_out   : out std_logic_vector(31 downto 0)
);
end arith_machine;

architecture behv1 of arith_machine is
    signal w_addr   : std_logic_vector(4 downto 0);
    signal a_data   : std_logic_vector(31 downto 0);
    signal b_data   : std_logic_vector(31 downto 0);
    signal imm_sext : std_logic_vector(31 downto 0);
    signal imm_zext : std_logic_vector(31 downto 0);
    signal ula_b    : std_logic_vector(31 downto 0);
    signal res      : std_logic_vector(31 downto 0);
begin
    -- mux do registrador de escrita: 0 -> rd, 1 -> rt
    w_addr <= instr(15 downto 11) when rd_src = '0' else instr(20 downto 16);

    RF : entity work.reg_file
        port map (
            clk    => clk,
            rst    => reset,
            A_addr => instr(25 downto 21),
            B_addr => instr(20 downto 16),
            W_addr => w_addr,
            W_data => res,
            W_en   => wr_enable,
            A_data => a_data,
            B_data => b_data
        );

    SEXT : entity work.sign_extender
        port map (a => instr(15 downto 0), y => imm_sext);

    ZEXT : entity work.zero_extender
        port map (a => instr(15 downto 0), y => imm_zext);

    -- mux da entrada B da ULA
    with ula_src2 select
        ula_b <= b_data   when "00",
                 imm_sext when "01",
                 imm_zext when "10",
                 (others => '0') when others;

    U_ULA : entity work.ula
        port map (
            A             => a_data,
            B             => ula_b,
            control       => ula_op,
            result        => res,
            flag_neg      => negative,
            flag_zero     => zero,
            flag_overflow => overflow
        );

    ula_out <= res;
end architecture behv1;
