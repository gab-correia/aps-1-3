import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

ADD, SUB, AND, OR = 0b000, 0b001, 0b100, 0b101
REG, SEXT, ZEXT = 0b00, 0b01, 0b10


def r_type(rs, rt, rd):
    return (rs << 21) | (rt << 16) | (rd << 11)


def i_type(rs, rt, imm):
    return (rs << 21) | (rt << 16) | (imm & 0xFFFF)


async def setup(dut):
    """Liga o clock e reseta o banco."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    dut.instr.value = 0
    dut.rd_src.value = 0
    dut.wr_enable.value = 0
    dut.ula_src2.value = 0
    dut.ula_op.value = 0
    dut.reset.value = 1
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    await Timer(1, "ns")


async def executa(dut, instr, rd_src, src2, op, wr=1):
    """Aplica uma instrucao, le ula_out e da um pulso de clock (escreve se wr=1)."""
    dut.instr.value = instr
    dut.rd_src.value = rd_src
    dut.ula_src2.value = src2
    dut.ula_op.value = op
    dut.wr_enable.value = wr
    await Timer(1, "ns")
    res = int(dut.ula_out.value)
    await RisingEdge(dut.clk)
    dut.wr_enable.value = 0
    await Timer(1, "ns")
    return res


async def le(dut, reg):
    """Le um registrador fazendo reg + $0 sem escrever."""
    return await executa(dut, r_type(reg, 0, 0), 0, REG, ADD, wr=0)


@cocotb.test()
async def test_addi(dut):
    """addi $1, $0, 5 e addi $2, $0, -3."""
    await setup(dut)
    assert await executa(dut, i_type(0, 1, 5), 1, SEXT, ADD) == 5
    assert await executa(dut, i_type(0, 2, -3), 1, SEXT, ADD) == 0xFFFFFFFD
    assert await le(dut, 1) == 5
    assert await le(dut, 2) == 0xFFFFFFFD


@cocotb.test()
async def test_add_sub_registradores(dut):
    """add $3, $1, $2 e sub $4, $1, $2."""
    await setup(dut)
    await executa(dut, i_type(0, 1, 10), 1, SEXT, ADD)
    await executa(dut, i_type(0, 2, 3), 1, SEXT, ADD)
    assert await executa(dut, r_type(1, 2, 3), 0, REG, ADD) == 13
    assert await executa(dut, r_type(1, 2, 4), 0, REG, SUB) == 7
    assert await le(dut, 3) == 13
    assert await le(dut, 4) == 7


@cocotb.test()
async def test_zero_extender(dut):
    """ori $5, $0, 0xFFFF completa com zeros; addi com 0xFFFF estende o sinal."""
    await setup(dut)
    assert await executa(dut, i_type(0, 5, 0xFFFF), 1, ZEXT, OR) == 0x0000FFFF
    assert await executa(dut, i_type(0, 6, 0xFFFF), 1, SEXT, ADD) == 0xFFFFFFFF


@cocotb.test()
async def test_r0_sempre_zero(dut):
    """addi $0, $0, 7 nao altera R0."""
    await setup(dut)
    await executa(dut, i_type(0, 0, 7), 1, SEXT, ADD)
    assert await le(dut, 0) == 0


@cocotb.test()
async def test_wr_enable(dut):
    """Com wr_enable = 0 o registrador nao muda."""
    await setup(dut)
    await executa(dut, i_type(0, 7, 42), 1, SEXT, ADD, wr=0)
    assert await le(dut, 7) == 0


@cocotb.test()
async def test_flags(dut):
    """zero e negative."""
    await setup(dut)
    await executa(dut, i_type(0, 1, 1), 1, SEXT, ADD)
    dut.instr.value = r_type(1, 1, 0)
    dut.ula_src2.value = REG
    dut.ula_op.value = SUB
    await Timer(1, "ns")
    assert int(dut.zero.value) == 1
    assert int(dut.negative.value) == 0
    dut.instr.value = i_type(0, 0, -1)
    dut.ula_src2.value = SEXT
    dut.ula_op.value = ADD
    await Timer(1, "ns")
    assert int(dut.zero.value) == 0
    assert int(dut.negative.value) == 1
