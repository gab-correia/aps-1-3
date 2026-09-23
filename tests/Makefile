# Testes cocotb
#   make -C tests                 -> roda todos
#   make -C tests reg_file        -> so o reg_file
#   make -C tests arith_machine   -> so a arith_machine
#   make -C tests toplevel_mips   -> so o toplevel_mips
SIM ?= ghdl
TOPLEVEL_LANG = vhdl
SRC = $(CURDIR)/../src

DUT ?= all

ifeq ($(DUT),reg_file)
VHDL_SOURCES = $(SRC)/reg_file.vhd
else ifeq ($(DUT),arith_machine)
VHDL_SOURCES = $(SRC)/reg_file.vhd $(SRC)/ula.vhd $(SRC)/sign_extender.vhd \
               $(SRC)/zero_extender.vhd $(SRC)/arith_machine.vhd
else ifeq ($(DUT),toplevel_mips)
VHDL_SOURCES = $(SRC)/reg_file.vhd $(SRC)/ula.vhd $(SRC)/sign_extender.vhd \
               $(SRC)/zero_extender.vhd $(SRC)/arith_machine.vhd $(SRC)/toplevel_mips.vhd
endif

ifeq ($(DUT),all)
.PHONY: all reg_file arith_machine toplevel_mips clean
all: reg_file arith_machine toplevel_mips
reg_file arith_machine toplevel_mips:
	$(MAKE) DUT=$@ SIM_BUILD=sim_build/$@ COCOTB_RESULTS_FILE=results_$@.xml
clean:
	rm -rf sim_build results*.xml __pycache__
else
# cocotb 1.x
TOPLEVEL = $(DUT)
MODULE   = test_$(DUT)
# cocotb 2.x
COCOTB_TOPLEVEL     = $(DUT)
COCOTB_TEST_MODULES = test_$(DUT)

include $(shell cocotb-config --makefiles)/Makefile.sim
endif
