PROJECT=mojo_top

all: $(PROJECT).bit

FPGA_TARGET ?= xc6slx9-2-tqg144


%.bit: %-routed.ncd
	cd build; if test -f $<; then bitgen -b -l -w -g 'Binary:yes' -g 'Compress' $< $(PROJECT); fi
	cp build/$(PROJECT).bin $(PROJECT).$(FPGA_TARGET).bin

%.ncd: %.xdl
	#echo MOGGLE
	# -xdl -xdl2ncd $<

%-routed.ncd: %.ncd
	cd build; par -w $< $@

%.ncd: %.ngd
	cd build; map -w $<

%.ngd: %.ngc
	cp mojo.ucf build/$(PROJECT).$(FPGA_TARGET).ucf
	cd build; ngdbuild -uc $(PROJECT).$(FPGA_TARGET).ucf  $(@:.ngd=.ngc)

%.ngc: %.xst
	cd build; xst -ifn $<

%.xst: %.prj
	echo run > build/$@
	echo -ifn $< >> build/$@
	echo -top $(basename $<) >> build/$@
	echo -ifmt MIXED >> build/$@
	echo -opt_mode SPEED >> build/$@
	echo -opt_level 1 >> build/$@
	echo -ofn $(<:.prj=.ngc) >> build/$@
	echo -p $(FPGA_TARGET) >> build/$@
	cat mojo.xst >> build/$@
%.prj: src/%.v
	for i in `ls src`; do \
	     echo "verilog $(notdir $(basename $<)) ../src/$$i" >> build/$@; \
	done

load: $(PROJECT).$(FPGA_TARGET).bin
	mojo.py -r $(PROJECT).$(FPGA_TARGET).bin

reset:
	mojo.py -e

clean:
	rm -rf build/*
	rm -f $(PROJECT).$(FPGA_TARGET).bin
	rm -rf _xmsgs
