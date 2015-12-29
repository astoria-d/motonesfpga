#ASMSOURCES =	regression.asm
ASMSOURCES =	ppu-minimum.asm

OBJECTS	=	$(ASMSOURCES:.asm=.o)

LIBRARIES =
#-------------------------------------------------------------------------------
all :	$(OBJECTS) $(LIBRARIES)
	ld65 -o regression.nes --config linker.cfg --obj $(OBJECTS)

.SUFFIXES : .asm .o

.asm.o :
	ca65 -t none $*.asm

clean :
	-rm *.nes
	-rm *.o

