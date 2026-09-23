# APS1 - DESCOMP

Projeto Quartus (DE0-CV, Cyclone V 5CEBA4F23C7).

## Estrutura

- `src/` - fontes VHDL
- `tests/` - testes cocotb

## Rodar os testes

```bash
pip install cocotb pytest
make -C tests
```

Simulador padrão: GHDL (`sudo apt install ghdl`).
