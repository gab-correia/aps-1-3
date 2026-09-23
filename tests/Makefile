# Testes cocotb
#   make -C tests                 -> roda reg_file e arith_machine
#   make -C tests reg_file        -> so o reg_file
#   make -C tests arith_machine   -> so a arith_machine
SIM ?= ghdl
TOPLEVEL_LANG = vhdl
SRC = $(CURDIR)/../src

DUT ?= all

ifeq ($(DUT),reg_file)
VHDL_SOURCES = $(SRC)/reg_file.vhd
else ifeq ($(DUT),arith_machine)
VHDL_SOURCES = $(SRC)/reg_file.vhd $(SRC)/ula.vhd $(SRC)/sign_extender.vhd \
               $(SRC)/zero_extender.vhd $(SRC)/arith_machine.vhd
endif

ifeq ($(DUT),all)
.PHONY: all reg_file arith_machine clean
all: reg_file arith_machine
reg_file arith_machine:
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
