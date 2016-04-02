ASMSOURCES =	sample1.asm

OBJECTS	=	$(ASMSOURCES:.asm=.o)

LIBRARIES =
#-------------------------------------------------------------------------------
all :	$(OBJECTS) $(LIBRARIES)
	ld65 -o regression.nes --config sample1.cfg --obj $(OBJECTS)
	./dd-img.sh regression
	cp sample1-chr.hex ../../de1_nes/
#	cp sample1-prg.hex ../../de1_nes/
#	cp regression.nes ../../de1_nes/simulation/modelsim/rom-file.nes

    
run : all
	VirtuaNES.exe regression.nes


.SUFFIXES : .asm .o

.asm.o :
	ca65 -t none $*.asm

clean :
	-rm *.nes
	-rm *.o
	-rm *.bin *.hex

