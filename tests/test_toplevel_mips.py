import re
from pathlib import Path

import cocotb
from cocotb.triggers import Timer

# (instrucao, valor esperado em LEDR)
PROGRAMA = [
    ("addi $1, $0, 5", 0b0000000101),
    ("addi $2, $0, 3", 0b0000000011),
    ("add  $3, $1, $2", 0b0000001000),
    ("sub  $4, $1, $2", 0b0000000010),
    ("and  $5, $1, $2", 0b0000000001),
    ("or   $6, $1, $2", 0b0000000111),
    ("xor  $7, $1, $2", 0b0000000110),
    ("nor  $8, $1, $2", 0b1111111000),
    ("ori  $9, $0, 0x3F0", 0b1111110000),
    ("addi $10, $0, -1", 0b1111111111),
    ("add  $11, $3, $4", 0b0000001010),
    ("nada", 0),
]

FUNCT = {"add": 0x20, "sub": 0x22, "and": 0x24, "or": 0x25, "xor": 0x26, "nor": 0x27}
OPCODE = {"addi": 0x08, "ori": 0x0D}


def codifica(asm):
    op, *args = asm.replace(",", " ").split()
    regs = [int(a[1:]) for a in args if a.startswith("$")]
    if op in FUNCT:
        rd, rs, rt = regs
        return (rs << 21) | (rt << 16) | (rd << 11) | FUNCT[op]
    rt, rs = regs
    return (OPCODE[op] << 26) | (rs << 21) | (rt << 16) | (int(args[2], 0) & 0xFFFF)


def test_codificacao():
    """Os hex do toplevel_mips.vhd batem com a codificacao MIPS."""
    vhd = (Path(__file__).parent / "../src/toplevel_mips.vhd").read_text()
    hexes = [int(h, 16) for h in re.findall(r'instr <= x"([0-9A-Fa-f]{8})"', vhd)]
    esperado = [codifica(asm) for asm, _ in PROGRAMA if asm != "nada"]
    assert hexes == esperado, [f"{h:08X}" for h in hexes]


async def aperta(dut, botao):
    """Aperta e solta KEY(botao) (ativo em 0)."""
    dut.KEY.value = 0b1111 & ~(1 << botao)
    await Timer(10, "ns")
    dut.KEY.value = 0b1111
    await Timer(10, "ns")


@cocotb.test()
async def test_programa(dut):
    """Reset, depois aperta KEY(0) e confere LEDR e HEX0 a cada passo."""
    test_codificacao()
    dut.CLOCK_50.value = 0
    dut.SW.value = 0
    dut.KEY.value = 0b1111
    await Timer(1, "ns")
    await aperta(dut, 1)

    for cnt, (asm, leds) in enumerate(PROGRAMA):
        got = int(dut.LEDR.value)
        assert got == leds, f"cnt={cnt} {asm}: LEDR={got:010b}, esperado {leds:010b}"
        await aperta(dut, 0)

    # reset: volta pro cnt 0 (addi $1, $0, 5 -> LEDR = 5)
    await aperta(dut, 1)
    assert int(dut.HEX0.value) == 0b1000000, "HEX0 deveria mostrar 0"
    assert int(dut.LEDR.value) == 5

