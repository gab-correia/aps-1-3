# Testes cocotb - rodar com: make -C tests
SIM ?= ghdl
TOPLEVEL_LANG = vhdl

SRC = $(CURDIR)/../src
VHDL_SOURCES = $(SRC)/reg_file.vhd

# cocotb 1.x
TOPLEVEL = reg_file
MODULE   = test_reg_file
# cocotb 2.x
COCOTB_TOPLEVEL     = reg_file
COCOTB_TEST_MODULES = test_reg_file

include $(shell cocotb-config --makefiles)/Makefile.sim
