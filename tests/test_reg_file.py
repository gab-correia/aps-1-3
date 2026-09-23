import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


async def setup(dut):
    """Liga o clock e reseta o banco."""
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    dut.W_en.value = 0
    dut.W_addr.value = 0
    dut.W_data.value = 0
    dut.A_addr.value = 0
    dut.B_addr.value = 0
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)


async def write(dut, addr, data):
    dut.W_addr.value = addr
    dut.W_data.value = data
    dut.W_en.value = 1
    await RisingEdge(dut.clk)
    dut.W_en.value = 0
    await Timer(1, "ns")


async def read(dut, a, b):
    dut.A_addr.value = a
    dut.B_addr.value = b
    await Timer(1, "ns")
    return int(dut.A_data.value), int(dut.B_data.value)


@cocotb.test()
async def test_reset(dut):
    """Depois do reset todos os registradores valem 0."""
    await setup(dut)
    for i in range(32):
        a, b = await read(dut, i, i)
        assert a == 0 and b == 0, f"R{i} deveria ser 0"


@cocotb.test()
async def test_write_read(dut):
    """Escreve em R1..R31 e le pelas portas A e B."""
    await setup(dut)
    valores = {i: random.getrandbits(32) for i in range(1, 32)}
    for i, v in valores.items():
        await write(dut, i, v)
    for i, v in valores.items():
        a, b = await read(dut, i, 32 - i if i > 0 else 0)
        assert a == v, f"A: R{i} = {a:#x}, esperado {v:#x}"
        assert b == valores[32 - i], f"B: R{32-i} = {b:#x}, esperado {valores[32-i]:#x}"


@cocotb.test()
async def test_r0_sempre_zero(dut):
    """Escrever em R0 nao tem efeito."""
    await setup(dut)
    await write(dut, 0, 0xDEADBEEF)
    a, b = await read(dut, 0, 0)
    assert a == 0 and b == 0, "R0 deveria continuar 0"


@cocotb.test()
async def test_w_en_desligado(dut):
    """Com W_en = 0 nada e escrito."""
    await setup(dut)
    await write(dut, 5, 0x12345678)
    dut.W_addr.value = 5
    dut.W_data.value = 0xFFFFFFFF
    dut.W_en.value = 0
    await RisingEdge(dut.clk)
    a, _ = await read(dut, 5, 0)
    assert a == 0x12345678, f"R5 mudou sem W_en: {a:#x}"


@cocotb.test()
async def test_reset_limpa(dut):
    """Reset zera registradores ja escritos."""
    await setup(dut)
    await write(dut, 7, 0xCAFE)
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    a, _ = await read(dut, 7, 0)
    assert a == 0, f"R7 deveria ser 0 apos reset: {a:#x}"


@cocotb.test()
async def test_reset_assincrono(dut):
    """Reset zera o banco sem precisar de borda de clock."""
    await setup(dut)
    await write(dut, 9, 0xBEEF)
    dut.rst.value = 1
    await Timer(1, "ns")
    a, _ = await read(dut, 9, 0)
    dut.rst.value = 0
    assert a == 0, f"R9 deveria ser 0 logo apos rst: {a:#x}"
